import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'budget_notification.dart';
import '../../services/snackbar_service.dart';
import '../profile/favorites/favorite_controller.dart';
import 'dart:developer' as dev;

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

        // Debug logging
        dev.log('=== OVERALL BUDGET FETCH DEBUG ===');
        dev.log('Document exists: ${budgetDoc.exists}');
        dev.log('Document data: ${budgetDoc.data()}');
        dev.log('Budget amount: ${budgetData.value['amount']}');
        dev.log('Alert percentage: ${budgetData.value['alertPercentage']}');
        dev.log('Receive alert: ${budgetData.value['receiveAlert']}');
        dev.log('==================================');
      } else {
        budgetData.value = {};
        dev.log('Overall budget document does not exist');
      }
    } catch (e) {
      dev.log('Error fetching overall budget: $e');
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

      dev.log('=== INCOME CALCULATION ===');
      dev.log('Income: $income');
      dev.log('Total Expenses: $totalExpenses');
      dev.log('Remaining Income: ${income - totalExpenses}');

      if (income <= 0) {
        remainingIncomePercentage.value = 0.0;
        dev.log('Income is 0 or negative, setting percentage to 0');
      } else {
        remainingIncome.value = income - totalExpenses;
        double percentageSpent = totalExpenses / income;
        dev.log(
            'Percentage spent: ${(percentageSpent * 100).toStringAsFixed(1)}%');

        // Calculate the remaining percentage as a decimal
        remainingIncomePercentage.value = 1.0 - percentageSpent;

        // Ensure the percentage is between 0 and 1
        remainingIncomePercentage.value = remainingIncomePercentage.value.clamp(
          0.0,
          1.0,
        );

        dev.log(
            'Remaining percentage: ${(remainingIncomePercentage.value * 100).toStringAsFixed(1)}%');
        dev.log('========================');

        // Check for income notification
        await _checkIncomeNotification();
      }
    } catch (e) {
      dev.log('Error in totalOverallIncome: $e');
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
            'isFromFavorites': false, // Mark as regular budget category
          };
        }).toList();

        // Add favorites categories to budget categories
        await _addFavoritesCategoriesToBudget(fetchBudgetCategories);

        budgetCategories.assignAll(fetchBudgetCategories);
      }
    } catch (e) {
      dev.log('Error fetching budget categories: $e');
    }
  }

  // Add favorites categories to budget categories list
  Future<void> _addFavoritesCategoriesToBudget(
      List<Map<String, dynamic>> budgetCategories) async {
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

      // Get unique favorites titles that are not already in budget categories
      Set<String> existingCategories = budgetCategories
          .map((cat) => cat['title'].toString().toLowerCase())
          .toSet();

      for (var favorite in favoriteController.favorites) {
        String title = favorite['title'] ?? '';
        if (title.isNotEmpty &&
            !existingCategories.contains(title.toLowerCase())) {
          // Only add favorites categories that have been set as budget categories
          bool hasBudgetCategory =
              await _checkIfFavoriteHasBudgetCategory(title);

          if (hasBudgetCategory) {
            // Get the budget data for this favorite category
            Map<String, dynamic> budgetData =
                await _getFavoriteBudgetData(title);

            if (budgetData.isNotEmpty) {
              // Add favorites category to budget categories with actual budget data
              budgetCategories.add({
                'budgetId': budgetData['budgetId'],
                'id': budgetData['id'],
                'alertPercentage': budgetData['alertPercentage'],
                'receiveAlert': budgetData['receiveAlert'],
                "icon": _getCategoryIcon(title),
                "color": _getCategoryColor(title),
                "title": title,
                "amount": "${budgetData['amount'].toStringAsFixed(2)}",
                'isFromFavorites': true, // Mark as favorites category
                'favoriteData': favorite, // Store original favorite data
              });
            }
          }
        }
      }
    } catch (e) {
      dev.log('Error adding favorites categories to budget: $e');
    }
  }

  // Check if a favorite has been set as a budget category
  Future<bool> _checkIfFavoriteHasBudgetCategory(String favoriteTitle) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final monthRange = _getCurrentMonthRange();
      final querySnapshot = await _firestore
          .collection('budget')
          .where('userId', isEqualTo: user.uid)
          .where('category', isEqualTo: favoriteTitle)
          .where('timestamp', isGreaterThanOrEqualTo: monthRange['start'])
          .where('timestamp', isLessThan: monthRange['end'])
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      dev.log('Error checking if favorite has budget category: $e');
      return false;
    }
  }

  // Get budget data for a favorite category
  Future<Map<String, dynamic>> _getFavoriteBudgetData(
      String favoriteTitle) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final monthRange = _getCurrentMonthRange();
      final querySnapshot = await _firestore
          .collection('budget')
          .where('userId', isEqualTo: user.uid)
          .where('category', isEqualTo: favoriteTitle)
          .where('timestamp', isGreaterThanOrEqualTo: monthRange['start'])
          .where('timestamp', isLessThan: monthRange['end'])
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        return {
          'budgetId': data['budgetId'],
          'id': doc.id,
          'alertPercentage': data['alertPercentage'],
          'receiveAlert': data['receiveAlert'],
          'amount': data['amount'],
        };
      }

      return {};
    } catch (e) {
      dev.log('Error getting favorite budget data: $e');
      return {};
    }
  }

  // Method to refresh all budget data
  Future<void> refreshBudgetData() async {
    try {
      // Initialize FavoriteController if not already initialized
      try {
        Get.find<FavoriteController>();
      } catch (e) {
        Get.put(FavoriteController());
      }

      await Future.wait([
        fetchBudgetCategory(),
        fetchExpensesByCategory(),
        calculateRemainingBudget(),
      ]);
    } catch (e) {
      dev.log('Error refreshing budget data: $e');
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

      // Check for overall budget exceeded notification using overall budget
      await _checkOverallBudgetNotification(overallBudget);

      // Check for income notification
      await _checkIncomeNotification();

      // print('Total Category Budgets: $totalCategoryBudgets');
      // print('Overall Budget: $overallBudget');
      // print('Remaining Budget: ${remainingBudget.value}');
      // print('Remaining Budget Percentage: ${remainingBudgetPercentage.value}%');
      // print('Category Budgets: $categoryBudgets');
    } catch (e) {
      dev.log('Error calculating remaining budget: $e');
    }
  }

  // Check if overall budget alert percentage threshold is reached and send notification
  Future<void> _checkOverallBudgetNotification(double overallBudget) async {
    try {
      if (overallBudget <= 0) return;

      double totalExpenses = await fetchTotalExpenses();
      double percentageSpent = (totalExpenses / overallBudget) * 100;
      double alertPercentage = budgetData.value['alertPercentage'] ?? 80.0;
      bool receiveAlert = budgetData.value['receiveAlert'] ?? false;

      // Debug logging
      dev.log('=== OVERALL BUDGET NOTIFICATION DEBUG ===');
      dev.log('Total Expenses: $totalExpenses');
      dev.log('Overall Budget: $overallBudget');
      dev.log('Alert Percentage: $alertPercentage%');
      dev.log('Receive Alert: $receiveAlert');
      dev.log('Percentage Spent: $percentageSpent%');
      dev.log('=========================================');

      // Send notification if alert percentage threshold is reached OR budget is exceeded
      if (receiveAlert &&
          (percentageSpent >= alertPercentage ||
              totalExpenses > overallBudget)) {
        double exceededAmount = totalExpenses - overallBudget;

        dev.log('Sending notification - Exceeded Amount: $exceededAmount');

        if (Get.isRegistered<BudgetNotification>()) {
          final budgetNotification = Get.find<BudgetNotification>();
          await budgetNotification.sendOverallBudgetExceededNotification(
            totalExpenses: totalExpenses,
            budgetLimit: overallBudget,
            exceededAmount: exceededAmount,
          );
        }
      } else {
        dev.log('Notification not sent - conditions not met');
      }
    } catch (e) {
      dev.log('Error checking overall budget notification: $e');
    }
  }

  // Check if income alert percentage threshold is reached and send notification
  Future<void> _checkIncomeNotification() async {
    try {
      double income = incomeData.value['amount'] ?? 0.0;
      if (income <= 0) return;

      double totalExpenses = await fetchTotalExpenses();
      double percentageSpent = (totalExpenses / income) * 100;
      double alertPercentage = incomeData.value['alertPercentage'] ?? 80.0;
      bool receiveAlert = incomeData.value['receiveAlert'] ?? false;

      // Send notification if alert percentage threshold is reached
      if (receiveAlert && percentageSpent >= alertPercentage) {
        double remainingIncome = income - totalExpenses;
        if (Get.isRegistered<BudgetNotification>()) {
          final budgetNotification = Get.find<BudgetNotification>();
          await budgetNotification.sendIncomeRemaining(
            spentPercentage: percentageSpent / 100,
            remainingBudget: remainingIncome,
          );
        }
      }
    } catch (e) {
      dev.log('Error checking income notification: $e');
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

          // Check if expense is within current month based on receipt date
          bool isInCurrentMonth = true;
          if (data['receiptDate'] != null) {
            try {
              DateTime receiptDate = DateTime.parse(data['receiptDate']);
              DateTime now = DateTime.now();
              DateTime startOfMonth = DateTime(now.year, now.month, 1);
              DateTime startOfNextMonth = (now.month < 12)
                  ? DateTime(now.year, now.month + 1, 1)
                  : DateTime(now.year + 1, 1, 1);

              isInCurrentMonth = receiptDate.isAfter(
                      startOfMonth.subtract(const Duration(days: 1))) &&
                  receiptDate.isBefore(startOfNextMonth);
            } catch (e) {
              // If receipt date parsing fails, use timestamp
              isInCurrentMonth = true;
            }
          }

          if (amount != null && isInCurrentMonth) {
            double amountValue;
            if (amount is num) {
              amountValue = amount.toDouble();
            } else if (amount is String) {
              // Remove any minus sign and parse as double
              String cleanAmount = amount.replaceAll('-', '');
              amountValue = double.tryParse(cleanAmount) ?? 0.0;
            } else {
              amountValue = 0.0;
            }
            totalAmount += amountValue;
          }
        }

        // Add favorites expenses for this category
        double favoritesAmount =
            await _getFavoritesExpensesForCategory(category);
        totalAmount += favoritesAmount;

        dev.log(
            'Category: $category, Regular expenses: ${totalAmount - favoritesAmount}, Favorites: $favoritesAmount, Total: $totalAmount');

        categoryTotalAmount.value = totalAmount;
        return totalAmount;
      }
      return 0.0;
    } catch (e) {
      dev.log('Error fetching total amount by category: $e');
      categoryTotalAmount.value = 0.0;
      return 0.0;
    }
  }

  // Get favorites expenses for a specific category
  Future<double> _getFavoritesExpensesForCategory(String category) async {
    try {
      // Initialize FavoriteController if not already initialized
      FavoriteController favoriteController;
      try {
        favoriteController = Get.find<FavoriteController>();
      } catch (e) {
        favoriteController = Get.put(FavoriteController());
        // Setup the stream to load favorites data
        await favoriteController.setupFavoritesStream();
      }

      double totalFavoritesExpenses = 0.0;
      final monthRange = _getCurrentMonthRange();

      for (var favorite in favoriteController.favorites) {
        String title = favorite['title'] ?? '';
        if (title.toLowerCase() == category.toLowerCase()) {
          // Get payment history for this favorite
          List<Map<String, dynamic>> paymentHistory =
              List<Map<String, dynamic>>.from(favorite['paymentHistory'] ?? []);

          // Calculate total payments made in current month for this category
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
              totalFavoritesExpenses += amount;
            }
          }
        }
      }

      return totalFavoritesExpenses;
    } catch (e) {
      dev.log('Error getting favorites expenses for category: $e');
      return 0.0;
    }
  }

  Future<double> fetchTotalExpenses() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get all expenses for the user (no date filtering in query)
      final QuerySnapshot expensesSnapshot = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: user.uid)
          .get();

      double totalExpenses = 0.0;
      DateTime now = DateTime.now();
      DateTime startOfMonth = DateTime(now.year, now.month, 1);
      DateTime startOfNextMonth = (now.month < 12)
          ? DateTime(now.year, now.month + 1, 1)
          : DateTime(now.year + 1, 1, 1);

      dev.log('=== FETCHING TOTAL EXPENSES ===');
      dev.log(
          'Current month: ${now.year}-${now.month.toString().padLeft(2, '0')}');
      dev.log(
          'Date range: ${startOfMonth.toString()} to ${startOfNextMonth.toString()}');
      dev.log('Total documents fetched: ${expensesSnapshot.docs.length}');

      for (var doc in expensesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final amount = data['amount'];

        // Check if expense is within current month based on receipt date
        bool isInCurrentMonth = false;
        String dateSource = '';

        if (data['receiptDate'] != null &&
            data['receiptDate'].toString().isNotEmpty) {
          try {
            DateTime receiptDate = DateTime.parse(data['receiptDate']);
            isInCurrentMonth = receiptDate
                    .isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
                receiptDate.isBefore(startOfNextMonth);
            dateSource = 'receiptDate';
          } catch (e) {
            // If receipt date parsing fails, check timestamp as fallback
            DateTime timestamp = (data['timestamp'] as Timestamp).toDate();
            isInCurrentMonth = timestamp
                    .isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
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

        if (amount != null && isInCurrentMonth) {
          double amountValue;
          if (amount is num) {
            amountValue = amount.toDouble();
          } else if (amount is String) {
            // Remove any minus sign and parse as double
            String cleanAmount = amount.replaceAll('-', '');
            amountValue = double.tryParse(cleanAmount) ?? 0.0;
          } else {
            amountValue = 0.0;
          }
          totalExpenses += amountValue;
          dev.log(
              'Expense: ${data['category']} - Amount: $amountValue - Source: $dateSource');
        }
      }

      // Add favorites expenses to total
      double favoritesExpenses = await _getTotalFavoritesExpenses();
      totalExpenses += favoritesExpenses;

      dev.log('Regular expenses: ${totalExpenses - favoritesExpenses}');
      dev.log('Favorites expenses: $favoritesExpenses');
      dev.log('Total expenses for current month: $totalExpenses');
      dev.log('===============================');
      return totalExpenses;
    } catch (e) {
      dev.log('Error fetching total expenses: $e');
      return 0.0;
    }
  }

  // Get total favorites expenses for all categories
  Future<double> _getTotalFavoritesExpenses() async {
    try {
      // Initialize FavoriteController if not already initialized
      FavoriteController favoriteController;
      try {
        favoriteController = Get.find<FavoriteController>();
      } catch (e) {
        favoriteController = Get.put(FavoriteController());
        // Setup the stream to load favorites data
        await favoriteController.setupFavoritesStream();
      }

      double totalFavoritesExpenses = 0.0;
      final monthRange = _getCurrentMonthRange();

      for (var favorite in favoriteController.favorites) {
        // Get payment history for this favorite
        List<Map<String, dynamic>> paymentHistory =
            List<Map<String, dynamic>>.from(favorite['paymentHistory'] ?? []);

        // Calculate total payments made in current month
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
            totalFavoritesExpenses += amount;
          }
        }
      }

      return totalFavoritesExpenses;
    } catch (e) {
      dev.log('Error getting total favorites expenses: $e');
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
      DateTime now = DateTime.now();
      DateTime startOfMonth = DateTime(now.year, now.month, 1);
      DateTime startOfNextMonth = (now.month < 12)
          ? DateTime(now.year, now.month + 1, 1)
          : DateTime(now.year + 1, 1, 1);

      for (var doc in expensesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final category = data['category'] as String;
        final amount = data['amount'];

        // Check if expense is within current month based on receipt date
        bool isInCurrentMonth = true;
        if (data['receiptDate'] != null) {
          try {
            DateTime receiptDate = DateTime.parse(data['receiptDate']);
            isInCurrentMonth = receiptDate
                    .isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
                receiptDate.isBefore(startOfNextMonth);
          } catch (e) {
            // If receipt date parsing fails, use timestamp
            isInCurrentMonth = true;
          }
        }

        if (amount != null && isInCurrentMonth) {
          double amountValue;
          if (amount is num) {
            amountValue = amount.toDouble();
          } else if (amount is String) {
            // Remove any minus sign and parse as double
            String cleanAmount = amount.replaceAll('-', '');
            amountValue = double.tryParse(cleanAmount) ?? 0.0;
          } else {
            amountValue = 0.0;
          }

          if (categoryTotals.containsKey(category)) {
            categoryTotals[category] = categoryTotals[category]! + amountValue;
          } else {
            categoryTotals[category] = amountValue;
          }
        }
      }

      // Add favorites expenses to category totals
      await _addFavoritesExpensesToCategoryTotals(categoryTotals);

      // Sort the map by total amount in descending order
      var sortedCategories = categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Update the RxMap
      expensesByCategory.assignAll(Map.fromEntries(sortedCategories));
      dev.log(
          'Expenses by category for current month (based on receipt date): $expensesByCategory');
    } catch (e) {
      dev.log('Error fetching expenses by category: $e');
      expensesByCategory.clear();
    }
  }

  // Add favorites expenses to category totals for income distribution
  Future<void> _addFavoritesExpensesToCategoryTotals(
      Map<String, double> categoryTotals) async {
    try {
      // Initialize FavoriteController if not already initialized
      FavoriteController favoriteController;
      try {
        favoriteController = Get.find<FavoriteController>();
      } catch (e) {
        favoriteController = Get.put(FavoriteController());
        // Setup the stream to load favorites data
        await favoriteController.setupFavoritesStream();
      }

      final monthRange = _getCurrentMonthRange();

      for (var favorite in favoriteController.favorites) {
        String title = favorite['title'] ?? '';
        if (title.isNotEmpty) {
          double totalPaidThisMonth = 0.0;

          // Get payment history for this favorite
          List<Map<String, dynamic>> paymentHistory =
              List<Map<String, dynamic>>.from(favorite['paymentHistory'] ?? []);

          // Calculate total payments made in current month
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
              totalPaidThisMonth += amount;
            }
          }

          if (categoryTotals.containsKey(title)) {
            categoryTotals[title] = categoryTotals[title]! + totalPaidThisMonth;
          } else {
            categoryTotals[title] = totalPaidThisMonth;
          }
        }
      }
    } catch (e) {
      dev.log('Error adding favorites expenses to category totals: $e');
    }
  }
}
