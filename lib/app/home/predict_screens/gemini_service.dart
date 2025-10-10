import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:snapwise/services/ai_controller.dart';

class GeminiService {
  final aiController = Get.put(AiController());
  static const String apiKey = 'AIzaSyCr_7b0ouVns2_KYDndPigjH74I9Sv98x0';
  final model = GenerativeModel(
    model: 'gemini-1.5-flash-latest',
    apiKey: apiKey,
  );

  Future<List<double>> generateBudgetAllocation(double totalBudget) async {
    final prompt = '''
    Given a total budget of $totalBudget, allocate it among the following categories:
    1. Food
    2. Transport
    3. Shopping
    4. Utilities
    5. Entertainment
    6. Others

    Provide only the numerical values for each category, separated by commas, in the order listed above.
    Ensure that the sum of all allocations equals the total budget of $totalBudget.
    ''';

    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);

    if (response.text != null) {
      final allocations = response.text!
          .split(',')
          .map((s) => double.tryParse(s.trim()) ?? 0.0)
          .toList();
      if (allocations.length == 6) {
        return allocations;
      }
    }

    // Fallback to a simple equal distribution if AI fails
    return List.filled(6, totalBudget / 6);
  }
}
