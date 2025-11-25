import 'package:workmanager/workmanager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:developer' as log;
import '../app/auth_screens/sms_service/sms_service.dart';

/// Background notification service that runs even when app is closed
/// Uses WorkManager to schedule periodic checks for notifications
class BackgroundNotificationService {
  static const String TASK_NAME = 'notification_check_task';
  static const String PERIODIC_TASK_NAME = 'periodic_notification_check';
  
  // Notification tracking key in local storage
  static const String SENT_NOTIFICATIONS_KEY = 'sent_notifications_history';
  
  // Duplicate prevention window (24 hours)
  static const Duration DUPLICATE_WINDOW = Duration(hours: 24);

  /// Initialize background notification service
  static Future<void> initialize() async {
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false, // Set to true for debugging
      );
      
      // Register periodic task (runs every 15 minutes)
      await Workmanager().registerPeriodicTask(
        PERIODIC_TASK_NAME,
        TASK_NAME,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );
      
      log.log('✅ Background notification service initialized');
    } catch (e) {
      log.log('❌ Error initializing background notification service: $e');
    }
  }

  /// Cancel all background tasks
  static Future<void> cancelAll() async {
    try {
      await Workmanager().cancelAll();
      log.log('✅ All background tasks cancelled');
    } catch (e) {
      log.log('❌ Error cancelling background tasks: $e');
    }
  }

  /// Check if notification was already sent (duplicate prevention)
  static Future<bool> wasNotificationSent({
    required String userId,
    required String notificationType,
    required String notificationKey,
  }) async {
    try {
      final storage = GetStorage();
      final sentNotifications = storage.read(SENT_NOTIFICATIONS_KEY) as Map<String, dynamic>? ?? {};
      
      final key = '${userId}_${notificationType}_$notificationKey';
      final lastSentStr = sentNotifications[key] as String?;
      
      if (lastSentStr == null) return false;
      
      final lastSent = DateTime.parse(lastSentStr);
      final now = DateTime.now();
      
      // Check if notification was sent within duplicate window
      return now.difference(lastSent) < DUPLICATE_WINDOW;
    } catch (e) {
      log.log('❌ Error checking notification history: $e');
      return false;
    }
  }

  /// Mark notification as sent
  static Future<void> markNotificationSent({
    required String userId,
    required String notificationType,
    required String notificationKey,
  }) async {
    try {
      final storage = GetStorage();
      final sentNotifications = storage.read(SENT_NOTIFICATIONS_KEY) as Map<String, dynamic>? ?? {};
      
      final key = '${userId}_${notificationType}_$notificationKey';
      sentNotifications[key] = DateTime.now().toIso8601String();
      
      await storage.write(SENT_NOTIFICATIONS_KEY, sentNotifications);
      log.log('✅ Notification marked as sent: $key');
    } catch (e) {
      log.log('❌ Error marking notification as sent: $e');
    }
  }

  /// Clean up old notification history (older than duplicate window)
  static Future<void> cleanupOldHistory() async {
    try {
      final storage = GetStorage();
      final sentNotifications = storage.read(SENT_NOTIFICATIONS_KEY) as Map<String, dynamic>? ?? {};
      
      final now = DateTime.now();
      final keysToRemove = <String>[];
      
      sentNotifications.forEach((key, value) {
        try {
          final sentTime = DateTime.parse(value as String);
          if (now.difference(sentTime) > DUPLICATE_WINDOW) {
            keysToRemove.add(key);
          }
        } catch (e) {
          keysToRemove.add(key); // Remove invalid entries
        }
      });
      
      for (final key in keysToRemove) {
        sentNotifications.remove(key);
      }
      
      await storage.write(SENT_NOTIFICATIONS_KEY, sentNotifications);
      log.log('✅ Cleaned up ${keysToRemove.length} old notification records');
    } catch (e) {
      log.log('❌ Error cleaning up notification history: $e');
    }
  }

  /// Manually trigger background notification check (for testing)
  static Future<void> triggerManualCheck() async {
    try {
      log.log('🔔 Manually triggering background notification check...');
      await _checkAndSendNotifications();
      log.log('✅ Manual notification check completed');
    } catch (e) {
      log.log('❌ Error in manual notification check: $e');
    }
  }
}

