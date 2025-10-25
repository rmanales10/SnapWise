import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'feedback_controller.dart';
import '../services/emailjs_config.dart';

class EmailJSTestWidget extends StatefulWidget {
  const EmailJSTestWidget({Key? key}) : super(key: key);

  @override
  State<EmailJSTestWidget> createState() => _EmailJSTestWidgetState();
}

class _EmailJSTestWidgetState extends State<EmailJSTestWidget> {
  final FeedbackController _feedbackController = Get.find<FeedbackController>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  int _rating = 5;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with test data
    _nameController.text = 'Test User';
    _emailController.text = 'test@example.com';
    _purposeController.text = 'Testing EmailJS Integration';
    _commentController.text =
        'This is a test email to verify EmailJS is working correctly.';
  }

  @override
  Widget build(BuildContext context) {
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: EmailJSConfig.isConfigured
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                border: Border.all(
                  color:
                      EmailJSConfig.isConfigured ? Colors.green : Colors.orange,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        EmailJSConfig.isConfigured
                            ? Icons.check_circle
                            : Icons.warning,
                        color: EmailJSConfig.isConfigured
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'EmailJS Configuration Status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: EmailJSConfig.isConfigured
                              ? Colors.green.shade800
                              : Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    EmailJSConfig.configurationStatus,
                    style: TextStyle(
                      color: EmailJSConfig.isConfigured
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                    ),
                  ),
                  if (!EmailJSConfig.isConfigured) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Please update lib/services/emailjs_config.dart with your EmailJS credentials.',
                      style:
                          TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Test Form
            const Text(
              'Test EmailJS Integration',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _purposeController,
              decoration: const InputDecoration(
                labelText: 'Purpose',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            const Text('Rating:'),
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                  icon: Icon(
                    Icons.star,
                    color: index < _rating ? Colors.amber : Colors.grey,
                    size: 32,
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Comment',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendTestEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E2E4F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Sending...'),
                        ],
                      )
                    : const Text('Send Test Email'),
              ),
            ),

            const SizedBox(height: 24),

            // Instructions
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border.all(color: Colors.blue.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Instructions:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Make sure EmailJS is configured in lib/services/emailjs_config.dart\n'
                    '2. Fill out the form above\n'
                    '3. Click "Send Test Email"\n'
                    '4. Check your Gmail inbox for the test email\n'
                    '5. Check the console logs for any errors',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendTestEmail() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _purposeController.text.isEmpty ||
        _commentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _feedbackController.sendFeedbackEmail(
        _nameController.text,
        _emailController.text,
        _purposeController.text,
        _rating,
        _commentController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test email sent! Check your inbox and console logs.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _purposeController.dispose();
    _commentController.dispose();
    super.dispose();
  }
}
