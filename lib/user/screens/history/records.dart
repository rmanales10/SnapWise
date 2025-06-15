import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snapwise/user/screens/expense/view_expense.dart';
import 'package:snapwise/user/screens/home/home_screens/home_controller.dart';
import 'package:snapwise/user/screens/profile/favorites/favorite_controller.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  final HomeController controller = Get.put(HomeController());
  final FavoriteController favoriteController = Get.put(FavoriteController());
  final formatter = NumberFormat.currency(
    locale: 'en_PH',
    symbol: 'PHP ',
    decimalDigits: 2,
  );

  bool isSelecting = false;
  List<int> selectedIndices = [];
  bool get isTablet => MediaQuery.of(context).size.shortestSide > 600;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "History",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isTablet ? 24 : 20,
            color: Colors.black,
          ),
        ),
      ),
      body: Obx(
        () => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Payments Made Today',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              _buildTodayPayments(),

              controller.transactionsHistory.isEmpty
                  ? Center(
                    child: Text(
                      "There are no transactions for now",
                      style: TextStyle(fontSize: isTablet ? 20 : 16),
                    ),
                  )
                  : Column(
                    children: [
                      SizedBox(height: 10),
                      SizedBox(
                        height: 500, // adjust as needed
                        child: _buildTransactionsList(),
                      ),
                    ],
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayPayments() {
    final todayPayments = <Map<String, dynamic>>[];

    for (var fav in favoriteController.favorites) {
      final title = fav['title'] ?? '';
      final history = fav['paymentHistory'] as List? ?? [];
      for (var payment in history) {
        final paymentDateRaw = payment['timestamp'];
        final paymentDate =
            paymentDateRaw is Timestamp
                ? paymentDateRaw.toDate()
                : paymentDateRaw as DateTime;
        final now = DateTime.now();
        if (paymentDate.year == now.year &&
            paymentDate.month == now.month &&
            paymentDate.day == now.day) {
          todayPayments.add({
            'title': title,
            'amount': payment['amount'],
            'date': paymentDate,
          });
        }
      }
    }

    if (todayPayments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Text(
          'No payments made today.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: todayPayments.length,
      itemBuilder: (context, index) {
        final payment = todayPayments[index];
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt_long, color: Colors.blue, size: 28),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment['title'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          DateFormat('MMM d, yyyy').format(payment['date']),
                          style: TextStyle(color: Colors.black45, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  '-${formatter.format(payment['amount']).replaceAll('PHP ', '')}',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionsList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 30 : 20,
        vertical: isTablet ? 15 : 10,
      ),
      itemCount: controller.transactionsHistory.length,
      itemBuilder: (context, index) {
        var tx = controller.transactionsHistory[index];
        return Padding(
          padding: EdgeInsets.only(bottom: isTablet ? 15 : 10),
          child: Stack(
            children: [
              GestureDetector(
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewExpense(expenseId: tx['id']),
                      ),
                    ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(isTablet ? 15 : 10),
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
                            Icon(
                              tx["icon"],
                              color: Colors.orange,
                              size: isTablet ? 36 : 30,
                            ),
                            SizedBox(width: isTablet ? 15 : 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx["title"],
                                  style: TextStyle(
                                    fontSize: isTablet ? 20 : 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  tx["date"],
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
                          (() {
                            final amount =
                                double.tryParse(tx["amount"].toString()) ?? 0.0;
                            return '${amount < 0 ? "" : "-"}${formatter.format(amount.abs()).replaceAll('PHP ', "")}';
                          })(),
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: isTablet ? 18 : 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (isSelecting)
                Positioned(
                  right: isTablet ? 10 : 5,
                  top: 0,
                  bottom: 0,
                  child: Checkbox(
                    activeColor: Colors.red,
                    value: selectedIndices.contains(index),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          selectedIndices.add(index);
                        } else {
                          selectedIndices.remove(index);
                        }
                      });
                    },
                    materialTapTargetSize:
                        isTablet
                            ? MaterialTapTargetSize.padded
                            : MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
