import 'dart:developer';
import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiAi extends GetxController {
  RxBool isFetchingData = false.obs;
  final apiKey =
      'AIzaSyCr_7b0ouVns2_KYDndPigjH74I9Sv98x0'; // Replace with your actual API key

  Future<Map<String, String>> extractExpenseDetails(
    String extractedText,
  ) async {
    final model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: apiKey,
    );

    final prompt = '''
    Based on the following text extracted from a receipt or expense document:
    1. Categorize it into one of these categories: Shopping, Travel, Food, Entertainment, Utilities, or Other.
    2. Extract the total amount spent.
    
    Respond in the following format:
    Category: [category name]
    Amount: [total amount]

    If either the category or amount cannot be determined, use an empty string for that field.

    Extracted text:
    $extractedText
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      String responseText = response.text?.trim() ?? '';
      Map<String, String> result = {'category': '', 'amount': ''};

      // Parse the response
      List<String> lines = responseText.split('\n');
      for (String line in lines) {
        if (line.startsWith('Category:')) {
          result['category'] = line.substring('Category:'.length).trim();
        } else if (line.startsWith('Amount:')) {
          result['amount'] = line.substring('Amount:'.length).trim();
        }
      }

      // Log the results
      log('Expense Category: ${result['category']}');
      log('Expense Amount: ${result['amount']}');

      // Post-processing
      if (result['category']!.isEmpty) result['category'] = 'Other';
      if (result['amount']!.isEmpty) result['amount'] = '0';
      isFetchingData.value = true;
      return result;
    } catch (e) {
      log('Error in extractExpenseDetails: $e');
      return {'category': 'Other', 'amount': '0'};
    }
  }

  // Helper method to validate and clean up the amount
  String cleanAmount(String amount) {
    // Remove any non-numeric characters except for decimal point
    String cleanedAmount = amount.replaceAll(RegExp(r'[^\d.]'), '');

    // If there's no valid number, return '0'
    if (cleanedAmount.isEmpty || double.tryParse(cleanedAmount) == null) {
      return '0';
    }

    return cleanedAmount;
  }

  @override
  void onClose() {
    // Any cleanup code can go here
    super.onClose();
  }
}
