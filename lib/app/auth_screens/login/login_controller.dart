import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  @override
  void onInit() {
    super.onInit();
    _initializeGoogleSignIn();
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      await _googleSignIn.initialize(
        // Android client ID from google-services.json
        serverClientId:
            '722916662508-usuk99tjnpe38rgq7dlph34oh0t5069k.apps.googleusercontent.com',
      );
      developer.log('GoogleSignIn initialized successfully');
    } catch (e) {
      developer.log('Error initializing GoogleSignIn: $e');
    }
  }

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

        // Get phone number from Firestore if it exists
        String? phoneNumber;
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>?;
          phoneNumber = userData?['phoneNumber'] as String?;
        }

        // Store phone number in temporary storage (even if null, so we can update it)
        await _storage.write('tempUserPhoneNumber', phoneNumber ?? '');

        // Generate verification code for SMS
        String verificationCode = _generateVerificationCode();
        await _storage.write('verificationCode', verificationCode);
        developer.log('Generated verification code: $verificationCode');

        // SMS verification will be handled by the verification screen
        errorMessage = 'Please check your phone for verification';
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
    final random = Random();
    String code = '';
    for (int i = 0; i < 6; i++) {
      code += random.nextInt(10).toString();
    }
    return code;
  }

  Future<bool> verifyCode(String code) async {
    try {
      final storedCode = await _storage.read('verificationCode') ?? '';
      developer.log('Verifying SMS code: $code');
      developer.log('Expected code: $storedCode');

      if (code == storedCode) {
        // Get stored user credentials
        final email = await _storage.read('tempUserEmail');
        final password = await _storage.read('tempUserPassword');
        final uid = await _storage.read('tempUserUid');
        final phoneNumber = await _storage.read('tempUserPhoneNumber');

        if (email != null && password != null && uid != null) {
          // Prepare update data
          Map<String, dynamic> updateData = {
            'isVerified': true,
            'verifiedAt': FieldValue.serverTimestamp(),
          };

          // Update phone number if it exists from temp storage
          // (This would be the phone number from Firestore or passed from VerifyScreen)
          if (phoneNumber != null && phoneNumber.toString().isNotEmpty) {
            updateData['phoneNumber'] = phoneNumber;
          }

          // Update user verification status and phone number in Firestore
          await _firestore.collection('users').doc(uid).update(updateData);

          // Clear temporary data
          await _storage.remove('tempUserEmail');
          await _storage.remove('tempUserPassword');
          await _storage.remove('tempUserUid');
          await _storage.remove('tempUserPhoneNumber');
          await _storage.remove('verificationCode');

          // Get current user and update data
          User? currentUser = _auth.currentUser;
          if (currentUser != null) {
            updateUserData(currentUser);
          }

          return true;
        }
      }
      SnackbarService.showError(
          title: 'Verification Error', message: 'Invalid code');
      return false;
    } catch (e) {
      developer.log('Error verifying SMS code: $e');
      _auth.signOut();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading.value = true;

    try {
      developer.log('=== GOOGLE SIGN-IN START ===');

      // Check if authenticate is supported on this platform
      if (!_googleSignIn.supportsAuthenticate()) {
        developer.log('ERROR: authenticate() not supported on this platform');
        SnackbarService.showError(
            title: 'Google Sign-In Error',
            message: 'Google Sign-In is not supported on this platform');
        return false;
      }

      // Trigger the interactive Google Sign-In flow using the new API
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      developer.log('Google sign-in dialog completed');

      developer.log('User signed in: ${googleUser.email}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      developer.log('Got authentication tokens');

      // Validate that we have the required tokens
      if (googleAuth.idToken == null) {
        developer.log('ERROR: No ID token received');
        SnackbarService.showError(
            title: 'Google Sign-In Error',
            message: 'Failed to get authentication token');
        return false;
      }

      // Create a new credential (only idToken is required, accessToken is optional)
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      developer.log('Created Firebase credential');

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      developer.log('Signed in to Firebase');

      if (userCredential.user != null) {
        developer.log('Firebase user created: ${userCredential.user!.uid}');

        // Create or update user in Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': userCredential.user!.email,
          'displayName': userCredential.user!.displayName,
          'photoUrl': userCredential.user!.photoURL,
          'isVerified': true, // Google users are pre-verified
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'authProvider': 'google',
        }, SetOptions(merge: true));
        developer.log('User data stored in Firestore');

        // Update local user data (no await - it's void)
        updateUserData(userCredential.user);
        developer.log('Local user data updated');

        developer.log('=== GOOGLE SIGN-IN SUCCESS ===');
        return true;
      } else {
        developer.log('ERROR: userCredential.user is null');
        SnackbarService.showError(
            title: 'Google Sign-In Error',
            message: 'Failed to create user account');
        return false;
      }
    } on FirebaseAuthException catch (e) {
      developer.log('FirebaseAuthException: ${e.code} - ${e.message}');
      String errorMessage = 'Authentication failed';

      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage =
              'An account already exists with the same email but different sign-in credentials.';
          break;
        case 'invalid-credential':
          errorMessage = 'The credential is malformed or has expired.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Google sign-in is not enabled for this app.';
          break;
        case 'user-disabled':
          errorMessage = 'This user account has been disabled.';
          break;
        case 'user-not-found':
          errorMessage = 'No user found with this credential.';
          break;
        case 'wrong-password':
          errorMessage = 'Invalid password.';
          break;
        default:
          errorMessage = e.message ?? 'An authentication error occurred';
      }

      SnackbarService.showError(
          title: 'Authentication Error', message: errorMessage);
      return false;
    } catch (e, stackTrace) {
      developer.log('Google Sign-In Error: $e');
      developer.log('Stack trace: $stackTrace');

      // Check if user cancelled the sign-in
      if (e.toString().contains('sign_in_canceled') ||
          e.toString().contains('ERROR_USER_CANCELED') ||
          e.toString().contains('User canceled')) {
        developer.log('User cancelled sign-in');
        // Don't show error snackbar for cancellation
        return false;
      }

      // Provide more specific error messages
      String errorMessage = 'An unexpected error occurred';
      if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('PlatformException')) {
        errorMessage = 'Google Sign-In is not properly configured.';
      } else if (e.toString().contains('DEVELOPER_ERROR')) {
        errorMessage =
            'Google Sign-In configuration error. Please check SHA-1 fingerprint.';
      }

      SnackbarService.showError(
          title: 'Google Sign-In Error', message: errorMessage);
      return false;
    } finally {
      _isLoading.value = false;
      developer.log('Google sign-in process completed');
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
      // Fetch existing user document to preserve phone number if it exists
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      // Preserve existing phone number from Firestore, or use Firebase Auth phone number
      String? existingPhoneNumber;
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        existingPhoneNumber = userData?['phoneNumber'] as String?;
      }

      // Use existing phone number if available, otherwise fall back to Firebase Auth phone number
      final phoneNumber = existingPhoneNumber ?? user.phoneNumber ?? '';

      // Fetch IP address and country
      final response = await _connect.get('https://ipapi.co/json/');
      final ipData = response.body;
      final country = ipData['country_name'] ?? 'Philippines';

      final now = DateTime.now();

      // Prepare user data for Firestore (can use DateTime)
      final userDataFirestore = {
        'displayName': user.displayName ?? '',
        'phoneNumber': phoneNumber,
        'email': user.email ?? '',
        'country': country,
        'status': 'active', // Default status
        'lastLogin': now,
      };

      // Prepare user data for local storage (convert DateTime to String)
      final userDataLocal = {
        'displayName': user.displayName ?? '',
        'phoneNumber': phoneNumber,
        'email': user.email ?? '',
        'country': country,
        'status': 'active',
        'lastLogin': now.toIso8601String(), // Convert DateTime to String
      };

      // Store in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(userDataFirestore, SetOptions(merge: true));

      // Store locally with serializable data
      await _storage.write('extendedUserInfo', userDataLocal);

      developer.log('Extended user info stored successfully');
      if (phoneNumber.isNotEmpty) {
        developer.log('Phone number preserved: $phoneNumber');
      }
    } catch (e) {
      developer.log('Error storing extended user info: $e');
      SnackbarService.showError(
          title: 'Data Error', message: 'Failed to store user information');
    }
  }
}
