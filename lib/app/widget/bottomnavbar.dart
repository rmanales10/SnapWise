import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snapwise/app/budget/budget.dart';
import 'package:snapwise/app/budget/budget_controller.dart';
import 'package:snapwise/app/budget/edit_budget.dart';
import 'package:snapwise/app/budget/edit_budget_category.dart';
import 'package:snapwise/app/budget/income/edit_income.dart';
import 'package:snapwise/app/budget/income/input_income.dart';
import 'package:snapwise/app/budget/create_budget.dart';
import 'package:snapwise/app/expense/expense.dart';
import 'package:snapwise/app/expense/expense_controller.dart';
import 'package:snapwise/app/history/records.dart';
import 'package:snapwise/app/home/home_screens/home.dart';
import 'package:snapwise/app/home/home_screens/home_controller.dart';
import 'package:snapwise/app/home/predict_screens/predict.dart';
import 'package:snapwise/app/profile/favorites/add_favorites.dart';
import 'package:snapwise/app/profile/favorites/favorite_history.dart';
import 'package:snapwise/app/profile/favorites/favorite_screen.dart';
import 'package:snapwise/app/profile/settings/notification.dart';
import 'package:snapwise/app/profile/profile.dart';
import 'package:snapwise/app/profile/settings/setting.dart';

class BottomNavBar extends StatefulWidget {
  final int initialIndex;
  const BottomNavBar({super.key, this.initialIndex = 0});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  final HomeController controller = Get.put(HomeController());
  final expenseController = Get.put(ExpenseController());
  final _budgetController = Get.put(BudgetController());
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    // Only fetch budget data here, home data will be fetched by HomeController
    fetchData();
  }

  Future<void> fetchData() async {
    _budgetController.fetchBudgetCategory();
    _budgetController.fetchOverallBudget();
    _budgetController.fetchIncome();
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
    CreateBudget(),
    InputIncome(),
    NotificationSettingsPage(),
    ExpenseManualPage(),
    FavoriteHistory(),
    FavoriteScreen(),
    AddFavoritesScreen()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Center(child: body[_currentIndex]),
      floatingActionButton: SizedBox(
        width: 70,
        height: 70,
        child: FloatingActionButton(
          onPressed: () {
            setState(() {
              _currentIndex = 12;
              expenseController.fetchCategories();
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
            _buildNavItem(0, Icons.home_filled),
            _buildNavItem(1, Icons.receipt_long_sharp),
            SizedBox(width: 48), // Space for FAB
            _buildNavItem(2, Icons.pie_chart_rounded),
            _buildNavItem(3, Icons.person),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    return InkWell(
      onTap: () {
        setState(() => _currentIndex = index);

        // Only refresh data if it's been a while since last refresh
        // Removed automatic refresh to prevent infinite fetching
        // if (index == 0) {
        //   controller.forceRefreshData();
        // }
      },
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: _currentIndex == index
            ? BoxDecoration(
                shape: BoxShape.circle,
                // ignore: deprecated_member_use
                color: Color.fromARGB(255, 3, 30, 53).withOpacity(0.1),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: _currentIndex == index
                  ? Color.fromARGB(255, 3, 30, 53)
                  : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
