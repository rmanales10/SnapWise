import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class BudgetNotification extends GetxController {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> sendBudgetExceededNotification({
    required double spentPercentage,
    required double remainingBudget,
  }) async {
    // Schedule the notification to be shown after 5 minutes
    await Future.delayed(const Duration(minutes: 5));

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'budget_alert_channel',
          'Budget Alerts',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    spentPercentage = spentPercentage * 100;
    await _flutterLocalNotificationsPlugin.show(
      2, // Use a unique ID
      'Budget Alert',
      'You\'ve spent ${spentPercentage.toStringAsFixed(2)}% of your budget. Remaining: $remainingBudget',
      platformChannelSpecifics,
    );

    // Log the event
    await _analytics.logEvent(
      name: 'budget_exceeded_notification',
      parameters: {
        'spent_percentage': spentPercentage,
        'remaining_budget': remainingBudget,
      },
    );
  }

  Future<void> sendIncomeRemaining({
    required double spentPercentage,
    required double remainingBudget,
  }) async {
    // Schedule the notification to be shown after 5 minutes
    // await Future.delayed(const Duration(minutes: 5));

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'income_alert_channel',
          'Income Alerts',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    spentPercentage = spentPercentage * 100;
    await _flutterLocalNotificationsPlugin.show(
      2, // Use a unique ID
      'Income Alert',
      'You\'ve spent ${spentPercentage.toStringAsFixed(2)}% of your income. Remaining: $remainingBudget',
      platformChannelSpecifics,
    );

    // Log the event
    await _analytics.logEvent(
      name: 'income_remaining_notification',
      parameters: {
        'spent_percentage': spentPercentage,
        'remaining_income': remainingBudget,
      },
    );
  }
}
