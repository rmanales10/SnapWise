import 'package:emperiosquartet/add/add_receipt_page.dart';
import 'package:emperiosquartet/add/addbudgets.dart';
import 'package:emperiosquartet/dashboard/dashboard.dart';
import 'package:emperiosquartet/dashboard/expense.dart';
import 'package:flutter/material.dart';

class HomeNavigation extends StatefulWidget {
  const HomeNavigation({super.key});

  @override
  State<HomeNavigation> createState() => _HomeNavigationState();
}

class _HomeNavigationState extends State<HomeNavigation> {
  int _currentIndex = 0;
  List<Widget> body = [
    DashboardPage(),
    ExpenseInsightPage(),
    const NewBudgetScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: body[_currentIndex],
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddReceiptPage(),
            )),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
          backgroundColor: const Color.fromARGB(255, 37, 52, 65),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.blue,
          currentIndex: _currentIndex,
          onTap: (int newValue) {
            setState(() {
              _currentIndex = newValue;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.insights), label: 'Expense'),
            BottomNavigationBarItem(
                icon: Icon(Icons.wallet), label: 'Add Budget'),
          ]),
    );
  }
}
