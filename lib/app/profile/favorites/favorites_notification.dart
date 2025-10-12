import 'package:get/get.dart';
import '../../../services/notification_service.dart';

class FavoritesNotification extends GetxController {
  final NotificationService _notificationService =
      Get.find<NotificationService>();

  // Payment Due Today Notification
  Future<void> sendPaymentDueTodayNotification({
    required String title,
    required double amountToPay,
    required String frequency,
  }) async {
    await _notificationService.showPaymentDueToday(
      title: title,
      amountToPay: amountToPay,
      frequency: frequency,
    );
  }

  // Payment Due Soon Notification (1-3 days before)
  Future<void> sendPaymentDueSoonNotification({
    required String title,
    required double amountToPay,
    required String frequency,
    required int daysUntilDue,
  }) async {
    await _notificationService.showPaymentDueSoon(
      title: title,
      amountToPay: amountToPay,
      frequency: frequency,
      daysUntilDue: daysUntilDue,
    );
  }

  // Missed Payment Notification
  Future<void> sendMissedPaymentNotification({
    required String title,
    required double amountToPay,
    required String frequency,
    required int daysOverdue,
  }) async {
    await _notificationService.showPaymentOverdue(
      title: title,
      amountToPay: amountToPay,
      frequency: frequency,
      daysOverdue: daysOverdue,
    );
  }

  // Payment Completed Notification
  Future<void> sendPaymentCompletedNotification({
    required String title,
    required double totalAmount,
  }) async {
    await _notificationService.showPaymentCompleted(
      title: title,
      totalAmount: totalAmount,
    );
  }

  // Helper method to calculate next payment date based on frequency
  DateTime calculateNextPaymentDate(String frequency, DateTime startDate) {
    switch (frequency.toLowerCase()) {
      case 'daily':
        return startDate.add(Duration(days: 1));
      case 'weekly':
        return startDate.add(Duration(days: 7));
      case 'monthly':
        return DateTime(startDate.year, startDate.month + 1, startDate.day);
      case 'yearly':
        return DateTime(startDate.year + 1, startDate.month, startDate.day);
      default:
        return startDate.add(Duration(days: 1));
    }
  }

  // Helper method to check if payment is due
  Map<String, dynamic> checkPaymentStatus({
    required DateTime startDate,
    required String frequency,
    required DateTime endDate,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Calculate all payment dates from start to end
    List<DateTime> paymentDates = [];
    DateTime currentDate = startDate;

    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      paymentDates.add(currentDate);
      currentDate = calculateNextPaymentDate(frequency, currentDate);
    }

    // Find the next due payment
    DateTime? nextDueDate;
    DateTime? lastDueDate;

    for (DateTime paymentDate in paymentDates) {
      if (paymentDate.isAfter(today)) {
        nextDueDate = paymentDate;
        break;
      }
      lastDueDate = paymentDate;
    }

    // Determine status
    if (nextDueDate != null) {
      final daysUntilDue = nextDueDate.difference(today).inDays;
      if (daysUntilDue == 0) {
        return {'status': 'due_today', 'days': 0};
      } else if (daysUntilDue <= 3) {
        return {'status': 'due_soon', 'days': daysUntilDue};
      } else {
        return {'status': 'upcoming', 'days': daysUntilDue};
      }
    } else if (lastDueDate != null) {
      final daysOverdue = today.difference(lastDueDate).inDays;
      if (daysOverdue > 0) {
        return {'status': 'overdue', 'days': daysOverdue};
      }
    }

    return {'status': 'completed', 'days': 0};
  }
}
