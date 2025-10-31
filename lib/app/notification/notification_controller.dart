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
  static const List<String> _incorrectBudgetPatterns = [
    '₱0.00',
    '₱3100.00',
    '₱8000.00',
    '₱-300.00',
    '₱-',
    'Budget budget',
  ];
  static const List<String> _incorrectNotificationPatterns = [
    'exceeded',
    'Overall Budget Alert!',
    'Spent: ₱-',
    'budget (₱-',
    '100%',
  ];

  // Method to add custom cleanup patterns
  void addCleanupPattern(String pattern) {
    if (!_incorrectBudgetPatterns.contains(pattern)) {
      // Note: This would require making the list non-const,
      // but for now we'll keep it as a design consideration
    }
  }

  // Method to get current cleanup configuration
  Map<String, dynamic> getCleanupConfiguration() {
    return {
      'oldNotificationCleanupDays': _oldNotificationCleanupDays,
      'incorrectBudgetPatterns': _incorrectBudgetPatterns,
      'incorrectNotificationPatterns': _incorrectNotificationPatterns,
    };
  }

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

    _notificationsSubscription = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('timestamp', isGreaterThanOrEqualTo: oldTimestamp)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      print('🔔 NotificationController: Notifications changed, refreshing...');
      // Debounce rapid updates
      Future.delayed(Duration(milliseconds: 500), () {
        if (snapshot.metadata.hasPendingWrites) return;
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
      notifications.value = snapshot.docs.map((doc) {
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
      print('Updated notifications: ${notifications.length} items');
    } catch (e) {
      print('Error updating notifications from snapshot: $e');
    }
  }

  // Helper method to check if a notification contains incorrect data
  bool _isIncorrectNotification(String title, String body) {
    // Check for basic incorrect budget patterns
    for (String pattern in _incorrectBudgetPatterns) {
      if (body.contains(pattern) || title.contains(pattern)) {
        return true;
      }
    }

    // Check for complex patterns
    if ((body.contains('exceeded') && body.contains('₱0.00')) ||
        (title.contains('Overall Budget Alert!') &&
            body.contains('₱8000.00')) ||
        (body.contains('Spent: ₱-') && body.contains('budget (₱-')) ||
        (body.contains('100%') && body.contains('₱-300.00'))) {
      return true;
    }

    return false;
  }

  // Helper method to generate grouping key for notifications
  String _getNotificationGroupKey(Map<String, dynamic> notification) {
    // Group by type and title for better duplicate detection
    return '${notification['type']}_${notification['title']}';
  }

  // Clean up old notifications with incorrect data
  Future<void> _cleanupIncorrectNotifications() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return;

      // Get all notifications for the user
      final QuerySnapshot querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .get();

      List<String> notificationsToDelete = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final body = data['body'] ?? '';
        final title = data['title'] ?? '';

        // Check for notifications with incorrect budget data using configurable patterns
        if (_isIncorrectNotification(title, body)) {
          notificationsToDelete.add(doc.id);
        }
      }

      // Delete incorrect notifications
      if (notificationsToDelete.isNotEmpty) {
        for (String docId in notificationsToDelete) {
          await _firestore.collection('notifications').doc(docId).delete();
        }
        print(
            'Cleaned up ${notificationsToDelete.length} incorrect notifications');
      }
    } catch (e) {
      print('Error cleaning up notifications: $e');
    }
  }

  Future<void> fetchNotifications() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Clean up old notifications with incorrect data first
      await _cleanupIncorrectNotifications();

      // Fetch notifications from the last 30 days (same as cleanup window)
      final cutoffDate =
          DateTime.now().subtract(Duration(days: _oldNotificationCleanupDays));
      final oldTimestamp = Timestamp.fromDate(cutoffDate);

      final QuerySnapshot querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('timestamp', isGreaterThanOrEqualTo: oldTimestamp)
          .orderBy('timestamp', descending: true)
          .get();

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

      // Clear old notifications (runs in background)
      clearOldNotifications();
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
      // Group notifications by type and title
      Map<String, List<Map<String, dynamic>>> groupedNotifications = {};

      for (var notification in notifications) {
        String key = _getNotificationGroupKey(notification);
        if (!groupedNotifications.containsKey(key)) {
          groupedNotifications[key] = [];
        }
        groupedNotifications[key]!.add(notification);
      }

      // Keep only the most recent notification of each type
      List<Map<String, dynamic>> notificationsToKeep = [];
      List<String> notificationsToDelete = [];

      for (var group in groupedNotifications.values) {
        if (group.length > 1) {
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

      print('Removed ${notificationsToDelete.length} duplicate notifications');
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
