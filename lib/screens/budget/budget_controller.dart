import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';

class BudgetController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RxBool isSuccess = false.obs;
  final Rx<Map<String, dynamic>> budgetData = Rx<Map<String, dynamic>>({});
  final Rx<Map<String, dynamic>> incomeData = Rx<Map<String, dynamic>>({});
  RxList<Map<String, dynamic>> budgetCategories = <Map<String, dynamic>>[].obs;
  RxDouble remainingBudget = 0.0.obs;
  RxDouble remainingBudgetPercentage = 0.0.obs;
  RxDouble categoryTotalAmount = 0.0.obs;
  RxDouble remainingIncomePercentage = 0.0.obs;

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
      Get.snackbar('Error', 'Failed to add expense: ${e.toString()}');
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
      Get.snackbar('Error', 'Failed to add expense: ${e.toString()}');
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

      Get.snackbar('Success', 'Budget deleted successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete budget: ${e.toString()}');
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
      Get.snackbar('Error', 'Failed to add income: ${e.toString()}');
    }
  }

  Future<void> addOverallBudget(
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

      await _firestore.collection('overallBudget').doc(user.uid).set({
        'userId': user.uid,
        'amount': amount,
        'alertPercentage': alertPercentage,
        'receiveAlert': receiveAlert,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      isSuccess.value = true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to add expense: ${e.toString()}');
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
      Get.snackbar('Error', 'Failed to fetch budget: ${e.toString()}');
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
      Get.snackbar('Error', 'Failed to fetch income: ${e.toString()}');
    }
  }

  Future<void> fetchBudgetCategory() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final querySnapshot =
            await _firestore
                .collection('budget')
                .where('userId', isEqualTo: user.uid)
                .orderBy('timestamp', descending: true)
                .get();

        final fetchBudgetCategories =
            querySnapshot.docs.map((doc) {
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
      // log('Error fetching transactions: $e');
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

      // Fetch all budget categories
      QuerySnapshot budgetSnapshot =
          await _firestore
              .collection('budget')
              .where('userId', isEqualTo: user.uid)
              .get();

      double totalCategoryBudgets = 0.0;
      Map<String, double> categoryBudgets = {};
      for (var doc in budgetSnapshot.docs) {
        String category = doc['category'];
        double amount = doc['amount'];
        categoryBudgets[category] = amount;
        totalCategoryBudgets += amount;
      }

      // Calculate remaining budget (overall budget minus sum of category budgets)
      remainingBudget.value = overallBudget - totalCategoryBudgets;

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

      // print('Total Category Budgets: $totalCategoryBudgets');
      // print('Overall Budget: $overallBudget');
      // print('Remaining Budget: ${remainingBudget.value}');
      // print('Remaining Budget Percentage: ${remainingBudgetPercentage.value}%');
      // print('Category Budgets: $categoryBudgets');
    } catch (e) {
      // log('Error calculating remaining budget: $e');
    }
  }

  Future<double> fetchTotalAmountByCategory(String category) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final querySnapshot =
            await _firestore
                .collection('expenses')
                .where('userId', isEqualTo: user.uid)
                .where('category', isEqualTo: category)
                .get();

        double totalAmount = 0.0;
        for (var doc in querySnapshot.docs) {
          totalAmount += (doc.data()['amount'] as num).toDouble();
        }

        categoryTotalAmount.value = totalAmount;
        return totalAmount;
      }
      return 0.0;
    } catch (e) {
      // log('Error fetching total amount by category: $e');
      categoryTotalAmount.value = 0.0;
      return 0.0;
    }
  }

  Future<void> calculateIncomeOverallBudgetPercentage() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Fetch income
      await fetchIncome();
      double income = incomeData.value['amount'] ?? 0.0;

      // Fetch overall budget
      await fetchOverallBudget();
      double overallBudget = budgetData.value['amount'] ?? 0.0;

      if (overallBudget == 0) {
        remainingIncomePercentage.value = 0.0; // Avoid division by zero
      }

      remainingIncomePercentage.value =
          ((income - overallBudget) / overallBudget) == -1
              ? 0.0
              : ((income - overallBudget) / overallBudget);
    } catch (e) {
      // log('Error calculating income-overall budget percentage: $e');
      remainingIncomePercentage.value = 0.0;
    }
  }
}
