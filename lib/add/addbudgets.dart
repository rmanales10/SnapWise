import 'package:emperiosquartet/sidebar/navbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewBudgetScreen extends StatefulWidget {
  const NewBudgetScreen({super.key});

  @override
  _NewBudgetScreenState createState() => _NewBudgetScreenState();
}

class _NewBudgetScreenState extends State<NewBudgetScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  String _period = 'None';
  String selectedItem = 'Groceries'; // Default selected item
  String selectedMonth = 'January'; // Default selected month
  bool _budgetOverspent = false;
  bool _riskOfOverspending = false;
  List<Map<String, dynamic>> purchasedItems = [];

  final CollectionReference budgets =
      FirebaseFirestore.instance.collection('users');
  final _auth = FirebaseAuth.instance;
  User? get user => _auth.currentUser;

  void addItem() {
    setState(() {
      double amount = double.tryParse(priceController.text) ?? 0.0;
      double budgetAmount =
          double.tryParse(_amountController.text.trim()) ?? 0.0;

      // Calculate the total amount including the new item
      double totalSpent = purchasedItems.fold(
          0.0, (sum, item) => sum + (item['amount'] as double));
      double newTotal = totalSpent + amount;

      if (amount > 0) {
        if (newTotal <= budgetAmount) {
          // Add the item if it does not exceed the budget
          purchasedItems.add({
            'category': selectedItem,
            'amount': amount,
          });
          priceController.clear();
        } else {
          // Notify the user that the item exceeds the budget
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This item exceeds your budget.')),
          );
        }
      } else {
        // Notify the user if the amount is invalid
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid amount.')),
        );
      }
    });
  }

  Future<void> _confirmAndSaveBudget() async {
    String budgetName = _nameController.text.trim();
    String amount = _amountController.text.trim();

    if (budgetName.isEmpty || amount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields.')),
      );
      return;
    }

    bool? confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('CONFIRM BUDGET'),
          content: Text(
            'Are you sure you want to save this budget "$budgetName" with PHP $amount?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child:
                  const Text('Confirm', style: TextStyle(color: Colors.green)),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _saveBudget();
    }
  }

  Future<void> _saveBudget() async {
    try {
      // Save the budget information
      await budgets.doc(user!.uid).collection('budgets').doc('main').set({
        'name': _nameController.text.trim(),
        'period': _period,
        'total': double.tryParse(_amountController.text.trim()) ?? 0.0,
        'month': selectedMonth, // Save the selected month
        'budgetOverspent': _budgetOverspent,
        'riskOfOverspending': _riskOfOverspending,
        'purchasedItems': purchasedItems,
        'spent': 0.0, // Initial spent value for new budget
      });

      // Clear the form after saving
      _nameController.clear();
      _amountController.clear();
      setState(() {
        _period = 'None';
        selectedMonth = 'January'; // Reset to default
        _budgetOverspent = false;
        _riskOfOverspending = false;
        purchasedItems = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save budget: $e')),
      );
    }
  }

// Add this helper method to update Firestore
  Future<void> _updateBudgetField(String field, dynamic value) async {
    try {
      await budgets
          .doc(user!.uid)
          .collection('budgets')
          .doc('main')
          .update({field: value});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$field updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update $field: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const Navbar(),
      appBar: AppBar(
        title: const Text('New Budget'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Budget Name',
                labelStyle: TextStyle(fontWeight: FontWeight.w500),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _period,
              decoration: const InputDecoration(
                labelText: 'Period',
                labelStyle: TextStyle(fontWeight: FontWeight.w500),
                border: OutlineInputBorder(),
              ),
              items: ['None', 'Daily', 'Weekly', 'Monthly']
                  .map((period) => DropdownMenuItem(
                        value: period,
                        child: Text(period),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _period = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Budget Amount',
                labelStyle: TextStyle(fontWeight: FontWeight.w500),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Dropdown for month selection
            DropdownButtonFormField<String>(
              value: selectedMonth,
              decoration: const InputDecoration(
                labelText: 'Month',
                labelStyle: TextStyle(fontWeight: FontWeight.w500),
                border: OutlineInputBorder(),
              ),
              items: [
                'January',
                'February',
                'March',
                'April',
                'May',
                'June',
                'July',
                'August',
                'September',
                'October',
                'November',
                'December'
              ]
                  .map((month) => DropdownMenuItem(
                        value: month,
                        child: Text(month),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedMonth = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedItem,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Groceries', 'Shopping', 'Utilities']
                        .map((item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedItem = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
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
              itemCount: purchasedItems.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(purchasedItems[index]['category']),
                  trailing: Text(
                      'PHP ${purchasedItems[index]['amount'].toStringAsFixed(2)}'),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'NOTIFICATIONS',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SwitchListTile(
              title: const Text('Notify if Budget Overspent'),
              value: _budgetOverspent,
              onChanged: (value) {
                setState(() {
                  _budgetOverspent = value;
                });
              },
            ),

            const SizedBox(height: 23),
            Center(
              child: Container(
                height: 40,
                width: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: _confirmAndSaveBudget,
                  child: const Text('Save'),
                ),
              ),
            ),
          ],
        ),
      ),
      // bottomNavigationBar: BottomAppBar(
      //   height: 70,
      //   color: Color.fromARGB(255, 37, 52, 65), // Set bottom bar color
      //   child: Row(
      //     mainAxisAlignment: MainAxisAlignment.spaceAround,
      //     children: [
      //       IconButton(
      //         icon: Icon(Icons.home,
      //             color: Colors.white), // Set icon color to white
      //         onPressed: () {
      //           Navigator.push(
      //             context,
      //             MaterialPageRoute(builder: (context) => DashboardPage()),
      //           );
      //         },
      //       ),
      //       IconButton(
      //         icon: Icon(Icons.insights,
      //             color: Colors.white), // Set icon color to white
      //         onPressed: () {
      //           Navigator.push(
      //             context,
      //             MaterialPageRoute(builder: (context) => ExpenseInsightPage()),
      //           );
      //         },
      //       ),
      //       IconButton(
      //         icon: Icon(Icons.account_balance_wallet,
      //             color: Colors.white), // Set icon color to white
      //         onPressed: () {
      //           Navigator.push(
      //             context,
      //             MaterialPageRoute(builder: (context) => NewBudgetScreen()),
      //           );
      //         },
      //       ),
      //       FloatingActionButton(
      //         onPressed: () {
      //           Navigator.push(
      //             context,
      //             MaterialPageRoute(builder: (context) => AddReceiptPage()),
      //           );
      //         },
      //         child: Icon(Icons.add),
      //         backgroundColor: Colors.blue,
      //       ),
      //     ],
      //   ),
      // ),
    );
  }
}
