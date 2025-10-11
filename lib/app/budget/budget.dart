import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:snapwise/app/budget/budget_controller.dart';
import 'package:snapwise/app/budget/budget_notification.dart';
import 'package:snapwise/app/budget/edit_budget_category.dart';
import 'package:snapwise/app/widget/bottomnavbar.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  bool isbudgetTab = true;
  RxDouble overallBudget = 0.0.obs;
  RxDouble income = 0.0.obs;
  RxDouble remainingBudgetPercentage = 0.0.obs;
  final _budgetNotification = Get.put(BudgetNotification());
  final _budgetController = Get.put(BudgetController());

  // Sorting variables
  String currentSortBy = 'name'; // 'name', 'amount', 'spent', 'remaining'
  bool isAscending = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    await Future.wait([
      _budgetController.refreshBudgetData(),
      _budgetController.fetchOverallBudget(),
      _budgetController.fetchIncome(),
      _budgetController.totalOverallIncome(),
    ]);
  }

  // Sorting methods
  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sort Categories',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 20),
            _buildSortOption('Name', 'name', Icons.sort_by_alpha),
            _buildSortOption('Budget Amount', 'amount', Icons.attach_money),
            _buildSortOption('Amount Spent', 'spent', Icons.trending_down),
            _buildSortOption(
                'Remaining Amount', 'remaining', Icons.account_balance_wallet),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isAscending = !isAscending;
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 3, 30, 53),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isAscending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isAscending ? 'Ascending' : 'Descending',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String title, String sortBy, IconData icon) {
    bool isSelected = currentSortBy == sortBy;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color.fromARGB(255, 3, 30, 53) : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? const Color.fromARGB(255, 3, 30, 53)
              : Colors.black87,
        ),
      ),
      trailing: isSelected
          ? Icon(
              isAscending ? Icons.arrow_upward : Icons.arrow_downward,
              color: const Color.fromARGB(255, 3, 30, 53),
            )
          : null,
      onTap: () {
        setState(() {
          currentSortBy = sortBy;
        });
        Navigator.pop(context);
      },
    );
  }

  List<Map<String, dynamic>> _getSortedCategories() {
    List<Map<String, dynamic>> categories =
        List.from(_budgetController.budgetCategories);

    // For sorting by spent or remaining, we'll sort by budget amount as fallback
    // since we need async data for actual spent amounts
    categories.sort((a, b) {
      int comparison = 0;

      switch (currentSortBy) {
        case 'name':
          comparison = a['title'].toString().compareTo(b['title'].toString());
          break;
        case 'amount':
          double amountA = double.parse(a['amount'].toString());
          double amountB = double.parse(b['amount'].toString());
          comparison = amountA.compareTo(amountB);
          break;
        case 'spent':
        case 'remaining':
          // For now, sort by budget amount as fallback
          // The actual sorting by spent/remaining will be handled in the UI
          double amountA = double.parse(a['amount'].toString());
          double amountB = double.parse(b['amount'].toString());
          comparison = amountA.compareTo(amountB);
          break;
      }

      return isAscending ? comparison : -comparison;
    });

    return categories;
  }

  // Method to sort categories with async data
  Future<List<Map<String, dynamic>>> _getSortedCategoriesWithAsyncData() async {
    List<Map<String, dynamic>> categories =
        List.from(_budgetController.budgetCategories);

    if (currentSortBy == 'spent' || currentSortBy == 'remaining') {
      // Fetch spent amounts for all categories
      Map<String, double> spentAmounts = {};
      for (var category in categories) {
        double spent = await _budgetController.fetchTotalAmountByCategory(
          category['title'].toString(),
        );
        spentAmounts[category['title'].toString()] = spent;
      }

      // Sort based on spent or remaining amounts
      categories.sort((a, b) {
        String titleA = a['title'].toString();
        String titleB = b['title'].toString();
        double spentA = spentAmounts[titleA] ?? 0.0;
        double spentB = spentAmounts[titleB] ?? 0.0;
        double budgetA = double.parse(a['amount'].toString());
        double budgetB = double.parse(b['amount'].toString());

        int comparison = 0;
        if (currentSortBy == 'spent') {
          comparison = spentA.compareTo(spentB);
        } else if (currentSortBy == 'remaining') {
          double remainingA = budgetA - spentA;
          double remainingB = budgetB - spentB;
          comparison = remainingA.compareTo(remainingB);
        }

        return isAscending ? comparison : -comparison;
      });
    }

    return categories;
  }

  // Check for category budget notification
  Future<void> _checkCategoryBudgetNotification(
    String category,
    double amountSpent,
    double categoryLimit,
  ) async {
    try {
      double exceededAmount = amountSpent - categoryLimit;
      if (exceededAmount > 0) {
        await _budgetNotification.sendCategoryBudgetExceededNotification(
          category: category,
          categoryExpenses: amountSpent,
          categoryLimit: categoryLimit,
          exceededAmount: exceededAmount,
        );
      }
    } catch (e) {
      print('Error checking category budget notification: $e');
    }
  }

  final List<Category> categories = [
    Category(
      icon: Icons.shopping_cart,
      name: "Shopping",
      spent: 1200,
      budget: 1000,
      color: Colors.orange,
      exceeded: true,
    ),
    Category(
      icon: Icons.fastfood,
      name: "Food",
      spent: 500,
      budget: 2000,
      color: Colors.redAccent,
    ),
    Category(
      icon: Icons.directions_car,
      name: "Transport",
      spent: 300,
      budget: 800,
      color: Colors.green,
    ),
    Category(
      icon: Icons.home,
      name: "Rent",
      spent: 1200,
      budget: 1200,
      color: Colors.blue,
      exceeded: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth >= 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 40 : 20,
          vertical: isTablet ? 40 : 20,
        ),
        child: Column(
          children: [
            const SizedBox(height: 25),
            Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(width: 1, color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      isbudgetTab ? 'Monthly Budget' : 'Monthly Income',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 0),
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        isbudgetTab
                            ? MaterialPageRoute(
                                builder: (context) =>
                                    BottomNavBar(initialIndex: 5),
                              )
                            : MaterialPageRoute(
                                builder: (context) =>
                                    BottomNavBar(initialIndex: 4),
                              ),
                      ),
                      child: Icon(LucideIcons.edit, size: isTablet ? 30 : 20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            isbudgetTab
                ? _buildCircularIndicator(isTablet, true)
                : _buildCircularIndicator(isTablet, false),
            const SizedBox(height: 20),
            Container(
              width: 350,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Stack(
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    alignment: isbudgetTab
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: Container(
                      width: 175,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 3, 30, 53),
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => isbudgetTab = true),
                          child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              'Budget',
                              style: TextStyle(
                                color: isbudgetTab
                                    ? Colors.white
                                    // ignore: deprecated_member_use
                                    : Colors.black.withOpacity(0.7),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => isbudgetTab = false),
                          child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              'Income',
                              style: TextStyle(
                                color: isbudgetTab
                                    // ignore: deprecated_member_use
                                    ? Colors.black.withOpacity(0.7)
                                    : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  "Categories",
                  style: TextStyle(
                    fontSize: isTablet ? 26 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      isbudgetTab
                          ? MaterialPageRoute(
                              builder: (context) =>
                                  BottomNavBar(initialIndex: 9),
                            )
                          : MaterialPageRoute(
                              builder: (context) =>
                                  BottomNavBar(initialIndex: 10),
                            ),
                    );
                  },
                  child: Image.asset(
                    'assets/wallet (1).png',
                    height: 28,
                    width: 28,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 5),
                GestureDetector(
                  onTap: _showSortOptions,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: currentSortBy != 'name'
                          ? const Color.fromARGB(255, 3, 30, 53)
                              .withOpacity(0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: currentSortBy != 'name'
                          ? Border.all(
                              color: const Color.fromARGB(255, 3, 30, 53)
                                  .withOpacity(0.3),
                              width: 1,
                            )
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sort_rounded,
                          size: 20,
                          color: currentSortBy != 'name'
                              ? const Color.fromARGB(255, 3, 30, 53)
                              : Colors.grey[700],
                        ),
                        if (currentSortBy != 'name') ...[
                          const SizedBox(width: 4),
                          Icon(
                            isAscending
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 16,
                            color: const Color.fromARGB(255, 3, 30, 53),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: fetchData,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Obx(() {
                    return isbudgetTab
                        ? FutureBuilder<List<Map<String, dynamic>>>(
                            future: (currentSortBy == 'spent' ||
                                    currentSortBy == 'remaining')
                                ? _getSortedCategoriesWithAsyncData()
                                : Future.value(_getSortedCategories()),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(20),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              List<Map<String, dynamic>> categories =
                                  snapshot.data ?? _getSortedCategories();

                              return Column(
                                children: categories.map((category) {
                                  return FutureBuilder<double>(
                                    future: _budgetController
                                        .fetchTotalAmountByCategory(
                                      category['title'].toString(),
                                    ),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Container(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            children: [
                                              SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(
                                                    category['color'] ??
                                                        Colors.grey,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 16),
                                              Text(
                                                'Loading ${category['title']}...',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      } else if (snapshot.hasError) {
                                        return Container(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                                color: Colors.red.shade200),
                                          ),
                                          child: Text(
                                            'Error loading ${category['title']}: ${snapshot.error}',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        );
                                      } else {
                                        double amountSpent =
                                            snapshot.data ?? 0.0;
                                        double totalBudget = double.parse(
                                          category['amount'].toString(),
                                        );
                                        double alertPercentage = double.parse(
                                          category['alertPercentage']
                                              .toString(),
                                        );
                                        bool exceeded =
                                            (amountSpent / totalBudget) >=
                                                (alertPercentage / 100);

                                        // Check for category budget notification
                                        if (exceeded &&
                                            (category['receiveAlert'] ??
                                                false)) {
                                          _checkCategoryBudgetNotification(
                                            category['title'],
                                            amountSpent,
                                            totalBudget,
                                          );
                                        }

                                        return _buildCategoryItem1(
                                          isTablet,
                                          id: category['budgetId'],
                                          icon: category['icon'],
                                          category: category['title'],
                                          amountSpent: amountSpent,
                                          totalBudget: totalBudget,
                                          color:
                                              category['color'] ?? Colors.grey,
                                          exceeded: exceeded,
                                          alertPercentage: alertPercentage,
                                          receiveAlert:
                                              category['receiveAlert'] ?? false,
                                        );
                                      }
                                    },
                                  );
                                }).toList(),
                              );
                            },
                          )
                        : Column(
                            children: _budgetController
                                .expensesByCategory.entries
                                .map((
                              entry,
                            ) {
                              String category = entry.key;
                              double amountSpent = entry.value;
                              return _buildCategoryItem2(
                                isTablet,
                                icon: _getCategoryIcon(category),
                                category: category,
                                amountSpent: amountSpent,
                                totalBudget: _budgetController
                                        .incomeData.value['amount'] ??
                                    0.0,
                                color: _getCategoryColor(category),
                                exceeded: false,
                                percentageOfIncome: _budgetController
                                                .incomeData.value['amount'] !=
                                            null &&
                                        _budgetController
                                                .incomeData.value['amount'] !=
                                            0
                                    ? ((amountSpent /
                                            _budgetController
                                                .incomeData.value['amount'] *
                                            100)
                                        .clamp(0.0, 100.0)
                                        .toStringAsFixed(1))
                                    : '0.0',
                              );
                            }).toList(),
                          );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatLargeNumber(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 100000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    } else {
      return value.toStringAsFixed(2);
    }
  }

  Widget _buildCircularIndicator(bool isTablet, bool isBudget) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CircularPercentIndicator(
          radius: isTablet ? 100.0 : 80.0,
          lineWidth: 20.0,
          percent: isBudget
              ? _budgetController.remainingBudgetPercentage.value
              : _budgetController.remainingIncomePercentage.value,
          center: Obx(() {
            String amount = isBudget
                ? formatLargeNumber(_budgetController.remainingBudget.value)
                : formatLargeNumber(
                    _budgetController.remainingIncome.value,
                  );
            return Text(
              amount == 'null' ? '0' : amount,
              style: TextStyle(
                fontSize: isTablet ? 32 : 24,
                fontWeight: FontWeight.bold,
              ),
            );
          }),
          progressColor: Colors.orange,
          backgroundColor: const Color.fromARGB(255, 3, 30, 53),
          circularStrokeCap: CircularStrokeCap.round,
        ),
        Obx(() {
          double alertPercentage = isBudget
              ? _budgetController.budgetData.value['alertPercentage'] ?? 0
              : _budgetController.incomeData.value['alertPercentage'] ?? 0;
          double percentage = isBudget
              ? _budgetController.remainingBudgetPercentage.value
              : _budgetController.remainingIncomePercentage.value;
          double remainingPercentage = (1 - percentage) * 100;
          if (remainingPercentage >= alertPercentage) {
            return Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: Colors.red.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning,
                  color: Colors.white,
                  size: isTablet ? 24 : 20,
                ),
              ),
            );
          } else {
            return SizedBox.shrink();
          }
        }),
      ],
    );
  }

  Widget _buildCategoryItem1(
    bool isTablet, {
    required String id,
    required IconData icon,
    required String category,
    required double amountSpent,
    required double totalBudget,
    required Color color,
    bool exceeded = false,
    required double alertPercentage,
    required bool receiveAlert,
  }) {
    final percent = (amountSpent / totalBudget).clamp(0.0, 1.0);
    final remaining = totalBudget - amountSpent;

    if (receiveAlert) {
      if (alertPercentage >= percent) {
        _budgetNotification.sendBudgetExceededNotification(
          spentPercentage: percent,
          remainingBudget: remaining,
        );
        _budgetController.addNotification(category);
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  border: Border.all(width: 1, color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      category,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (exceeded)
                const Icon(Icons.error, color: Colors.red, size: 20),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Remaining ₱${remaining < 0 ? 0 : remaining.toStringAsFixed(0)}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          LinearProgressIndicator(
            value: percent,
            color: color,
            backgroundColor: Colors.grey.shade300,
            minHeight: 8,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Column(
                children: [
                  Text(
                    "₱ $amountSpent of ₱ $totalBudget",
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (exceeded)
                    Text(
                      "You've exceed the limit!",
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditBudgetCategoryPage(
                      budgetId: id,
                      alertPercentage: alertPercentage,
                      amount: totalBudget,
                      category: category,
                      receiveAlert: receiveAlert,
                    ),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7F3DFF),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'Edit',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem2(
    bool isTablet, {
    required IconData icon,
    required String category,
    required double amountSpent,
    required double totalBudget,
    required Color color,
    bool exceeded = false,
    required String percentageOfIncome,
  }) {
    final percent = (amountSpent / totalBudget).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  border: Border.all(width: 1, color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      category,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                "$percentageOfIncome% of income",
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: percent,
            color: color,
            backgroundColor: Colors.grey.shade300,
            minHeight: 8,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    // Implement this method to return the appropriate icon for each category
    // For example:
    switch (category.toLowerCase()) {
      case 'shopping':
        return LucideIcons.shoppingBag;
      case 'food':
        return LucideIcons.utensils;
      case 'transport':
        return LucideIcons.train;
      case 'rent':
        return LucideIcons.home;
      case 'entertainment':
        return Icons.movie;
      default:
        return LucideIcons.dollarSign;
    }
  }

  Color _getCategoryColor(String category) {
    // Implement this method to return the appropriate color for each category
    // For example:
    switch (category.toLowerCase()) {
      case 'shopping':
        return Colors.blue;
      case 'food':
        return Colors.green;
      case 'transport':
        return Colors.orange;
      case 'rent':
        return Colors.purple;
      case 'entertainment':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class Category {
  final IconData icon;
  final String name;
  final double spent;
  final double budget;
  final Color color;
  final bool exceeded;

  Category({
    required this.icon,
    required this.name,
    required this.spent,
    required this.budget,
    required this.color,
    this.exceeded = false,
  });
}
