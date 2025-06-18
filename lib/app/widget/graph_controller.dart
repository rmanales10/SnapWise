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

  Future<void> fetchExpenses() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        log('No user logged in');
        return;
      }

      QuerySnapshot querySnapshot =
          await _firestore
              .collection('expenses')
              .where('userId', isEqualTo: user.uid)
              .get();

      // Clear existing data
      dailyExpenses.clear();
      monthlyExpenses.clear();

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        double amount = (data['amount'] as num).toDouble();
        DateTime date = (data['timestamp'] as Timestamp).toDate();

        updateDailyExpenses(date, amount);
        updateMonthlyExpenses(date, amount);
      }
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
      final month = now.subtract(Duration(days: i * 30));
      final monthKey = DateFormat('yyyy-MM').format(month);
      expenses.add(monthlyExpenses[monthKey] ?? 0.0);
    }

    return expenses;
  }
}
