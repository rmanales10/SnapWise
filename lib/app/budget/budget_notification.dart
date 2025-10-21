import 'package:get/get.dart';
import '../../services/notification_service.dart';
import '../../services/notification_settings_service.dart';
import 'package:flutter/foundation.dart';

class BudgetNotification extends GetxController {
  NotificationService? _notificationService;
  NotificationSettingsService? _settingsService;

  @override
  void onInit() {
    super.onInit();
    // Only initialize notification service if not on web and service is available
    if (!kIsWeb && Get.isRegistered<NotificationService>()) {
      _notificationService = Get.find<NotificationService>();
    }
    // Initialize settings service
    if (Get.isRegistered<NotificationSettingsService>()) {
      _settingsService = Get.find<NotificationSettingsService>();
    }
  }

  // Overall Budget Notification
  Future<void> sendOverallBudgetExceededNotification({
    required double totalExpenses,
    required double budgetLimit,
    required double exceededAmount,
  }) async {
    // Check if budget notifications are enabled
    if (_settingsService != null && !_settingsService!.isBudgetAlertsEnabled) {
      return;
    }

    if (_notificationService != null) {
      await _notificationService!.showOverallBudgetExceeded(
        totalExpenses: totalExpenses,
        budgetLimit: budgetLimit,
        exceededAmount: exceededAmount,
      );
    }
  }

  // Category Budget Notification
  Future<void> sendCategoryBudgetExceededNotification({
    required String category,
    required double categoryExpenses,
    required double categoryLimit,
    required double exceededAmount,
  }) async {
    // Check if budget notifications are enabled
    if (_settingsService != null && !_settingsService!.isBudgetAlertsEnabled) {
      return;
    }

    if (_notificationService != null) {
      await _notificationService!.showCategoryBudgetExceeded(
        category: category,
        categoryExpenses: categoryExpenses,
        categoryLimit: categoryLimit,
        exceededAmount: exceededAmount,
      );
    }
  }

  // Legacy method for backward compatibility
  Future<void> sendBudgetExceededNotification({
    required double spentPercentage,
    required double remainingBudget,
  }) async {
    // Check if budget notifications are enabled
    if (_settingsService != null && !_settingsService!.isBudgetAlertsEnabled) {
      return;
    }

    // This method is deprecated, use the new methods instead
    if (_notificationService != null) {
      await _notificationService!.showCategoryBudgetExceeded(
        category: 'Budget',
        categoryExpenses: remainingBudget,
        categoryLimit: remainingBudget,
        exceededAmount: 0.0,
      );
    }
  }

  Future<void> sendIncomeRemaining({
    required double spentPercentage,
    required double remainingBudget,
  }) async {
    // Check if income notifications are enabled
    if (_settingsService != null && !_settingsService!.isIncomeAlertsEnabled) {
      return;
    }

    if (_notificationService != null) {
      await _notificationService!.showIncomeAlert(
        spentPercentage: spentPercentage,
        remainingIncome: remainingBudget,
      );
    }
  }

  // Expense Added Notification
  Future<void> sendExpenseAddedNotification({
    required String category,
    required double amount,
    required String receiptDate,
  }) async {
    // Check if expense notifications are enabled
    if (_settingsService != null && !_settingsService!.isExpenseAlertsEnabled) {
      return;
    }

    if (_notificationService != null) {
      await _notificationService!.showExpenseAdded(
        category: category,
        amount: amount,
        receiptDate: receiptDate,
      );
    }
  }
}
