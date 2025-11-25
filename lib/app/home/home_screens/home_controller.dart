import 'dart:developer';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../services/snackbar_service.dart';
import '../../../services/monthly_reset_service.dart';
import '../../widget/monthly_reset_income_dialog.dart';

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

  // Real-time stream subscriptions
  StreamSubscription<QuerySnapshot>? _expensesSubscription;
  StreamSubscription<QuerySnapshot>? _favoritesSubscription;
  StreamSubscription<DocumentSnapshot>? _budgetSubscription;
  StreamSubscription<DocumentSnapshot>? _incomeSubscription;

  @override
  void onInit() {
    super.onInit();
    // Check and perform monthly reset if needed
    _checkMonthlyReset();
    // Set up real-time listeners
    _setupRealtimeListeners();
    // Initial data fetch
    refreshAllData();
  }

  // Check if monthly reset is needed and show income dialog if needed
  Future<void> _checkMonthlyReset() async {
    try {
      if (Get.isRegistered<MonthlyResetService>()) {
        final monthlyResetService = Get.find<MonthlyResetService>();
        await monthlyResetService.checkAndPerformMonthlyReset();
      }
    } catch (e) {
      log('Error checking monthly reset: $e');
    }
  }

  // Check income after data refresh and show dialog if needed
  Future<void> _checkIncomeAfterRefresh() async {
    try {
      // Wait a bit for UI to be ready
      await Future.delayed(const Duration(milliseconds: 1000));

      // Get current income value
      final rawIncome = getRawIncome();
      log('=== INCOME CHECK AFTER REFRESH ===');
      log('Raw income: $rawIncome');

      if (rawIncome == 0.0 || rawIncome <= 0) {
        log('Income is 0 - showing income dialog');
        // Show blocking dialog to set income
        await MonthlyResetIncomeDialog.show();
      }
    } catch (e) {
      log('Error checking income after refresh: $e');
    }
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    // Cancel all real-time subscriptions
    _expensesSubscription?.cancel();
    _favoritesSubscription?.cancel();
    _budgetSubscription?.cancel();
    _incomeSubscription?.cancel();
    super.onClose();
  }

  /// Set up real-time Firestore listeners for automatic updates
  void _setupRealtimeListeners() {
    final user = _auth.currentUser;
    if (user == null) {
      log('User not authenticated, cannot set up real-time listeners');
      return;
    }

    log('=== SETTING UP REAL-TIME LISTENERS ===');

    // Listen to expenses changes
    _expensesSubscription = _firestore
        .collection('expenses')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      log('📊 Real-time update: Expenses changed (${snapshot.docs.length} documents)');
      _handleExpensesUpdate();
    }, onError: (error) {
      log('Error in expenses listener: $error');
    });

    // Listen to favorites/priority payments changes
    _favoritesSubscription = _firestore
        .collection('favorites')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      log('⭐ Real-time update: Favorites changed (${snapshot.docs.length} documents)');
      _handleFavoritesUpdate();
    }, onError: (error) {
      log('Error in favorites listener: $error');
    });

    // Listen to budget changes
    _budgetSubscription = _firestore
        .collection('overallBudget')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        // Use 'amount' field to match getTotalBudget() method
        final amount = data?['amount'];

        if (amount != null && amount is num) {
          totalBudget.value = _formatAmount(amount);
          log('💰 Real-time update: Budget changed to ${totalBudget.value} (raw: $amount)');
        } else {
          totalBudget.value = '0.00';
          log('💰 Real-time update: No valid budget found');
        }
      }
    }, onError: (error) {
      log('Error in budget listener: $error');
    });

    // Listen to income changes
    _incomeSubscription = _firestore
        .collection('income')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        // Use 'amount' field to match getTotalIncome() method
        final amount = data?['amount'];

        if (amount != null && amount is num) {
          totalIncome.value = _formatAmount(amount);
          log('💵 Real-time update: Income changed to ${totalIncome.value} (raw: $amount)');
        } else {
          totalIncome.value = '0.00';
          log('💵 Real-time update: No valid income found');
        }
      }
    }, onError: (error) {
      log('Error in income listener: $error');
    });

    log('✅ Real-time listeners set up successfully');
  }

  /// Handle real-time expenses updates
  void _handleExpensesUpdate() async {
    if (_isRefreshingData) {
      log('Already refreshing, skipping expenses update');
      return;
    }

    _isRefreshingData = true;
    try {
      await Future.wait([
        fetchTransactions(),
        fetchTransactionsHistory(),
        _fetchCurrentMonthTotalForDisplay(),
      ]);
      log('✅ Expenses data refreshed');
    } finally {
      _isRefreshingData = false;
    }
  }

  /// Handle real-time favorites updates
  void _handleFavoritesUpdate() async {
    if (_isRefreshingData) {
      log('Already refreshing, skipping favorites update');
      return;
    }

    _isRefreshingData = true;
    try {
      await getTotalPaymentHistory();
      await _fetchCurrentMonthTotalForDisplay();
      log('✅ Favorites data refreshed');
    } finally {
      _isRefreshingData = false;
    }
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
        _checkMonthlyReset(),
        fetchTransactions(),
        getTotalPaymentHistory(),
        getTotalIncome(),
        getTotalBudget(),
        _fetchCurrentMonthTotalForDisplay(),
      ]);

      // REMOVED: Monthly calculation verification to prevent infinite loops
      // await _verifyMonthlyCalculation();

      // Log the final cached values to ensure consistency
      log('=== FINAL CACHED VALUES ===');
      log('transactionsHistory.length: ${transactionsHistory.length}');

      // Check if income needs to be set after data refresh
      _checkIncomeAfterRefresh();
      log('totalPaymentHistory.value: ${totalPaymentHistory.value}');
      log('Current month total: ${_currentMonthTotal.value}');
      log('Current getTotalSpent(): ${getTotalSpent()}');
      log('==========================');
    } finally {
      _isRefreshingData = false;
    }
  }

  // Fetch current month total for display
  Future<void> _fetchCurrentMonthTotalForDisplay() async {
    try {
      double total = await _fetchCurrentMonthTotal();
      _currentMonthTotal.value = total;
      log('Updated current month total for display: $total');
    } catch (e) {
      log('Error fetching current month total for display: $e');
      _currentMonthTotal.value = 0.0;
    }
  }

  // REMOVED: _verifyMonthlyCalculation method to prevent infinite refresh loops
  // The method was causing infinite loops due to data inconsistency detection

  /// Helper method to format amount in M/k format
  /// Reduces code duplication across listeners and fetch methods
  String _formatAmount(num amount) {
    double total = amount.toDouble();

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
        // Fetch all expenses and filter by Posting Date (when user added) for today only
        final querySnapshot = await _firestore
            .collection('expenses')
            .where('userId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .get();

        DateTime now = DateTime.now();
        DateTime startOfToday = DateTime(now.year, now.month, now.day);
        DateTime endOfToday =
            DateTime(now.year, now.month, now.day, 23, 59, 59);

        log('=== FETCHING RECENT TRANSACTIONS (Posting Date) ===');
        log('Current DateTime.now(): $now');
        log('Start of today: $startOfToday');
        log('End of today: $endOfToday');
        log('========================================================');

        final fetchedTransactions = querySnapshot.docs
            .map((doc) {
              final data = doc.data();

              // Check if expense was ADDED today based on Posting Date
              bool isAddedToday = false;

              // Use transactionDate to check if expense was added today
              if (data['transactionDate'] != null &&
                  data['transactionDate'].toString().isNotEmpty) {
                try {
                  DateTime transactionDate =
                      DateTime.parse(data['transactionDate']);
                  isAddedToday = transactionDate.isAfter(
                          startOfToday.subtract(const Duration(seconds: 1))) &&
                      transactionDate
                          .isBefore(endOfToday.add(const Duration(seconds: 1)));

                  log('Posting Date: $transactionDate - isAddedToday: $isAddedToday');
                } catch (e) {
                  // If Posting Date parsing fails, fall back to timestamp
                  DateTime timestamp =
                      (data['timestamp'] as Timestamp).toDate();
                  isAddedToday = timestamp.isAfter(
                          startOfToday.subtract(const Duration(seconds: 1))) &&
                      timestamp
                          .isBefore(endOfToday.add(const Duration(seconds: 1)));

                  log('Posting Date parsing failed, using timestamp: $timestamp - isAddedToday: $isAddedToday');
                }
              } else {
                // If no Posting Date, fall back to timestamp
                DateTime timestamp = (data['timestamp'] as Timestamp).toDate();
                isAddedToday = timestamp.isAfter(
                        startOfToday.subtract(const Duration(seconds: 1))) &&
                    timestamp
                        .isBefore(endOfToday.add(const Duration(seconds: 1)));

                log('No Posting Date, using timestamp: $timestamp - isAddedToday: $isAddedToday');
              }

              // Display receipt date (the actual date of the expense)
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
                "date": displayDate, // Show receipt date
                "amount": "-${data['amount'].toStringAsFixed(2)}",
                "isToday": isAddedToday, // Filter by Posting Date
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

        // Take only first 3 for display in transactions (most recent added today)
        final displayTransactions = fetchedTransactions.take(3).toList();
        transactions.assignAll(displayTransactions);

        log('=== RECENT TRANSACTIONS SUMMARY ===');
        log('Fetched ${fetchedTransactions.length} transactions ADDED today (filtered by transactionDate)');
        log('Displaying ${displayTransactions.length} recent transactions');
        if (fetchedTransactions.isNotEmpty) {
          log('Recent transactions added today:');
          for (var tx in fetchedTransactions) {
            log('  - ${tx['title']}: ${tx['amount']} (Receipt date: ${tx['date']})');
          }
        } else {
          log('No transactions added today!');
        }
        log('====================================');
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
    // Use the same monthly calculation as GraphController for consistency
    double currentMonthTotal = getCurrentMonthTotalFromCache();

    // Debug logging
    log('=== HOME SCREEN TOTAL SPENT (MONTHLY CALCULATION) ===');
    log('Current month total: $currentMonthTotal');
    log('==============================================');

    if (currentMonthTotal >= 1000000) {
      double inMillions = currentMonthTotal / 1000000;
      return '${inMillions.toStringAsFixed(1)}M';
    } else if (currentMonthTotal >= 1000) {
      double inThousands = currentMonthTotal / 1000;
      return '${inThousands.toStringAsFixed(1)}k';
    } else {
      return currentMonthTotal.toStringAsFixed(2);
    }
  }

  // Get current month total from cache (same calculation as GraphController)
  double getCurrentMonthTotalFromCache() {
    // Use the reactive current month total
    return _currentMonthTotal.value;
  }

  // Add a reactive variable to store current month total
  final RxDouble _currentMonthTotal = 0.0.obs;

  // Get current month total (reactive)
  double get currentMonthTotal => _currentMonthTotal.value;

  // Fetch and calculate current month total from Firestore based on receiptDate
  Future<double> _fetchCurrentMonthTotal() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0.0;

      DateTime now = DateTime.now();
      DateTime startOfMonth = DateTime(now.year, now.month, 1);
      DateTime startOfNextMonth = (now.month < 12)
          ? DateTime(now.year, now.month + 1, 1)
          : DateTime(now.year + 1, 1, 1);

      // Get ALL expenses for the user (we'll filter by receiptDate in code)
      final querySnapshot = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .get();

      double regularExpenses = 0.0;
      for (var doc in querySnapshot.docs) {
        final data = doc.data();

        // Check if this expense is from current month based on receiptDate
        DateTime expenseDate;
        bool isCurrentMonth = false;

        if (data['receiptDate'] != null &&
            data['receiptDate'].toString().isNotEmpty) {
          try {
            // Parse receipt date (format: YYYY-MM-DD)
            expenseDate = DateTime.parse(data['receiptDate']);
            isCurrentMonth = expenseDate
                    .isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
                expenseDate.isBefore(startOfNextMonth);
            log('Expense ${data['category']} - ReceiptDate: ${data['receiptDate']} - Parsed: $expenseDate - IsCurrentMonth: $isCurrentMonth');
          } catch (e) {
            // If receipt date parsing fails, skip this expense
            log('Error parsing receipt date for expense ${data['category']}: $e');
            continue;
          }
        } else {
          // If no receipt date, skip this expense
          log('No receipt date for expense ${data['category']}, skipping');
          continue;
        }

        if (isCurrentMonth) {
          double amountValue;
          if (data['amount'] is num) {
            amountValue = data['amount'].toDouble();
          } else if (data['amount'] is String) {
            // Remove any minus sign and parse as double
            String cleanAmount = data['amount'].replaceAll('-', '');
            amountValue = double.tryParse(cleanAmount) ?? 0.0;
          } else {
            amountValue = 0.0;
          }
          regularExpenses += amountValue;
          log('Added expense ${data['category']} - Amount: $amountValue - ReceiptDate: ${data['receiptDate']}');
        }
      }

      // Get favorites payments for current month (also based on receipt date)
      double favoritesPayments = await _getFavoritesPaymentsForCurrentMonth();

      log('Current month total (based on receiptDate) - Regular: $regularExpenses, Favorites: $favoritesPayments, Total: ${regularExpenses + favoritesPayments}');

      return regularExpenses + favoritesPayments;
    } catch (e) {
      log('Error fetching current month total: $e');
      return 0.0;
    }
  }

  // Get favorites payments for current month
  Future<double> _getFavoritesPaymentsForCurrentMonth() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0.0;

      DateTime now = DateTime.now();
      DateTime startOfMonth = DateTime(now.year, now.month, 1);
      DateTime startOfNextMonth = (now.month < 12)
          ? DateTime(now.year, now.month + 1, 1)
          : DateTime(now.year + 1, 1, 1);

      // Get all favorites for the user
      final querySnapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: user.uid)
          .get();

      double totalAmount = 0.0;

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
          if (paymentDate
                  .isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
              paymentDate.isBefore(startOfNextMonth)) {
            double amount = (payment['amount'] ?? 0.0).toDouble();
            totalAmount += amount;
          }
        }
      }

      return totalAmount;
    } catch (e) {
      log('Error getting favorites payments for current month: $e');
      return 0.0;
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
      
      // Check if budget is from current month
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfNextMonth = (now.month < 12)
          ? DateTime(now.year, now.month + 1, 1)
          : DateTime(now.year + 1, 1, 1);
      
      bool isCurrentMonth = false;
      if (budgetData['timestamp'] != null) {
        final Timestamp budgetTimestamp = budgetData['timestamp'] as Timestamp;
        final budgetDate = budgetTimestamp.toDate();
        isCurrentMonth = budgetDate.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
                        budgetDate.isBefore(startOfNextMonth);
      }
      
      if (!isCurrentMonth) {
        // Budget is from previous month, treat as 0
        totalBudget.value = '0.00';
        log('Budget is from previous month, displaying as 0');
        return;
      }
      
      final amount = budgetData['amount'];

      if (amount == null || amount is! num) {
        totalBudget.value = '0.00';
        return;
      }

      // Use helper method to format - reduces code duplication
      totalBudget.value = _formatAmount(amount);
      log('Fetched budget: ${totalBudget.value} (raw: $amount)');
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
      
      // Check if income is from current month
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfNextMonth = (now.month < 12)
          ? DateTime(now.year, now.month + 1, 1)
          : DateTime(now.year + 1, 1, 1);
      
      bool isCurrentMonth = false;
      if (incomeData['timestamp'] != null) {
        final Timestamp incomeTimestamp = incomeData['timestamp'] as Timestamp;
        final incomeDate = incomeTimestamp.toDate();
        isCurrentMonth = incomeDate.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
                        incomeDate.isBefore(startOfNextMonth);
      }
      
      if (!isCurrentMonth) {
        // Income is from previous month, treat as 0
        totalIncome.value = '0.00';
        log('Income is from previous month, displaying as 0');
        return;
      }
      
      final amount = incomeData['amount'];

      if (amount == null || amount is! num) {
        totalIncome.value = '0.00';
        return;
      }

      // Use helper method to format - reduces code duplication
      totalIncome.value = _formatAmount(amount);
      log('=== INCOME FETCH ===');
      log('Raw income amount: $amount');
      log('Formatted income: ${totalIncome.value}');
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
