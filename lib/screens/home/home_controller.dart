import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';

class HomeController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  RxList<Map<String, dynamic>> transactions = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> transactionsHistory =
      <Map<String, dynamic>>[].obs;
  final Rx<Map<String, dynamic>> budgetData = Rx<Map<String, dynamic>>({});

  @override
  void onInit() {
    super.onInit();
    fetchTransactions();
    fetchTransactionsHistory();
  }

  Future<void> fetchTransactions() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final querySnapshot =
            await _firestore
                .collection('expenses')
                .where('userId', isEqualTo: user.uid)
                .orderBy('timestamp', descending: true)
                .get();

        final fetchedTransactions =
            querySnapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                "icon": _getCategoryIcon(data['category']),
                "title": data['category'],
                "date": _formatDate(data['timestamp']),
                "amount": "-${data['amount'].toStringAsFixed(2)}",
              };
            }).toList();

        transactionsHistory.assignAll(fetchedTransactions);
      }
    } catch (e) {
      log('Error fetching transactions: $e');
    }
  }

  Future<void> fetchTransactionsHistory() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final querySnapshot =
            await _firestore
                .collection('expenses')
                .where('userId', isEqualTo: user.uid)
                .orderBy('timestamp', descending: true)
                .limit(3)
                .get();

        final fetchedTransactions =
            querySnapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                "icon": _getCategoryIcon(data['category']),
                "title": data['category'],
                "date": _formatDate(data['timestamp']),
                "amount": "-${data['amount'].toStringAsFixed(2)}",
              };
            }).toList();

        transactions.assignAll(fetchedTransactions);
      }
    } catch (e) {
      log('Error fetching transactions: $e');
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'shopping':
        return LucideIcons.shoppingBag;
      case 'food':
        return LucideIcons.utensils;
      case 'transport':
        return LucideIcons.train;
      case 'rent':
        return LucideIcons.home;
      case 'entertainment':
        return Icons.movie;
      default:
        return LucideIcons.dollarSign;
    }
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final month = _getMonthAbbreviation(date.month);
    return '$month ${date.day}, ${date.year}';
  }

  String _getMonthAbbreviation(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  String getTotalSpent() {
    double total = transactions.fold(0.0, (sum, transaction) {
      // Assuming 'amount' is stored as a string with '-' prefix
      String amountStr = transaction['amount'].replaceAll('-', '');
      return sum + double.parse(amountStr);
    });

    if (total >= 1000) {
      double inThousands = total / 1000;
      return '${inThousands.toStringAsFixed(1)}k';
    } else {
      return total.toStringAsFixed(2);
    }
  }

  Future<void> getTotalBudget() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final DocumentSnapshot budgetDoc =
          await _firestore.collection('overallBudget').doc(user.uid).get();

      if (budgetDoc.exists) {
        budgetData.value = budgetDoc.data() as Map<String, dynamic>;
      } else {
        budgetData.value = {};
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch budget: ${e.toString()}');
    }
  }
}
