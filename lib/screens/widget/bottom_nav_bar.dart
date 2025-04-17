import 'package:flutter/material.dart';
import 'package:snapwise/screens/budget/budget.dart';
import 'package:snapwise/screens/budget/edit_budget.dart';
import 'package:snapwise/screens/budget/edit_budget_category.dart';
import 'package:snapwise/screens/budget/income/edit_income.dart';
import 'package:snapwise/screens/budget/income/input_income.dart';
import 'package:snapwise/screens/budget/input_budget.dart';
import 'package:snapwise/screens/expense/expense.dart';
import 'package:snapwise/screens/history/records.dart';
import 'package:snapwise/screens/home/home.dart';
import 'package:snapwise/screens/home/predict.dart';
import 'package:snapwise/screens/profile/profile.dart';
import 'package:snapwise/screens/profile/setting.dart';

class BottomNavBar extends StatefulWidget {
  final int initialIndex;
  const BottomNavBar({super.key, this.initialIndex = 0});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  List<Widget> body = [
    HomePage(),
    TransactionHistoryPage(),
    BudgetPage(),
    ProfilePage(),
    IncomeEditPage(),
    EditBudgetPage(),
    EditBudgetCategoryPage(),
    SettingsPage(),
    PredictBudgetPage(),
    CreateBudgetPage(),
    IncomeInputPage(),
    ExpenseManualPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: body[_currentIndex]),
      floatingActionButton: SizedBox(
        width: 70,
        height: 70,
        child: FloatingActionButton(
          onPressed: () {
            setState(() {
              _currentIndex =
                  body.length - 1; // Use the last index of the body list
            });
          },
          backgroundColor: Color.fromARGB(255, 3, 30, 53),

          shape: CircleBorder(),
          child: Icon(Icons.add, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 10,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_filled, 'Home'),
            _buildNavItem(1, Icons.receipt_long_sharp, 'Records'),
            SizedBox(width: 48), // Space for FAB
            _buildNavItem(2, Icons.pie_chart_rounded, 'Budget'),
            _buildNavItem(3, Icons.person, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color:
                _currentIndex == index
                    ? Color.fromARGB(255, 3, 30, 53)
                    : Colors.grey,
          ),
          Text(
            label,
            style: TextStyle(
              color:
                  _currentIndex == index
                      ? Color.fromARGB(255, 3, 30, 53)
                      : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
