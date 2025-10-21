import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';
import '../profile/favorites/favorite_controller.dart';

class GraphController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RxMap<String, double> dailyExpenses = <String, double>{}.obs;
  final RxMap<String, double> monthlyExpenses = <String, double>{}.obs;
  final RxDouble currentMonthTotal = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchExpenses();
  }

  // Method to refresh data when needed
  Future<void> refreshData() async {
    await fetchExpenses();
  }

  // Get total expenses for current period (includes both regular expenses and favorites)
  double getTotalExpenses({bool isDaily = true}) {
    if (isDaily) {
      // For daily view, return sum of current month daily expenses
      return getCurrentMonthExpenses()
          .fold(0.0, (double sum, expense) => sum + expense);
    } else {
      // For monthly view, return sum of last 12 months
      return getMonthlyExpensesForLastYear()
          .fold(0.0, (double sum, expense) => sum + expense);
    }
  }

  // Get formatted total expenses string
  String getFormattedTotalExpenses({bool isDaily = true}) {
    double total = getTotalExpenses(isDaily: isDaily);

    if (total >= 1000000) {
      double inMillions = total / 1000000;
      return 'PHP ${inMillions.toStringAsFixed(1)}M';
    } else if (total >= 1000) {
      double inThousands = total / 1000;
      return 'PHP ${inThousands.toStringAsFixed(1)}k';
    } else {
      return 'PHP ${total.toStringAsFixed(2)}';
    }
  }

  Future<void> fetchExpenses() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        log('No user logged in');
        return;
      }

      // Clear existing data
      dailyExpenses.clear();
      monthlyExpenses.clear();

      // Fetch all expenses (not just current month)
      QuerySnapshot querySnapshot = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: false)
          .get();

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        double amount = (data['amount'] as num).toDouble();

        // Use receipt date for graphing (when purchase was made)
        // Fallback to timestamp if receiptDate is not available
        DateTime date;
        if (data['receiptDate'] != null) {
          // Parse receipt date string (format: YYYY-MM-DD)
          date = DateTime.parse(data['receiptDate']);
        } else {
          // Fallback to timestamp for backward compatibility
          date = (data['timestamp'] as Timestamp).toDate();
        }

        // Debug logging to see what dates we're processing
        log('Processing expense: ${data['category']} - Amount: $amount - Date: ${date.toString()} - ReceiptDate: ${data['receiptDate']} - Timestamp: ${data['timestamp']}');

        // Include all records based on receipt date for historical graph
        updateDailyExpenses(date, amount);
        updateMonthlyExpenses(date, amount);
        log('Including expense in graph: ${data['category']} - ${date.toString()}');
      }

      // Fetch and include favorites payments
      await _fetchFavoritesPayments();

      // Update current month total to match home controller
      await _updateCurrentMonthTotal();

      log('Fetched ${querySnapshot.docs.length} expenses');
      log('Daily expenses: ${dailyExpenses.length} entries');
      log('Monthly expenses: ${monthlyExpenses.length} entries');
    } catch (e) {
      log('Error fetching expenses: $e');
    }
  }

  // Fetch favorites payments and add them to the graph data
  Future<void> _fetchFavoritesPayments() async {
    try {
      // Initialize FavoriteController if not already initialized
      FavoriteController favoriteController;
      try {
        favoriteController = Get.put(FavoriteController());
      } catch (e) {
        favoriteController = Get.put(FavoriteController());
        // Setup the stream to load favorites data
        await favoriteController.setupFavoritesStream();
      }

      for (var favorite in favoriteController.favorites) {
        // Get payment history for this favorite
        List<Map<String, dynamic>> paymentHistory =
            List<Map<String, dynamic>>.from(favorite['paymentHistory'] ?? []);

        // Add each payment to the graph data
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

          double amount = (payment['amount'] ?? 0.0).toDouble();

          // Add to graph data
          updateDailyExpenses(paymentDate, amount);
          updateMonthlyExpenses(paymentDate, amount);
        }
      }
    } catch (e) {
      log('Error fetching favorites payments: $e');
    }
  }

  List<double> getCurrentMonthExpenses() {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final currentMonthKey = DateFormat('yyyy-MM').format(now);

    log('Getting current month expenses for $currentMonthKey, $daysInMonth days');
    log('Daily expenses keys: ${dailyExpenses.keys.take(5).toList()}');

    List<double> result = List.generate(daysInMonth, (index) {
      final day = index + 1;
      final dateKey = '$currentMonthKey-${day.toString().padLeft(2, '0')}';

      // Get regular expenses (favorites are already included in dailyExpenses)
      double regularExpenses = dailyExpenses[dateKey] ?? 0.0;

      return regularExpenses;
    });

    log('Current month expenses total: ${result.fold(0.0, (sum, expense) => sum + expense)}');
    return result;
  }

  // Update current month total to match home controller calculation exactly
  Future<void> _updateCurrentMonthTotal() async {
    try {
      final total = await _getCurrentMonthTotalFromFirestore();
      currentMonthTotal.value = total;
      log('Updated current month total: $total');
    } catch (e) {
      log('Error updating current month total: $e');
      currentMonthTotal.value = 0.0;
    }
  }

  // Get total expenses for current month (matching home controller calculation exactly)
  double getCurrentMonthTotal() {
    return currentMonthTotal.value;
  }

  // Get current month total using the same method as home controller
  Future<double> _getCurrentMonthTotalFromFirestore() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        return 0.0;
      }

      // Get regular expenses for current month (same as home controller)
      final monthRange = _getCurrentMonthRange();
      final querySnapshot = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: user.uid)
          .where('timestamp', isGreaterThanOrEqualTo: monthRange['start'])
          .where('timestamp', isLessThan: monthRange['end'])
          .get();

      double regularExpensesTotal = 0.0;
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
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
        regularExpensesTotal += amountValue;
      }

      // Get favorites payments for current month (same as home controller)
      double favoritesTotal =
          await _getFavoritesPaymentsForCurrentMonthFromFirestore();

      log('Graph Controller - Regular expenses: $regularExpensesTotal, Favorites: $favoritesTotal, Total: ${regularExpensesTotal + favoritesTotal}');

      return regularExpensesTotal + favoritesTotal;
    } catch (e) {
      log('Error getting current month total from Firestore: $e');
      return 0.0;
    }
  }

  // Helper method to get current month range (same as home controller)
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

  // Get favorites payments for current month from Firestore (same as home controller)
  Future<double> _getFavoritesPaymentsForCurrentMonthFromFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return 0.0;
      }

      // Get all favorites for the user (same as home controller)
      final querySnapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: user.uid)
          .get();

      double totalAmount = 0.0;
      final monthRange = _getCurrentMonthRange();

      // Process each favorite's payment history (same as home controller)
      for (var doc in querySnapshot.docs) {
        final favoriteData = doc.data();
        List<Map<String, dynamic>> paymentHistory =
            List<Map<String, dynamic>>.from(
                favoriteData['paymentHistory'] ?? []);

        // Calculate payments made in current month (same as home controller)
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

          // Check if payment is within current month (same as home controller)
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

      return totalAmount;
    } catch (e) {
      log('Error getting favorites payments for current month from Firestore: $e');
      return 0.0;
    }
  }

  void updateDailyExpenses(DateTime date, double amount) {
    String dateKey = DateFormat('yyyy-MM-dd').format(date);
    if (dailyExpenses.containsKey(dateKey)) {
      dailyExpenses[dateKey] = dailyExpenses[dateKey]! + amount;
    } else {
      dailyExpenses[dateKey] = amount;
    }
  }

  void updateMonthlyExpenses(DateTime date, double amount) {
    String monthKey = DateFormat('yyyy-MM').format(date);
    log('Adding to monthly expenses: $monthKey - Amount: $amount');
    if (monthlyExpenses.containsKey(monthKey)) {
      monthlyExpenses[monthKey] = monthlyExpenses[monthKey]! + amount;
    } else {
      monthlyExpenses[monthKey] = amount;
    }
    log('Monthly expenses now: $monthlyExpenses');
  }

  List<double> getDailyExpensesForLastMonth() {
    DateTime now = DateTime.now();
    DateTime oneMonthAgo = now.subtract(Duration(days: 30));
    List<double> expenses = [];

    for (int i = 0; i < 30; i++) {
      DateTime date = oneMonthAgo.add(Duration(days: i));
      String dateKey = DateFormat('yyyy-MM-dd').format(date);
      expenses.add(dailyExpenses[dateKey] ?? 0);
    }

    return expenses;
  }

  List<double> getMonthlyExpensesForLastYear() {
    final now = DateTime.now();
    List<double> expenses = [];

    log('Getting monthly expenses for last year');
    log('Monthly expenses keys: ${monthlyExpenses.keys.take(5).toList()}');

    for (int i = 11; i >= 0; i--) {
      // Calculate the correct month and year
      int targetMonth = now.month - i;
      int targetYear = now.year;

      // Handle negative months (go to previous year)
      while (targetMonth <= 0) {
        targetMonth += 12;
        targetYear -= 1;
      }

      final monthDate = DateTime(targetYear, targetMonth, 1);
      final monthKey = DateFormat('yyyy-MM').format(monthDate);

      // Get regular expenses (favorites are already included in monthlyExpenses)
      double regularExpenses = monthlyExpenses[monthKey] ?? 0.0;

      expenses.add(regularExpenses);

      log('Month $monthKey (i=$i): Total=${regularExpenses.toStringAsFixed(2)}');
    }

    log('Monthly expenses total: ${expenses.fold(0.0, (sum, expense) => sum + expense)}');
    return expenses;
  }
}
