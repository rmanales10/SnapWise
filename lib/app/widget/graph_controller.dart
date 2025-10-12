import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';

class GraphController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RxMap<String, double> dailyExpenses = <String, double>{}.obs;
  final RxMap<String, double> monthlyExpenses = <String, double>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchExpenses();
  }

  // Method to refresh data when needed
  Future<void> refreshData() async {
    await fetchExpenses();
  }

  // Get total expenses for current period
  double getTotalExpenses({bool isDaily = true}) {
    if (isDaily) {
      return getCurrentMonthExpenses()
          .fold(0.0, (double sum, expense) => sum + expense);
    } else {
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

        updateDailyExpenses(date, amount);
        updateMonthlyExpenses(date, amount);
      }

      log('Fetched ${querySnapshot.docs.length} expenses');
      log('Daily expenses: ${dailyExpenses.length} entries');
      log('Monthly expenses: ${monthlyExpenses.length} entries');
    } catch (e) {
      log('Error fetching expenses: $e');
    }
  }

  List<double> getCurrentMonthExpenses() {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final currentMonthKey = DateFormat('yyyy-MM').format(now);

    return List.generate(daysInMonth, (index) {
      final day = index + 1;
      final dateKey = '$currentMonthKey-${day.toString().padLeft(2, '0')}';
      return dailyExpenses[dateKey] ?? 0.0;
    });
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
    if (monthlyExpenses.containsKey(monthKey)) {
      monthlyExpenses[monthKey] = monthlyExpenses[monthKey]! + amount;
    } else {
      monthlyExpenses[monthKey] = amount;
    }
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

    for (int i = 11; i >= 0; i--) {
      // Get the exact month (not approximate days)
      final monthDate = DateTime(now.year, now.month - i, 1);
      // If we go into previous year
      if (now.month - i <= 0) {
        final adjustedMonth = monthDate.month + 12;
        final adjustedYear = monthDate.year - 1;
        final adjustedDate = DateTime(adjustedYear, adjustedMonth, 1);
        final monthKey = DateFormat('yyyy-MM').format(adjustedDate);
        expenses.add(monthlyExpenses[monthKey] ?? 0.0);
      } else {
        final monthKey = DateFormat('yyyy-MM').format(monthDate);
        expenses.add(monthlyExpenses[monthKey] ?? 0.0);
      }
    }

    return expenses;
  }
}