/// Background task callback dispatcher
/// This function runs in a separate isolate
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      log.log('🔔 Background notification task started: $task');
      
      // Initialize Firebase in background isolate
      await Firebase.initializeApp();
      await GetStorage.init();
      
      // Clean up old notification history
      await BackgroundNotificationService.cleanupOldHistory();
      
      // Check for notifications that need to be sent
      await _checkAndSendNotifications();
      
      log.log('✅ Background notification task completed');
      return Future.value(true);
    } catch (e) {
      log.log('❌ Background notification task failed: $e');
      return Future.value(false);
    }
  });
}

/// Check and send notifications in background
Future<void> _checkAndSendNotifications() async {
  try {
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;
    
    // Get current user
    final user = auth.currentUser;
    if (user == null) {
      log.log('⚠️ No user logged in, skipping background notifications');
      return;
    }
    
    final userId = user.uid;
    final now = DateTime.now();
    
    // Initialize notification plugin for background
    final FlutterLocalNotificationsPlugin notificationsPlugin = 
        FlutterLocalNotificationsPlugin();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    await notificationsPlugin.initialize(initializationSettings);
    
    // Check for budget alerts
    await _checkBudgetAlerts(userId, firestore, notificationsPlugin);
    
    // Check for payment reminders
    await _checkPaymentReminders(userId, firestore, notificationsPlugin);
    
    log.log('✅ Notification checks completed');
  } catch (e) {
    log.log('❌ Error checking notifications: $e');
  }
}

/// Check budget alerts
Future<void> _checkBudgetAlerts(
  String userId,
  FirebaseFirestore firestore,
  FlutterLocalNotificationsPlugin notificationsPlugin,
) async {
  try {
    // Get user's budget data
    final budgetDoc = await firestore
        .collection('users')
        .doc(userId)
        .collection('budget')
        .doc('current')
        .get();
    
    if (!budgetDoc.exists) return;
    
    final budgetData = budgetDoc.data() as Map<String, dynamic>;
    final budgetLimit = (budgetData['limit'] as num?)?.toDouble() ?? 0;
    
    if (budgetLimit <= 0) return;
    
    // Get current month expenses
    final startOfMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final expensesSnapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .get();
    
    double totalExpenses = 0;
    for (final doc in expensesSnapshot.docs) {
      final data = doc.data();
      totalExpenses += (data['amount'] as num?)?.toDouble() ?? 0;
    }
    
    // Check if budget exceeded
    if (totalExpenses > budgetLimit) {
      final exceededAmount = totalExpenses - budgetLimit;
      final notificationKey = 'budget_${budgetLimit.toStringAsFixed(0)}';
      
      // Check for duplicates
      final alreadySent = await BackgroundNotificationService.wasNotificationSent(
        userId: userId,
        notificationType: 'budget_exceeded',
        notificationKey: notificationKey,
      );
      
      if (!alreadySent) {
        await _sendBudgetExceededNotification(
          notificationsPlugin,
          totalExpenses,
          budgetLimit,
          exceededAmount,
        );
        
        // Save to Firestore
        await _saveNotificationToFirestore(
          userId: userId,
          title: '🚨 Budget Exceeded!',
          body: 'You\'ve exceeded your budget by ₱${exceededAmount.toStringAsFixed(2)}',
          type: 'budget_exceeded',
          firestore: firestore,
        );
        
        // Mark as sent
        await BackgroundNotificationService.markNotificationSent(
          userId: userId,
          notificationType: 'budget_exceeded',
          notificationKey: notificationKey,
        );
      }
    }
  } catch (e) {
    log.log('❌ Error checking budget alerts: $e');
  }
}

