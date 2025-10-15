import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'sms_service.dart';

/// Example usage of the SMS Service
class SmsExample extends StatelessWidget {
  const SmsExample({super.key});

  @override
  Widget build(BuildContext context) {
    final SmsService smsService = Get.put(SmsService());

    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Service Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Send SnapWise Branded Message
            ElevatedButton(
              onPressed: () async {
                bool success = await smsService.sendSnapWiseMessage(
                  phoneNumber: '09123456789',
                  message: 'welcome message! Thank you for joining us.',
                );
                print('SnapWise SMS sent: $success');
                print('Sender: ${smsService.senderName}');
              },
              child: const Text('Send SnapWise Branded Message'),
            ),

            const SizedBox(height: 16),

            // Send Bulk SMS
            ElevatedButton(
              onPressed: () async {
                bool success = await smsService.sendBulkSms(
                  numbers: ['09123456789', '09987654321'],
                  message: 'Bulk message from SnapWise!',
                );
                print('Bulk SMS sent: $success');
              },
              child: const Text('Send Bulk SMS'),
            ),

            const SizedBox(height: 16),

            // Send Verification Code
            ElevatedButton(
              onPressed: () async {
                bool success = await smsService.sendVerificationCode(
                  phoneNumber: '09123456789',
                  code: '123456',
                );
                print('Verification SMS sent: $success');
              },
              child: const Text('Send Verification Code'),
            ),

            const SizedBox(height: 16),

            // Send Password Reset
            ElevatedButton(
              onPressed: () async {
                bool success = await smsService.sendPasswordResetCode(
                  phoneNumber: '09123456789',
                  code: '789012',
                );
                print('Password reset SMS sent: $success');
              },
              child: const Text('Send Password Reset Code'),
            ),

            const SizedBox(height: 16),

            // Send Notification
            ElevatedButton(
              onPressed: () async {
                bool success = await smsService.sendNotification(
                  phoneNumber: '09123456789',
                  title: 'Budget Alert',
                  message: 'You have exceeded your monthly budget limit.',
                );
                print('Notification SMS sent: $success');
              },
              child: const Text('Send SnapWise Notification'),
            ),

            const SizedBox(height: 16),

            // Loading indicator
            Obx(() => smsService.isLoading
                ? const Center(child: CircularProgressIndicator())
                : const SizedBox.shrink()),

            const SizedBox(height: 16),

            // Error display
            Obx(() => smsService.lastError.isNotEmpty
                ? Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Error: ${smsService.lastError}',
                      style: TextStyle(color: Colors.red.shade800),
                    ),
                  )
                : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}
