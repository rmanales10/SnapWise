import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snapwise/services/emailjs_config.dart';
import 'package:snapwise/web/feedback_controller.dart';

class EmailJSTestSimple extends StatelessWidget {
  const EmailJSTestSimple({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FeedbackController controller = Get.find<FeedbackController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('EmailJS Test'),
        backgroundColor: const Color(0xFF2E2E4F),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Configuration Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'EmailJS Configuration Status',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Configured: ${EmailJSConfig.isConfigured}'),
                    Text('Status: ${EmailJSConfig.configurationStatus}'),
                    const SizedBox(height: 8),
                    const Text('Credentials:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Service ID: ${EmailJSConfig.serviceId}'),
                    Text('Template ID: ${EmailJSConfig.templateId}'),
                    Text('Public Key: ${EmailJSConfig.publicKey}'),
                    Text('Private Key: ${EmailJSConfig.privateKey}'),
                    Text('Recipient: ${EmailJSConfig.recipientEmail}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Test Button
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await controller.sendFeedbackEmail(
                      'Test User',
                      'test@example.com',
                      'Testing EmailJS',
                      5,
                      'This is a test message to verify EmailJS integration.',
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Test failed: $e')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E2E4F),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Send Test Email'),
              ),
            ),

            const SizedBox(height: 20),

            // Instructions
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Instructions:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                        '1. Check if EmailJS is properly configured above'),
                    const Text(
                        '2. If not configured, update the credentials in emailjs_config.dart'),
                    const Text(
                        '3. Make sure you have created a Gmail service and template in EmailJS dashboard'),
                    const Text(
                        '4. Click "Send Test Email" to test the integration'),
                    const Text(
                        '5. Check the console logs for detailed error information'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
