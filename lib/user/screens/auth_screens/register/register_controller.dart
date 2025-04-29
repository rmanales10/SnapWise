import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_storage/get_storage.dart';

class RegisterController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _storage = GetStorage();

  final _username = ''.obs;
  final _email = ''.obs;
  final _password = ''.obs;

  set username(String value) => _username.value = value;
  set email(String value) => _email.value = value;
  set password(String value) => _password.value = value;

  String get username => _username.value;
  String get email => _email.value;
  String get password => _password.value;
  RxString errorMessage = ''.obs;
  final _connect = GetConnect();

  Future<void> storeExtendedUserInfo(User user) async {
    try {
      // Fetch IP address and country
      final response = await _connect.get('https://ipapi.co/json/');
      final ipData = response.body;
      final country = ipData['country_name'];

      // Prepare user data
      final userData = {
        'displayName': user.displayName ?? '',
        'phoneNumber': user.phoneNumber ?? '',
        'email': user.email ?? '',
        'country': country,
        'status': 'active', // Default status
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

  bool validateInputs() {
    return username.isNotEmpty && email.isNotEmpty && password.isNotEmpty;
  }

  Future<bool> register() async {
    if (!validateInputs()) {
      return false;
    }

    try {
      // Create user with email and password
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Update user profile with username
      await userCredential.user?.updateDisplayName(username);

      // Send email verification
      await userCredential.user?.sendEmailVerification();

      // Store extended user info
      if (userCredential.user != null) {
        await storeExtendedUserInfo(userCredential.user!);
      }

      return true;
    } on FirebaseAuthException catch (e) {
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
      errorMessage.value = 'An unexpected error occurred. Please try again.';
      return false;
    }
  }

  void clearData() {
    _username.value = '';
    _email.value = '';
    _password.value = '';
  }
}
