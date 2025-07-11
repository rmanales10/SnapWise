import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:snapwise/app/expense/view_expense.dart';
import 'package:snapwise/app/home/home_screens/home_controller.dart';
import 'package:snapwise/app/widget/bottomnavbar.dart';
import 'package:snapwise/app/widget/graph.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double _calculateBalance(String income, String spent) {
    double incomeValue = _parseFormattedAmount(income);
    double spentValue = _parseFormattedAmount(spent);
    return incomeValue - spentValue;
  }

  double _parseFormattedAmount(String amount) {
    amount = amount.replaceAll('\$', '').replaceAll('PHP', '').trim();
    if (amount.endsWith('k')) {
      return double.parse(amount.substring(0, amount.length - 1)) * 1000;
    } else if (amount.endsWith('M')) {
      return double.parse(amount.substring(0, amount.length - 1)) * 1000000;
    } else {
      return double.parse(amount);
    }
  }

  final HomeController controller = Get.put(HomeController());
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  final _storage = GetStorage();
  RxString photoUrl = ''.obs;
  final bool isTablet = MediaQueryData.fromView(
        // ignore: deprecated_member_use
        WidgetsBinding.instance.window,
      ).size.shortestSide >
      600;

  @override
  void initState() {
    super.initState();
    _fetchPhotoUrl();
  }

  Future<void> _fetchPhotoUrl() async {
    photoUrl.value = _storage.read('photoUrl') ?? '';
    controller.fetchTransactions();
    controller.getTotalBudget();
    controller.getTotalIncome();
  }

  Future<void> sendBudgetExceededNotification({
    required double spentPercentage,
    required double remainingBudget,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'budget_alert_channel',
      'Budget Alerts',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      2, // Use a unique ID
      'Budget Alert',
      'You\'ve spent ${(spentPercentage * 100).toStringAsFixed(1)}% of your budget. Remaining: \$${remainingBudget.toStringAsFixed(2)}',
      platformChannelSpecifics,
    );

    // Log the event
    await _analytics.logEvent(
      name: 'budget_exceeded_notification',
      parameters: {
        'spent_percentage': spentPercentage,
        'remaining_budget': remainingBudget,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBalanceSection(),
              TransactionsGraph(),
              const SizedBox(height: 20),
              _buildTransactionsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 30 : 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color.fromARGB(97, 77, 77, 114), Colors.grey.shade100],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: isTablet ? 30 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 40 : 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.all(isTablet ? 3 : 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue, width: 3),
                    ),
                    child: Obx(() {
                      ImageProvider imageProvider = photoUrl.isNotEmpty
                          ? NetworkImage(photoUrl.value) as ImageProvider
                          : const AssetImage('assets/logo.png')
                              as ImageProvider;
                      return CircleAvatar(
                        backgroundImage: imageProvider,
                        backgroundColor: Colors.grey,
                        radius: isTablet ? 30 : 20,
                      );
                    }),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/notification'),
                    child: Icon(
                      Icons.notifications,
                      color: const Color.fromARGB(255, 3, 30, 53),
                      size: isTablet ? 35 : 24,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Text(
              'Account Balance',
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 5),
            Obx(() {
              String income = controller.totalIncome.value;
              String spent = controller.getTotalSpent();
              double balance = _calculateBalance(income, spent);
              return Text(
                '₱ ${balance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: isTablet ? 32 : 28,
                  fontWeight: FontWeight.bold,
                ),
              );
            }),
            SizedBox(height: isTablet ? 20 : 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Obx(
                        () => GestureDetector(
                          onTap: () => sendBudgetExceededNotification(
                            remainingBudget: 10,
                            spentPercentage: 10,
                          ),
                          child: _buildBalanceCard(
                            'assets/money-management 1.png',
                            'Budget',
                            'PHP ${controller.totalBudget}',
                          ),
                        ),
                      ),
                      SizedBox(width: isTablet ? 30 : 10),
                      Obx(
                        () => _buildBalanceCard(
                          'assets/save-money 1.png',
                          'Income',
                          'PHP ${controller.totalIncome}',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isTablet ? 20 : 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Obx(
                        () => _buildBalanceCard(
                          'assets/sales 1.png',
                          'Total Spent',
                          'PHP ${controller.getTotalSpent()}',
                        ),
                      ),
                      SizedBox(width: isTablet ? 30 : 10),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  BottomNavBar(initialIndex: 8),
                            ),
                          );
                        },
                        child: Container(
                          width: isTablet ? 250 : 150,
                          padding: EdgeInsets.symmetric(
                            vertical: isTablet ? 12 : 7,
                            horizontal: isTablet ? 30 : 20,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 3, 30, 53),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 5,
                                offset: const Offset(0, 5),
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Predict Budget',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isTablet ? 18 : 15,
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
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(String imagePath, String title, String amount) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 15 : 10),
      width: isTablet ? 250 : 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 5,
            offset: const Offset(0, 5),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset(
            imagePath,
            width: isTablet ? 45 : 30,
            height: isTablet ? 45 : 30,
            fit: BoxFit.contain,
          ),
          SizedBox(width: isTablet ? 15 : 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: isTablet ? 18 : 14,
                  color: Colors.black45,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                amount,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isTablet ? 18 : 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 40 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Transactions',
                style: TextStyle(
                  fontSize: isTablet ? 22 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => BottomNavBar(initialIndex: 1),
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 15 : 10,
                    vertical: isTablet ? 8 : 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    'See All',
                    style: TextStyle(
                      color: const Color.fromARGB(255, 141, 59, 179),
                      fontWeight: FontWeight.bold,
                      fontSize: isTablet ? 16 : 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Obx(
            () => Column(
              children: controller.transactions.map((transaction) {
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ViewExpense(expenseId: transaction['id']),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildTransactionItem(
                      transaction["icon"],
                      transaction["title"],
                      transaction["date"],
                      transaction["amount"],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(
    IconData icon,
    String title,
    String date,
    String amount,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: isTablet ? 15 : 10,
          horizontal: isTablet ? 20 : 15,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.orange, size: isTablet ? 36 : 30),
                SizedBox(width: isTablet ? 15 : 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isTablet ? 20 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      date,
                      style: TextStyle(
                        color: Colors.black45,
                        fontSize: isTablet ? 16 : 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Text(
              amount,
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: isTablet ? 18 : 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
