import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _storage = GetStorage();
  final _connect = GetConnect();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  RxBool isSuccess = false.obs;

  // RxMap to store user information
  final Rx<Map<String, String?>> userData = Rx<Map<String, String?>>({});

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
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      _isLoading.value = false;

      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        Get.snackbar('Warning', 'Please verify your email before logging in');
        await _auth.signOut();
        return false;
      }

      // Update user data
      updateUserData(userCredential.user);

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
        case 'invalid-credential':
          errorMessage = 'Wrong email or password.';
          break;
        default:
          errorMessage = 'An error occurred. Please try again.';
      }
      Get.snackbar('Error', errorMessage);
      return false;
    } catch (e) {
      _isLoading.value = false;
      Get.snackbar('Error', 'An unexpected error occurred');
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
      isSuccess.value = true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to send password reset email');
      isSuccess.value = false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading.value = true;

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        _isLoading.value = false;
        Get.snackbar('Error', 'Google Sign-In was cancelled');
        return false;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      _isLoading.value = false;

      if (userCredential.user != null) {
        // Update user data
        updateUserData(userCredential.user);

        return true;
      } else {
        Get.snackbar('Error', 'Failed to sign in with Google');
        return false;
      }
    } catch (e) {
      _isLoading.value = false;
      Get.snackbar('Error', 'An error occurred during Google Sign-In');
      log('Google Sign-In Error: $e');
      return false;
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
      Navigator.pushReplacementNamed(context, '/login');
      Get.snackbar('Success', 'Logout Successfully');
      Get.reset();
    } catch (e) {
      log(e.toString());
      Get.snackbar('Error', 'Failed to logout. Please try again.');
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

      print('Extended user info stored successfully');
    } catch (e) {
      print('Error storing extended user info: $e');
      Get.snackbar('Error', 'Failed to store user information');
    }
  }
}
