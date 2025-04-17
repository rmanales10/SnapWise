import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

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

  Future<bool> login() async {
    if (!validateInputs()) {
      Get.snackbar('Error', 'Please fill in all fields');
      return false;
    }

    _isLoading.value = true;

    try {
      // Sign in user with email and password
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      _isLoading.value = false;

      // Check if email is verified
      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        Get.snackbar('Warning', 'Please verify your email before logging in');
        await _auth.signOut();
        return false;
      }

      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading.value = false;
      String errorMessage;
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
        default:
          errorMessage = 'An error occurred. Please try again.';
      }
      Get.snackbar('Error', errorMessage);
      return false;
    } catch (e) {
      _isLoading.value = false;
      Get.snackbar('Error', 'An unexpected error occurred');
      print('Login error: ${e.toString()}');
      return false;
    }
  }

  Future<void> resetPassword() async {
    if (emailController.text.isEmpty) {
      Get.snackbar('Error', 'Please enter your email address');
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: emailController.text);
      Get.snackbar(
        'Success',
        'Password reset email sent. Please check your inbox.',
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to send password reset email');
      print('Password reset error: ${e.toString()}');
    }
  }

  void clearData() {
    emailController.clear();
    passwordController.clear();
  }
}
