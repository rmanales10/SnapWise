import 'package:emperiosquartet/add/addbudgets.dart';
import 'package:emperiosquartet/add/add_receipt_page.dart';
import 'package:emperiosquartet/dashboard/expense.dart';
import 'package:emperiosquartet/sidebar/navbar.dart';
import 'package:emperiosquartet/Vewlist/viewlist.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardPage extends StatelessWidget {
  final CollectionReference budgetRef =
      FirebaseFirestore.instance.collection('users');
  final _auth = FirebaseAuth.instance;

  DashboardPage({super.key});

  User? get user => _auth.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const Navbar(),
      appBar: _buildAppBar(context),
      body: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBudgetOverview(),
            const SizedBox(height: 7),
            _buildLastRecordOverview(context),
            const SizedBox(height: 7),
            _buildReceiptsList(),
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

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('DASHBOARD', style: TextStyle(color: Colors.black)),
      backgroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteBudget(context),
        ),
      ],
    );
  }

  Widget _buildBudgetOverview() {
    return FutureBuilder<DocumentSnapshot>(
      future: budgetRef.doc(user!.uid).collection('budgets').doc('main').get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading budget data'));
        }

        // Default placeholders for no data
        if (!snapshot.hasData ||
            snapshot.data == null ||
            snapshot.data!.data() == null) {
          return const Padding(
            padding: EdgeInsets.all(11.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: BudgetCard(
                        label: 'Budget',
                        amount: 'PHP 0',
                        icon: Icons.pie_chart,
                      ),
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: BudgetSpentCard(spentPercentage: 0),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: BudgetCard(
                        label: 'Total Spent',
                        amount: 'PHP 0',
                        icon: Icons.money_off,
                      ),
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: BudgetCard(
                        label: 'Remaining',
                        amount: 'PHP 0',
                        icon: Icons.savings,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        // If data exists, calculate values as usual
        var data = snapshot.data!.data() as Map<String, dynamic>;
        double totalBudget = (data['total'] ?? 0).toDouble();
        double spentAmount = (data['spent'] ?? 0).toDouble();
        double remainingAmount = totalBudget - spentAmount;
        double spentPercentage =
            totalBudget > 0 ? spentAmount / totalBudget : 0;
        spentPercentage = spentPercentage.clamp(0, 1);

        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: BudgetCard(
                      label: 'Budget',
                      amount: 'PHP ${totalBudget.toStringAsFixed(0)}',
                      icon: Icons.pie_chart,
                      onTap: () => _editBudget(context, totalBudget),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: BudgetSpentCard(spentPercentage: spentPercentage),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: BudgetCard(
                      label: 'Total Spent',
                      amount: 'PHP ${spentAmount.toStringAsFixed(0)}',
                      icon: Icons.money_off,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: BudgetCard(
                      label: 'Remaining',
                      amount: 'PHP ${remainingAmount.toStringAsFixed(0)}',
                      icon: Icons.savings,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLastRecordOverview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Last Record Overview',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        const Text('Last 30 days', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AllReceiptsPage()),
            );
          },
          child: const Text('View All List'),
        ),
      ],
    );
  }

  Widget _buildReceiptsList() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('receipts')
            .orderBy('date', descending: true)
            .limit(5)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No receipts available'));
          }

          var records = snapshot.data!.docs;

          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              var record = records[index].data() as Map<String, dynamic>;
              String category = record['category'] ?? 'Unknown';
              double amount = (record['totalAmount'] ?? 0.0).toDouble();
              String formattedAmount = amount.toStringAsFixed(2);
              String storeName = record['storeName'] ?? 'No Store Name';
              String date = record['date'] ?? 'No Date';

              return ListTile(
                leading: const Icon(Icons.receipt, color: Colors.blue),
                title: Text(
                  storeName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Category: $category\nDate: $date'),
                trailing: Text(
                  'PHP $formattedAmount',
                  style: const TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _editBudget(BuildContext context, double currentBudget) async {
    final TextEditingController budgetController =
        TextEditingController(text: currentBudget.toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Edit Budget"),
          content: TextField(
            controller: budgetController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "New Budget Amount"),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Save"),
              onPressed: () async {
                double newBudget = double.parse(budgetController.text);
                await budgetRef
                    .doc(user!.uid)
                    .collection('budgets')
                    .doc('main')
                    .update({'total': newBudget});
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteBudget(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Budget"),
          content: const Text("Are you sure you want to delete the budget?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Delete"),
              onPressed: () async {
                await budgetRef
                    .doc(user!.uid)
                    .collection('budgets')
                    .doc('main')
                    .delete();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

// Reusable UI Widgets
class BudgetCard extends StatelessWidget {
  final String label;
  final String amount;
  final IconData icon;
  final VoidCallback? onTap;

  const BudgetCard({
    super.key,
    required this.label,
    required this.amount,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        width: MediaQuery.of(context).size.width * 0.22,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 5),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.blue, size: 30),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Text(amount, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class BudgetSpentCard extends StatelessWidget {
  final double spentPercentage;

  const BudgetSpentCard({super.key, required this.spentPercentage});

  @override
  Widget build(BuildContext context) {
    // Calculate the remaining percentage
    double remainingPercentage = 1 - spentPercentage;

    // Determine if the remaining percentage is 10% or less
    bool isLowBudget = remainingPercentage <= 0.1;

    return Container(
      padding: const EdgeInsets.all(16),
      width: MediaQuery.of(context).size.width * 0.22,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 5),
        ],
      ),
      child: Column(
        children: [
          CircularProgressIndicator(
            value: spentPercentage,
            backgroundColor: Colors.grey[300],
            color: spentPercentage >= 0.9
                ? Colors.red
                : const Color.fromARGB(255, 66, 57, 229),
          ),
          const SizedBox(height: 8),
          Text(
            '${(spentPercentage * 100).toStringAsFixed(0)}% spent',
            style: const TextStyle(fontSize: 12),
          ),
          if (isLowBudget)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Low budget!',
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
