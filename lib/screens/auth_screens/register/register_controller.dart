import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
      return false;
    }
  }

  void clearData() {
    _username.value = '';
    _email.value = '';
    _password.value = '';
  }
}
