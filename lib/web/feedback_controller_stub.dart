import 'package:get/get.dart';
import 'package:snapwise/services/snackbar_service.dart';

/// Stub implementation of FeedbackController for non-web platforms
/// This prevents EmailJS import errors on mobile platforms
class FeedbackController extends GetxController {
  @override
  void onInit() {
    super.onInit();
  }

  /// Stub method for sending feedback on non-web platforms
  Future<void> sendFeedback({
    required String name,
    required String email,
    required String purpose,
    required int rating,
    required String comment,
  }) async {
    // Show a message that feedback is not available on mobile
    SnackbarService.showError(
      title: 'Feedback Not Available',
      message:
          'Feedback feature is only available on the web platform. Please visit our website to send feedback.',
    );
  }
}
