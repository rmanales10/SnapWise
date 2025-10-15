import 'package:get/get.dart';
import 'dart:math';
import 'dart:developer' as log;
import '../sms_service/sms_service.dart';

class RegisterController extends GetxController {
  final _username = ''.obs;
  final _email = ''.obs;
  final _password = ''.obs;
  final _phoneNumber = ''.obs;
  final _verificationCode = ''.obs;
  final _isEmailVerified = false.obs;

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
      log.log('Verifying SMS code: $code');
      log.log('Expected code: ${_verificationCode.value}');

      if (code == _verificationCode.value) {
        _isEmailVerified.value = true;
        log.log('SMS verification successful');
        return true;
      }
      errorMessage.value = 'Invalid verification code';

      return false;
    } catch (e) {
      log.log('Error verifying code: $e');
      errorMessage.value = 'Error verifying code: ${e.toString()}';
      return false;
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
      log.log('Starting registration process for phone: $phoneNumber');

      // Generate verification code for SMS
      _verificationCode.value = _generateVerificationCode();
      log.log('Generated verification code: ${_verificationCode.value}');

      // Send SMS verification code
      SmsService smsService = Get.put(SmsService());
      bool smsSuccess = await smsService.sendVerificationCode(
        phoneNumber: phoneNumber,
        code: _verificationCode.value,
      );

      if (smsSuccess) {
        log.log('SMS verification code sent successfully');
        return true;
      } else {
        errorMessage.value =
            'Failed to send verification SMS. Please try again.';
        return false;
      }
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
  }
}
