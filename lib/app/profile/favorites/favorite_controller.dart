import 'dart:async';

import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'favorites_notification.dart';
import '../../../services/snackbar_service.dart';
import 'dart:developer' as dev;

class FavoriteController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FavoritesNotification _favoritesNotification =
      Get.put(FavoritesNotification());

  final RxList<Map<String, dynamic>> favorites = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  StreamSubscription? _favoritesSubscription;

  // Track last notification times to prevent spam
  final Map<String, DateTime> _lastNotificationTimes = {};

  @override
  void onInit() {
    super.onInit();
    setupFavoritesStream();
    // Check for notifications every time favorites are loaded
    checkAllFavoritesNotifications();
    // Set up periodic notification checks
    _setupPeriodicNotificationCheck();
  }

  // Set up periodic notification checks (every 30 minutes)
  void _setupPeriodicNotificationCheck() {
    Timer.periodic(Duration(minutes: 30), (timer) {
      if (favorites.isNotEmpty) {
        checkAllFavoritesNotifications();
      }
    });
  }

  // Check notifications for all favorites
  Future<void> checkAllFavoritesNotifications() async {
    try {
      dev.log(
          'Checking favorites notifications for ${favorites.length} favorites');
      for (var favorite in favorites) {
        await _checkFavoriteNotification(favorite);
      }
    } catch (e) {
      dev.log('Error checking favorites notifications: $e');
    }
  }

  // Check notifications when app becomes active
  Future<void> checkNotificationsOnAppResume() async {
    dev.log('App resumed - checking favorites notifications');
    await checkAllFavoritesNotifications();
  }

  // Manual notification check (can be called from UI)
  Future<void> refreshNotifications() async {
    dev.log('Manual notification refresh triggered');
    await checkAllFavoritesNotifications();
  }

  // Update favorites status based on due dates - only move to Missed, never auto-Paid
  Future<void> updateFavoritesStatus() async {
    try {
      for (var favorite in favorites) {
        String currentStatus = favorite['status'] ?? 'Pending';

        // Skip if already paid or missed
        if (currentStatus == 'Paid' || currentStatus == 'Missed') continue;

        // Skip if recently retried (within last 5 minutes)
        if (favorite['lastRetryDate'] != null) {
          DateTime lastRetryDate = favorite['lastRetryDate'] is Timestamp
              ? (favorite['lastRetryDate'] as Timestamp).toDate()
              : favorite['lastRetryDate'] as DateTime;
          if (DateTime.now().difference(lastRetryDate).inMinutes < 5) {
            dev.log('Skipping recently retried payment: ${favorite['title']}');
            continue;
          }
        }

        String frequency = favorite['frequency'] ?? 'monthly';
        String startDateStr = favorite['startDate'] ?? '';
        String endDateStr = favorite['endDate'] ?? '';

        if (startDateStr.isEmpty || endDateStr.isEmpty) continue;

        DateTime startDate = DateFormat('yyyy-MM-dd').parse(startDateStr);
        DateTime endDate = DateFormat('yyyy-MM-dd').parse(endDateStr);

        // Get payment history
        List<Map<String, dynamic>> paymentHistory =
            List<Map<String, dynamic>>.from(favorite['paymentHistory'] ?? []);
        double totalAmount = (favorite['totalAmount'] ?? 0.0).toDouble();

        // Check payment status
        Map<String, dynamic> paymentStatus =
            _favoritesNotification.checkPaymentStatus(
          startDate: startDate,
          frequency: frequency,
          endDate: endDate,
          paymentHistory: paymentHistory,
          totalAmount: totalAmount,
        );

        String newStatus = 'Pending';
        // Only move to Missed if overdue, never auto-mark as Paid
        if (paymentStatus['status'] == 'missed') {
          newStatus = 'Missed';
        }

        // Update status in Firestore if it changed to Missed
        if (newStatus != currentStatus && newStatus == 'Missed') {
          await _firestore.collection('favorites').doc(favorite['id']).update({
            'status': newStatus,
          });
          dev.log(
              'Updated favorite ${favorite['title']} status from $currentStatus to $newStatus');
        }
      }
    } catch (e) {
      dev.log('Error updating favorites status: $e');
    }
  }

  // Check notification for a specific favorite
  Future<void> _checkFavoriteNotification(Map<String, dynamic> favorite) async {
    try {
      bool receiveAlert = favorite['receiveAlert'] ?? false;
      if (!receiveAlert) return;

      String favoriteId = favorite['id'] ?? favorite['title'] ?? 'unknown';
      String frequency = favorite['frequency'] ?? 'monthly';
      String startDateStr = favorite['startDate'] ?? '';
      String endDateStr = favorite['endDate'] ?? '';

      if (startDateStr.isEmpty || endDateStr.isEmpty) return;

      DateTime startDate = DateFormat('yyyy-MM-dd').parse(startDateStr);
      DateTime endDate = DateFormat('yyyy-MM-dd').parse(endDateStr);

      // Get payment history from favorite data
      List<Map<String, dynamic>> paymentHistory =
          List<Map<String, dynamic>>.from(favorite['paymentHistory'] ?? []);
      double totalAmount = (favorite['totalAmount'] ?? 0.0).toDouble();

      Map<String, dynamic> paymentStatus =
          _favoritesNotification.checkPaymentStatus(
        startDate: startDate,
        frequency: frequency,
        endDate: endDate,
        paymentHistory: paymentHistory,
        totalAmount: totalAmount,
      );

      String title = favorite['title'] ?? 'Payment';
      double amountToPay = (favorite['amountToPay'] ?? 0.0).toDouble();
      String status = paymentStatus['status'];

      // Check if we should send notification (cooldown period)
      String notificationKey = '$favoriteId-$status';
      DateTime now = DateTime.now();
      DateTime? lastNotification = _lastNotificationTimes[notificationKey];

      // Cooldown periods: 1 hour for due_today, 6 hours for due_soon, 12 hours for missed
      Duration cooldownPeriod = Duration(hours: 1);
      if (status == 'due_soon') cooldownPeriod = Duration(hours: 6);
      if (status == 'missed') cooldownPeriod = Duration(hours: 12);

      if (lastNotification != null &&
          now.difference(lastNotification) < cooldownPeriod) {
        dev.log('Skipping notification for $title ($status) - cooldown active');
        return;
      }

      bool notificationSent = false;
      switch (status) {
        case 'due_today':
          await _favoritesNotification.sendPaymentDueTodayNotification(
            title: title,
            amountToPay: amountToPay,
            frequency: frequency,
          );
          notificationSent = true;
          dev.log('Sent due today notification for $title');
          break;
        case 'due_soon':
          await _favoritesNotification.sendPaymentDueSoonNotification(
            title: title,
            amountToPay: amountToPay,
            frequency: frequency,
            daysUntilDue: paymentStatus['days'],
          );
          notificationSent = true;
          dev.log(
              'Sent due soon notification for $title (${paymentStatus['days']} days)');
          break;
        case 'missed':
          await _favoritesNotification.sendMissedPaymentNotification(
            title: title,
            amountToPay: amountToPay,
            frequency: frequency,
            daysOverdue: paymentStatus['days'],
          );
          notificationSent = true;
          dev.log(
              'Sent missed payment notification for $title (${paymentStatus['days']} days overdue)');
          break;
      }

      // Update last notification time if notification was sent
      if (notificationSent) {
        _lastNotificationTimes[notificationKey] = now;
      }
    } catch (e) {
      dev.log('Error checking favorite notification: $e');
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

        // Update status based on due dates
        updateFavoritesStatus();
      },
      onError: (error) {
        SnackbarService.showFavoritesError(
            'Failed to fetch favorites: ${error.toString()}');
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

      SnackbarService.showFavoritesSuccess('Favorite added successfully');
    } catch (e) {
      SnackbarService.showFavoritesError(
          'Failed to add favorite: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateFavoriteStatus(String favoriteId, String status) async {
    try {
      await _firestore.collection('favorites').doc(favoriteId).update({
        'status': status,
      });
      SnackbarService.showFavoritesSuccess('Status updated successfully');
    } catch (e) {
      SnackbarService.showFavoritesError(
          'Failed to update status: ${e.toString()}');
    }
  }

  // Method to manually mark a favorite as paid (user confirmation required)
  Future<void> markAsPaid(String favoriteId) async {
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

      // Only mark as paid if the total amount is reached
      if (currentPaidAmount >= totalAmount) {
        await _firestore.collection('favorites').doc(favoriteId).update({
          'status': 'Paid',
        });
        SnackbarService.showFavoritesSuccess('Payment confirmed successfully');
      } else {
        SnackbarService.showFavoritesError(
            'Cannot mark as paid. Amount paid (₱${currentPaidAmount.toStringAsFixed(2)}) is less than total amount (₱${totalAmount.toStringAsFixed(2)})');
      }
    } catch (e) {
      SnackbarService.showFavoritesError(
          'Failed to mark as paid: ${e.toString()}');
    }
  }

  // Method to reset a missed payment back to pending
  Future<void> resetMissedPayment(String favoriteId) async {
    try {
      // Get the current favorite document to check its details
      final doc =
          await _firestore.collection('favorites').doc(favoriteId).get();
      if (!doc.exists) {
        SnackbarService.showFavoritesError('Favorite not found');
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      String frequency = data['frequency'] ?? 'monthly';
      String startDateStr = data['startDate'] ?? '';
      String endDateStr = data['endDate'] ?? '';

      if (startDateStr.isEmpty || endDateStr.isEmpty) {
        SnackbarService.showFavoritesError('Invalid payment dates');
        return;
      }

      DateTime now = DateTime.now();

      // Calculate new dates based on frequency
      DateTime newStartDate = now;
      DateTime newEndDate;

      switch (frequency) {
        case 'daily':
          newEndDate = now.add(Duration(days: 1));
          break;
        case 'weekly':
          newEndDate = now.add(Duration(days: 7));
          break;
        case 'monthly':
          newEndDate = DateTime(now.year, now.month + 1, now.day);
          break;
        case 'yearly':
          newEndDate = DateTime(now.year + 1, now.month, now.day);
          break;
        default:
          newEndDate = now.add(Duration(days: 1));
      }

      // Update the favorite with new dates and reset status
      await _firestore.collection('favorites').doc(favoriteId).update({
        'status': 'Pending',
        'startDate': DateFormat('yyyy-MM-dd').format(newStartDate),
        'endDate': DateFormat('yyyy-MM-dd').format(newEndDate),
        'lastRetryDate': FieldValue.serverTimestamp(),
      });

      SnackbarService.showFavoritesSuccess(
          'Payment reset to pending with new due date');
    } catch (e) {
      SnackbarService.showFavoritesError(
          'Failed to reset payment: ${e.toString()}');
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

      // Determine new status based on payment and due dates
      String newStatus = 'Pending';
      if (newPaidAmount >= totalAmount) {
        // Only mark as Paid when user manually confirms payment
        newStatus = 'Paid';
      } else {
        // Check if payment is missed based on due dates
        String frequency = data['frequency'] ?? 'monthly';
        String startDateStr = data['startDate'] ?? '';
        String endDateStr = data['endDate'] ?? '';

        if (startDateStr.isNotEmpty && endDateStr.isNotEmpty) {
          DateTime startDate = DateFormat('yyyy-MM-dd').parse(startDateStr);
          DateTime endDate = DateFormat('yyyy-MM-dd').parse(endDateStr);

          Map<String, dynamic> paymentStatus =
              _favoritesNotification.checkPaymentStatus(
            startDate: startDate,
            frequency: frequency,
            endDate: endDate,
            paymentHistory: paymentHistory,
            totalAmount: totalAmount,
          );

          if (paymentStatus['status'] == 'missed') {
            newStatus = 'Missed';
          }
        }
      }

      // Update the document with new payment information
      await _firestore.collection('favorites').doc(favoriteId).update({
        'paidAmount': newPaidAmount,
        'paymentHistory': paymentHistory,
        'status': newStatus,
      });

      // Send completion notification if payment is fully completed
      if (newPaidAmount >= totalAmount) {
        String title = data['title'] ?? 'Payment';
        await _favoritesNotification.sendPaymentCompletedNotification(
          title: title,
          totalAmount: totalAmount,
        );
      }

      SnackbarService.showFavoritesSuccess(
        newPaidAmount >= totalAmount
            ? 'Payment completed successfully'
            : 'Payment processed. Remaining: ₱${(totalAmount - newPaidAmount).toStringAsFixed(2)}',
      );
    } catch (e) {
      SnackbarService.showFavoritesError(
          'Failed to process payment: ${e.toString()}');
    }
  }

  Future<void> deleteFavorite(String favoriteId) async {
    try {
      await _firestore.collection('favorites').doc(favoriteId).delete();

      SnackbarService.showFavoritesSuccess('Favorite deleted successfully');
    } catch (e) {
      SnackbarService.showFavoritesError(
          'Failed to delete favorite: ${e.toString()}');
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

      SnackbarService.showFavoritesSuccess(
          'All favorites deleted successfully');
    } catch (e) {
      SnackbarService.showFavoritesError(
          'Failed to delete all favorites: ${e.toString()}');
    }
  }
}
