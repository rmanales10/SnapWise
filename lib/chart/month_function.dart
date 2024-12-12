import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class IncomeController extends GetxController {
  var monthlyExpenses =
      List<double>.filled(12, 0.0).obs; // List to store monthly expenses
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? get user => _auth.currentUser;

  @override
  void onInit() {
    super.onInit();
    fetchMonthlyExpenses(); // Call the method to fetch monthly expenses on init
  }

  // This method will be used to update the selected time range
  void changeTimeRange(String value) {
    fetchMonthlyExpenses(); // Re-fetch expenses whenever time range changes
  }

  // Fetch monthly expenses from Firestore and aggregate by month
  Future<void> fetchMonthlyExpenses() async {
    try {
      if (user == null) {
        log("User not authenticated.");
        return;
      }

      // Reference to the user's receipts collection in Firestore
      CollectionReference receiptsCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('receipts');

      // Get all receipt documents
      QuerySnapshot querySnapshot = await receiptsCollection.get();
      List<double> expensesPerMonth =
          List.filled(12, 0.0); // Initialize array for monthly expenses

      // Iterate over each receipt document
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Ensure we have a valid 'date' field and parse it to DateTime
        if (data.containsKey('date') && data['date'] is String) {
          // Parse the date (e.g., "28/11/2024") into a DateTime object
          DateTime receiptDate = _parseDate(data['date']);
          int month = receiptDate.month - 1; // Zero-indexed months

          // Ensure 'totalAmount' exists and is valid
          double receiptTotal = (data['totalAmount'] ?? 0.0).toDouble();

          // Add the receipt's total to the appropriate month
          expensesPerMonth[month] += receiptTotal;
        }
      }

      // Update the observable list of monthly expenses
      monthlyExpenses.value = expensesPerMonth;
    } catch (e) {
      log("Failed to fetch data: $e"); // Log the error for debugging
    }
  }

// Helper method to parse the date string in the format "28/11/2024"
  DateTime _parseDate(String dateString) {
    List<String> dateParts = dateString.split('/');
    int day = int.parse(dateParts[0]);
    int month = int.parse(dateParts[1]);
    int year = int.parse(dateParts[2]);
    return DateTime(year, month, day); // Return DateTime object
  }

  // This method can be used to add new receipts into Firestore.
  Future<void> addReceipt(double totalAmount, DateTime date) async {
    try {
      if (user == null) {
        log("User not authenticated.");
        return;
      }

      // Reference to the user's receipts collection in Firestore
      CollectionReference receiptsCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('receipts');

      // Adding a new receipt document to Firestore
      await receiptsCollection.add({
        'totalAmount': totalAmount,
        'date':
            date.toIso8601String(), // Store the date in ISO8601 string format
      });

      log("Receipt added successfully");

      // Re-fetch the monthly expenses after adding a new receipt
      fetchMonthlyExpenses();
    } catch (e) {
      log("Failed to add receipt: $e"); // Log the error if something fails
    }
  }
}
