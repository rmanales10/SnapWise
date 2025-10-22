import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:developer' as log;
import '../../../services/snackbar_service.dart';

import 'package:snapwise/app/crypto/cryptograpy.dart';

class ForgotController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final emailController = TextEditingController();
  final isSuccess = false.obs;
  RxString errorMessage = ''.obs;
  RxString verificationCode = ''.obs;
  RxBool isUserFound = false.obs;
  RxString userPassword = ''.obs;
  RxBool isVerified = false.obs;
  RxBool isReset = false.obs;

  String _generateVerificationCode() {
    Random random = Random();
    String code = '';
    for (int i = 0; i < 6; i++) {
      code += random.nextInt(10).toString();
    }
    return code;
  }

  Future<void> sendVerificationEmail(String email) async {
    // Validate email format
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      isUserFound.value = false;
      errorMessage.value = 'Please enter a valid email address';
      SnackbarService.showError(
          title: 'Invalid Email',
          message: 'Please enter a valid email address');
      return;
    }

    try {
      // Check if user exists in Firestore
      final user = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase().trim())
          .get();

      if (user.docs.isEmpty) {
        isUserFound.value = false;
        errorMessage.value = 'No account found with this email address';
        SnackbarService.showError(
            title: 'User Not Found',
            message: 'No account found with this email address');
        return;
      }

      isUserFound.value = true;
      userPassword.value = user.docs.first.data()['password'];

      // Generate verification code
      verificationCode.value = _generateVerificationCode();
      log.log('Generated verification code: ${verificationCode.value}');

      // Create SMTP server configuration
      // TODO: Move these credentials to environment variables for security
      final smtpServer = SmtpServer(
        'smtp.gmail.com',
        port: 465,
        username: 'officialsnapwise@gmail.com',
        password:
            'unrl zpuk rmov jqlf', // This should be in environment variables
        ssl: true,
        allowInsecure: false, // Changed to false for better security
      );

      // Create email message
      final message = Message()
        ..from = Address('officialsnapwise@gmail.com', 'SnapWise')
        ..recipients.add(email)
        ..subject = 'Reset your SnapWise account'
        ..text = 'Your verification code is: ${verificationCode.value}'
        ..html = '''
          <h1>Reset your SnapWise account</h1>
          <p>Please use the following verification code to reset your account:</p>
          <h2 style="color: #2D2C44; font-size: 24px; padding: 10px; background-color: #f5f5f5; text-align: center;">${verificationCode.value}</h2>
          <p>This code will expire in 10 minutes.</p>
          <p>If you didn't request this reset, please ignore this email.</p>
          <br>
          <p>Best regards,<br>The SnapWise Team</p>
        ''';

      log.log('Attempting to send email to: $email');

      // Send email
      final sendReport = await send(message, smtpServer);
      log.log('Send report: $sendReport');

      // Clear any previous error messages
      errorMessage.value = '';

      SnackbarService.showSuccess(
          title: 'Email Sent', message: 'Verification code sent to your email');
    } catch (e) {
      log.log('Error sending reset email: $e');
      errorMessage.value =
          'Failed to send verification email. Please try again.';

      // Provide more specific error messages
      String errorMsg = 'Failed to send verification email. Please try again.';
      if (e.toString().contains('authentication')) {
        errorMsg = 'Email authentication failed. Please contact support.';
      } else if (e.toString().contains('network')) {
        errorMsg = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('timeout')) {
        errorMsg = 'Request timed out. Please try again.';
      }

      SnackbarService.showError(title: 'Email Error', message: errorMsg);
    }
  }

  Future<void> verifyCode(String code, String email) async {
    try {
      // Validate code format
      if (code.length != 6 || !RegExp(r'^\d{6}$').hasMatch(code)) {
        isVerified.value = false;
        SnackbarService.showError(
            title: 'Invalid Code',
            message: 'Please enter a valid 6-digit code');
        return;
      }

      if (code == verificationCode.value) {
        isVerified.value = true;
        errorMessage.value = '';
        SnackbarService.showSuccess(
            title: 'Success', message: 'Code verified successfully');
      } else {
        isVerified.value = false;
        SnackbarService.showError(
            title: 'Invalid Code',
            message: 'The verification code is incorrect. Please try again.');
      }
    } catch (e) {
      isVerified.value = false;
      log.log('Verification error: $e');
      SnackbarService.showError(
          title: 'Verification Error',
          message: 'An error occurred during verification. Please try again.');
    }
  }

  Future<void> resetPassword(String newPassword, String email) async {
    try {
      // Validate new password
      if (newPassword.length < 6) {
        isReset.value = false;
        SnackbarService.showError(
            title: 'Invalid Password',
            message: 'Password must be at least 6 characters long');
        return;
      }

      // Check if user is verified
      if (!isVerified.value) {
        isReset.value = false;
        SnackbarService.showError(
            title: 'Verification Required',
            message: 'Please verify your code first');
        return;
      }

      final decryptedPassword = decryptText(userPassword.value);
      await _auth.signInWithEmailAndPassword(
        email: email.toLowerCase().trim(),
        password: decryptedPassword,
      );
      await updatePassword(newPassword);
      log.log(
          'Password reset successful for user: ${_auth.currentUser?.uid ?? 'No user found'}');
    } on FirebaseAuthException catch (e) {
      log.log('Firebase Auth Error during password reset: $e');
      isReset.value = false;

      String errorMsg = 'Failed to reset password. Please try again.';
      switch (e.code) {
        case 'user-not-found':
          errorMsg = 'User account not found.';
          break;
        case 'wrong-password':
          errorMsg = 'Invalid credentials. Please contact support.';
          break;
        case 'too-many-requests':
          errorMsg = 'Too many attempts. Please try again later.';
          break;
        case 'network-request-failed':
          errorMsg = 'Network error. Please check your internet connection.';
          break;
      }

      SnackbarService.showError(title: 'Reset Error', message: errorMsg);
    } catch (e) {
      log.log('Error resetting password: $e');
      isReset.value = false;
      SnackbarService.showError(
          title: 'Reset Error',
          message: 'An unexpected error occurred. Please try again.');
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      if (_auth.currentUser == null) {
        isReset.value = false;
        SnackbarService.showError(
            title: 'Authentication Error',
            message: 'User session expired. Please try again.');
        return;
      }

      // Update password in Firebase Auth
      await _auth.currentUser!.updatePassword(newPassword);

      // Update password in Firestore
      await _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .update({'password': encryptText(newPassword)});

      // Sign out user after successful password update
      await _auth.signOut();

      isReset.value = true;
      SnackbarService.showSuccess(
          title: 'Success',
          message:
              'Password reset successfully. Please login with your new password.');
    } on FirebaseAuthException catch (e) {
      log.log('Firebase Auth Error during password update: $e');
      isReset.value = false;

      String errorMsg = 'Failed to update password. Please try again.';
      switch (e.code) {
        case 'weak-password':
          errorMsg = 'Password is too weak. Please choose a stronger password.';
          break;
        case 'requires-recent-login':
          errorMsg = 'Please verify your identity again.';
          break;
        case 'network-request-failed':
          errorMsg = 'Network error. Please check your internet connection.';
          break;
      }

      SnackbarService.showError(title: 'Update Error', message: errorMsg);
    } catch (e) {
      log.log('Error updating password: $e');
      isReset.value = false;
      SnackbarService.showError(
          title: 'Update Error',
          message: 'An unexpected error occurred. Please try again.');
    }
  }
}
