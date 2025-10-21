import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/snackbar_service.dart';

class NotificationController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  RxList notifications = [].obs;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  // Helper function to get start and end of current month
  Map<String, Timestamp> _getCurrentMonthRange() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfNextMonth = (now.month < 12)
        ? DateTime(now.year, now.month + 1, 1)
        : DateTime(now.year + 1, 1, 1);
    return {
      'start': Timestamp.fromDate(startOfMonth),
      'end': Timestamp.fromDate(startOfNextMonth),
    };
  }

  Future<void> fetchNotifications() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      final monthRange = _getCurrentMonthRange();
      final QuerySnapshot querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('timestamp', isGreaterThanOrEqualTo: monthRange['start'])
          .where('timestamp', isLessThan: monthRange['end'])
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
      default:
        return Colors.grey;
    }
  }
}
