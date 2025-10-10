import 'dart:developer';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:snapwise/services/ai_controller.dart';

class GeminiAi extends GetxController {
  RxBool isFetchingData = false.obs;
  final aiController = Get.put(AiController());

  Future<Map<String, String>> extractExpenseDetails(String imageBase64) async {
    try {
      await aiController.getApiKey();
      final bytes = base64.decode(imageBase64);

      final model = GenerativeModel(
          model: 'gemini-2.5-flash', apiKey: aiController.apiKey.value);

      final prompt = '''
      Look at this receipt or expense document image and:
      1. Categorize it into one of these categories: Shopping, Travel, Food, Entertainment, Utilities, or Other.
      2. Extract the total amount spent.
      3. Extract the date of the transaction.
      
      Respond in the following format:
      Category: [category name]
      Amount: [total amount]
      Date: [date in YYYY-MM-DD format]

      If any field cannot be determined, use an empty string for that field.
      ''';

      final content = [
        Content.multi([TextPart(prompt), DataPart('image/jpeg', bytes)]),
      ];

      final response = await model.generateContent(content);

      String responseText = response.text?.trim() ?? '';
      Map<String, String> result = {'category': '', 'amount': '', 'date': ''};

      // Parse the response
      List<String> lines = responseText.split('\n');
      for (String line in lines) {
        if (line.startsWith('Category:')) {
          result['category'] = line.substring('Category:'.length).trim();
        } else if (line.startsWith('Amount:')) {
          result['amount'] = line.substring('Amount:'.length).trim();
        } else if (line.startsWith('Date:')) {
          result['date'] = line.substring('Date:'.length).trim();
        }
      }

      // Log the results
      log('Expense Category: ${result['category']}');
      log('Expense Amount: ${result['amount']}');
      log('Expense Date: ${result['date']}');

      // Post-processing
      if (result['category']!.isEmpty) result['category'] = 'Other';
      if (result['amount']!.isEmpty) result['amount'] = '0';
      if (result['date']!.isEmpty) {
        // Set current date as default if no date is extracted
        result['date'] =
            DateTime.now().toString().split(' ')[0]; // YYYY-MM-DD format
      }
      isFetchingData.value = true;
      return result;
    } catch (e) {
      log('Error in extractExpenseDetails: $e');
      return {
        'category': 'Other',
        'amount': '0',
        'date': DateTime.now().toString().split(' ')[0],
      };
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
