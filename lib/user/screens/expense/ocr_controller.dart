import 'dart:developer';
import 'package:get/get.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'gemini_ai.dart';

class OcrController extends GetxController {
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final geminiAi = Get.put(GeminiAi());

  Future<String> extractTextFromImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );

      String extractedText = recognizedText.text;
      if (extractedText.isEmpty) {
        throw Exception('No text extracted from the image');
      }

      return extractedText;
    } catch (e) {
      log('Error in extractTextFromImage: $e');
      throw Exception('Failed to extract text from image: $e');
    }
  }

  Future<Map<String, String>> identifyExpenseDetails(String extractedText) async {
    try {
      Map<String, String> expenseDetails = await geminiAi.extractExpenseDetails(
        extractedText,
      );

      return expenseDetails;
    } catch (e) {
      log('Error in identifyExpenseDetails: $e');
      return {'category': 'Unknown', 'amount': 'Unknown'};
    }
  }

  @override
  void onClose() {
    textRecognizer.close();
    super.onClose();
  }
}