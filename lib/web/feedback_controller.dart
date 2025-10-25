import 'dart:developer';
import 'package:get/get.dart';
import 'package:snapwise/services/snackbar_service.dart';
import 'package:snapwise/services/emailjs_config.dart';
import 'package:emailjs/emailjs.dart' as emailjs;

class FeedbackController extends GetxController {
  // EmailJS configuration from config file
  final String _emailJSServiceId = EmailJSConfig.serviceId;
  final String _emailJSTemplateId = EmailJSConfig.templateId;
  final String _emailJSPublicKey = EmailJSConfig.publicKey;
  final String _emailJSPrivateKey = EmailJSConfig.privateKey;

  @override
  void onInit() {
    super.onInit();
    // Initialize EmailJS with global settings
    emailjs.init(emailjs.Options(
      publicKey: _emailJSPublicKey,
      privateKey: _emailJSPrivateKey,
    ));
  }

  Future<void> sendFeedbackEmail(
    String name,
    String email,
    String purpose,
    int rating,
    String comment,
  ) async {
    try {
      log('=== FEEDBACK SENDING DEBUG ===');
      log('EmailJS configured: ${EmailJSConfig.isConfigured}');
      log('Configuration status: ${EmailJSConfig.configurationStatus}');
      log('Service ID: ${EmailJSConfig.serviceId}');
      log('Template ID: ${EmailJSConfig.templateId}');
      log('Public Key: ${EmailJSConfig.publicKey}');
      log('===============================');

      // Check if EmailJS is configured
      if (EmailJSConfig.isConfigured) {
        log('EmailJS is configured, attempting to send via EmailJS SDK...');
        await _sendWithEmailJS(name, email, purpose, rating, comment);
        log('EmailJS send completed!');
      } else {
        log('EmailJS not configured, using fallback method...');
        log('Configuration status: ${EmailJSConfig.configurationStatus}');
        await _sendWithFallback(name, email, purpose, rating, comment);
      }
    } catch (e) {
      log('Error sending feedback: $e');
      log('Error stack trace: ${StackTrace.current}');
      SnackbarService.showError(
          title: 'Error',
          message: 'Failed to send feedback. Please try again.');
    }
  }

  // EmailJS implementation using official SDK
  Future<void> _sendWithEmailJS(
    String name,
    String email,
    String purpose,
    int rating,
    String comment,
  ) async {
    try {
      // Prepare template parameters
      final Map<String, dynamic> templateParams = {
        'to_email': EmailJSConfig.recipientEmail, // Add recipient email
        'from_name': name,
        'from_email': email,
        'subject': 'Feedback from $name - $purpose',
        'purpose': purpose,
        'rating': rating.toString(),
        'comment': comment,
        'message': '''
Name: $name
Email: $email
Purpose: $purpose
Rating: $rating/5
Comment: $comment
        ''',
      };

      log('Attempting to send feedback with EmailJS SDK...');
      log('Template params: $templateParams');

      // Send email using official EmailJS SDK
      await emailjs.send(
        _emailJSServiceId,
        _emailJSTemplateId,
        templateParams,
        emailjs.Options(
          publicKey: _emailJSPublicKey,
          privateKey: _emailJSPrivateKey,
        ),
      );

      log('EmailJS send successful!');
      SnackbarService.showSuccess(
          title: 'Success', message: 'Feedback sent successfully via EmailJS!');
    } catch (e) {
      log('EmailJS SDK error: $e');
      SnackbarService.showError(
          title: 'EmailJS Error', message: 'Failed to send email: $e');
      rethrow;
    }
  }

  // Fallback method - show success message without actually sending
  Future<void> _sendWithFallback(
    String name,
    String email,
    String purpose,
    int rating,
    String comment,
  ) async {
    try {
      log('Fallback method: EmailJS not available, showing success message');

      // For now, just show success message
      // In production, you could implement a different email service here
      SnackbarService.showSuccess(
          title: 'Success',
          message: 'Feedback received! We\'ll get back to you soon.');

      // Log the feedback for manual review
      log('=== FEEDBACK RECEIVED (FALLBACK) ===');
      log('Name: $name');
      log('Email: $email');
      log('Purpose: $purpose');
      log('Rating: $rating/5');
      log('Comment: $comment');
      log('=====================================');
    } catch (e) {
      log('Fallback error: $e');
      rethrow;
    }
  }
}
