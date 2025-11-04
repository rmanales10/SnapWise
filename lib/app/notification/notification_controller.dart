import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/snackbar_service.dart';

class NotificationController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  RxList notifications = [].obs;

  // Real-time stream subscription
  StreamSubscription<QuerySnapshot>? _notificationsSubscription;

  // Configurable constants
  static const int _oldNotificationCleanupDays = 30;

  @override
  void onInit() {
    super.onInit();
    _setupRealtimeListener();
    fetchNotifications();
  }

  @override
  void onClose() {
    // Cancel subscription
    _notificationsSubscription?.cancel();
    super.onClose();
  }

  /// Set up real-time Firestore listener for automatic notification updates
  void _setupRealtimeListener() {
    final user = _auth.currentUser;
    if (user == null) {
      print(
          'NotificationController: User not authenticated, cannot set up listener');
      return;
    }

    print('🔔 NotificationController: Setting up real-time listener');

    // Listen to notifications changes
    final cutoffDate =
        DateTime.now().subtract(Duration(days: _oldNotificationCleanupDays));
    final oldTimestamp = Timestamp.fromDate(cutoffDate);

    print('   Cutoff date: $cutoffDate (30 days ago)');

    _notificationsSubscription = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('timestamp', isGreaterThanOrEqualTo: oldTimestamp)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      print('🔔 NotificationController: Notifications changed, refreshing...');
      print(
          '   Snapshot has ${snapshot.docs.length} documents, hasPendingWrites: ${snapshot.metadata.hasPendingWrites}');
      // Debounce rapid updates
      Future.delayed(Duration(milliseconds: 500), () {
        _updateNotificationsFromSnapshot(snapshot);
      });
    }, onError: (error) {
      print('NotificationController: Error in notifications listener: $error');
    });

    print('✅ NotificationController: Real-time listener active');
  }

  /// Update notifications from Firestore snapshot
  void _updateNotificationsFromSnapshot(QuerySnapshot snapshot) {
    try {
      print('Processing ${snapshot.docs.length} documents from snapshot');
      notifications.value = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        print('  Document: ${data['title']}, timestamp: ${data['timestamp']}');
        return {
          'id': doc.id,
          'title': data['title'] ?? 'Notification',
          'description': data['body'] ?? 'No description available',
          'timestamp': data['timestamp'],
          'type': data['type'] ?? 'general',
          'icon': _getNotificationIcon(data['type']),
          'color': _getNotificationColor(data['type']),
          'isRead': data['isRead'] ?? false,
        };
      }).toList();
      print('Updated notifications: ${notifications.length} items');
    } catch (e) {
      print('Error updating notifications from snapshot: $e');
    }
  }

  // Helper method to generate grouping key for notifications
  String _getNotificationGroupKey(Map<String, dynamic> notification) {
    // Group by type and title for better duplicate detection
    return '${notification['type']}_${notification['title']}';
  }

  Future<void> fetchNotifications() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Fetch notifications from the last 30 days
      final cutoffDate =
          DateTime.now().subtract(Duration(days: _oldNotificationCleanupDays));
      final oldTimestamp = Timestamp.fromDate(cutoffDate);

      print('   Query cutoff: $oldTimestamp');

      final QuerySnapshot querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('timestamp', isGreaterThanOrEqualTo: oldTimestamp)
          .orderBy('timestamp', descending: true)
          .get();

      print('   Query returned ${querySnapshot.docs.length} documents');

      notifications.value = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        return {
          'id': doc.id,
          'title': data['title'] ?? 'Notification',
          'description': data['body'] ?? 'No description available',
          'timestamp': data['timestamp'],
          'type': data['type'] ?? 'general',
          'icon': _getNotificationIcon(data['type']),
          'color': _getNotificationColor(data['type']),
          'isRead': data['isRead'] ?? false,
        };
      }).toList();

      // Remove duplicate notifications after fetching
      removeDuplicateNotifications();

      print('✅ Fetched ${notifications.length} notifications from Firestore');
    } catch (e) {
      SnackbarService.showError(
          title: 'Notification Error',
          message: 'Failed to fetch notifications: ${e.toString()}');
    }
  }

  void markAllAsRead() {
    for (var notification in notifications) {
      notification['isRead'] = true;
      _firestore.collection('notifications').doc(notification['id']).update({
        'isRead': true,
      });
    }
    notifications.refresh();
  }

  void removeAllNotifications() {
    for (var notification in notifications) {
      _firestore.collection('notifications').doc(notification['id']).delete();
    }
    notifications.clear();
  }

  // Clear old notifications (older than configured days)
  Future<void> clearOldNotifications() async {
    try {
      final cutoffDate =
          DateTime.now().subtract(Duration(days: _oldNotificationCleanupDays));
      final oldTimestamp = Timestamp.fromDate(cutoffDate);

      final QuerySnapshot oldNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: _auth.currentUser?.uid)
          .where('timestamp', isLessThan: oldTimestamp)
          .get();

      // Delete old notifications
      for (var doc in oldNotifications.docs) {
        await _firestore.collection('notifications').doc(doc.id).delete();
      }

      print('Cleared ${oldNotifications.docs.length} old notifications');
    } catch (e) {
      print('Error clearing old notifications: $e');
    }
  }

  // Remove duplicate notifications (keep only the most recent of each type)
  void removeDuplicateNotifications() {
    try {
      print('Removing duplicates from ${notifications.length} notifications');

      // Group notifications by type and title
      Map<String, List<Map<String, dynamic>>> groupedNotifications = {};

      for (var notification in notifications) {
        String key = _getNotificationGroupKey(notification);
        if (!groupedNotifications.containsKey(key)) {
          groupedNotifications[key] = [];
        }
        groupedNotifications[key]!.add(notification);
      }

      print(
          'Grouped into ${groupedNotifications.length} unique notification types');

      // Keep only the most recent notification of each type
      List<Map<String, dynamic>> notificationsToKeep = [];
      List<String> notificationsToDelete = [];

      for (var group in groupedNotifications.values) {
        if (group.length > 1) {
          print(
              'Found ${group.length} duplicates for type: ${_getNotificationGroupKey(group.first)}');
          // Sort by timestamp (most recent first)
          group.sort((a, b) {
            Timestamp timestampA = a['timestamp'] as Timestamp;
            Timestamp timestampB = b['timestamp'] as Timestamp;
            return timestampB.compareTo(timestampA);
          });

          // Keep the most recent one
          notificationsToKeep.add(group.first);

          // Mark others for deletion
          for (int i = 1; i < group.length; i++) {
            notificationsToDelete.add(group[i]['id']);
          }
        } else {
          // Only one notification of this type, keep it
          notificationsToKeep.add(group.first);
        }
      }

      // Delete duplicate notifications from Firestore
      for (String notificationId in notificationsToDelete) {
        _firestore.collection('notifications').doc(notificationId).delete();
      }

      // Update the local list
      notifications.value = notificationsToKeep;
      notifications.refresh();

      print(
          'Removed ${notificationsToDelete.length} duplicate notifications, kept ${notificationsToKeep.length}');
    } catch (e) {
      print('Error removing duplicate notifications: $e');
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'budget_exceeded':
        return Icons.warning;
      case 'income_alert':
        return Icons.account_balance_wallet;
      case 'payment_due_today':
        return Icons.schedule;
      case 'payment_due_soon':
        return Icons.alarm;
      case 'payment_overdue':
        return Icons.error;
      case 'payment_completed':
        return Icons.check_circle;
      case 'expense_added':
        return Icons.add_shopping_cart;
      case 'monthly_reset':
        return Icons.calendar_today;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'budget_exceeded':
        return Colors.red;
      case 'income_alert':
        return Colors.blue;
      case 'payment_due_today':
        return Colors.orange;
      case 'payment_due_soon':
        return Colors.amber;
      case 'payment_overdue':
        return Colors.red.shade700;
      case 'payment_completed':
        return Colors.green;
      case 'expense_added':
        return Colors.purple;
      case 'monthly_reset':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  // Clear all notifications (for debugging/cleanup)
  Future<void> clearAllNotifications() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return;

      // Get all notifications for the user
      final QuerySnapshot querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .get();

      // Delete all notifications
      for (var doc in querySnapshot.docs) {
        await _firestore.collection('notifications').doc(doc.id).delete();
      }

      // Clear local list
      notifications.clear();
      notifications.refresh();

      print('Cleared all notifications');
    } catch (e) {
      print('Error clearing notifications: $e');
    }
  }
}
