import 'dart:async';

import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'favorites_notification.dart';

class FavoriteController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FavoritesNotification _favoritesNotification =
      Get.put(FavoritesNotification());

  final RxList<Map<String, dynamic>> favorites = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  StreamSubscription? _favoritesSubscription;

  @override
  void onInit() {
    super.onInit();
    setupFavoritesStream();
    // Check for notifications every time favorites are loaded
    checkAllFavoritesNotifications();
  }

  // Check notifications for all favorites
  Future<void> checkAllFavoritesNotifications() async {
    try {
      for (var favorite in favorites) {
        await _checkFavoriteNotification(favorite);
      }
    } catch (e) {
      print('Error checking favorites notifications: $e');
    }
  }

  // Check notification for a specific favorite
  Future<void> _checkFavoriteNotification(Map<String, dynamic> favorite) async {
    try {
      bool receiveAlert = favorite['receiveAlert'] ?? false;
      if (!receiveAlert) return;

      String frequency = favorite['frequency'] ?? 'monthly';
      String startDateStr = favorite['startDate'] ?? '';
      String endDateStr = favorite['endDate'] ?? '';

      if (startDateStr.isEmpty || endDateStr.isEmpty) return;

      DateTime startDate = DateFormat('yyyy-MM-dd').parse(startDateStr);
      DateTime endDate = DateFormat('yyyy-MM-dd').parse(endDateStr);

      Map<String, dynamic> paymentStatus =
          _favoritesNotification.checkPaymentStatus(
        startDate: startDate,
        frequency: frequency,
        endDate: endDate,
      );

      String title = favorite['title'] ?? 'Payment';
      double amountToPay = (favorite['amountToPay'] ?? 0.0).toDouble();

      switch (paymentStatus['status']) {
        case 'due_today':
          await _favoritesNotification.sendPaymentDueTodayNotification(
            title: title,
            amountToPay: amountToPay,
            frequency: frequency,
          );
          break;
        case 'due_soon':
          await _favoritesNotification.sendPaymentDueSoonNotification(
            title: title,
            amountToPay: amountToPay,
            frequency: frequency,
            daysUntilDue: paymentStatus['days'],
          );
          break;
        case 'overdue':
          await _favoritesNotification.sendMissedPaymentNotification(
            title: title,
            amountToPay: amountToPay,
            frequency: frequency,
            daysOverdue: paymentStatus['days'],
          );
          break;
      }
    } catch (e) {
      print('Error checking favorite notification: $e');
    }
  }

  @override
  void onClose() {
    _favoritesSubscription?.cancel();
    super.onClose();
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

  Future<void> setupFavoritesStream() async {
    final User? user = _auth.currentUser;
    if (user == null) return;
    final monthRange = _getCurrentMonthRange();
    _favoritesSubscription = _firestore
        .collection('favorites')
        .where('userId', isEqualTo: user.uid)
        .where('timestamp', isGreaterThanOrEqualTo: monthRange['start'])
        .where('timestamp', isLessThan: monthRange['end'])
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        favorites.value = snapshot.docs.map((doc) {
          final data = doc.data();
          return {'id': doc.id, ...data};
        }).toList();

        // Check notifications when favorites data changes
        checkAllFavoritesNotifications();
      },
      onError: (error) {
        Get.snackbar(
          'Error',
          'Failed to fetch favorites: ${error.toString()}',
        );
      },
    );
  }

  Future<void> addFavorite({
    required String title,
    required double totalAmount,
    required double amountToPay,
    required String frequency,
    required String startDate,
    required String endDate,
    required bool receiveAlert,
  }) async {
    try {
      isLoading.value = true;
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('favorites').add({
        'userId': user.uid,
        'title': title,
        'totalAmount': totalAmount,
        'amountToPay': amountToPay,
        'frequency': frequency,
        'startDate': startDate,
        'endDate': endDate,
        'receiveAlert': receiveAlert,
        'status': 'Pending',
        'paidAmount': 0.0,
        'timestamp': FieldValue.serverTimestamp(),
      });

      Get.snackbar('Success', 'Favorite added successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to add favorite: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateFavoriteStatus(String favoriteId, String status) async {
    try {
      await _firestore.collection('favorites').doc(favoriteId).update({
        'status': status,
      });
      Get.snackbar('Success', 'Status updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update status: ${e.toString()}');
    }
  }

  Future<void> updatePaymentStatus(String favoriteId, double paidAmount) async {
    try {
      // Get the current favorite document
      final doc =
          await _firestore.collection('favorites').doc(favoriteId).get();
      if (!doc.exists) {
        throw Exception('Favorite not found');
      }

      final data = doc.data() as Map<String, dynamic>;
      final totalAmount = (data['totalAmount'] ?? 0.0).toDouble();
      final currentPaidAmount = (data['paidAmount'] ?? 0.0).toDouble();
      final newPaidAmount = currentPaidAmount + paidAmount;

      // Get existing payment history or initialize new one
      List<Map<String, dynamic>> paymentHistory =
          List<Map<String, dynamic>>.from(data['paymentHistory'] ?? []);

      // Add new payment to history
      paymentHistory.add({'amount': paidAmount, 'timestamp': DateTime.now()});

      // Update the document with new payment information
      await _firestore.collection('favorites').doc(favoriteId).update({
        'paidAmount': newPaidAmount,
        'paymentHistory': paymentHistory,
        'status': newPaidAmount >= totalAmount ? 'Paid' : 'Pending',
      });

      // Send completion notification if payment is fully completed
      if (newPaidAmount >= totalAmount) {
        String title = data['title'] ?? 'Payment';
        await _favoritesNotification.sendPaymentCompletedNotification(
          title: title,
          totalAmount: totalAmount,
        );
      }

      Get.snackbar(
        'Success',
        newPaidAmount >= totalAmount
            ? 'Payment completed successfully'
            : 'Payment processed. Remaining: ₱${(totalAmount - newPaidAmount).toStringAsFixed(2)}',
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to process payment: ${e.toString()}');
    }
  }

  Future<void> deleteFavorite(String favoriteId) async {
    try {
      await _firestore.collection('favorites').doc(favoriteId).delete();

      Get.snackbar('Success', 'Favorite deleted successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete favorite: ${e.toString()}');
    }
  }

  Future<void> deleteAllFavorites() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      final monthRange = _getCurrentMonthRange();
      final QuerySnapshot querySnapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: user.uid)
          .where('timestamp', isGreaterThanOrEqualTo: monthRange['start'])
          .where('timestamp', isLessThan: monthRange['end'])
          .get();

      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      Get.snackbar('Success', 'All favorites deleted successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete all favorites: ${e.toString()}');
    }
  }
}
