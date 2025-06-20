import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpenseController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RxBool isSuccess = false.obs;
  final RxList<String> categories = <String>[].obs;
  final List<String> builtInCategories = [
    'Food',
    'Transport',
    'Entertainment',
    'Shopping',
    'Bills',
  ];
  final RxMap expenses = {}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
  }

  Future<void> addExpense(
    String category,
    double amount,
    String base64Image,
    String date,
  ) async {
    try {
      if (category.isEmpty || amount <= 0) {
        throw Exception('Invalid category or amount');
      }

      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('expenses').add({
        'userId': user.uid,
        'category': category,
        'amount': amount,
        'base64Image': base64Image,
        'date': date,
        'timestamp': FieldValue.serverTimestamp(),
      });
      isSuccess.value = true;
      Get.snackbar('Success', 'Expense added successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to add expense: ${e.toString()}');
    }
  }

  Future<void> fetchCategories() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final QuerySnapshot querySnapshot =
          await _firestore
              .collection('categories')
              .where('userId', isEqualTo: user.uid)
              .get();

      List<String> userCategories =
          querySnapshot.docs.map((doc) => doc['category'] as String).toList();

      // Combine built-in categories with user-specific categories
      Set<String> allCategories = {...builtInCategories, ...userCategories};

      categories.value = allCategories.toList();
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch categories: ${e.toString()}');
    }
  }

  Future<void> addCategory(String newCategory) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      if (!categories.contains(newCategory)) {
        await _firestore.collection('categories').add({
          'userId': user.uid,
          'category': newCategory,
        });
        await fetchCategories(); // Refresh the categories list
      } else {
        Get.snackbar('Info', 'Category already exists');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to add new category: ${e.toString()}');
    }
  }

  Future<void> fetchExpense(String expenseId) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final docSnapshot =
            await _firestore.collection('expenses').doc(expenseId).get();

        if (docSnapshot.exists) {
          expenses.value = docSnapshot.data() as Map<String, dynamic>;
        } else {
          throw Exception('Expense not found');
        }
      } else {
        throw Exception('User not authenticated');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Delete the expense document from Firestore
      await _firestore.collection('expenses').doc(expenseId).delete();

      // Remove the expense from the local expenses map if it exists
      expenses.remove(expenseId);

      isSuccess.value = true;
      Get.snackbar('Success', 'Expense deleted successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete expense: ${e.toString()}');
    }
  }
}
