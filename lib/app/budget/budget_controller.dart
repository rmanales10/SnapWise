import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'budget_notification.dart';
import '../../services/snackbar_service.dart';

class BudgetController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RxBool isSuccess = false.obs;
  final Rx<Map<String, dynamic>> budgetData = Rx<Map<String, dynamic>>({});
  final Rx<Map<String, dynamic>> incomeData = Rx<Map<String, dynamic>>({});
  RxList<Map<String, dynamic>> budgetCategories = <Map<String, dynamic>>[].obs;
  RxDouble remainingBudget = 0.0.obs;
  RxDouble remainingIncome = 0.0.obs;
  RxDouble remainingBudgetPercentage = 0.0.obs;
  RxDouble categoryTotalAmount = 0.0.obs;
  RxDouble remainingIncomePercentage = 0.0.obs;
  RxDouble totalCategoryBudget = 0.0.obs;
  QuerySnapshot? querySnapshot;

  Future<void> addBudget(
    String category,
    double amount,
    double alertPercentage,
    bool receiveAlert,
  ) async {
    String generateRandomBudgetId() {
      final random = Random();
      final number = random.nextInt(100000).toString().padLeft(5, '0');
      return 'budget#$number';
    }

    final budgetId = generateRandomBudgetId();

    try {
      if (category.isEmpty || amount <= 0) {
        throw Exception('Invalid category or amount');
      }

      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('budget').doc(budgetId).set({
        'budgetId': budgetId,
        'userId': user.uid,
        'category': category,
        'amount': amount,
        'alertPercentage': alertPercentage,
        'receiveAlert': receiveAlert,
        'timestamp': FieldValue.serverTimestamp(),
      });
      isSuccess.value = true;
    } catch (e) {
      SnackbarService.showBudgetError('Failed to add budget: ${e.toString()}');
    }
  }

  Future<void> setBudget(
    String category,
    double amount,
    double alertPercentage,
    bool receiveAlert,
    String budgetId,
  ) async {
    try {
      if (category.isEmpty || amount <= 0) {
        throw Exception('Invalid category or amount');
      }

      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('budget').doc(budgetId).set({
        'budgetId': budgetId,
        'userId': user.uid,
        'category': category,
        'amount': amount,
        'alertPercentage': alertPercentage,
        'receiveAlert': receiveAlert,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      isSuccess.value = true;
    } catch (e) {
      SnackbarService.showBudgetError(
          'Failed to update budget: ${e.toString()}');
    }
  }

  Future<void> deleteBudget(String budgetId) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('budget').doc(budgetId).delete();

      // Refresh the budget categories after deletion
      await fetchBudgetCategory();

      // Recalculate the remaining budget
      await calculateRemainingBudget();

      SnackbarService.showBudgetSuccess('Budget deleted successfully');
    } catch (e) {
      SnackbarService.showBudgetError(
          'Failed to delete budget: ${e.toString()}');
    }
  }

  Future<void> addIncome(
    double amount,
    double alertPercentage,
    bool receiveAlert,
  ) async {
    try {
      if (amount <= 0) {
        throw Exception('Invalid category or amount');
      }

      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('income').doc(user.uid).set({
        'userId': user.uid,
        'amount': amount,
        'alertPercentage': alertPercentage,
        'receiveAlert': receiveAlert,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      isSuccess.value = true;
    } catch (e) {
      SnackbarService.showIncomeError('Failed to add income: ${e.toString()}');
    }
  }

  Future<void> addOverallBudget(
    double amount,
    double alertPercentage,
    bool receiveAlert,
  ) async {
    try {
      if (amount <= 0) {
        throw Exception('Invalid amount');
      }

      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if overall budget exceeds income
      await fetchIncome();
      double income = incomeData.value['amount'] ?? 0.0;

      if (income > 0 && amount > income) {
        SnackbarService.showValidationWarning(
          'Overall budget cannot exceed your income of ₱${income.toStringAsFixed(2)}',
        );
        return;
      }

      await _firestore.collection('overallBudget').doc(user.uid).set({
        'userId': user.uid,
        'amount': amount,
        'alertPercentage': alertPercentage,
        'receiveAlert': receiveAlert,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      isSuccess.value = true;

      SnackbarService.showBudgetSuccess('Overall budget set successfully!');
    } catch (e) {
      SnackbarService.showBudgetError(
          'Failed to set overall budget: ${e.toString()}');
    }
  }

  Future<void> fetchOverallBudget() async {
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
      SnackbarService.showBudgetError(
          'Failed to fetch budget: ${e.toString()}');
    }
  }

  Future<void> fetchIncome() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final DocumentSnapshot incomeDoc =
          await _firestore.collection('income').doc(user.uid).get();

      if (incomeDoc.exists) {
        incomeData.value = incomeDoc.data() as Map<String, dynamic>;
      } else {
        incomeData.value = {};
      }
    } catch (e) {
      SnackbarService.showIncomeError(
          'Failed to fetch income: ${e.toString()}');
    }
  }

  Future<void> totalOverallIncome() async {
    try {
      await fetchIncome();
      double income = incomeData.value['amount'] ?? 0.0;
      double totalExpenses = await fetchTotalExpenses();

      if (income <= 0) {
        remainingIncomePercentage.value = 0.0;
      } else {
        remainingIncome.value = income - totalExpenses;
        double percentageSpent = totalExpenses / income;
        // print(remainingIncome.value);

        // Calculate the remaining percentage as a decimal
        remainingIncomePercentage.value = 1.0 - percentageSpent;

        // Ensure the percentage is between 0 and 1
        remainingIncomePercentage.value = remainingIncomePercentage.value.clamp(
          0.0,
          1.0,
        );
      }
    } catch (e) {
      // Handle any errors
      remainingIncomePercentage.value = 0.0;
    }
  }

  Future<void> fetchBudgetCategory() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final monthRange = _getCurrentMonthRange();
        final querySnapshot = await _firestore
            .collection('budget')
            .where('userId', isEqualTo: user.uid)
            .where('timestamp', isGreaterThanOrEqualTo: monthRange['start'])
            .where('timestamp', isLessThan: monthRange['end'])
            .orderBy('timestamp', descending: true)
            .get();

        final fetchBudgetCategories = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'budgetId': data['budgetId'],
            'id': doc.id,
            'alertPercentage': data['alertPercentage'],
            'receiveAlert': data['receiveAlert'],
            "icon": _getCategoryIcon(data['category']),
            "color": _getCategoryColor(data['category']),
            "title": data['category'],
            "amount": "${data['amount'].toStringAsFixed(2)}",
          };
        }).toList();

        budgetCategories.assignAll(fetchBudgetCategories);
      }
    } catch (e) {
      print('Error fetching budget categories: $e');
    }
  }

  // Method to refresh all budget data
  Future<void> refreshBudgetData() async {
    try {
      await Future.wait([
        fetchBudgetCategory(),
        fetchExpensesByCategory(),
        calculateRemainingBudget(),
      ]);
    } catch (e) {
      print('Error refreshing budget data: $e');
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'shopping':
        return Colors.blue;
      case 'food':
        return Colors.green;
      case 'transport':
        return Colors.orange;
      case 'rent':
        return Colors.purple;
      case 'entertainment':
        return Colors.red;
      default:
        return Colors.grey;
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

  Future<void> calculateRemainingBudget() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Fetch overall budget
      await fetchOverallBudget();
      double overallBudget = budgetData.value['amount'] ?? 0.0;

      // Fetch all budget categories for the current month
      final monthRange = _getCurrentMonthRange();
      QuerySnapshot budgetSnapshot = await _firestore
          .collection('budget')
          .where('userId', isEqualTo: user.uid)
          .where('timestamp', isGreaterThanOrEqualTo: monthRange['start'])
          .where('timestamp', isLessThan: monthRange['end'])
          .get();

      totalCategoryBudget.value = 0.0;
      Map<String, double> categoryBudgets = {};
      for (var doc in budgetSnapshot.docs) {
        String category = doc['category'];
        double amount = doc['amount'];
        categoryBudgets[category] = amount;
        totalCategoryBudget.value += amount;
      }

      // Calculate remaining budget (overall budget minus sum of category budgets)
      remainingBudget.value = overallBudget - totalCategoryBudget.value;

      // Calculate the percentage of overall budget remaining
      if (overallBudget > 0) {
        remainingBudgetPercentage.value =
            (remainingBudget.value / overallBudget) == -1
                ? 0
                : remainingBudget.value / overallBudget;
      } else {
        remainingBudgetPercentage.value = 0;
      }

      // Ensure the percentage is not negative
      remainingBudgetPercentage.value = remainingBudgetPercentage.value.clamp(
        0,
        100,
      );

      // Check for overall budget exceeded notification
      await _checkOverallBudgetNotification(overallBudget);

      // print('Total Category Budgets: $totalCategoryBudgets');
      // print('Overall Budget: $overallBudget');
      // print('Remaining Budget: ${remainingBudget.value}');
      // print('Remaining Budget Percentage: ${remainingBudgetPercentage.value}%');
      // print('Category Budgets: $categoryBudgets');
    } catch (e) {
      print('Error calculating remaining budget: $e');
    }
  }

  // Check if overall budget is exceeded and send notification
  Future<void> _checkOverallBudgetNotification(double overallBudget) async {
    try {
      if (overallBudget <= 0) return;

      double totalExpenses = await fetchTotalExpenses();
      double exceededAmount = totalExpenses - overallBudget;

      if (exceededAmount > 0) {
        // Check if user has notifications enabled for overall budget
        bool receiveAlert = budgetData.value['receiveAlert'] ?? false;
        if (receiveAlert) {
          final budgetNotification = Get.find<BudgetNotification>();
          await budgetNotification.sendOverallBudgetExceededNotification(
            totalExpenses: totalExpenses,
            budgetLimit: overallBudget,
            exceededAmount: exceededAmount,
          );
        }
      }
    } catch (e) {
      print('Error checking overall budget notification: $e');
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

  Future<double> fetchTotalAmountByCategory(String category) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final monthRange = _getCurrentMonthRange();
        final querySnapshot = await _firestore
            .collection('expenses')
            .where('userId', isEqualTo: user.uid)
            .where('category', isEqualTo: category)
            .where('timestamp', isGreaterThanOrEqualTo: monthRange['start'])
            .where('timestamp', isLessThan: monthRange['end'])
            .get();

        double totalAmount = 0.0;
        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          final amount = data['amount'];
          if (amount != null && amount is num) {
            totalAmount += amount.toDouble();
          }
        }

        categoryTotalAmount.value = totalAmount;
        return totalAmount;
      }
      return 0.0;
    } catch (e) {
      print('Error fetching total amount by category: $e');
      categoryTotalAmount.value = 0.0;
      return 0.0;
    }
  }

  Future<double> fetchTotalExpenses() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      final monthRange = _getCurrentMonthRange();
      final QuerySnapshot expensesSnapshot = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: user.uid)
          .where('timestamp', isGreaterThanOrEqualTo: monthRange['start'])
          .where('timestamp', isLessThan: monthRange['end'])
          .get();

      double totalExpenses = 0.0;
      for (var doc in expensesSnapshot.docs) {
        totalExpenses +=
            (doc.data() as Map<String, dynamic>)['amount'] as double;
      }

      return totalExpenses;
    } catch (e) {
      // log('Error fetching total expenses: $e');
      return 0.0;
    }
  }

  Future<void> addNotification(String category) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('notification').doc(category).set({
        'userId': user.uid,
        'category': category,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      isSuccess.value = true;
    } catch (e) {
      SnackbarService.showNotificationInfo(
          'Failed to add notification: ${e.toString()}');
    }
  }

  final RxMap<String, double> expensesByCategory = <String, double>{}.obs;

  Future<void> fetchExpensesByCategory() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      final monthRange = _getCurrentMonthRange();
      final QuerySnapshot expensesSnapshot = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: user.uid)
          .where('timestamp', isGreaterThanOrEqualTo: monthRange['start'])
          .where('timestamp', isLessThan: monthRange['end'])
          .get();

      Map<String, double> categoryTotals = {};

      for (var doc in expensesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final category = data['category'] as String;
        final amount = (data['amount'] as num).toDouble();

        if (categoryTotals.containsKey(category)) {
          categoryTotals[category] = categoryTotals[category]! + amount;
        } else {
          categoryTotals[category] = amount;
        }
      }

      // Sort the map by total amount in descending order
      var sortedCategories = categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Update the RxMap
      expensesByCategory.assignAll(Map.fromEntries(sortedCategories));
      // print(expensesByCategory);
    } catch (e) {
      // print('Error fetching expenses by category: $e');
      expensesByCategory.clear();
    }
  }
}
