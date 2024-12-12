import 'package:emperiosquartet/add/addbudgets.dart';
import 'package:emperiosquartet/add/add_receipt_page.dart';
import 'package:emperiosquartet/chart/month_function.dart';
import 'package:emperiosquartet/chart/month_widget.dart';
import 'package:emperiosquartet/dashboard/dashboard.dart';
import 'package:emperiosquartet/sidebar/navbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class ExpenseInsightPage extends StatelessWidget {
  final CollectionReference budgetRef =
      FirebaseFirestore.instance.collection('users');

  ExpenseInsightPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const Navbar(),
      appBar: AppBar(
        title: const Text(
          'EXPENSE INSIGHT',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ExpenseTrendSection(),
              const SizedBox(height: 20),
              BudgetOverviewSection(budgetRef: budgetRef),
              const SizedBox(height: 20),
              HighestExpensesSection(budgetRef: budgetRef),
            ],
          ),
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

class ExpenseTrendSection extends StatefulWidget {
  const ExpenseTrendSection({super.key});

  @override
  _ExpenseTrendSectionState createState() => _ExpenseTrendSectionState();
}

class _ExpenseTrendSectionState extends State<ExpenseTrendSection> {
  bool showMonthly = true;
  final IncomeController incomeController = Get.put(IncomeController());

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 5)
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 350,
            width: double.infinity, // Ensures it fills the width of the parent
            color: Colors.blue[50], // Placeholder for chart
            child: RevenueVsProfitMarginChart(),
          ),
        ],
      ),
    );
  }
}

class BudgetOverviewSection extends StatelessWidget {
  final _auth = FirebaseAuth.instance;
  User? get user => _auth.currentUser;
  final CollectionReference budgetRef;

