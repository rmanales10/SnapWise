import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:snapwise/screens/widget/bottom_nav_bar.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  bool isbudgetTab = true;

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
                      onTap:
                          () => Navigator.push(
                            context,
                            isbudgetTab
                                ? MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          BottomNavBar(initialIndex: 5),
                                )
                                : MaterialPageRoute(
                                  builder:
                                      (context) =>
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
                ? CircularPercentIndicator(
                  radius: isTablet ? 100.0 : 80.0,
                  lineWidth: 20.0,
                  percent: 0.75,
                  center: Text(
                    "5000",
                    style: TextStyle(
                      fontSize: isTablet ? 32 : 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  progressColor: Colors.orange,
                  backgroundColor: const Color.fromARGB(255, 3, 30, 53),
                  circularStrokeCap: CircularStrokeCap.round,
                )
                : CircularPercentIndicator(
                  radius: isTablet ? 100.0 : 80.0,
                  lineWidth: 20.0,
                  percent: 0.75,
                  center: Text(
                    "7000",
                    style: TextStyle(
                      fontSize: isTablet ? 32 : 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  progressColor: Colors.orange,
                  backgroundColor: const Color.fromARGB(255, 3, 30, 53),
                  circularStrokeCap: CircularStrokeCap.round,
                ),
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
                    alignment:
                        isbudgetTab
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
                                color:
                                    isbudgetTab
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
                                color:
                                    isbudgetTab
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
                            builder: (context) => BottomNavBar(initialIndex: 9),
                          )
                          : MaterialPageRoute(
                            builder:
                                (context) => BottomNavBar(initialIndex: 10),
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
                const Icon(Icons.sort_rounded, size: 32),
              ],
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children:
                      categories.map((category) {
                        return isbudgetTab
                            ? _buildCategoryItem1(
                              isTablet,
                              icon: category.icon,
                              category: category.name,
                              amountSpent: category.spent,
                              totalBudget: category.budget,
                              color: category.color,
                              exceeded: category.exceeded,
                            )
                            : _buildCategoryItem2(
                              isTablet,
                              icon: category.icon,
                              category: category.name,
                              amountSpent: category.spent,
                              totalBudget: category.budget,
                              color: category.color,
                              exceeded: category.exceeded,
                            );
                      }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
      // bottomNavigationBar: CustomBottomNavBar(
      //   currentIndex: _selectedIndex,
      //   onTap: _onNavItemTapped,
      // ),
    );
  }

  Widget _buildCategoryItem1(
    bool isTablet, {
    required IconData icon,
    required String category,
    required double amountSpent,
    required double totalBudget,
    required Color color,
    bool exceeded = false,
  }) {
    final percent = (amountSpent / totalBudget).clamp(0.0, 1.0);
    final remaining = totalBudget - amountSpent;

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
            "Remaining ${remaining < 0 ? 0 : remaining.toStringAsFixed(0)}",
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
                    "\$$amountSpent of \$$totalBudget",
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
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BottomNavBar(initialIndex: 6),
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
              if (exceeded)
                const Icon(Icons.error, color: Colors.red, size: 25),
              if (!exceeded)
                Text(
                  "${(percent * 100).toStringAsFixed(0)} %",
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
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
