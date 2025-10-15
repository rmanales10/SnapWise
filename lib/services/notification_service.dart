import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class NotificationService extends GetxController {
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Notification IDs for different types
  static const int OVERALL_BUDGET_ID = 1;
  static const int CATEGORY_BUDGET_ID = 2;
  static const int INCOME_ALERT_ID = 3;
  static const int PAYMENT_DUE_TODAY_ID = 10;
  static const int PAYMENT_DUE_SOON_ID = 11;
  static const int PAYMENT_OVERDUE_ID = 12;
  static const int PAYMENT_COMPLETED_ID = 13;

  // Channel IDs
  static const String OVERALL_BUDGET_CHANNEL = 'overall_budget_channel';
  static const String CATEGORY_BUDGET_CHANNEL = 'category_budget_channel';
  static const String INCOME_ALERT_CHANNEL = 'income_alert_channel';
  static const String PAYMENT_DUE_TODAY_CHANNEL = 'payment_due_today_channel';
  static const String PAYMENT_DUE_SOON_CHANNEL = 'payment_due_soon_channel';
  static const String PAYMENT_OVERDUE_CHANNEL = 'payment_overdue_channel';
  static const String PAYMENT_COMPLETED_CHANNEL = 'payment_completed_channel';

  @override
  void onInit() {
    super.onInit();
    _initializeNotifications();
  }

  /// Initialize notification service with proper settings
  Future<void> _initializeNotifications() async {
    try {
      // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

      // iOS initialization settings
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Combined initialization settings
      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      // Initialize the plugin
      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channels for Android
      await _createNotificationChannels();

      // Request permissions
      await _requestPermissions();

      if (kDebugMode) {
        print('NotificationService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing NotificationService: $e');
      }
    }
  }

  /// Create notification channels for Android 8.0+
  Future<void> _createNotificationChannels() async {
    if (!kIsWeb) {
      // Overall Budget Channel
      const AndroidNotificationChannel overallBudgetChannel =
          AndroidNotificationChannel(
        OVERALL_BUDGET_CHANNEL,
        'Overall Budget Alerts',
        description: 'Notifications for overall budget exceeded',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      // Category Budget Channel
      const AndroidNotificationChannel categoryBudgetChannel =
          AndroidNotificationChannel(
        CATEGORY_BUDGET_CHANNEL,
        'Category Budget Alerts',
        description: 'Notifications for category budget exceeded',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      // Income Alert Channel
      const AndroidNotificationChannel incomeAlertChannel =
          AndroidNotificationChannel(
        INCOME_ALERT_CHANNEL,
        'Income Alerts',
        description: 'Notifications for income-related alerts',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      // Payment Due Today Channel
      const AndroidNotificationChannel paymentDueTodayChannel =
          AndroidNotificationChannel(
        PAYMENT_DUE_TODAY_CHANNEL,
        'Payment Due Today',
        description: 'Notifications for payments due today',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      // Payment Due Soon Channel
      const AndroidNotificationChannel paymentDueSoonChannel =
          AndroidNotificationChannel(
        PAYMENT_DUE_SOON_CHANNEL,
        'Payment Due Soon',
        description: 'Notifications for payments due soon',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      // Payment Overdue Channel
      const AndroidNotificationChannel paymentOverdueChannel =
          AndroidNotificationChannel(
        PAYMENT_OVERDUE_CHANNEL,
        'Payment Overdue',
        description: 'Notifications for overdue payments',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      // Payment Completed Channel
      const AndroidNotificationChannel paymentCompletedChannel =
          AndroidNotificationChannel(
        PAYMENT_COMPLETED_CHANNEL,
        'Payment Completed',
        description: 'Notifications for completed payments',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      // Create all channels
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(overallBudgetChannel);

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(categoryBudgetChannel);

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(incomeAlertChannel);

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(paymentDueTodayChannel);

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(paymentDueSoonChannel);

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(paymentOverdueChannel);

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(paymentCompletedChannel);
    }
  }

  /// Request notification permissions
  Future<bool> _requestPermissions() async {
    if (kIsWeb) return false;

    try {
      // Android 13+ permission request
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();

      final bool? granted =
          await androidImplementation?.requestNotificationsPermission();

      if (kDebugMode) {
        print('Android notification permission granted: $granted');
      }

      return granted ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting notification permissions: $e');
      }
      return false;
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      print('Notification tapped: ${response.payload}');
    }

    // Handle different notification types based on payload
    // You can navigate to specific screens here
    switch (response.payload) {
      case 'budget':
        // Navigate to budget screen
        break;
      case 'favorites':
        // Navigate to favorites screen
        break;
      default:
        // Navigate to home screen
        break;
    }
  }

  /// Show overall budget exceeded notification
  Future<void> showOverallBudgetExceeded({
    required double totalExpenses,
    required double budgetLimit,
    required double exceededAmount,
  }) async {
    try {
      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        OVERALL_BUDGET_CHANNEL,
        'Overall Budget Alerts',
        channelDescription: 'Notifications for overall budget exceeded',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      );

      DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        OVERALL_BUDGET_ID,
        '🚨 Budget Limit Exceeded!',
        'You\'ve exceeded your overall budget by ₱${exceededAmount.toStringAsFixed(2)}. Total spent: ₱${totalExpenses.toStringAsFixed(2)}',
        notificationDetails,
        payload: 'budget',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error showing overall budget notification: $e');
      }
    }
  }

  /// Show category budget exceeded notification
  Future<void> showCategoryBudgetExceeded({
    required String category,
    required double categoryExpenses,
    required double categoryLimit,
    required double exceededAmount,
  }) async {
    try {
      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        CATEGORY_BUDGET_CHANNEL,
        'Category Budget Alerts',
        channelDescription: 'Notifications for category budget exceeded',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      );

      DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        CATEGORY_BUDGET_ID,
        '⚠️ $category Budget Exceeded!',
        'You\'ve exceeded your $category budget by ₱${exceededAmount.toStringAsFixed(2)}. Spent: ₱${categoryExpenses.toStringAsFixed(2)}',
        notificationDetails,
        payload: 'budget',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error showing category budget notification: $e');
      }
    }
  }

  /// Show income alert notification
  Future<void> showIncomeAlert({
    required double spentPercentage,
    required double remainingIncome,
  }) async {
    try {
      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        INCOME_ALERT_CHANNEL,
        'Income Alerts',
        channelDescription: 'Notifications for income-related alerts',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
        playSound: true,
        enableVibration: true,
      );

      DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        INCOME_ALERT_ID,
        '💰 Income Alert',
        'You\'ve spent ${(spentPercentage * 100).toStringAsFixed(2)}% of your income. Remaining: ₱${remainingIncome.toStringAsFixed(2)}',
        notificationDetails,
        payload: 'income',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error showing income alert notification: $e');
      }
    }
  }

  /// Show payment due today notification
  Future<void> showPaymentDueToday({
    required String title,
    required double amountToPay,
    required String frequency,
  }) async {
    try {
      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        PAYMENT_DUE_TODAY_CHANNEL,
        'Payment Due Today',
        channelDescription: 'Notifications for payments due today',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      );

      DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        PAYMENT_DUE_TODAY_ID,
        '💰 Payment Due Today!',
        '$title payment of ₱${amountToPay.toStringAsFixed(2)} is due today ($frequency)',
        notificationDetails,
        payload: 'favorites',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error showing payment due today notification: $e');
      }
    }
  }

  /// Show payment due soon notification
  Future<void> showPaymentDueSoon({
    required String title,
    required double amountToPay,
    required String frequency,
    required int daysUntilDue,
  }) async {
    try {
      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        PAYMENT_DUE_SOON_CHANNEL,
        'Payment Due Soon',
        channelDescription: 'Notifications for payments due soon',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
        playSound: true,
        enableVibration: true,
      );

      DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      String dayText = daysUntilDue == 1 ? 'tomorrow' : 'in $daysUntilDue days';

      await _flutterLocalNotificationsPlugin.show(
        PAYMENT_DUE_SOON_ID,
        '⏰ Payment Due Soon!',
        '$title payment of ₱${amountToPay.toStringAsFixed(2)} is due $dayText ($frequency)',
        notificationDetails,
        payload: 'favorites',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error showing payment due soon notification: $e');
      }
    }
  }

  /// Show payment overdue notification
  Future<void> showPaymentOverdue({
    required String title,
    required double amountToPay,
    required String frequency,
    required int daysOverdue,
  }) async {
    try {
      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        PAYMENT_OVERDUE_CHANNEL,
        'Payment Overdue',
        channelDescription: 'Notifications for overdue payments',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      );

      DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      String dayText = daysOverdue == 1 ? '1 day ago' : '$daysOverdue days ago';

      await _flutterLocalNotificationsPlugin.show(
        PAYMENT_OVERDUE_ID,
        '🚨 Payment Overdue!',
        '$title payment of ₱${amountToPay.toStringAsFixed(2)} was due $dayText ($frequency)',
        notificationDetails,
        payload: 'favorites',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error showing payment overdue notification: $e');
      }
    }
  }

  /// Show payment completed notification
  Future<void> showPaymentCompleted({
    required String title,
    required double totalAmount,
  }) async {
    try {
      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        PAYMENT_COMPLETED_CHANNEL,
        'Payment Completed',
        channelDescription: 'Notifications for completed payments',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
        playSound: true,
        enableVibration: true,
      );

      DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
        PAYMENT_COMPLETED_ID,
        '✅ Payment Completed!',
        '$title payment of ₱${totalAmount.toStringAsFixed(2)} has been completed successfully!',
        notificationDetails,
        payload: 'favorites',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error showing payment completed notification: $e');
      }
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
    } catch (e) {
      if (kDebugMode) {
        print('Error canceling all notifications: $e');
      }
    }
  }

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(id);
    } catch (e) {
      if (kDebugMode) {
        print('Error canceling notification $id: $e');
      }
    }
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting pending notifications: $e');
      }
      return [];
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      if (kIsWeb) return false;

      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();

      return await androidImplementation?.areNotificationsEnabled() ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking notification status: $e');
      }
      return false;
    }
  }
}
