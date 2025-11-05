import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as log;
import 'package:flutter/foundation.dart';
import '../../../services/snackbar_service.dart';
import '../../../services/firebase_options.dart';

class ForgotController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final emailController = TextEditingController();
  final isSuccess = false.obs;
  RxString errorMessage = ''.obs;

  Future<void> sendPasswordResetEmail(String email) async {
    // Validate email format
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      errorMessage.value = 'Please enter a valid email address';
      SnackbarService.showError(
          title: 'Invalid Email',
          message: 'Please enter a valid email address');
      return;
    }

    try {
      log.log('Sending password reset email to: $email');

      // Configure ActionCodeSettings for password reset
      // Use Firebase auth domain for the continue URL
      final String continueUrl =
          'https://${DefaultFirebaseOptions.web.authDomain}/__/auth/action';
      log.log('Using continue URL: $continueUrl');

      final ActionCodeSettings actionCodeSettings = ActionCodeSettings(
        url: continueUrl,
        handleCodeInApp: false, // Use web URL (works on mobile too)
        androidPackageName: kIsWeb ? null : 'com.example.snapwise',
        androidInstallApp: false, // Don't prompt to install app
      );

      // Use Firebase's built-in password reset email with ActionCodeSettings
      await _auth.sendPasswordResetEmail(
        email: email.trim().toLowerCase(),
        actionCodeSettings: actionCodeSettings,
      );

      log.log('Password reset email sent successfully');

      // Clear any previous error messages
      errorMessage.value = '';
      isSuccess.value = true;

      SnackbarService.showSuccess(
          title: 'Email Sent',
          message:
              'Password reset email sent. Please check your inbox (and spam folder) and follow the instructions to reset your password.');
    } on FirebaseAuthException catch (e) {
      log.log(
          'Firebase Auth Error sending password reset: ${e.code} - ${e.message}');

      String errorMsg =
          'Failed to send password reset email. Please try again.';

      switch (e.code) {
        case 'user-not-found':
          errorMsg = 'No account found with this email address.';
          break;
        case 'invalid-email':
          errorMsg = 'The email address is badly formatted.';
          break;
        case 'too-many-requests':
          errorMsg = 'Too many requests. Please try again later.';
          break;
        case 'network-request-failed':
          errorMsg = 'Network error. Please check your internet connection.';
          break;
        case 'invalid-continue-uri':
          errorMsg = 'Invalid continue URL. Please contact support.';
          log.log('Invalid continue URL. Check Firebase console settings.');
          break;
        case 'unauthorized-continue-uri':
          errorMsg = 'Unauthorized continue URL. Please contact support.';
          log.log(
              'Unauthorized continue URL. Add URL to Firebase authorized domains.');
          break;
        default:
          errorMsg =
              'Failed to send password reset email: ${e.message ?? e.code}';
      }

      errorMessage.value = errorMsg;
      SnackbarService.showError(
          title: 'Password Reset Error', message: errorMsg);
    } catch (e) {
      log.log('Error sending password reset email: $e');
      errorMessage.value =
          'Failed to send password reset email. Please try again.';
      SnackbarService.showError(
          title: 'Password Reset Error',
          message: 'An unexpected error occurred. Please try again.');
    }
  }
}
