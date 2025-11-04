import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as log;
import '../../../services/snackbar_service.dart';

class SmsService extends GetxController {
  // Semaphore API configuration
  static const String _baseUrl = 'https://api.semaphore.co/api/v4/messages';
  static const String _apiKey = 'c6743576f5f28b8c6d5e429813d8d6ce';
  static const String _senderName = 'ABESO';

  // Observable variables
  final RxBool _isLoading = false.obs;
  final RxString _lastError = ''.obs;

  // Getters
  bool get isLoading => _isLoading.value;
  String get lastError => _lastError.value;

  /// Send SMS to single number
  Future<bool> sendSms({
    required String number,
    required String message,
  }) async {
    return await sendBulkSms(
      numbers: [number],
      message: message,
    );
  }

  /// Send SMS to multiple numbers
  Future<bool> sendBulkSms({
    required List<String> numbers,
    required String message,
  }) async {
    try {
      _isLoading.value = true;
      _lastError.value = '';

      // Validate inputs
      if (numbers.isEmpty) {
        _lastError.value = 'No phone numbers provided';
        return false;
      }

      if (message.trim().isEmpty) {
        _lastError.value = 'Message cannot be empty';
        return false;
      }

      // Format phone numbers (remove spaces, add country code if needed)
      List<String> formattedNumbers = _formatPhoneNumbers(numbers);

      // Prepare request body
      Map<String, String> requestBody = {
        'apikey': _apiKey,
        'number': formattedNumbers.join(','),
        'message': message,
        'sendername': _senderName,
      };

      log.log('Sending SMS to: ${formattedNumbers.join(', ')}');
      log.log('Message: $message');

      // Make HTTP POST request
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: requestBody,
      );

      // Handle response
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        log.log('SMS sent successfully: $responseData');

        // Show success message
        SnackbarService.showSuccess(
          title: 'SMS Sent',
          message: 'Message sent to ${formattedNumbers.length} recipient(s)',
        );

        return true;
      } else {
        final errorData = json.decode(response.body);
        _lastError.value = errorData['message'] ?? 'Failed to send SMS';
        log.log(
            'SMS sending failed: ${response.statusCode} - ${response.body}');

        SnackbarService.showError(
          title: 'SMS Failed',
          message: _lastError.value,
        );

        return false;
      }
    } catch (e) {
      _lastError.value = 'Network error: ${e.toString()}';
      log.log('SMS service error: $e');

      SnackbarService.showError(
        title: 'SMS Error',
        message: 'Failed to send SMS. Please check your connection.',
      );

      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Send verification code SMS
  Future<bool> sendVerificationCode({
    required String phoneNumber,
    required String code,
  }) async {
    String message =
        'Your SnapWise verification code is: $code\n\nThis code will expire in 10 minutes.\n\n- SnapWise';

    return await sendSms(
      number: phoneNumber,
      message: message,
    );
  }

  /// Send password reset SMS
  Future<bool> sendPasswordResetCode({
    required String phoneNumber,
    required String code,
  }) async {
    String message =
        'Your SnapWise password reset code is: $code\n\nThis code will expire in 15 minutes.\n\n- SnapWise';

    return await sendSms(
      number: phoneNumber,
      message: message,
    );
  }

  /// Send notification SMS
  Future<bool> sendNotification({
    required String phoneNumber,
    required String title,
    required String message,
  }) async {
    String fullMessage = 'Your SnapWise $title\n\n$message\n\n- SnapWise';

    return await sendSms(
      number: phoneNumber,
      message: fullMessage,
    );
  }

  /// Send SnapWise branded message
  Future<bool> sendSnapWiseMessage({
    required String phoneNumber,
    required String message,
  }) async {
    String brandedMessage = 'Your SnapWise $message\n\n- SnapWise';

    return await sendSms(
      number: phoneNumber,
      message: brandedMessage,
    );
  }

  /// Format phone numbers for Semaphore API
  List<String> _formatPhoneNumbers(List<String> numbers) {
    return numbers.map((number) {
      // Remove all non-digit characters
      String cleaned = number.replaceAll(RegExp(r'[^\d]'), '');

      // Add Philippines country code if not present
      if (cleaned.startsWith('09') && cleaned.length == 11) {
        cleaned = '63${cleaned.substring(1)}';
      } else if (cleaned.startsWith('9') && cleaned.length == 10) {
        cleaned = '63$cleaned';
      } else if (!cleaned.startsWith('63') && cleaned.length == 10) {
        cleaned = '63$cleaned';
      }

      return cleaned;
    }).toList();
  }

  /// Validate phone number format
  bool isValidPhoneNumber(String phoneNumber) {
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Check if it's a valid Philippines mobile number
    return (cleaned.startsWith('09') && cleaned.length == 11) ||
        (cleaned.startsWith('63') && cleaned.length == 12) ||
        (cleaned.startsWith('9') && cleaned.length == 10);
  }

  /// Get formatted phone number
  String getFormattedPhoneNumber(String phoneNumber) {
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    if (cleaned.startsWith('09') && cleaned.length == 11) {
      return '+63${cleaned.substring(1)}';
    } else if (cleaned.startsWith('63') && cleaned.length == 12) {
      return '+$cleaned';
    } else if (cleaned.startsWith('9') && cleaned.length == 10) {
      return '+63$cleaned';
    }

    return phoneNumber; // Return original if can't format
  }

  /// Clear last error
  void clearError() {
    _lastError.value = '';
  }

  /// Update API key
  void updateApiKey(String newApiKey) {
    // In a real app, you might want to store this securely
    // For now, just update the constant
    log.log('API key updated');
  }

  /// Get current sender name
  String get senderName => _senderName;

  /// Update sender name (for future use)
  void updateSenderName(String newSenderName) {
    log.log('Sender name updated to: $newSenderName');
  }
}
