import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:math';
import 'dart:developer' as log;

import 'package:snapwise/app/crypto/cryptograpy.dart';

class RegisterController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _storage = GetStorage();

  final _username = ''.obs;
  final _email = ''.obs;
  final _password = ''.obs;
  final _phoneNumber = ''.obs;
  final _verificationCode = ''.obs;
  final _isEmailVerified = false.obs;
  UserCredential? _userCredential;

  set username(String value) => _username.value = value;
  set email(String value) => _email.value = value;
  set password(String value) => _password.value = value;
  set phoneNumber(String value) => _phoneNumber.value = value;

  String get username => _username.value;
  String get email => _email.value;
  String get password => _password.value;
  String get phoneNumber => _phoneNumber.value;
  String get verificationCode => _verificationCode.value;
  bool get isEmailVerified => _isEmailVerified.value;
  RxString errorMessage = ''.obs;
  final _connect = GetConnect();

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
      // Generate verification code
      _verificationCode.value = _generateVerificationCode();
      log.log('Generated verification code: ${_verificationCode.value}');

      // Create SMTP server configuration
      final smtpServer = SmtpServer(
        'mail.intrusion101.com',
        port: 465,
        username: 'snapwise@intrusion101.com',
        password: '#+U^L0r!baSF',
        ssl: true,
        allowInsecure: true,
      );

      // Create email message
      final message = Message()
        ..from = Address('snapwise@intrusion101.com', 'SnapWise')
        ..recipients.add(email)
        ..subject = 'Verify your SnapWise account'
        ..text = 'Your verification code is: ${_verificationCode.value}'
        ..html = '''
          <h1>Welcome to SnapWise!</h1>
          <p>Thank you for registering. Please use the following verification code to complete your registration:</p>
          <h2 style="color: #2D2C44; font-size: 24px; padding: 10px; background-color: #f5f5f5; text-align: center;">${_verificationCode.value}</h2>
          <p>This code will expire in 10 minutes.</p>
          <p>If you didn't request this verification, please ignore this email.</p>
          <br>
          <p>Best regards,<br>The SnapWise Team</p>
        ''';

      log.log('Attempting to send email to: $email');

      // Send email
      final sendReport = await send(message, smtpServer);
      log.log('Send report: $sendReport');
      Get.snackbar('Success', 'Verification email sent successfully');
    } catch (e) {
      log.log('Error sending verification email: $e');
      errorMessage.value = 'Failed to send verification email: ${e.toString()}';
      Get.snackbar('Error', errorMessage.value);
    }
  }

  Future<bool> verifyCode(String code) async {
    try {
      log.log('Verifying code: $code');
      log.log('Expected code: ${_verificationCode.value}');

      if (code == _verificationCode.value) {
        _isEmailVerified.value = true;

        // Now that email is verified, complete the registration
        if (_userCredential != null) {
          // Update user profile with username
          await _userCredential!.user?.updateDisplayName(username);
          log.log('Username updated successfully');

          // Store extended user info
          await storeExtendedUserInfo(_userCredential!.user!);
          log.log('Extended user info stored');

          // Sign out the temporary user
          await _auth.signOut();

          return true;
        }
      }
      errorMessage.value = 'Invalid verification code';

      return false;
    } catch (e) {
      log.log('Error verifying code: $e');
      errorMessage.value = 'Error verifying code: ${e.toString()}';
      return false;
    }
  }

  Future<void> storeExtendedUserInfo(User user) async {
    try {
      String country = '';
      final response = await _connect.get('https://ipwho.is/');
      if (response.status.hasError) {
        log.log('Error: ${response.statusText}');
      } else {
        final ipData = response.body;
        country = ipData['country'];
        log.log('Country: $country');
      }
      // Prepare user data
      final userData = {
        'displayName': user.displayName ?? username,
        'phoneNumber': user.phoneNumber ?? phoneNumber,
        'email': user.email ?? email,
        'country': country,
        'status': 'active',
        'isVerified': true,
        'createdAt': FieldValue.serverTimestamp(),
        'password': encryptText(password),
      };

      // Store in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(userData, SetOptions(merge: true));

      // Store locally
      await _storage.write('extendedUserInfo', userData);

      log.log('Extended user info stored successfully');
    } catch (e) {
      log.log('Error storing extended user info: $e');

      Get.snackbar('Error', 'Failed to store user information');
    }
  }

  bool validateInputs() {
    return username.isNotEmpty && email.isNotEmpty && password.isNotEmpty;
  }

  Future<bool> register() async {
    if (!validateInputs()) {
      return false;
    }

    try {
      log.log('Starting registration process for email: $email');

      // Create temporary user with email and password
      _userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      log.log('Password: $password');
      log.log('Encrypted password: ${encryptText(password)}');
      log.log('Decrypted password: ${decryptText(encryptText(password))}');

      log.log('Temporary user created successfully');

      // Send verification email
      await sendVerificationEmail();
      log.log('Verification email sent');

      return true;
    } on FirebaseAuthException catch (e) {
      log.log('Firebase Auth Error: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'weak-password':
          errorMessage.value = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          errorMessage.value = 'An account already exists for that email.';
          break;
        case 'invalid-email':
          errorMessage.value =
              'The email address is invalid. Please enter a valid email address.';
          break;
        default:
          errorMessage.value = 'An error occurred. Please try again.';
      }

      return false;
    } catch (e) {
      log.log('Unexpected error during registration: $e');
      errorMessage.value = 'An unexpected error occurred. Please try again.';
      return false;
    }
  }

  void clearData() {
    _username.value = '';
    _email.value = '';
    _password.value = '';
    _phoneNumber.value = '';
    _verificationCode.value = '';
    _isEmailVerified.value = false;
    _userCredential = null;
  }
}
