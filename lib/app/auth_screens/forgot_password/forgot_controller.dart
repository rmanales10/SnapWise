import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:developer' as log;

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
    final user = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .get();
    if (user.docs.isEmpty) {
      isUserFound.value = false;
      Get.snackbar('Error', 'User not found');
      return;
    }
    isUserFound.value = true;
    userPassword.value = user.docs.first.data()['password'];
    try {
      // Generate verification code
      verificationCode.value = _generateVerificationCode();
      log.log('Generated verification code: ${verificationCode.value}');

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
      Get.snackbar('Success', 'Reset email sent successfully');
    } catch (e) {
      log.log('Error sending reset email: $e');
      errorMessage.value = 'Failed to send reset email: ${e.toString()}';
      Get.snackbar('Error', errorMessage.value);
    }
  }

  Future<void> verifyCode(String code, String email) async {
    try {
      if (code == verificationCode.value) {
        isVerified.value = true;
        Get.snackbar('Success', 'Code verified successfully');
      } else {
        isVerified.value = false;
        Get.snackbar('Error', 'Invalid code');
      }
    } catch (e) {
      isVerified.value = false;
      log.log('Decryption error: $e');
    }
  }

  Future<void> resetPassword(String newPassword, String email) async {
    try {
      final decryptedPassword = decryptText(userPassword.value);
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: decryptedPassword,
      );
      await updatePassword(newPassword);
      log.log(_auth.currentUser?.uid ?? 'No user found');
    } on FirebaseAuthException catch (e) {
      log.log('Error resetting password: $e');
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser!.updatePassword(newPassword);
      await _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .update({'password': encryptText(newPassword)});
      await _auth.signOut();
      isReset.value = true;
      Get.snackbar('Success', 'Password reset successfully');
    } catch (e) {
      isReset.value = false;
      Get.snackbar('Error', 'Failed to reset password');
    }
  }
}
