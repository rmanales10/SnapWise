import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'snackbar_service.dart';
import '../app/budget/budget_controller.dart';

class MonthlyResetService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Track last reset month to prevent multiple resets
  static const String _lastResetKey = 'lastResetMonth';

  /// Check if monthly reset is needed and perform it
  ///
  /// Returns true if a reset was performed, false otherwise.
  ///
  /// This method checks based on the CURRENT MONTH (DateTime.now()):
  /// - Gets current month (e.g., "2025-10" for October)
  /// - Compares with last reset month stored in Firestore
  /// - If different, archives previous month data and resets for current month
  /// - Example: If today is November 1 and last reset was October,
  ///   it archives October data and resets for November
  Future<bool> checkAndPerformMonthlyReset() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        dev.log('User not authenticated, skipping monthly reset check');
        return false;
      }

      // Get CURRENT MONTH based on device/system date
      final now = DateTime.now();
      final currentMonthKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}';

      // Get last reset month from user document
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final lastResetMonth = userDoc.data()?[_lastResetKey] as String?;

      // If no reset has been done OR current month is different from last reset, perform reset
      // This means: Reset happens when you're IN a new month (based on current date)
      if (lastResetMonth == null || lastResetMonth != currentMonthKey) {
        dev.log('=== MONTHLY RESET DETECTED ===');
        dev.log('Last reset: $lastResetMonth');
        dev.log('Current month: $currentMonthKey');
        dev.log('Performing monthly reset...');

        await _performMonthlyReset(currentMonthKey);

        // Update last reset month
        await _firestore.collection('users').doc(user.uid).set({
          _lastResetKey: currentMonthKey,
        }, SetOptions(merge: true));

        dev.log('✅ Monthly reset completed for $currentMonthKey');
        return true; // Reset was performed
      } else {
        dev.log('No monthly reset needed (already reset for $currentMonthKey)');
        return false; // No reset needed
      }
    } catch (e) {
      dev.log('Error checking monthly reset: $e');
      return false;
    }
  }

  /// Perform the actual monthly reset
  ///
  /// IMPORTANT: Favorites are NEVER reset or modified during monthly reset!
  /// - Favorites collection remains untouched
  /// - Favorites are only read to calculate expense totals for archiving
  /// - Payment history in favorites is preserved across all months
  Future<void> _performMonthlyReset(String newMonthKey) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      dev.log('Starting monthly reset process...');
      dev.log('⚠️ NOTE: Favorites are NOT reset - they persist across months');

      // Step 1: Archive income to history
      await _archiveIncomeToHistory();

      // Step 2: Archive expense totals to history (expenses themselves remain)
      // NOTE: This reads favorites payments but does NOT modify favorites collection
      await _archiveExpenseTotalsToHistory();

      // Step 3: Archive budgets to history
      await _archiveBudgetsToHistory();

      // Step 4: Reset income
      await _resetIncome();

      // Step 5: Reset expense totals (expenses records stay for history)
      // NOTE: Favorites are NOT touched - they remain unchanged
      await _resetExpenseTotals();

      // Step 5.5: Reset expense categories for income distribution
      await _resetExpenseCategories();

      // Step 6: Reset budgets and apply predictions if available
      // NOTE: Favorites are NOT affected by budget resets
      await _resetAndApplyBudgets(newMonthKey);

      dev.log('✅ Monthly reset completed successfully');

      // Send monthly reset notification
      await _sendMonthlyResetNotification(newMonthKey);

      SnackbarService.showSuccess(
        title: 'Monthly Reset',
        message: 'Your finances have been reset for the new month!',
      );
    } catch (e) {
      dev.log('Error performing monthly reset: $e');
      SnackbarService.showError(
        title: 'Reset Error',
        message: 'Failed to perform monthly reset: ${e.toString()}',
      );
    }
  }

  /// Archive current income to history
  Future<void> _archiveIncomeToHistory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final incomeDoc =
          await _firestore.collection('income').doc(user.uid).get();
      if (incomeDoc.exists) {
        final incomeData = incomeDoc.data()!;
        final amount = incomeData['amount'] ?? 0.0;

        if (amount > 0) {
          // Get current month key for archiving
          final now = DateTime.now();
          final monthKey =
              '${now.year}-${now.month.toString().padLeft(2, '0')}';

          // Archive to income history
          await _firestore.collection('incomeHistory').add({
            'userId': user.uid,
            'amount': amount,
            'alertPercentage': incomeData['alertPercentage'] ?? 80.0,
            'receiveAlert': incomeData['receiveAlert'] ?? false,
            'month': monthKey,
            'timestamp': FieldValue.serverTimestamp(),
          });

          dev.log(
              'Archived income: ₱${amount.toStringAsFixed(2)} for $monthKey');
        }
      }
    } catch (e) {
      dev.log('Error archiving income: $e');
    }
  }

  /// Archive expense totals to history (expenses themselves remain in expenses collection)
  Future<void> _archiveExpenseTotalsToHistory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Calculate current month total expenses
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfNextMonth = (now.month < 12)
          ? DateTime(now.year, now.month + 1, 1)
          : DateTime(now.year + 1, 1, 1);

      // Get all expenses for current month
      final expensesQuery = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: user.uid)
          .get();

      double regularExpenses = 0.0;
      for (var doc in expensesQuery.docs) {
        final data = doc.data();
        if (data['receiptDate'] != null) {
          try {
            final receiptDate = DateTime.parse(data['receiptDate']);
            if (receiptDate
                    .isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
                receiptDate.isBefore(startOfNextMonth)) {
              final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
              regularExpenses += amount.abs();
            }
          } catch (e) {
            dev.log('Error parsing receiptDate: $e');
          }
        }
      }

      // Get favorites payments for current month (READ ONLY - favorites are NOT modified)
      // This is only used to calculate expense totals for archiving
      // Favorites collection itself remains untouched and persists across months
      final favoritesQuery = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: user.uid)
          .get();

      double favoritesTotal = 0.0;
      for (var doc in favoritesQuery.docs) {
        final favoriteData = doc.data();
        final paymentHistory = List<Map<String, dynamic>>.from(
            favoriteData['paymentHistory'] ?? []);

        for (var payment in paymentHistory) {
          final paymentDateRaw = payment['timestamp'];
          DateTime? paymentDate;

          if (paymentDateRaw is Timestamp) {
            paymentDate = paymentDateRaw.toDate();
          } else if (paymentDateRaw is DateTime) {
            paymentDate = paymentDateRaw;
          }

          if (paymentDate != null &&
              paymentDate
                  .isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
              paymentDate.isBefore(startOfNextMonth)) {
            final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
            favoritesTotal += amount.abs();
          }
        }
      }

      final totalExpenses = regularExpenses + favoritesTotal;
      final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      if (totalExpenses > 0) {
        await _firestore.collection('expenseTotalsHistory').add({
          'userId': user.uid,
          'totalSpent': totalExpenses,
          'regularExpenses': regularExpenses,
          'favoritesExpenses': favoritesTotal,
          'month': monthKey,
          'timestamp': FieldValue.serverTimestamp(),
        });

        dev.log(
            'Archived expense totals: ₱${totalExpenses.toStringAsFixed(2)} for $monthKey');
      }
    } catch (e) {
      dev.log('Error archiving expense totals: $e');
    }
  }

  /// Archive budgets to history
  Future<void> _archiveBudgetsToHistory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      // Archive overall budget
      final overallBudgetDoc =
          await _firestore.collection('overallBudget').doc(user.uid).get();
      if (overallBudgetDoc.exists) {
        final budgetData = overallBudgetDoc.data()!;
        final amount = budgetData['amount'] ?? 0.0;

        if (amount > 0) {
          await _firestore.collection('budgetHistory').add({
            'userId': user.uid,
            'type': 'overall',
            'amount': amount,
            'alertPercentage': budgetData['alertPercentage'] ?? 80.0,
            'receiveAlert': budgetData['receiveAlert'] ?? false,
            'month': monthKey,
            'timestamp': FieldValue.serverTimestamp(),
          });

          dev.log(
              'Archived overall budget: ₱${amount.toStringAsFixed(2)} for $monthKey');
        }
      }

      // Archive category budgets for current month only
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfNextMonth = (now.month < 12)
          ? DateTime(now.year, now.month + 1, 1)
          : DateTime(now.year + 1, 1, 1);

      final budgetQuery = await _firestore
          .collection('budget')
          .where('userId', isEqualTo: user.uid)
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('timestamp', isLessThan: Timestamp.fromDate(startOfNextMonth))
          .get();

      for (var doc in budgetQuery.docs) {
        final budgetData = doc.data();
        final amount = budgetData['amount'] ?? 0.0;
        final category = budgetData['category'] ?? 'Unknown';

        if (amount > 0) {
          await _firestore.collection('budgetHistory').add({
            'userId': user.uid,
            'type': 'category',
            'category': category,
            'amount': amount,
            'alertPercentage': budgetData['alertPercentage'] ?? 80.0,
            'receiveAlert': budgetData['receiveAlert'] ?? false,
            'month': monthKey,
            'timestamp': FieldValue.serverTimestamp(),
          });

          dev.log(
              'Archived category budget: $category - ₱${amount.toStringAsFixed(2)} for $monthKey');
        }
      }
    } catch (e) {
      dev.log('Error archiving budgets: $e');
    }
  }

  /// Reset income for new month
  Future<void> _resetIncome() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Reset income to 0 (user will set new income)
      await _firestore.collection('income').doc(user.uid).set({
        'amount': 0.0,
        'alertPercentage': 80.0,
        'receiveAlert': true,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      dev.log('Income reset for new month');
    } catch (e) {
      dev.log('Error resetting income: $e');
    }
  }

  /// Reset expense totals (expenses themselves remain for history)
  Future<void> _resetExpenseTotals() async {
    try {
      // Expense totals are calculated dynamically, so no explicit reset needed
      // Individual expense records remain in 'expenses' collection for history
      dev.log('Expense totals reset (calculated dynamically)');
    } catch (e) {
      dev.log('Error resetting expense totals: $e');
    }
  }

  /// Reset expense categories shown in Income tab
  /// This clears the categories so they show fresh for the new month
  Future<void> _resetExpenseCategories() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Clear expensesByCategory in BudgetController if it's registered
      // This ensures income tab categories start fresh for the new month
      if (Get.isRegistered<BudgetController>()) {
        try {
          final budgetController = Get.find<BudgetController>();
          budgetController.expensesByCategory.clear();
          dev.log('Cleared expense categories for income distribution');
        } catch (e) {
          dev.log(
              'BudgetController not available or error clearing categories: $e');
        }
      }
    } catch (e) {
      dev.log('Error resetting expense categories: $e');
    }
  }

  /// Reset budgets and apply predictions if available
  Future<void> _resetAndApplyBudgets(String newMonthKey) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Check if prediction exists
      final predictionDoc =
          await _firestore.collection('predictionBudget').doc(user.uid).get();

      if (predictionDoc.exists) {
        // Apply prediction to new month
        final predictionData = predictionDoc.data()!;
        final totalBudget =
            (predictionData['totalBudget'] as num?)?.toDouble() ?? 0.0;
        final categories =
            List<Map<String, dynamic>>.from(predictionData['categories'] ?? []);

        dev.log('Applying saved prediction to new month: $newMonthKey');

        // Set overall budget
        if (totalBudget > 0) {
          await _firestore.collection('overallBudget').doc(user.uid).set({
            'userId': user.uid,
            'amount': totalBudget,
            'alertPercentage': 80.0,
            'receiveAlert': true,
            'timestamp': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          dev.log('Applied overall budget: ₱${totalBudget.toStringAsFixed(2)}');
        }

        // Set category budgets
        for (var category in categories) {
          final categoryName = category['name'] ?? '';
          final categoryAmount =
              (category['amount'] as num?)?.toDouble() ?? 0.0;

          if (categoryName.isNotEmpty && categoryAmount > 0) {
            // Create budget document ID using category name
            final budgetId = '${user.uid}_${categoryName}';

            await _firestore.collection('budget').doc(budgetId).set({
              'budgetId': budgetId,
              'userId': user.uid,
              'category': categoryName,
              'amount': categoryAmount,
              'alertPercentage': 80.0,
              'receiveAlert': true,
              'timestamp': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

            dev.log(
                'Applied category budget: $categoryName - ₱${categoryAmount.toStringAsFixed(2)}');
          }
        }

        dev.log('✅ Prediction applied successfully to new month');
      } else {
        // No prediction, reset budgets to 0
        await _firestore.collection('overallBudget').doc(user.uid).set({
          'amount': 0.0,
          'alertPercentage': 80.0,
          'receiveAlert': true,
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // No need to delete category budgets - they remain as history
        // New budgets will be created when user sets them
        dev.log('No prediction found, budgets will remain for history');
      }
    } catch (e) {
      dev.log('Error resetting budgets: $e');
    }
  }

  /// Send notification when monthly reset is performed
  Future<void> _sendMonthlyResetNotification(String monthKey) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Parse month key to get month name (e.g., "2025-11" -> "November")
      final parts = monthKey.split('-');
      if (parts.length >= 2) {
        final monthNum = int.parse(parts[1]);
        final monthNames = [
          '',
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December'
        ];
        final monthName =
            monthNum > 0 && monthNum <= 12 ? monthNames[monthNum] : monthKey;

        await _firestore.collection('notifications').add({
          'userId': user.uid,
          'title': '📅 Monthly Reset Complete',
          'body':
              'Welcome to $monthName! Your finances have been reset for the new month. Don\'t forget to set your income!',
          'type': 'monthly_reset',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });

        dev.log('Sent monthly reset notification for $monthKey');
      }
    } catch (e) {
      dev.log('Error sending monthly reset notification: $e');
    }
  }
}