/// Check payment reminders
Future<void> _checkPaymentReminders(
  String userId,
  FirebaseFirestore firestore,
  FlutterLocalNotificationsPlugin notificationsPlugin,
) async {
  try {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Get all favorites (payment reminders)
    final favoritesSnapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .get();
    
    for (final doc in favoritesSnapshot.docs) {
      final data = doc.data();
      final dueDate = (data['dueDate'] as Timestamp?)?.toDate();
      
      if (dueDate == null) continue;
      
      final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
      final daysDifference = dueDateOnly.difference(today).inDays;
      
      final title = data['title'] as String? ?? 'Payment';
      final amount = (data['amountToPay'] as num?)?.toDouble() ?? 0;
      final frequency = data['frequency'] as String? ?? 'one-time';
      
      final notificationKey = '${doc.id}_${dueDate.toIso8601String()}';
      
      // Payment due today
      if (daysDifference == 0) {
        final alreadySent = await BackgroundNotificationService.wasNotificationSent(
          userId: userId,
          notificationType: 'payment_due_today',
          notificationKey: notificationKey,
        );
        
        if (!alreadySent) {
          await _sendPaymentDueTodayNotification(
            notificationsPlugin,
            title,
            amount,
            frequency,
          );
          
          await _saveNotificationToFirestore(
            userId: userId,
            title: '💰 Payment Due Today!',
            body: '$title payment of ₱${amount.toStringAsFixed(2)} is due today',
            type: 'payment_due_today',
            firestore: firestore,
          );
          
          // Send SMS
          await _sendSmsNotification(
            userId: userId,
            title: '💰 Payment Due Today!',
            body: '$title payment of ₱${amount.toStringAsFixed(2)} is due today',
            firestore: firestore,
          );
          
          await BackgroundNotificationService.markNotificationSent(
            userId: userId,
            notificationType: 'payment_due_today',
            notificationKey: notificationKey,
          );
        }
      }
      // Payment due soon (1-3 days)
      else if (daysDifference > 0 && daysDifference <= 3) {
        final alreadySent = await BackgroundNotificationService.wasNotificationSent(
          userId: userId,
          notificationType: 'payment_due_soon',
          notificationKey: notificationKey,
        );
        
        if (!alreadySent) {
          await _sendPaymentDueSoonNotification(
            notificationsPlugin,
            title,
            amount,
            frequency,
            daysDifference,
          );
          
          await _saveNotificationToFirestore(
            userId: userId,
            title: '⏰ Payment Due Soon!',
            body: '$title payment of ₱${amount.toStringAsFixed(2)} is due in $daysDifference days',
            type: 'payment_due_soon',
            firestore: firestore,
          );
          
          await BackgroundNotificationService.markNotificationSent(
            userId: userId,
            notificationType: 'payment_due_soon',
            notificationKey: notificationKey,
          );
        }
      }
      // Payment overdue
      else if (daysDifference < 0) {
        final daysOverdue = -daysDifference;
        final alreadySent = await BackgroundNotificationService.wasNotificationSent(
          userId: userId,
          notificationType: 'payment_overdue',
          notificationKey: notificationKey,
        );
        
        if (!alreadySent) {
          await _sendPaymentOverdueNotification(
            notificationsPlugin,
            title,
            amount,
            frequency,
            daysOverdue,
          );
          
          await _saveNotificationToFirestore(
            userId: userId,
            title: '🚨 Payment Overdue!',
            body: '$title payment of ₱${amount.toStringAsFixed(2)} is $daysOverdue days overdue',
            type: 'payment_overdue',
            firestore: firestore,
          );
          
          // Send SMS for overdue payments
          await _sendSmsNotification(
            userId: userId,
            title: '🚨 Payment Overdue!',
            body: '$title payment of ₱${amount.toStringAsFixed(2)} is $daysOverdue days overdue',
            firestore: firestore,
          );
          
          await BackgroundNotificationService.markNotificationSent(
            userId: userId,
            notificationType: 'payment_overdue',
            notificationKey: notificationKey,
          );
        }
      }
    }
  } catch (e) {
    log.log('❌ Error checking payment reminders: $e');
  }
}

