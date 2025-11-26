import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'dart:developer' as log;
import '../../../services/snackbar_service.dart';

class SmsHistoryEntry {
  final String id;
  final String phoneNumber;
  final String message;
  final DateTime timestamp;
  final bool success;

  SmsHistoryEntry({
    required this.id,
    required this.phoneNumber,
    required this.message,
    required this.timestamp,
    required this.success,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'phoneNumber': phoneNumber,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'success': success,
      };

  factory SmsHistoryEntry.fromJson(Map<String, dynamic> json) =>
      SmsHistoryEntry(
        id: json['id'],
        phoneNumber: json['phoneNumber'],
        message: json['message'],
        timestamp: DateTime.parse(json['timestamp']),
        success: json['success'] ?? true,
      );
}

class SmsService extends GetxController {
  // Semaphore API configuration
  static const String _baseUrl = 'https://api.semaphore.co/api/v4/messages';
  static const String _apiKey = 'c6743576f5f28b8c6d5e429813d8d6ce';
  static const String _senderName = 'ABESO';
  static const String _smsHistoryKey = 'sms_history';

  // Observable variables
  final RxBool _isLoading = false.obs;
  final RxString _lastError = ''.obs;
  final GetStorage _storage = GetStorage();
  final RxList<SmsHistoryEntry> smsHistory = <SmsHistoryEntry>[].obs;

  // Getters
  bool get isLoading => _isLoading.value;
  String get lastError => _lastError.value;
  List<SmsHistoryEntry> get history => smsHistory.toList();

  @override
  void onInit() {
    super.onInit();
    _loadSmsHistory();
  }

  /// Load SMS history from local storage
  void _loadSmsHistory() {
    try {
      final List<dynamic>? historyData = _storage.read(_smsHistoryKey);
      if (historyData != null) {
        smsHistory.value = historyData
            .map((json) =>
                SmsHistoryEntry.fromJson(json as Map<String, dynamic>))
            .toList();
        // Sort by timestamp (newest first)
        smsHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
    } catch (e) {
      log.log('Error loading SMS history: $e');
    }
  }

  /// Save SMS history to local storage
  Future<void> _saveSmsHistory() async {
    try {
      final List<Map<String, dynamic>> historyData =
          smsHistory.map((entry) => entry.toJson()).toList();
      await _storage.write(_smsHistoryKey, historyData);
    } catch (e) {
      log.log('Error saving SMS history: $e');
    }
  }

  /// Add SMS entry to history
  Future<void> _addToHistory({
    required String phoneNumber,
    required String message,
    required bool success,
  }) async {
    final entry = SmsHistoryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      phoneNumber: phoneNumber,
      message: message,
      timestamp: DateTime.now(),
      success: success,
    );

    smsHistory.insert(0, entry);
    // Keep only last 1000 entries to prevent storage bloat
    if (smsHistory.length > 1000) {
      smsHistory.removeRange(1000, smsHistory.length);
    }
    await _saveSmsHistory();
  }

  /// Check if duplicate SMS exists (same or similar message to same number within last 24 hours)
  bool _isDuplicate(String phoneNumber, String message) {
    final now = DateTime.now();
    final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));

    // Check for exact duplicate
    bool exactDuplicate = smsHistory.any((entry) =>
        entry.phoneNumber == phoneNumber &&
        entry.message == message &&
        entry.timestamp.isAfter(twentyFourHoursAgo) &&
        entry.success);

    if (exactDuplicate) {
      return true;
    }

