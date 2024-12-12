import 'package:emperiosquartet/add/addbudgets.dart';
import 'package:emperiosquartet/dashboard/dashboard.dart';
import 'package:emperiosquartet/dashboard/expense.dart';
import 'package:emperiosquartet/sidebar/navbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddReceiptPage extends StatefulWidget {
  const AddReceiptPage({super.key});

  @override
  _AddReceiptPageState createState() => _AddReceiptPageState();
}

class _AddReceiptPageState extends State<AddReceiptPage> {
  final TextEditingController storeNameController = TextEditingController();
  final TextEditingController totalAmountController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController purchasedItemController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  String selectedCategory = 'Groceries';
  List<Map<String, dynamic>> purchasedItems = [];
  double totalAmount = 0.0;

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get user => _auth.currentUser;

  /// Adds a purchased item to the list
  void addItem() {
    if (purchasedItemController.text.isEmpty ||
        priceController.text.isEmpty ||
        double.tryParse(priceController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please input valid item and price.')),
      );
      return;
    }

    setState(() {
      double price = double.tryParse(priceController.text) ?? 0.0;
      purchasedItems.add({
        'item': purchasedItemController.text,
        'price': price,
      });

      // Clear the input fields
      purchasedItemController.clear();
      priceController.clear();

      // Update the total amount
      totalAmount += price;
      totalAmountController.text = totalAmount.toStringAsFixed(2);
    });
  }

  /// Saves the receipt and updates the user's budget
  Future<void> saveReceipt() async {
    if (storeNameController.text.isEmpty ||
        dateController.text.isEmpty ||
        purchasedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields.')),
      );
      return;
    }

    try {
      // Add the receipt to Firestore
      await firestore
          .collection('users')
          .doc(user!.uid)
          .collection('receipts')
          .add({
        'storeName': storeNameController.text,
        'date': dateController.text,
        'totalAmount': totalAmount,
        'category': selectedCategory,
        'items': purchasedItems,
      });

      DocumentReference budgetDoc = firestore
          .collection('users')
          .doc(user!.uid)
          .collection('budgets')
          .doc('main');
      DocumentSnapshot budgetSnapshot = await budgetDoc.get();

      if (budgetSnapshot.exists) {
        double currentSpent = (budgetSnapshot['spent'] ?? 0.0).toDouble();
        double totalBudget = (budgetSnapshot['total'] ?? 0.0).toDouble();

        double newSpentAmount = currentSpent + totalAmount;
        double remainingAmount = totalBudget - newSpentAmount;

        await budgetDoc.update({
          'spent': newSpentAmount,
          'remaining': remainingAmount,
        });
      }

      await updateBudget();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt saved successfully!')),
      );

      // Reset fields
      storeNameController.clear();
      purchasedItems.clear();
      totalAmount = 0.0;
      dateController.clear();
      totalAmountController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save receipt: $e')),
      );
    }
  }

  /// Updates the user's budget based on the saved receipt
  Future<void> updateBudget() async {
    DocumentReference budgetDoc = firestore
        .collection('users')
        .doc(user!.uid)
        .collection('budgets')
        .doc('main');

    try {
      DocumentSnapshot budgetSnapshot = await budgetDoc.get();

      if (budgetSnapshot.exists) {
        // Fetch current budget details
        Map<String, dynamic> budgetData =
            budgetSnapshot.data() as Map<String, dynamic>;
        List<dynamic> purchasedItems = budgetData['purchasedItems'] ?? [];

        // Update category amounts
        for (var item in purchasedItems) {
          if (item['category'] == selectedCategory) {
            item['amount'] -= totalAmount.toInt();
          }
        }

        // Update Firestore document
        await budgetDoc.update({'purchasedItems': purchasedItems});
      }
    } catch (e) {
      throw Exception('Failed to update budget: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const Navbar(),
      appBar: AppBar(
        title: const Text('Add New Receipt'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: storeNameController,
                decoration: const InputDecoration(
                  labelText: 'Store Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: dateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    dateController.text =
                        '${pickedDate.day}/${pickedDate.month}/${pickedDate.year}';
                  }
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: ['Groceries', 'Shopping', 'Utilities']
                    .map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: purchasedItemController,
                      decoration: const InputDecoration(
                        labelText: 'Purchased Item',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: addItem,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: purchasedItems.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(purchasedItems[index]['item']),
                    trailing: Text(
                        'PHP ${purchasedItems[index]['price'].toStringAsFixed(2)}'),
                  );
                },
              ),
              const SizedBox(height: 20),
              TextField(
                controller: totalAmountController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Total Amount',
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: SizedBox(
                  height: 40,
                  width: 200,
                  child: ElevatedButton(
                    onPressed: saveReceipt,
                    child: const Text('Save'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pop(context),
        child: const Icon(Icons.keyboard_return),
      ),
    );
  }
}