/// Send budget exceeded notification
Future<void> _sendBudgetExceededNotification(
  FlutterLocalNotificationsPlugin plugin,
  double totalExpenses,
  double budgetLimit,
  double exceededAmount,
) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'budget_alerts',
    'Budget Alerts',
    channelDescription: 'Notifications for budget exceeded',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
  );

  const NotificationDetails details = NotificationDetails(android: androidDetails);

  await plugin.show(
    1,
    '🚨 Budget Exceeded!',
    'You\'ve exceeded your budget (₱${budgetLimit.toStringAsFixed(2)}) by ₱${exceededAmount.toStringAsFixed(2)}',
    details,
  );
}

/// Send payment due today notification
Future<void> _sendPaymentDueTodayNotification(
  FlutterLocalNotificationsPlugin plugin,
  String title,
  double amount,
  String frequency,
) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'payment_due_today',
    'Payment Due Today',
    channelDescription: 'Notifications for payments due today',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
  );

  const NotificationDetails details = NotificationDetails(android: androidDetails);

  await plugin.show(
    10,
    '💰 Payment Due Today!',
    '$title payment of ₱${amount.toStringAsFixed(2)} is due today ($frequency)',
    details,
  );
}

/// Send payment due soon notification
Future<void> _sendPaymentDueSoonNotification(
  FlutterLocalNotificationsPlugin plugin,
  String title,
  double amount,
  String frequency,
  int daysUntilDue,
) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'payment_due_soon',
    'Payment Due Soon',
    channelDescription: 'Notifications for payments due soon',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
  );

  const NotificationDetails details = NotificationDetails(android: androidDetails);

  final dayText = daysUntilDue == 1 ? 'tomorrow' : 'in $daysUntilDue days';

  await plugin.show(
    11,
    '⏰ Payment Due Soon!',
    '$title payment of ₱${amount.toStringAsFixed(2)} is due $dayText ($frequency)',
    details,
  );
}

/// Send payment overdue notification
Future<void> _sendPaymentOverdueNotification(
  FlutterLocalNotificationsPlugin plugin,
  String title,
  double amount,
  String frequency,
  int daysOverdue,
) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'payment_overdue',
    'Payment Overdue',
    channelDescription: 'Notifications for overdue payments',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
  );

  const NotificationDetails details = NotificationDetails(android: androidDetails);

  final dayText = daysOverdue == 1 ? '1 day ago' : '$daysOverdue days ago';

  await plugin.show(
    12,
    '🚨 Payment Overdue!',
    '$title payment of ₱${amount.toStringAsFixed(2)} was due $dayText ($frequency)',
    details,
  );
}

/// Save notification to Firestore
Future<void> _saveNotificationToFirestore({
  required String userId,
  required String title,
  required String body,
  required String type,
  required FirebaseFirestore firestore,
}) async {
  try {
    await firestore.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  } catch (e) {
    log.log('❌ Error saving notification to Firestore: $e');
  }
}

/// Send SMS notification
Future<void> _sendSmsNotification({
  required String userId,
  required String title,
  required String body,
  required FirebaseFirestore firestore,
}) async {
  try {
    // Get user's phone number
    final userDoc = await firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return;
    
    final userData = userDoc.data() as Map<String, dynamic>;
    final phoneNumber = userData['phoneNumber'] as String?;
    
    if (phoneNumber == null || phoneNumber.isEmpty) return;
    
    // Send SMS using SmsService
    final smsService = SmsService();
    await smsService.sendNotification(
      phoneNumber: phoneNumber,
      title: title,
      message: body,
    );
  } catch (e) {
    log.log('❌ Error sending SMS notification: $e');
  }
}
