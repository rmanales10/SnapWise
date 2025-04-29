import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  RxList<Map<String, dynamic>> notifications = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final QuerySnapshot querySnapshot =
          await _firestore
              .collection('notification')
              .where('userId', isEqualTo: user.uid)
              .orderBy('timestamp', descending: true)
              .get();

      notifications.value =
          querySnapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            return {
              'id': doc.id,
              'title': data['category'],
              'description':
                  'Your ${data['category']} budget has exceeded the limit',
              'timestamp': data['timestamp'],
              'icon': _getCategoryIcon(data['category']),
              'color': _getCategoryColor(data['category']),
              'isRead': data['isRead'] ?? false,
            };
          }).toList();
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch notifications: ${e.toString()}');
    }
  }

  void markAllAsRead() {
    for (var notification in notifications) {
      notification['isRead'] = true;
      _firestore.collection('notification').doc(notification['id']).update({
        'isRead': true,
      });
    }
    notifications.refresh();
  }

  void removeAllNotifications() {
    for (var notification in notifications) {
      _firestore.collection('notification').doc(notification['id']).delete();
    }
    notifications.clear();
  }

  IconData _getCategoryIcon(String category) {
    // Implement this method to return the appropriate icon for each category
    // For example:
    switch (category.toLowerCase()) {
      case 'shopping':
        return Icons.shopping_bag;
      case 'utilities':
        return Icons.bolt;
      // Add more cases as needed
      default:
        return Icons.notifications;
    }
  }

  Color _getCategoryColor(String category) {
    // Implement this method to return the appropriate color for each category
    // For example:
    switch (category.toLowerCase()) {
      case 'shopping':
        return Colors.orange;
      case 'utilities':
        return Colors.blue;
      // Add more cases as needed
      default:
        return Colors.grey;
    }
  }
}
