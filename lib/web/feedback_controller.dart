import 'dart:developer';

import 'package:get/get.dart';
import 'package:flutter/material.dart';

class FeedbackController extends GetxController {
  final String _apiUrl = 'http://intrusion101.com/send_email.php';
  late GetConnect _connect;

  @override
  void onInit() {
    super.onInit();
    _connect = GetConnect();
  }

  Future<void> sendFeedbackEmail(
    String name,
    String email,
    String purpose,
    int rating,
    String comment,
  ) async {
    try {
      // Prepare the request data according to API requirements
      final Map<String, dynamic> requestData = {
        'to': 'snapwiseofficial25@gmail.com', // Change to recipient's email
        'subject': 'Feedback from $name - $purpose',
        'message': '''
Name: $name
Email: $email
Purpose: $purpose
Rating: $rating/5
Comment: $comment
        ''',
      };

      log('Attempting to send feedback to: $_apiUrl');
      log('Feedback data: $requestData');

      // Make HTTP POST request using GetConnect
      final response = await _connect.post(
        _apiUrl,
        requestData,
      );

      log('Response status code: ${response.statusCode}');
      log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = response.body;

        if (responseData['success'] == true) {
          Get.snackbar(
            'Success',
            responseData['message'] ?? 'Feedback sent successfully',
            snackPosition: SnackPosition.TOP,
            backgroundColor: const Color(0xFF4CAF50),
            colorText: Colors.white,
          );
        } else {
          throw Exception(responseData['error'] ?? 'Failed to send feedback');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      log('Error sending feedback: $e');
      Get.snackbar(
        'Error',
        'Failed to send feedback. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFFF44336),
        colorText: Colors.white,
      );
    }
  }
}
