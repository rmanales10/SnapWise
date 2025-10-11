import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SnackbarService {
  // Success Snackbar
  static void showSuccess({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
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
  }) {
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
  }) {
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
  }) {
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
  static void showBudgetSuccess(String message) {
    showSuccess(
      title: '🎉 Budget Success',
      message: message,
    );
  }

  static void showBudgetError(String message) {
    showError(
      title: '❌ Budget Error',
      message: message,
    );
  }

  static void showBudgetWarning(String message) {
    showWarning(
      title: '⚠️ Budget Warning',
      message: message,
    );
  }

  // Income-specific snackbars
  static void showIncomeSuccess(String message) {
    showSuccess(
      title: '💰 Income Success',
      message: message,
    );
  }

  static void showIncomeError(String message) {
    showError(
      title: '❌ Income Error',
      message: message,
    );
  }

  static void showIncomeWarning(String message) {
    showWarning(
      title: '⚠️ Income Warning',
      message: message,
    );
  }

  // Expense-specific snackbars
  static void showExpenseSuccess(String message) {
    showSuccess(
      title: '💸 Expense Success',
      message: message,
    );
  }

  static void showExpenseError(String message) {
    showError(
      title: '❌ Expense Error',
      message: message,
    );
  }

  // Favorites-specific snackbars
  static void showFavoritesSuccess(String message) {
    showSuccess(
      title: '⭐ Favorites Success',
      message: message,
    );
  }

  static void showFavoritesError(String message) {
    showError(
      title: '❌ Favorites Error',
      message: message,
    );
  }

  // Notification-specific snackbars
  static void showNotificationInfo(String message) {
    showInfo(
      title: '🔔 Notification',
      message: message,
    );
  }

  // Validation-specific snackbars
  static void showValidationError(String message) {
    showError(
      title: '📝 Validation Error',
      message: message,
    );
  }

  static void showValidationWarning(String message) {
    showWarning(
      title: '⚠️ Validation Warning',
      message: message,
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
