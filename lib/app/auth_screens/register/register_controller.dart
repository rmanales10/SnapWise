import 'package:get/get.dart';
import 'dart:developer' as log;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:snapwise/app/crypto/cryptograpy.dart';
import '../../../services/snackbar_service.dart';

class RegisterController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _username = ''.obs;
  final _email = ''.obs;
  final _password = ''.obs;
  final _phoneNumber = ''.obs;

  set username(String value) => _username.value = value;
  set email(String value) => _email.value = value;
  set password(String value) => _password.value = value;
  set phoneNumber(String value) => _phoneNumber.value = value;

  String get username => _username.value;
  String get email => _email.value;
  String get password => _password.value;
  String get phoneNumber => _phoneNumber.value;
  RxString errorMessage = ''.obs;

  bool validateInputs() {
    if (username.isEmpty) {
      errorMessage.value = 'Please enter a username';
      return false;
    }
    if (email.isEmpty) {
      errorMessage.value = 'Please enter an email address';
      return false;
    }
    if (password.isEmpty || password.length < 6) {
      errorMessage.value = 'Password must be at least 6 characters';
      return false;
    }
    return true;
  }

  Future<bool> register() async {
    if (!validateInputs()) {
      return false;
    }

    try {
      log.log('Starting registration process for email: $email');

      // Create user with email and password
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      User? user = userCredential.user;
      if (user == null) {
        errorMessage.value = 'Failed to create user account';
        return false;
      }

      log.log('User created successfully: ${user.uid}');

      // Send email verification
      // Note: ActionCodeSettings should be configured in Firebase Console
      // Go to Authentication → Settings → Email action URL
      try {
        await user.sendEmailVerification();
        log.log('Email verification sent successfully to: $email');
      } on FirebaseAuthException catch (e) {
        log.log('Error sending email verification: ${e.code} - ${e.message}');
        // Don't fail registration if email verification fails
        // User can resend verification email later
        if (e.code == 'too-many-requests') {
          log.log(
              'Too many verification emails sent. User should wait before requesting again.');
        }
      } catch (e) {
        log.log('Unexpected error sending email verification: $e');
        // Continue with registration even if email verification fails
      }

      // Create user document in Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'username': username,
        'email': email.trim(),
        'phoneNumber': phoneNumber.isNotEmpty ? phoneNumber : '',
        'isVerified': false, // Will be set to true after email verification
        'createdAt': FieldValue.serverTimestamp(),
        'password': encryptText(password),
      });

      log.log('User document created in Firestore');

      return true;
    } on FirebaseAuthException catch (e) {
      log.log('Firebase Auth Error during registration: $e');
      String errorMsg = 'Registration failed';

      switch (e.code) {
        case 'weak-password':
          errorMsg = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          errorMsg = 'An account already exists for that email.';
          break;
        case 'invalid-email':
          errorMsg = 'The email address is badly formatted.';
          break;
        case 'operation-not-allowed':
          errorMsg = 'Email/password accounts are not enabled.';
          break;
        default:
          errorMsg = 'Registration failed: ${e.message}';
      }

      errorMessage.value = errorMsg;
      SnackbarService.showError(title: 'Registration Error', message: errorMsg);
      return false;
    } catch (e) {
      log.log('Unexpected error during registration: $e');
      errorMessage.value = 'An unexpected error occurred. Please try again.';
      SnackbarService.showError(
          title: 'Registration Error',
          message: 'An unexpected error occurred. Please try again.');
      return false;
    }
  }

  void clearData() {
    _username.value = '';
    _email.value = '';
    _password.value = '';
    _phoneNumber.value = '';
  }
}
