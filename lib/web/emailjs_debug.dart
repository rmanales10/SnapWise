import 'package:flutter/material.dart';
import 'package:snapwise/services/emailjs_config.dart';

class EmailJSDebug extends StatelessWidget {
  const EmailJSDebug({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EmailJS Debug'),
        backgroundColor: const Color(0xFF2E2E4F),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'EmailJS Configuration Debug',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Configuration Status
            Card(
              color: EmailJSConfig.isConfigured
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          EmailJSConfig.isConfigured
                              ? Icons.check_circle
                              : Icons.error,
                          color: EmailJSConfig.isConfigured
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          EmailJSConfig.isConfigured
                              ? 'Configured'
                              : 'Not Configured',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: EmailJSConfig.isConfigured
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(EmailJSConfig.configurationStatus),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Current Values
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Configuration:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildConfigRow('Service ID', EmailJSConfig.serviceId),
                    _buildConfigRow('Template ID', EmailJSConfig.templateId),
                    _buildConfigRow('Public Key', EmailJSConfig.publicKey),
                    _buildConfigRow('Private Key', EmailJSConfig.privateKey),
                    _buildConfigRow(
                        'Recipient Email', EmailJSConfig.recipientEmail),
                  ],
                ),
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
                      'How to Fix:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                        '1. Make sure your Service ID and Template ID are correct'),
                    const Text(
                        '2. Verify your Public Key and Private Key are correct'),
                    const Text(
                        '3. Check that your Gmail service is active in EmailJS'),
                    const Text(
                        '4. Ensure your email template exists and uses correct variables'),
                    const Text('5. Test the feedback form again'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not set' : value,
              style: TextStyle(
                color: value.isEmpty ? Colors.red : Colors.black,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
