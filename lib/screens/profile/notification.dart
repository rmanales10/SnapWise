import 'package:flutter/material.dart';
import 'package:snapwise/screens/widget/bottomnavbar.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  int _selectedIndex = 3;
  bool _expenseAlertsEnabled = true;
  bool _budgetAlertsEnabled = true;

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery to get the screen width
    final double screenWidth = MediaQuery.of(context).size.width;

    // Define tablet threshold (e.g., 600px for tablets)
    final bool isTablet = screenWidth >= 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 30 : 15,
          vertical: isTablet ? 60 : 50,
        ),
        child: Column(
          children: [
            // Header Section
            Container(
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 40 : 20),
              color: Colors.white,
              child: Column(
                children: [
                  const SizedBox(height: 25),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.arrow_back),
                        ),
                      ),
                       Text(
                        'Notification',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isTablet ? 25 : 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                ],
              ),
            ),

            // Content Section
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Expense Alert Section
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 40 : 20,
                        vertical: isTablet ? 20 : 15,
                      ),
                      color: Colors.white,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Expense Alert',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize:
                                        isTablet
                                            ? 20
                                            : 17, // Adjust font size for tablet
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "Get notification about your expense",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize:
                                        isTablet
                                            ? 18
                                            : 16, // Adjust font size for tablet
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 5),
                          Transform.scale(
                            scale: 0.8,
                            child: Switch(
                              value: _expenseAlertsEnabled,
                              onChanged: (value) {
                                setState(() {
                                  _expenseAlertsEnabled = value;
                                });
                              },
                              activeTrackColor: const Color.fromARGB(
                                255,
                                3,
                                30,
                                53,
                              ),
                              inactiveTrackColor: const Color.fromARGB(
                                255,
                                3,
                                30,
                                53,
                              ),
                              activeColor: Colors.white,
                              inactiveThumbColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Budget Alert Section
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 40 : 20,
                        vertical: isTablet ? 20 : 15,
                      ),
                      color: Colors.white,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Budget',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize:
                                        isTablet
                                            ? 20
                                            : 17, // Adjust font size for tablet
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "Get notification when your budget exceeding the limit",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize:
                                        isTablet
                                            ? 18
                                            : 16, // Adjust font size for tablet
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 5),
                          Transform.scale(
                            scale: 0.8,
                            child: Switch(
                              value: _budgetAlertsEnabled,
                              onChanged: (value) {
                                setState(() {
                                  _budgetAlertsEnabled = value;
                                });
                              },
                              activeTrackColor: const Color.fromARGB(
                                255,
                                3,
                                30,
                                53,
                              ),
                              inactiveTrackColor: const Color.fromARGB(
                                255,
                                3,
                                30,
                                53,
                              ),
                              activeColor: Colors.white,
                              inactiveThumbColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
      ),
    );
  }
}
