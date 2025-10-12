import 'package:get/get.dart';
import '../../services/notification_service.dart';

class BudgetNotification extends GetxController {
  final NotificationService _notificationService =
      Get.find<NotificationService>();

  // Overall Budget Notification
  Future<void> sendOverallBudgetExceededNotification({
    required double totalExpenses,
    required double budgetLimit,
    required double exceededAmount,
  }) async {
    await _notificationService.showOverallBudgetExceeded(
      totalExpenses: totalExpenses,
      budgetLimit: budgetLimit,
      exceededAmount: exceededAmount,
    );
  }

  // Category Budget Notification
  Future<void> sendCategoryBudgetExceededNotification({
    required String category,
    required double categoryExpenses,
    required double categoryLimit,
    required double exceededAmount,
  }) async {
    await _notificationService.showCategoryBudgetExceeded(
      category: category,
      categoryExpenses: categoryExpenses,
      categoryLimit: categoryLimit,
      exceededAmount: exceededAmount,
    );
  }

  // Legacy method for backward compatibility
  Future<void> sendBudgetExceededNotification({
    required double spentPercentage,
    required double remainingBudget,
  }) async {
    // This method is deprecated, use the new methods instead
    await _notificationService.showCategoryBudgetExceeded(
      category: 'Budget',
      categoryExpenses: remainingBudget,
      categoryLimit: remainingBudget,
      exceededAmount: 0.0,
    );
  }

  Future<void> sendIncomeRemaining({
    required double spentPercentage,
    required double remainingBudget,
  }) async {
    await _notificationService.showIncomeAlert(
      spentPercentage: spentPercentage,
      remainingIncome: remainingBudget,
    );
  }
}
