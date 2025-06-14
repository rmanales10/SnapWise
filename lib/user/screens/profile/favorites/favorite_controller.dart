
import 'dart:async';

import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoriteController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxList<Map<String, dynamic>> favorites = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  StreamSubscription? _favoritesSubscription;

  @override
  void onInit() {
    super.onInit();
    _setupFavoritesStream();
  }

  @override
  void onClose() {
    _favoritesSubscription?.cancel();
    super.onClose();
  }

  void _setupFavoritesStream() {
    final User? user = _auth.currentUser;
    if (user == null) return;

    _favoritesSubscription = _firestore
        .collection('favorites')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            favorites.value =
                snapshot.docs.map((doc) {
                  final data = doc.data();
                  return {'id': doc.id, ...data};
                }).toList();
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

      // Update the document with new payment information
      await _firestore.collection('favorites').doc(favoriteId).update({
        'paidAmount': newPaidAmount,
        'paidAt': FieldValue.serverTimestamp(),
        'status': newPaidAmount >= totalAmount ? 'Paid' : 'Pending',
      });

      Get.snackbar(
        'Success',
        newPaidAmount >= totalAmount
            ? 'Payment completed successfully'
            : 'Partial payment processed. Remaining: ${(totalAmount - newPaidAmount).toStringAsFixed(2)}',
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

      final QuerySnapshot querySnapshot =
          await _firestore
              .collection('favorites')
              .where('userId', isEqualTo: user.uid)
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
