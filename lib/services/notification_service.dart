import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Request permission for iOS devices
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // Configure FCM
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log("onMessage: ${_messageToString(message)}");
      _showNotification(message);
      _logNotificationReceived(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log("onMessageOpenedApp: ${_messageToString(message)}");
      _logNotificationOpened(message);
      // Handle notification tapped logic here
    });
  }

  Future<void> _showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'your_channel_id',
          'your_channel_name',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title ?? '',
      message.notification?.body ?? '',
      platformChannelSpecifics,
      payload: message.data['payload'],
    );
  }

  Future<String?> getToken() async {
    return await _fcm.getToken();
  }

  String _messageToString(RemoteMessage message) {
    return '''
    RemoteMessage:
      data: ${message.data}
      notification: ${message.notification?.title} - ${message.notification?.body}
      messageId: ${message.messageId}
      sentTime: ${message.sentTime}
    ''';
  }

  void _logNotificationReceived(RemoteMessage message) {
    _analytics.logEvent(
      name: 'notification_received',
      parameters: {
        'title': message.notification?.title ?? 'No Title',
        'body': message.notification?.body ?? 'No Body',
      },
    );
  }

  void _logNotificationOpened(RemoteMessage message) {
    _analytics.logEvent(
      name: 'notification_opened',
      parameters: {
        'title': message.notification?.title ?? 'No Title',
        'body': message.notification?.body ?? 'No Body',
      },
    );
  }
}
