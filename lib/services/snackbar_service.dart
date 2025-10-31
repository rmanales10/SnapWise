import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SnackbarService {
  // Helper to get the current context
  static BuildContext? _getContext(BuildContext? context) {
    return context ?? Get.context;
  }

  // Success Snackbar
  static void showSuccess({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
    BuildContext? context,
  }) {
    final ctx = _getContext(context);

    if (ctx == null) {
      print('⚠️ Cannot show snackbar: No context available');
      return;
    }

    // Use native SnackBar if Get.context is null (after logout scenario)
    if (Get.context == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          duration: duration,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    // Use GetX snackbar when Get.context is available
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFF10B981), // Green
      colorText: Colors.white,
      duration: duration,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(
        Icons.check_circle_outline,
        color: Colors.white,
        size: 24,
      ),
      shouldIconPulse: false,
      barBlur: 0,
      overlayBlur: 0,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      titleText: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      messageText: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }

  // Error Snackbar
  static void showError({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 4),
    BuildContext? context,
  }) {
    final ctx = _getContext(context);

    if (ctx == null) {
      print('⚠️ Cannot show snackbar: No context available');
      return;
    }

    // Use native SnackBar if Get.context is null (after logout scenario)
    if (Get.context == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          duration: duration,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    // Use GetX snackbar when Get.context is available
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFFEF4444), // Red
      colorText: Colors.white,
      duration: duration,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(
        Icons.error_outline,
        color: Colors.white,
        size: 24,
      ),
      shouldIconPulse: false,
      barBlur: 0,
      overlayBlur: 0,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      titleText: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      messageText: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }

  // Warning Snackbar
  static void showWarning({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 4),
    BuildContext? context,
  }) {
    final ctx = _getContext(context);

    if (ctx == null) {
      print('⚠️ Cannot show snackbar: No context available');
      return;
    }

    // Use native SnackBar if Get.context is null (after logout scenario)
    if (Get.context == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.warning_outlined,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFF59E0B),
          duration: duration,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    // Use GetX snackbar when Get.context is available
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFFF59E0B), // Amber
      colorText: Colors.white,
      duration: duration,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(
        Icons.warning_outlined,
        color: Colors.white,
        size: 24,
      ),
      shouldIconPulse: false,
      barBlur: 0,
      overlayBlur: 0,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      titleText: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      messageText: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }

  // Info Snackbar
  static void showInfo({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
    BuildContext? context,
  }) {
    final ctx = _getContext(context);

    if (ctx == null) {
      print('⚠️ Cannot show snackbar: No context available');
      return;
    }

    // Use native SnackBar if Get.context is null (after logout scenario)
    if (Get.context == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color.fromARGB(255, 3, 30, 53),
          duration: duration,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    // Use GetX snackbar when Get.context is available
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor:
          const Color.fromARGB(255, 3, 30, 53), // App's primary color
      colorText: Colors.white,
      duration: duration,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(
        Icons.info_outline,
        color: Colors.white,
        size: 24,
      ),
      shouldIconPulse: false,
      barBlur: 0,
      overlayBlur: 0,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      titleText: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      messageText: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }

  // Budget-specific snackbars
  static void showBudgetSuccess(String message, {BuildContext? context}) {
    showSuccess(
      title: '🎉 Budget Success',
      message: message,
      context: context,
    );
  }

  static void showBudgetError(String message, {BuildContext? context}) {
    showError(
      title: '❌ Budget Error',
      message: message,
      context: context,
    );
  }

  static void showBudgetWarning(String message, {BuildContext? context}) {
    showWarning(
      title: '⚠️ Budget Warning',
      message: message,
      context: context,
    );
  }

  // Income-specific snackbars
  static void showIncomeSuccess(String message, {BuildContext? context}) {
    showSuccess(
      title: '💰 Income Success',
      message: message,
      context: context,
    );
  }

  static void showIncomeError(String message, {BuildContext? context}) {
    showError(
      title: '❌ Income Error',
      message: message,
      context: context,
    );
  }

  static void showIncomeWarning(String message, {BuildContext? context}) {
    showWarning(
      title: '⚠️ Income Warning',
      message: message,
      context: context,
    );
  }

  // Expense-specific snackbars
  static void showExpenseSuccess(String message, {BuildContext? context}) {
    showSuccess(
      title: '💸 Expense Success',
      message: message,
      context: context,
    );
  }

  static void showExpenseError(String message, {BuildContext? context}) {
    showError(
      title: '❌ Expense Error',
      message: message,
      context: context,
    );
  }

  // Favorites-specific snackbars
  static void showFavoritesSuccess(String message, {BuildContext? context}) {
    showSuccess(
      title: '⭐ Favorites Success',
      message: message,
      context: context,
    );
  }

  static void showFavoritesError(String message, {BuildContext? context}) {
    showError(
      title: '❌ Favorites Error',
      message: message,
      context: context,
    );
  }

  // Notification-specific snackbars
  static void showNotificationInfo(String message, {BuildContext? context}) {
    showInfo(
      title: '🔔 Notification',
      message: message,
      context: context,
    );
  }

  // Validation-specific snackbars
  static void showValidationError(String message, {BuildContext? context}) {
    showError(
      title: '📝 Validation Error',
      message: message,
      context: context,
    );
  }

  static void showValidationWarning(String message, {BuildContext? context}) {
    showWarning(
      title: '⚠️ Validation Warning',
      message: message,
      context: context,
    );
  }

  // Custom snackbar with specific styling
  static void showCustom({
    required String title,
    required String message,
    required Color backgroundColor,
    required IconData icon,
    Duration duration = const Duration(seconds: 3),
    SnackPosition position = SnackPosition.TOP,
  }) {
    if (Get.context == null) {
      print('⚠️ Cannot show snackbar: Get.context is null');
      return;
    }

    Get.snackbar(
      title,
      message,
      snackPosition: position,
      backgroundColor: backgroundColor,
      colorText: Colors.white,
      duration: duration,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: Icon(
        icon,
        color: Colors.white,
        size: 24,
      ),
      shouldIconPulse: false,
      barBlur: 0,
      overlayBlur: 0,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      titleText: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      messageText: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }
}
