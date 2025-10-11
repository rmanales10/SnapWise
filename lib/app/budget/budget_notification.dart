import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class BudgetNotification extends GetxController {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Overall Budget Notification
  Future<void> sendOverallBudgetExceededNotification({
    required double totalExpenses,
    required double budgetLimit,
    required double exceededAmount,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'overall_budget_alert_channel',
      'Overall Budget Alerts',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      1, // Unique ID for overall budget
      '🚨 Budget Limit Exceeded!',
      'You\'ve exceeded your overall budget by ₱${exceededAmount.toStringAsFixed(2)}. Total spent: ₱${totalExpenses.toStringAsFixed(2)}',
      platformChannelSpecifics,
    );
  }

  // Category Budget Notification
  Future<void> sendCategoryBudgetExceededNotification({
    required String category,
    required double categoryExpenses,
    required double categoryLimit,
    required double exceededAmount,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'category_budget_alert_channel',
      'Category Budget Alerts',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      2, // Unique ID for category budget
      '⚠️ $category Budget Exceeded!',
      'You\'ve exceeded your $category budget by ₱${exceededAmount.toStringAsFixed(2)}. Spent: ₱${categoryExpenses.toStringAsFixed(2)}',
      platformChannelSpecifics,
    );
  }

  // Legacy method for backward compatibility
  Future<void> sendBudgetExceededNotification({
    required double spentPercentage,
    required double remainingBudget,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'budget_alert_channel',
      'Budget Alerts',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    spentPercentage = spentPercentage * 100;
    await _flutterLocalNotificationsPlugin.show(
      3, // Use a unique ID
      'Budget Alert',
      'You\'ve spent ${spentPercentage.toStringAsFixed(2)}% of your budget. Remaining: ₱${remainingBudget.toStringAsFixed(2)}',
      platformChannelSpecifics,
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
      icon: '@mipmap/launcher_icon',
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
  }
}
