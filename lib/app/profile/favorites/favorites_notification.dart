import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class FavoritesNotification extends GetxController {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Payment Due Today Notification
  Future<void> sendPaymentDueTodayNotification({
    required String title,
    required double amountToPay,
    required String frequency,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'favorites_due_today_channel',
      'Payment Due Today',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      10, // Unique ID for payment due today
      '💰 Payment Due Today!',
      '$title payment of ₱${amountToPay.toStringAsFixed(2)} is due today ($frequency)',
      platformChannelSpecifics,
    );
  }

  // Payment Due Soon Notification (1-3 days before)
  Future<void> sendPaymentDueSoonNotification({
    required String title,
    required double amountToPay,
    required String frequency,
    required int daysUntilDue,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'favorites_due_soon_channel',
      'Payment Due Soon',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    String dayText = daysUntilDue == 1 ? 'tomorrow' : 'in $daysUntilDue days';

    await _flutterLocalNotificationsPlugin.show(
      11, // Unique ID for payment due soon
      '⏰ Payment Due Soon!',
      '$title payment of ₱${amountToPay.toStringAsFixed(2)} is due $dayText ($frequency)',
      platformChannelSpecifics,
    );
  }

  // Missed Payment Notification
  Future<void> sendMissedPaymentNotification({
    required String title,
    required double amountToPay,
    required String frequency,
    required int daysOverdue,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'favorites_missed_channel',
      'Missed Payment',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    String dayText = daysOverdue == 1 ? '1 day ago' : '$daysOverdue days ago';

    await _flutterLocalNotificationsPlugin.show(
      12, // Unique ID for missed payment
      '🚨 Payment Overdue!',
      '$title payment of ₱${amountToPay.toStringAsFixed(2)} was due $dayText ($frequency)',
      platformChannelSpecifics,
    );
  }

  // Payment Completed Notification
  Future<void> sendPaymentCompletedNotification({
    required String title,
    required double totalAmount,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'favorites_completed_channel',
      'Payment Completed',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      13, // Unique ID for payment completed
      '✅ Payment Completed!',
      '$title payment of ₱${totalAmount.toStringAsFixed(2)} has been completed successfully!',
      platformChannelSpecifics,
    );
  }

  // Helper method to calculate next payment date based on frequency
  DateTime calculateNextPaymentDate(String frequency, DateTime startDate) {
    switch (frequency.toLowerCase()) {
      case 'daily':
        return startDate.add(Duration(days: 1));
      case 'weekly':
        return startDate.add(Duration(days: 7));
      case 'monthly':
        return DateTime(startDate.year, startDate.month + 1, startDate.day);
      case 'yearly':
        return DateTime(startDate.year + 1, startDate.month, startDate.day);
      default:
        return startDate.add(Duration(days: 1));
    }
  }

  // Helper method to check if payment is due
  Map<String, dynamic> checkPaymentStatus({
    required DateTime startDate,
    required String frequency,
    required DateTime endDate,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Calculate all payment dates from start to end
    List<DateTime> paymentDates = [];
    DateTime currentDate = startDate;

    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      paymentDates.add(currentDate);
      currentDate = calculateNextPaymentDate(frequency, currentDate);
    }

    // Find the next due payment
    DateTime? nextDueDate;
    DateTime? lastDueDate;

    for (DateTime paymentDate in paymentDates) {
      if (paymentDate.isAfter(today)) {
        nextDueDate = paymentDate;
        break;
      }
      lastDueDate = paymentDate;
    }

    // Determine status
    if (nextDueDate != null) {
      final daysUntilDue = nextDueDate.difference(today).inDays;
      if (daysUntilDue == 0) {
        return {'status': 'due_today', 'days': 0};
      } else if (daysUntilDue <= 3) {
        return {'status': 'due_soon', 'days': daysUntilDue};
      } else {
        return {'status': 'upcoming', 'days': daysUntilDue};
      }
    } else if (lastDueDate != null) {
      final daysOverdue = today.difference(lastDueDate).inDays;
      if (daysOverdue > 0) {
        return {'status': 'overdue', 'days': daysOverdue};
      }
    }

    return {'status': 'completed', 'days': 0};
  }
}