  BudgetOverviewSection({super.key, required this.budgetRef});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: budgetRef.doc(user!.uid).collection('budgets').doc('main').get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text("Error: ${snapshot.error}");
        }

        var data = snapshot.data?.data() as Map<String, dynamic>?;

        // If no data exists, return the default layout
        if (data == null) {
          return _buildDefaultLayout();
        }

        // Extract budget data
        double totalBudget = (data['total'] ?? 0).toDouble();
        double spentAmount = (data['spent'] ?? 0).toDouble();
        bool budgetOverspent = (data['budgetOverspent'] ?? false);
        double remainingAmount = totalBudget - spentAmount;
        double spentPercentage =
            totalBudget > 0 ? spentAmount / totalBudget : 0;

        return _buildBudgetLayout(totalBudget, spentAmount, remainingAmount,
            spentPercentage, budgetOverspent);
      },
    );
  }

  // Default layout in case no data is found
  Widget _buildDefaultLayout() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 5),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NOVEMBER 2024', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('PHP 0'),
          LinearProgressIndicator(value: 0, backgroundColor: Colors.grey),
          SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                  child: Text('PHP 0 Spent',
                      style: TextStyle(color: Colors.grey))),
              Flexible(
                  child: Text('PHP 0 Remains',
                      style: TextStyle(color: Colors.green))),
            ],
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }

  // Layout with actual budget data
  Widget _buildBudgetLayout(double totalBudget, double spentAmount,
      double remainingAmount, double spentPercentage, bool budgetOverspent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 5),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('NOVEMBER 2024',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Text('PHP $totalBudget'),
          LinearProgressIndicator(
            value: spentPercentage,
            backgroundColor: Colors.grey[300],
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                  child: Text('PHP $spentAmount Spent',
                      style: const TextStyle(color: Colors.grey))),
              Flexible(
                  child: Text('PHP $remainingAmount Remains',
                      style: const TextStyle(color: Colors.green))),
            ],
          ),
          const SizedBox(height: 10),
          if (budgetOverspent && spentPercentage > 0.89)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Budget Check: Watch Your Spending ${(remainingAmount / totalBudget * 100).toStringAsFixed(1)}% left.',
                      style: const TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class HighestExpensesSection extends StatelessWidget {
  final _auth = FirebaseAuth.instance;
  User? get user => _auth.currentUser;
  final CollectionReference budgetRef;

  HighestExpensesSection({super.key, required this.budgetRef});

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(child: Text("User not logged in."));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: budgetRef.doc(user!.uid).collection('budgets').doc('main').get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return _buildDefaultExpensesUI();
        }

        var data = snapshot.data!.data() as Map<String, dynamic>?;

        if (data == null || !data.containsKey('purchasedItems')) {
          return _buildDefaultExpensesUI();
        }

        var purchasedItems = data['purchasedItems'] as List<dynamic>?;
        if (purchasedItems == null || purchasedItems.isEmpty) {
          return _buildDefaultExpensesUI();
        }

        double groceries = 0, shopping = 0, utilities = 0;

        for (var item in purchasedItems) {
          if (item is Map<String, dynamic>) {
            String category = item['category'] ?? '';
            double categoryAmount = (item['amount'] ?? 0).toDouble();

            if (category == 'Groceries') {
              groceries += categoryAmount;
            } else if (category == 'Shopping') {
              shopping += categoryAmount;
            } else if (category == 'Utilities') {
              utilities += categoryAmount;
            }
          }
        }

        return _buildExpensesUI(groceries, shopping, utilities);
      },
    );
  }

  Widget _buildExpensesUI(double groceries, double shopping, double utilities) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 5),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('NOVEMBER 2024',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const Text('HIGHEST EXPENSES', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),
          ExpenseCategoryTile(
            category: 'Groceries',
            amount: groceries.toInt(),
            onCategoryClick: (deduction) =>
                _deductFromBudget('Groceries', deduction),
          ),
          ExpenseCategoryTile(
            category: 'Shopping',
            amount: shopping.toInt(),
            onCategoryClick: (deduction) =>
                _deductFromBudget('Shopping', deduction),
          ),
          ExpenseCategoryTile(
            category: 'Utilities',
            amount: utilities.toInt(),
            onCategoryClick: (deduction) =>
                _deductFromBudget('Utilities', deduction),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultExpensesUI() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 5),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('NOVEMBER 2024',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const Text('HIGHEST EXPENSES', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),
          ExpenseCategoryTile(
            category: 'Groceries',
            amount: 0,
            onCategoryClick: (deduction) =>
                _deductFromBudget('Groceries', deduction),
          ),
          ExpenseCategoryTile(
            category: 'Shopping',
            amount: 0,
            onCategoryClick: (deduction) =>
                _deductFromBudget('Shopping', deduction),
          ),
          ExpenseCategoryTile(
            category: 'Utilities',
            amount: 0,
            onCategoryClick: (deduction) =>
                _deductFromBudget('Utilities', deduction),
          ),
        ],
      ),
    );
  }

  Future<void> _deductFromBudget(String category, double deduction) async {
    if (user == null) return;

    try {
      var querySnapshot =
          await budgetRef.doc(user!.uid).collection('receipts').get();

      double remainingDeduction = deduction;

      for (var doc in querySnapshot.docs) {
        if (remainingDeduction <= 0) break;

        var data = doc.data() as Map<String, dynamic>?;

        if (data == null ||
            !data.containsKey('categories') ||
            !data.containsKey('totalAmount')) {
          continue;
        }

        String receiptCategory = data['categories'] as String;
        double totalAmount = (data['totalAmount'] ?? 0).toDouble();

        if (receiptCategory == category) {
          if (totalAmount <= remainingDeduction) {
            await doc.reference.delete();
            remainingDeduction -= totalAmount;
          } else {
            await doc.reference.update({
              'totalAmount': totalAmount - remainingDeduction,
            });
            remainingDeduction = 0;
          }
        }
      }

      if (remainingDeduction > 0) {
        print(
            "Deduction could not be fully applied. Remaining: $remainingDeduction");
      } else {
        print('Successfully deducted $deduction from $category.');
      }
    } catch (e) {
      print('Error deducting expense: $e');
    }
  }
}

class ExpenseCategoryTile extends StatelessWidget {
  final String category;
  final int amount;
  final Function(double) onCategoryClick;

  const ExpenseCategoryTile({
    super.key,
    required this.category,
    required this.amount,
    required this.onCategoryClick,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onCategoryClick(amount.toDouble());
      },
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(category,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Text('PHP $amount'),
            ],
          ),
          LinearProgressIndicator(
            value: amount / 10000,
            backgroundColor: Colors.grey[300],
            color: category == 'Groceries'
                ? Colors.green
                : (category == 'Shopping' ? Colors.red : Colors.orange),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