    // Check for similar messages (same phone number, similar content within 24 hours)
    // Remove numbers and special characters for comparison
    String normalizeMessage(String msg) {
      return msg
          .toLowerCase()
          .replaceAll(RegExp(r'[₱$0-9.,]'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }

    String normalizedNewMessage = normalizeMessage(message);

    return smsHistory.any((entry) {
      if (entry.phoneNumber != phoneNumber ||
          !entry.timestamp.isAfter(twentyFourHoursAgo) ||
          !entry.success) {
        return false;
      }

      String normalizedOldMessage = normalizeMessage(entry.message);

      // Check if messages are very similar (80% similarity)
      if (normalizedNewMessage.length < 10 ||
          normalizedOldMessage.length < 10) {
        // For short messages, require exact match
        return normalizedNewMessage == normalizedOldMessage;
      }

      // Calculate similarity (simple character-based)
      int commonChars = 0;
      int minLength = normalizedNewMessage.length < normalizedOldMessage.length
          ? normalizedNewMessage.length
          : normalizedOldMessage.length;

      for (int i = 0; i < minLength; i++) {
        if (normalizedNewMessage[i] == normalizedOldMessage[i]) {
          commonChars++;
        }
      }

      double similarity = commonChars / minLength;
      return similarity >= 0.8; // 80% similarity threshold
    });
  }

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

      // Check for duplicates before sending
      List<String> numbersToSend = [];
      List<String> duplicateNumbers = [];

      for (String number in formattedNumbers) {
        if (_isDuplicate(number, message)) {
          duplicateNumbers.add(number);
          log.log('📱 Duplicate SMS detected for $number, skipping send');
        } else {
          numbersToSend.add(number);
        }
      }

      // If all numbers are duplicates, don't send
      if (numbersToSend.isEmpty) {
        _isLoading.value = false;
        _lastError.value =
            'Duplicate SMS detected. Same message was sent recently.';
        log.log('📱 Duplicate SMS prevented for all numbers');
        return false;
      }

      // If some numbers are duplicates, only send to non-duplicates
      if (duplicateNumbers.isNotEmpty) {
        log.log(
            '📱 Skipping ${duplicateNumbers.length} duplicate number(s), sending to ${numbersToSend.length} number(s)');
      }

      // Prepare request body (only for non-duplicate numbers)
      Map<String, String> requestBody = {
        'apikey': _apiKey,
        'number': numbersToSend.join(','),
        'message': message,
        'sendername': _senderName,
      };

      log.log('Sending SMS to: ${numbersToSend.join(', ')}');
      log.log('Message: $message');

      // Make HTTP POST request to priority endpoint
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: requestBody,
      );

      // Handle response
      bool success = false;
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        log.log('SMS sent successfully: $responseData');
        success = true;
      } else {
        final errorData = json.decode(response.body);
        _lastError.value = errorData['message'] ?? 'Failed to send SMS';
        log.log(
            'SMS sending failed: ${response.statusCode} - ${response.body}');

        SnackbarService.showError(
          title: 'SMS Failed',
          message: _lastError.value,
        );
      }

      // Save to history for each number
      for (String number in numbersToSend) {
        await _addToHistory(
          phoneNumber: number,
          message: message,
          success: success,
        );
      }

      // Also record duplicates in history (marked as not sent)
      for (String number in duplicateNumbers) {
        await _addToHistory(
          phoneNumber: number,
          message: message,
          success: false, // Mark as not sent due to duplicate
        );
      }

      return success;
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
  /// Limits total message to 80 characters
  Future<bool> sendNotification({
    required String phoneNumber,
    required String title,
    required String message,
  }) async {
    // Simplified format: "SnapWise: [content]"
    // Format overhead: "SnapWise: " = 10 characters
    // Available for content: 80 - 10 = 70 characters

    const int maxTotalLength = 80;
    const String prefix = 'SnapWise: ';
    const int prefixLength = prefix.length; // 10
    const int maxContentLength = maxTotalLength - prefixLength; // 70

    // Combine title and message more compactly
    // Remove emojis from title for SMS (they take extra characters)
    String cleanTitle = title.replaceAll(RegExp(r'[🚨⚠️💰💸⏰✅]'), '').trim();

    // Create compact message: prefer message content over title
    String content = message.isNotEmpty ? message : cleanTitle;

    // If we have both title and message, combine them compactly
    if (cleanTitle.isNotEmpty && message.isNotEmpty && cleanTitle != message) {
      // Use format: "Title: Message" if both exist and different
      content = '$cleanTitle: $message';
    }

    // Truncate if necessary (without ellipsis)
    if (content.length > maxContentLength) {
      content = content.substring(0, maxContentLength);
      log.log('📱 SMS message truncated to fit 80 character limit');
    }

    String fullMessage = '$prefix$content';

    // Double-check total length doesn't exceed limit
    if (fullMessage.length > maxTotalLength) {
      int excess = fullMessage.length - maxTotalLength;
      content = content.substring(0, content.length - excess);
      fullMessage = '$prefix$content';
    }

    log.log('📱 SMS message: "$fullMessage"');
    log.log(
        '📱 SMS message length: ${fullMessage.length} characters (max: $maxTotalLength)');

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

  /// Clear SMS history
  Future<void> clearHistory() async {
    smsHistory.clear();
    await _storage.remove(_smsHistoryKey);
    log.log('SMS history cleared');
  }

  /// Get SMS history count
  int get historyCount => smsHistory.length;

  /// Get successful SMS count
  int get successfulCount => smsHistory.where((entry) => entry.success).length;

  /// Get failed SMS count
  int get failedCount => smsHistory.where((entry) => !entry.success).length;
}
