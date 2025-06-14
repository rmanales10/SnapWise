import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snapwise/user/screens/expense/view_expense.dart';
import 'package:snapwise/user/screens/home/home_screens/home_controller.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  final HomeController controller = Get.put(HomeController());

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
        () =>
            controller.transactionsHistory.isEmpty
                ? Center(
                  child: Text(
                    "There are no transactions for now",
                    style: TextStyle(fontSize: isTablet ? 20 : 16),
                  ),
                )
                : Column(children: [Expanded(child: _buildTransactionsList())]),
      ),
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
                          tx["amount"],
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
