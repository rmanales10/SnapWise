import 'dart:developer';
import 'dart:async';

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

  // Prevent multiple simultaneous calls
  bool _isFetchingTransactions = false;
  bool _isFetchingTransactionHistory = false;

  // Add a flag to track if data is being refreshed
  bool _isRefreshingData = false;
  Timer? _refreshTimer;

  @override
  void onInit() {
    super.onInit();
    refreshAllData();
    // Removed periodic refresh to prevent infinite fetching
    // _startPeriodicRefresh();
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }

  // Manual refresh method for when user explicitly wants to refresh data
  Future<void> manualRefresh() async {
    if (!_isRefreshingData) {
      log('Manual refresh triggered');
      await refreshAllData();
    }
  }

  // Start periodic refresh every 30 seconds to ensure data consistency
  // DISABLED to prevent infinite fetching - use manualRefresh() instead
  // void _startPeriodicRefresh() {
  //   _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
  //     if (!_isRefreshingData) {
  //       log('Periodic refresh triggered');
  //       refreshAllData();
  //     }
  //   });
  // }

  Future<void> refreshAllData() async {
    // Prevent multiple simultaneous refreshes
    if (_isRefreshingData) {
      log('refreshAllData already in progress, skipping...');
      return;
    }

    _isRefreshingData = true;

    try {
      await Future.wait([
        fetchTransactions(),
        getTotalPaymentHistory(),
        getTotalIncome(),
        getTotalBudget(),
      ]);

      // REMOVED: Monthly calculation verification to prevent infinite loops
      // await _verifyMonthlyCalculation();

      // Log the final cached values to ensure consistency
      log('=== FINAL CACHED VALUES ===');
      log('transactionsHistory.length: ${transactionsHistory.length}');
      log('totalPaymentHistory.value: ${totalPaymentHistory.value}');
      log('Current getTotalSpent(): ${getTotalSpent()}');
      log('==========================');
    } finally {
      _isRefreshingData = false;
    }
  }

  // REMOVED: _verifyMonthlyCalculation method to prevent infinite refresh loops
  // The method was causing infinite loops due to data inconsistency detection

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
    // Prevent multiple simultaneous calls
    if (_isFetchingTransactions) {
      log('fetchTransactions already in progress, skipping...');
      return;
    }

    _isFetchingTransactions = true;

    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Fetch all expenses and filter by transaction date for today only
        final querySnapshot = await _firestore
            .collection('expenses')
            .where('userId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .get();

        DateTime now = DateTime.now();
        DateTime startOfToday = DateTime(now.year, now.month, now.day);
        DateTime endOfToday =
            DateTime(now.year, now.month, now.day, 23, 59, 59);

        final fetchedTransactions = querySnapshot.docs
            .map((doc) {
              final data = doc.data();

              // Check if expense is from today based on transaction date (timestamp)
              bool isToday = false;
              DateTime timestamp = (data['timestamp'] as Timestamp).toDate();
              isToday = timestamp.isAfter(
                      startOfToday.subtract(const Duration(seconds: 1))) &&
                  timestamp
                      .isBefore(endOfToday.add(const Duration(seconds: 1)));

              // Use receipt date for display if available, otherwise use timestamp
              String displayDate;
              if (data['receiptDate'] != null &&
                  data['receiptDate'].toString().isNotEmpty) {
                try {
                  DateTime receiptDate = DateTime.parse(data['receiptDate']);
                  displayDate = _formatDateFromDateTime(receiptDate);
                } catch (e) {
                  displayDate = _formatDate(data['timestamp']);
                }
              } else {
                displayDate = _formatDate(data['timestamp']);
              }

              return {
                'id': doc.id,
                "icon": _getCategoryIcon(data['category']),
                "title": data['category'],
                "date": displayDate,
                "amount": "-${data['amount'].toStringAsFixed(2)}",
                "isToday":
                    isToday, // Add flag for filtering today's transactions
              };
            })
            .where((transaction) => transaction['isToday'] == true)
            .map((transaction) {
              // Remove the flag before adding to final list
              transaction.remove('isToday');
              return transaction;
            })
            .toList();

        transactionsHistory.assignAll(fetchedTransactions);

        // Take only first 3 for display in transactions (most recent from today)
        final displayTransactions = fetchedTransactions.take(3).toList();
        transactions.assignAll(displayTransactions);

        log('Fetched ${fetchedTransactions.length} transactions for today (based on transaction date/timestamp)');
        log('Displaying ${displayTransactions.length} recent transactions from today');
      }
    } catch (e) {
      log('Error fetching transactions: $e');
    } finally {
      _isFetchingTransactions = false;
    }
  }

  Future<void> fetchTransactionsHistory() async {
    // Prevent multiple simultaneous calls
    if (_isFetchingTransactionHistory) {
      log('fetchTransactionsHistory already in progress, skipping...');
      return;
    }

    _isFetchingTransactionHistory = true;

    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Fetch all expenses and filter by receipt date for current month
        final querySnapshot = await _firestore
            .collection('expenses')
            .where('userId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .get();

        DateTime now = DateTime.now();
        DateTime startOfMonth = DateTime(now.year, now.month, 1);
        DateTime startOfNextMonth = (now.month < 12)
            ? DateTime(now.year, now.month + 1, 1)
            : DateTime(now.year + 1, 1, 1);

        log('=== FETCHING TRANSACTIONS HISTORY ===');
        log('Total documents from Firestore: ${querySnapshot.docs.length}');
        log('Date range: ${startOfMonth.toString()} to ${startOfNextMonth.toString()}');

        final allTransactions = <Map<String, dynamic>>[];

        for (var doc in querySnapshot.docs) {
          final data = doc.data();

          // Check if expense is within current month based on receipt date
          bool isInCurrentMonth = false;
          String dateSource = '';

          if (data['receiptDate'] != null &&
              data['receiptDate'].toString().isNotEmpty) {
            try {
              DateTime receiptDate = DateTime.parse(data['receiptDate']);
              isInCurrentMonth = receiptDate.isAfter(
                      startOfMonth.subtract(const Duration(days: 1))) &&
                  receiptDate.isBefore(startOfNextMonth);
              dateSource = 'receiptDate';
            } catch (e) {
              // If receipt date parsing fails, check timestamp as fallback
              DateTime timestamp = (data['timestamp'] as Timestamp).toDate();
              isInCurrentMonth = timestamp.isAfter(
                      startOfMonth.subtract(const Duration(days: 1))) &&
                  timestamp.isBefore(startOfNextMonth);
              dateSource = 'timestamp (fallback)';
            }
          } else {
            // If no receipt date, use timestamp
            DateTime timestamp = (data['timestamp'] as Timestamp).toDate();
            isInCurrentMonth = timestamp
                    .isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
                timestamp.isBefore(startOfNextMonth);
            dateSource = 'timestamp';
          }

          if (isInCurrentMonth) {
            // Use receipt date for display if available, otherwise use timestamp
            String displayDate;
            if (data['receiptDate'] != null &&
                data['receiptDate'].toString().isNotEmpty) {
              try {
                DateTime receiptDate = DateTime.parse(data['receiptDate']);
                displayDate = _formatDateFromDateTime(receiptDate);
              } catch (e) {
                displayDate = _formatDate(data['timestamp']);
              }
            } else {
              displayDate = _formatDate(data['timestamp']);
            }

            final transaction = {
              'id': doc.id,
              "icon": _getCategoryIcon(data['category']),
              "title": data['category'],
              "date": displayDate,
              "amount": "-${data['amount'].toStringAsFixed(2)}",
            };
            allTransactions.add(transaction);
            log('Added transaction: ${data['category']} - ${data['amount']} - Source: $dateSource - Date: $displayDate');
          } else {
            log('Skipped transaction: ${data['category']} - ${data['amount']} - Source: $dateSource');
          }
        }

        // Store ALL transactions for the current month in transactionsHistory
        transactionsHistory.assignAll(allTransactions);

        // Take only first 3 for display in transactions
        final displayTransactions = allTransactions.take(3).toList();
        transactions.assignAll(displayTransactions);

        log('Final result: ${allTransactions.length} total transactions for current month');
        log('Displaying ${displayTransactions.length} recent transactions');
        log('==========================================');
      }
    } catch (e) {
      log('Error fetching transactions: $e');
    } finally {
      _isFetchingTransactionHistory = false;
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

  String _formatDateFromDateTime(DateTime date) {
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
    // Use cached values for immediate display, but log the calculation
    double regularExpenses =
        transactionsHistory.fold(0.0, (double sum, transaction) {
      String amountStr = transaction['amount'].replaceAll('-', '');
      double amount = double.parse(amountStr);
      return sum + amount;
    });

    double favoritesPayments = totalPaymentHistory.value;
    double total = regularExpenses + favoritesPayments;

    // Debug logging
    log('=== HOME SCREEN TOTAL SPENT (CACHED VALUES) ===');
    log('Regular expenses (${transactionsHistory.length} transactions): $regularExpenses');
    log('Favorites payments: $favoritesPayments');
    log('Total: $total');
    log('Note: Using cached values - may not match BudgetController exactly');
    log('==============================================');

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

  // Force refresh data when inconsistencies are detected
  Future<void> forceRefreshData() async {
    log('Force refreshing data due to inconsistency...');
    await manualRefresh();
  }

  // Get raw total spent value without formatting
  double getRawTotalSpent() {
    double regularExpenses =
        transactionsHistory.fold(0.0, (double sum, transaction) {
      String amountStr = transaction['amount'].replaceAll('-', '');
      double amount = double.parse(amountStr);
      return sum + amount;
    });

    double favoritesPayments = totalPaymentHistory.value;
    return regularExpenses + favoritesPayments;
  }

  // Get raw income value without formatting
  double getRawIncome() {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return 0.0;

      // Get the raw income value from the cached data
      // We need to parse the formatted string back to raw value
      String formattedIncome = totalIncome.value;
      return _parseFormattedAmount(formattedIncome);
    } catch (e) {
      log('Error getting raw income: $e');
      return 0.0;
    }
  }

  // Helper method to parse formatted amounts back to raw values
  double _parseFormattedAmount(String amount) {
    amount = amount.replaceAll('\$', '').replaceAll('PHP', '').trim();

    if (amount.endsWith('k')) {
      return double.parse(amount.substring(0, amount.length - 1)) * 1000;
    } else if (amount.endsWith('M')) {
      return double.parse(amount.substring(0, amount.length - 1)) * 1000000;
    } else {
      return double.parse(amount);
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

      log('=== INCOME FETCH ===');
      log('Raw income amount: $total');

      if (total >= 1000000) {
        double inMillions = total / 1000000;
        totalIncome.value = '${inMillions.toStringAsFixed(1)}M';
        log('Formatted income: ${totalIncome.value}');
      } else if (total >= 1000) {
        double inThousands = total / 1000;
        totalIncome.value = '${inThousands.toStringAsFixed(1)}k';
        log('Formatted income: ${totalIncome.value}');
      } else {
        totalIncome.value = total.toStringAsFixed(2);
        log('Formatted income: ${totalIncome.value}');
      }
      log('==================');
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

      log('=== FAVORITES PAYMENT CALCULATION ===');
      log('Current month range: ${monthRange['start']?.toDate()} to ${monthRange['end']?.toDate()}');
      log('Total favorites found: ${querySnapshot.docs.length}');

      // Process each favorite's payment history
      for (var doc in querySnapshot.docs) {
        final favoriteData = doc.data();
        String favoriteName = favoriteData['title'] ?? 'Unknown';
        List<Map<String, dynamic>> paymentHistory =
            List<Map<String, dynamic>>.from(
                favoriteData['paymentHistory'] ?? []);

        log('Processing favorite: $favoriteName with ${paymentHistory.length} payments');

        // Calculate payments made in current month
        for (var payment in paymentHistory) {
          final paymentDateRaw = payment['timestamp'];
          DateTime paymentDate;

          if (paymentDateRaw is Timestamp) {
            paymentDate = paymentDateRaw.toDate();
          } else if (paymentDateRaw is DateTime) {
            paymentDate = paymentDateRaw;
          } else {
            log('Skipping invalid payment date: $paymentDateRaw');
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
            log('Favorites payment: $favoriteName - Amount: $amount - Date: $paymentDate');
          } else {
            log('Payment outside current month: $favoriteName - Amount: ${payment['amount']} - Date: $paymentDate');
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
}
