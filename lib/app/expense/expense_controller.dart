import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/snackbar_service.dart';

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
    String receiptDate, // Date from receipt/OCR
    String transactionDate, // Date when user input the expense
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
        'receiptDate': receiptDate, // Date from receipt/OCR scan
        'transactionDate': transactionDate, // Date when user input the expense
        'timestamp': FieldValue.serverTimestamp(),
      });
      isSuccess.value = true;
      SnackbarService.showExpenseSuccess('Expense added successfully');
    } catch (e) {
      SnackbarService.showExpenseError(
          'Failed to add expense: ${e.toString()}');
    }
  }

  // Helper function to get start and end of current month
  Map<String, Timestamp> _getCurrentMonthRange() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfNextMonth = (now.month < 12)
        ? DateTime(now.year, now.month + 1, 1)
        : DateTime(now.year + 1, 1, 1);
    return {
      'start': Timestamp.fromDate(startOfMonth),
      'end': Timestamp.fromDate(startOfNextMonth),
    };
  }

  Future<void> fetchCategories() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      final monthRange = _getCurrentMonthRange();
      final QuerySnapshot querySnapshot = await _firestore
          .collection('categories')
          .where('userId', isEqualTo: user.uid)
          .where('timestamp', isGreaterThanOrEqualTo: monthRange['start'])
          .where('timestamp', isLessThan: monthRange['end'])
          .get();

      List<String> userCategories =
          querySnapshot.docs.map((doc) => doc['category'] as String).toList();

      // Combine built-in categories with user-specific categories
      Set<String> allCategories = {...builtInCategories, ...userCategories};

      categories.value = allCategories.toList();
    } catch (e) {
      SnackbarService.showExpenseError(
          'Failed to fetch categories: ${e.toString()}');
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
          'timestamp': FieldValue.serverTimestamp(),
        });
        await fetchCategories(); // Refresh the categories list
      } else {
        SnackbarService.showInfo(
            title: 'Info', message: 'Category already exists');
      }
    } catch (e) {
      SnackbarService.showExpenseError(
          'Failed to add new category: ${e.toString()}');
    }
  }

  Future<void> fetchExpense(String expenseId) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final docSnapshot =
            await _firestore.collection('expenses').doc(expenseId).get();

        if (docSnapshot.exists) {
          final monthRange = _getCurrentMonthRange();
          final data = docSnapshot.data() as Map<String, dynamic>;
          final Timestamp? ts = data['timestamp'] as Timestamp?;
          if (ts != null &&
              ts.compareTo(monthRange['start']!) >= 0 &&
              ts.compareTo(monthRange['end']!) < 0) {
            expenses.value = docSnapshot.data() as Map<String, dynamic>;
          } else {
            throw Exception('Expense not in current month');
          }
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
      SnackbarService.showExpenseSuccess('Expense deleted successfully');
    } catch (e) {
      SnackbarService.showExpenseError(
          'Failed to delete expense: ${e.toString()}');
    }
  }
}
