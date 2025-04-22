import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:snapwise/screens/home/predict_screens/gemini_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PredictController extends GetxController {
  final geminiService = GeminiService();
  final RxDouble totalBudget = 0.0.obs;
  final RxList<Map<String, dynamic>> budgetCategories =
      <Map<String, dynamic>>[].obs;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<Map<String, dynamic>> categoryTemplates = [
    {'name': 'Food', 'icon': Icons.restaurant},
    {'name': 'Transport', 'icon': Icons.directions_car},
    {'name': 'Shopping', 'icon': Icons.shopping_bag},
    {'name': 'Utilities', 'icon': Icons.bolt},
    {'name': 'Entertainment', 'icon': Icons.movie},
    {'name': 'Others', 'icon': Icons.more_horiz},
  ];

  @override
  void onInit() {
    super.onInit();
    fetchExistingBudget();
  }

  Future<void> predictBudget(double amount) async {
    final allocations = await geminiService.generateBudgetAllocation(amount);

    budgetCategories.value = List.generate(
      categoryTemplates.length,
      (index) => {...categoryTemplates[index], 'amount': allocations[index]},
    );

    updateTotalBudget();
    await saveBudgetToFirebase(isPrediction: true);
  }

  Future<void> saveBudgetToFirebase({bool isPrediction = false}) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final collectionName =
            isPrediction ? 'predictionBudget' : 'editedBudget';
        await _firestore.collection(collectionName).doc(user.uid).set({
          'totalBudget': totalBudget.value,
          'categories':
              budgetCategories
                  .map(
                    (category) => {
                      'name': category['name'],
                      'amount': category['amount'],
                    },
                  )
                  .toList(),
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        Get.snackbar('Success', 'Budget saved successfully');
      } else {
        Get.snackbar('Error', 'User not authenticated');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to save budget: $e');
    }
  }

  Future<void> fetchExistingBudget() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        var docSnapshot =
            await _firestore.collection('editedBudget').doc(user.uid).get();

        if (!docSnapshot.exists) {
          docSnapshot =
              await _firestore
                  .collection('predictionBudget')
                  .doc(user.uid)
                  .get();
        }

        if (docSnapshot.exists) {
          final data = docSnapshot.data() as Map<String, dynamic>;
          budgetCategories.value = List<Map<String, dynamic>>.from(
            data['categories'].map((category) {
              final templateCategory = categoryTemplates.firstWhere(
                (temp) => temp['name'] == category['name'],
              );
              return {...templateCategory, 'amount': category['amount']};
            }),
          );
          updateTotalBudget();
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch existing budget: $e');
    }
  }

  Future<void> saveEditedBudget() async {
    await saveBudgetToFirebase(isPrediction: false);
  }

  void updateCategory(String categoryName, double newAmount) {
    final index = budgetCategories.indexWhere(
      (category) => category['name'] == categoryName,
    );
    if (index != -1) {
      budgetCategories[index] = {
        ...budgetCategories[index],
        'amount': newAmount,
      };
      updateTotalBudget();
    }
  }

  void updateTotalBudget() {
    totalBudget.value = budgetCategories.fold(
      0.0,
      (sum, category) => sum + (category['amount'] as double),
    );
  }

  void updateBudgetWithoutRefresh(
    double amount,
    List<Map<String, dynamic>> categories,
  ) {
    totalBudget.value = amount;
    budgetCategories.value = categories;
  }
}
