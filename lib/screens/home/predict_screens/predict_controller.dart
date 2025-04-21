import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:snapwise/screens/home/predict_screens/gemini_service.dart';

class PredictController extends GetxController {
  final geminiService = GeminiService();
  final RxDouble totalBudget = 15000.0.obs;
  final RxList<Map<String, dynamic>> budgetCategories =
      <Map<String, dynamic>>[].obs;

  final List<Map<String, dynamic>> categoryTemplates = [
    {'name': 'Food', 'icon': Icons.restaurant},
    {'name': 'Transport', 'icon': Icons.directions_car},
    {'name': 'Shopping', 'icon': Icons.shopping_bag},
    {'name': 'Utilities', 'icon': Icons.bolt},
    {'name': 'Entertainment', 'icon': Icons.movie},
    {'name': 'Others', 'icon': Icons.more_horiz},
  ];

  Future<void> predictBudget(double amount) async {
    totalBudget.value = amount;
    final allocations = await geminiService.generateBudgetAllocation(amount);

    budgetCategories.value = List.generate(
      categoryTemplates.length,
      (index) => {...categoryTemplates[index], 'amount': allocations[index]},
    );
  }
}
