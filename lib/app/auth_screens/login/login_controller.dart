import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:math';
import '../../../services/snackbar_service.dart';

import 'package:snapwise/app/auth_screens/login/login.dart';

// Enum for login result
enum LoginResult { success, unverified, error }

class LoginController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _storage = GetStorage();
  final _connect = GetConnect();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  RxBool isSuccess = false.obs;
  String errorMessage = '';

  // RxMap to store user information
  final Rx<Map<String, String?>> userData = Rx<Map<String, String?>>({});

  // Helper method to safely show snackbars

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  bool validateInputs() {
    return emailController.text.isNotEmpty &&
        passwordController.text.isNotEmpty;
  }

  Future<LoginResult> login() async {
    if (!validateInputs()) {
      errorMessage = 'Please fill in all fields';
      SnackbarService.showValidationError('Please fill in all fields');
      _auth.signOut();
      return LoginResult.error;
    }

    _isLoading.value = true;

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      _isLoading.value = false;

      // Check if user exists in Firestore and is verified
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user?.uid)
          .get();

      if (!userDoc.exists || userDoc.get('isVerified') != true) {
        // Store user credentials temporarily for verification
        await _storage.write('tempUserEmail', emailController.text);
        await _storage.write('tempUserPassword', passwordController.text);
        await _storage.write('tempUserUid', userCredential.user?.uid);

        // Send verification email
        await sendVerificationEmail();

        errorMessage = 'Please check your email for verification';
        _auth.signOut();
        return LoginResult.unverified;
      }

      // Update user data
      updateUserData(userCredential.user);

      return LoginResult.success;
    } on FirebaseAuthException catch (e) {
      _isLoading.value = false;

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found for that email.';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided for that user.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is badly formatted.';
          break;
        case 'user-disabled':
          errorMessage = 'This user has been disabled.';
          break;
        case 'invalid-credential':
          errorMessage = 'Invalid credentials. Please try again.';
          break;
        default:
          errorMessage = 'An error occurred. Please try again.';
      }
      SnackbarService.showError(title: 'Login Error', message: errorMessage);
      _auth.signOut();
      return LoginResult.error;
    } catch (e) {
      _isLoading.value = false;
      SnackbarService.showError(
          title: 'Login Error', message: 'An unexpected error occurred');
      _auth.signOut();
      return LoginResult.error;
    }
  }

  String _generateVerificationCode() {
    Random random = Random();
    String code = '';
    for (int i = 0; i < 6; i++) {
      code += random.nextInt(10).toString();
    }
    return code;
  }

  Future<void> sendVerificationEmail() async {
    try {
      String email = emailController.text;
      String verificationCode = _generateVerificationCode();

      // Store verification code
      await _storage.write('verificationCode', verificationCode);
      developer.log('Generated verification code: $verificationCode');

      // Create SMTP server configuration
      final smtpServer = SmtpServer(
        'smtp.gmail.com',
        port: 465,
        username: 'officialsnapwise@gmail.com',
        password: 'unrl zpuk rmov jqlf',
        ssl: true,
        allowInsecure: true,
      );

      // Create email message
      final message = Message()
        ..from = Address('officialsnapwise@gmail.com', 'SnapWise')
        ..recipients.add(email)
        ..subject = 'Verify your SnapWise account'
        ..text = 'Your verification code is: $verificationCode'
        ..html = '''
          <h1>Welcome to SnapWise!</h1>
          <p>Please use the following verification code to complete your login:</p>
          <h2 style="color: #2D2C44; font-size: 24px; padding: 10px; background-color: #f5f5f5; text-align: center;">$verificationCode</h2>
          <p>This code will expire in 10 minutes.</p>
          <p>If you didn't request this verification, please ignore this email.</p>
          <br>
          <p>Best regards,<br>The SnapWise Team</p>
        ''';

      developer.log('Attempting to send email to: $email');

      // Send email
      final sendReport = await send(message, smtpServer);
      developer.log('Send report: $sendReport');

      if (sendReport.toString().contains('OK')) {
        SnackbarService.showSuccess(
            title: 'Success', message: 'Verification email sent successfully');
      } else {
        throw Exception('Failed to send email: ${sendReport.toString()}');
      }
    } catch (e) {
      developer.log('Error sending verification email: $e');
      SnackbarService.showError(
          title: 'Email Error',
          message: 'Failed to send verification email: ${e.toString()}');
    }
  }

  Future<bool> verifyCode(String code) async {
    try {
      final storedCode = await _storage.read('verificationCode') ?? '';
      developer.log('Verifying code: $code');
      developer.log('Expected code: $storedCode');

      if (code == storedCode) {
        // Get stored user credentials
        final email = await _storage.read('tempUserEmail');
        final password = await _storage.read('tempUserPassword');
        final uid = await _storage.read('tempUserUid');

        if (email != null && password != null && uid != null) {
          // Update user verification status in Firestore
          await _firestore.collection('users').doc(uid).update({
            'isVerified': true,
            'verifiedAt': FieldValue.serverTimestamp(),
          });

          // Clear temporary data
          await _storage.remove('tempUserEmail');
          await _storage.remove('tempUserPassword');
          await _storage.remove('tempUserUid');
          await _storage.remove('verificationCode');

          // Get current user and update data
          User? currentUser = _auth.currentUser;
          if (currentUser != null) {
            updateUserData(currentUser);
          }

          return true;
        }
      }
      return false;
    } catch (e) {
      developer.log('Error verifying code: $e');
      _auth.signOut();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading.value = true;

    try {
      // Optional cleanup
      await _googleSignIn.disconnect();

      await _googleSignIn.initialize(
        serverClientId:
            '722916662508-v4u8l28sub5i4sabqtn51n9tcchhk1o8.apps.googleusercontent.com',
      );

      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      if (googleUser.displayName == null) {
        SnackbarService.showInfo(
            title: 'Cancelled', message: 'Google Sign-In was cancelled');
        return false;
      }

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        // ⚠️ accessToken no longer used or required
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        updateUserData(userCredential.user);
        return true;
      } else {
        SnackbarService.showError(
            title: 'Google Sign-In Error',
            message: 'Failed to sign in with Google');
        return false;
      }
    } on FirebaseAuthException catch (e) {
      SnackbarService.showError(
          title: 'Auth Error', message: e.message ?? 'Unknown Firebase error');
      developer.log('FirebaseAuthException: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      SnackbarService.showError(
          title: 'Google Sign-In Error',
          message: 'An unexpected error occurred');
      developer.log('Google Sign-In Error: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  void updateUserData(User? user) async {
    if (user != null) {
      userData.value = {
        'displayName': user.displayName,
        'photoUrl': user.photoURL,
        'phoneNumber': user.phoneNumber,
      };
      await _storage.write('displayName', userData.value['displayName']);
      await _storage.write('photoUrl', userData.value['photoUrl']);

      // Call the new function to store extended user info
      await storeExtendedUserInfo(user);
    } else {
      userData.value = {};
    }
  }

  void clearData() {
    emailController.clear();
    passwordController.clear();
    userData.value = {};
  }

  Future<void> logout(BuildContext context) async {
    try {
      final String? uid = _auth.currentUser?.uid;
      await _auth.signOut();
      await _storage.erase();
      await _firestore.collection('users').doc(uid).set({
        'status': 'inactive',
        'lastLogout': DateTime.now(),
      }, SetOptions(merge: true));

      // ignore: use_build_context_synchronously
      Get.offAll(() => const LoginPage());
      SnackbarService.showSuccess(
          title: 'Success', message: 'Logout Successfully');
      Get.reset();
    } catch (e) {
      developer.log(e.toString());
      SnackbarService.showError(
          title: 'Logout Error',
          message: 'Failed to logout. Please try again.');
    }
  }

  Future<void> storeExtendedUserInfo(User user) async {
    try {
      // Fetch IP address and country
      final response = await _connect.get('https://ipapi.co/json/');
      final ipData = response.body;
      final country = ipData['country_name'] ?? 'Philippines';

      // Prepare user data
      final userData = {
        'displayName': user.displayName ?? '',
        'phoneNumber': user.phoneNumber ?? '',
        'email': user.email ?? '',
        'country': country,
        'status': 'active', // Default status
        'lastLogin': DateTime.now(),
      };

      // Store in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(userData, SetOptions(merge: true));

      // Store locally
      await _storage.write('extendedUserInfo', userData);

      developer.log('Extended user info stored successfully');
    } catch (e) {
      developer.log('Error storing extended user info: $e');
      SnackbarService.showError(
          title: 'Data Error', message: 'Failed to store user information');
    }
  }
}
