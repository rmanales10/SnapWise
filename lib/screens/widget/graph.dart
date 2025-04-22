// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:snapwise/screens/widget/graph_controller.dart';

class TransactionsGraph extends StatefulWidget {
  final Color barColor;
  final Color selectedTextColor;
  final Color unselectedTextColor;

  const TransactionsGraph({
    super.key,
    this.barColor = Colors.blue,
    this.selectedTextColor = Colors.white,
    this.unselectedTextColor = Colors.grey,
  });

  @override
  _TransactionsGraphState createState() => _TransactionsGraphState();
}

class _TransactionsGraphState extends State<TransactionsGraph> {
  final GraphController graphController = Get.put(GraphController());

  bool isDaily = true;

  List<BarChartGroupData> getGraphData() {
    List<double> expenses =
        isDaily
            ? graphController.getCurrentMonthExpenses()
            : graphController.getMonthlyExpensesForLastYear();

    return List.generate(expenses.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: expenses[index],
            color: widget.barColor,
            width: isDaily ? 8 : 12,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            height: screenWidth * 0.5,
            padding: EdgeInsets.only(top: 20, left: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children:
                      List.generate(5, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Text(
                            '${(200 * index / 4).toInt()}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 10,
                            ),
                          ),
                        );
                      }).reversed.toList(),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: isDaily ? 900 : 500,
                        child: Obx(
                          () => BarChart(
                            BarChartData(
                              barGroups: getGraphData(),
                              borderData: FlBorderData(show: false),
                              gridData: FlGridData(show: false),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    getTitlesWidget: (value, meta) {
                                      if (isDaily) {
                                        if ((value.toInt() + 1) % 5 == 0) {
                                          return Text(
                                            "${value.toInt() + 1}",
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 8,
                                            ),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      } else {
                                        final now = DateTime.now();
                                        final months = [
                                          "JAN",
                                          "FEB",
                                          "MAR",
                                          "APR",
                                          "MAY",
                                          "JUN",
                                          "JUL",
                                          "AUG",
                                          "SEP",
                                          "OCT",
                                          "NOV",
                                          "DEC",
                                        ];
                                        final currentMonthIndex = now.month - 1;
                                        final monthIndex =
                                            (currentMonthIndex -
                                                (11 - value.toInt())) %
                                            12;
                                        return Text(
                                          months[monthIndex],
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 8,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              barTouchData: BarTouchData(
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipItem: (
                                    group,
                                    groupIndex,
                                    rod,
                                    rodIndex,
                                  ) {
                                    return BarTooltipItem(
                                      '${isDaily ? "Day" : "Month"} ${groupIndex + 1}: ${rod.toY.toStringAsFixed(2)}',
                                      const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                                  tooltipRoundedRadius: 8,
                                  tooltipPadding: const EdgeInsets.all(8),
                                  tooltipMargin: 8,
                                ),
                                touchCallback: (
                                  FlTouchEvent event,
                                  BarTouchResponse? touchResponse,
                                ) {
                                  // Custom touch handling can be added here if needed
                                },
                                handleBuiltInTouches: true,
                              ),
                              maxY:
                                  isDaily
                                      ? graphController
                                              .getCurrentMonthExpenses()
                                              .reduce((a, b) => a > b ? a : b) *
                                          1.2
                                      : graphController
                                              .getMonthlyExpensesForLastYear()
                                              .reduce((a, b) => a > b ? a : b) *
                                          1.2,
                              alignment: BarChartAlignment.spaceAround,
                              groupsSpace: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        Container(
          width: 200,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment:
                    isDaily ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  width: 100,
                  height: 35,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 3, 30, 53),
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isDaily = true),
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          'Daily',
                          style: TextStyle(
                            color:
                                isDaily ? Colors.white : Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isDaily = false),
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          'Monthly',
                          style: TextStyle(
                            color:
                                isDaily ? Colors.grey.shade600 : Colors.white,
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
    );
  }
}
