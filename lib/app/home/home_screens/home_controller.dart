import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../services/snackbar_service.dart';

class HomeController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  RxList<Map<String, dynamic>> transactions = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> transactionsHistory =
      <Map<String, dynamic>>[].obs;
  RxString totalBudget = '0.0'.obs;
  RxString totalIncome = '0.0'.obs;
  RxDouble totalPaymentHistory = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTransactions();
    fetchTransactionsHistory();
    getTotalPaymentHistory();
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

  Future<void> fetchTransactions() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final monthRange = _getCurrentMonthRange();
        final querySnapshot = await _firestore
            .collection('expenses')
            .where('userId', isEqualTo: user.uid)
            .where('timestamp', isGreaterThanOrEqualTo: monthRange['start'])
            .where('timestamp', isLessThan: monthRange['end'])
            .orderBy('timestamp', descending: true)
            .get();

        DateTime now = DateTime.now();
        DateTime startOfMonth = DateTime(now.year, now.month, 1);
        DateTime startOfNextMonth = (now.month < 12)
            ? DateTime(now.year, now.month + 1, 1)
            : DateTime(now.year + 1, 1, 1);

        final fetchedTransactions = querySnapshot.docs
            .map((doc) {
              final data = doc.data();

              // Check if expense is within current month based on receipt date
              bool isInCurrentMonth = true;
              if (data['receiptDate'] != null) {
                try {
                  DateTime receiptDate = DateTime.parse(data['receiptDate']);
                  isInCurrentMonth = receiptDate.isAfter(
                          startOfMonth.subtract(const Duration(days: 1))) &&
                      receiptDate.isBefore(startOfNextMonth);
                } catch (e) {
                  // If receipt date parsing fails, use timestamp
                  isInCurrentMonth = true;
                }
              }

              return {
                'id': doc.id,
                "icon": _getCategoryIcon(data['category']),
                "title": data['category'],
                "date": _formatDate(data['timestamp']),
                "amount": "-${data['amount'].toStringAsFixed(2)}",
                "isInCurrentMonth": isInCurrentMonth, // Add flag for filtering
              };
            })
            .where((transaction) => transaction['isInCurrentMonth'] == true)
            .map((transaction) {
              // Remove the flag before adding to final list
              transaction.remove('isInCurrentMonth');
              return transaction;
            })
            .toList();

        transactionsHistory.assignAll(fetchedTransactions);
        log('Fetched ${fetchedTransactions.length} transactions for current month (based on receipt date)');
      }
    } catch (e) {
      log('Error fetching transactions: $e');
    }
  }

  Future<void> fetchTransactionsHistory() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final monthRange = _getCurrentMonthRange();
        final querySnapshot = await _firestore
            .collection('expenses')
            .where('userId', isEqualTo: user.uid)
            .where('timestamp', isGreaterThanOrEqualTo: monthRange['start'])
            .where('timestamp', isLessThan: monthRange['end'])
            .orderBy('timestamp', descending: true)
            .get(); // Remove limit to get all transactions for filtering

        DateTime now = DateTime.now();
        DateTime startOfMonth = DateTime(now.year, now.month, 1);
        DateTime startOfNextMonth = (now.month < 12)
            ? DateTime(now.year, now.month + 1, 1)
            : DateTime(now.year + 1, 1, 1);

        final fetchedTransactions = querySnapshot.docs
            .map((doc) {
              final data = doc.data();

              // Check if expense is within current month based on receipt date
              bool isInCurrentMonth = true;
              if (data['receiptDate'] != null) {
                try {
                  DateTime receiptDate = DateTime.parse(data['receiptDate']);
                  isInCurrentMonth = receiptDate.isAfter(
                          startOfMonth.subtract(const Duration(days: 1))) &&
                      receiptDate.isBefore(startOfNextMonth);
                } catch (e) {
                  // If receipt date parsing fails, use timestamp
                  isInCurrentMonth = true;
                }
              }

              return {
                'id': doc.id,
                "icon": _getCategoryIcon(data['category']),
                "title": data['category'],
                "date": _formatDate(data['timestamp']),
                "amount": "-${data['amount'].toStringAsFixed(2)}",
                "isInCurrentMonth": isInCurrentMonth, // Add flag for filtering
              };
            })
            .where((transaction) => transaction['isInCurrentMonth'] == true)
            .map((transaction) {
              // Remove the flag before adding to final list
              transaction.remove('isInCurrentMonth');
              return transaction;
            })
            .take(3)
            .toList(); // Take only first 3 after filtering

        transactions.assignAll(fetchedTransactions);
        log('Fetched ${fetchedTransactions.length} recent transactions for current month (based on receipt date)');
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
    // Calculate from regular expenses
    double total = transactionsHistory.fold(0.0, (double sum, transaction) {
      // Assuming 'amount' is stored as a string with '-' prefix
      String amountStr = transaction['amount'].replaceAll('-', '');
      return sum + double.parse(amountStr);
    });

    // Add favorites payments from current month
    total += totalPaymentHistory.value;

    if (total >= 1000000) {
      double inMillions = total / 1000000;
      return '${inMillions.toStringAsFixed(1)}M';
    } else if (total >= 1000) {
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

      if (!budgetDoc.exists) {
        totalBudget.value = '0.00';
        return;
      }

      final budgetData = budgetDoc.data() as Map<String, dynamic>;
      final amount = budgetData['amount'];

      if (amount == null || amount is! num) {
        totalBudget.value = '0.00';
        return;
      }

      double total = amount.toDouble();

      if (total >= 1000000) {
        double inMillions = total / 1000000;
        totalBudget.value = '${inMillions.toStringAsFixed(1)}M';
      } else if (total >= 1000) {
        double inThousands = total / 1000;
        totalBudget.value = '${inThousands.toStringAsFixed(1)}k';
      } else {
        totalBudget.value = total.toStringAsFixed(2);
      }
    } catch (e) {
      SnackbarService.showError(
          title: 'Budget Error',
          message: 'Failed to fetch budget: ${e.toString()}');
      totalBudget.value = '0.00';
    }
  }

  Future<void> getTotalIncome() async {
    try {
      final User? user = _auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final DocumentSnapshot incomeDoc =
          await _firestore.collection('income').doc(user.uid).get();

      if (!incomeDoc.exists) {
        totalIncome.value = '0.00';
        return;
      }

      final incomeData = incomeDoc.data() as Map<String, dynamic>;
      final amount = incomeData['amount'];

      if (amount == null || amount is! num) {
        totalIncome.value = '0.00';
        return;
      }

      double total = amount.toDouble();

      if (total >= 1000000) {
        double inMillions = total / 1000000;
        totalIncome.value = '${inMillions.toStringAsFixed(1)}M';
      } else if (total >= 1000) {
        double inThousands = total / 1000;
        totalIncome.value = '${inThousands.toStringAsFixed(1)}k';
      } else {
        totalIncome.value = total.toStringAsFixed(2);
      }
    } catch (e) {
      SnackbarService.showError(
          title: 'Income Error',
          message: 'Failed to fetch income: ${e.toString()}');
      totalIncome.value = '0.00';
    }
  }

  Future<void> getTotalPaymentHistory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        totalPaymentHistory.value = 0.0;
        return;
      }

      // Get all favorites for the user (not filtered by timestamp)
      final querySnapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: user.uid)
          .get();

      double totalAmount = 0.0;
      final monthRange = _getCurrentMonthRange();

      // Process each favorite's payment history
      for (var doc in querySnapshot.docs) {
        final favoriteData = doc.data();
        List<Map<String, dynamic>> paymentHistory =
            List<Map<String, dynamic>>.from(
                favoriteData['paymentHistory'] ?? []);

        // Calculate payments made in current month
        for (var payment in paymentHistory) {
          final paymentDateRaw = payment['timestamp'];
          DateTime paymentDate;

          if (paymentDateRaw is Timestamp) {
            paymentDate = paymentDateRaw.toDate();
          } else if (paymentDateRaw is DateTime) {
            paymentDate = paymentDateRaw;
          } else {
            continue; // Skip invalid dates
          }

          // Check if payment is within current month
          final startDate = monthRange['start']?.toDate();
          final endDate = monthRange['end']?.toDate();
          if (startDate != null &&
              endDate != null &&
              paymentDate
                  .isAfter(startDate.subtract(const Duration(days: 1))) &&
              paymentDate.isBefore(endDate)) {
            double amount = (payment['amount'] ?? 0.0).toDouble();
            totalAmount += amount;
          }
        }
      }

      // Update the value only once at the end
      totalPaymentHistory.value = totalAmount;
      log('Total payment history: $totalAmount');
    } catch (e) {
      log('Error fetching payment history: $e');
      totalPaymentHistory.value = 0.0;
    }
  }

  // Method to refresh all data
  Future<void> refreshAllData() async {
    await fetchTransactions();
    await fetchTransactionsHistory();
    await getTotalPaymentHistory();
    await getTotalBudget();
    await getTotalIncome();
  }
}
