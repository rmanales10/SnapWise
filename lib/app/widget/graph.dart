// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:snapwise/app/widget/graph_controller.dart';

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
    List<double> expenses = isDaily
        ? graphController.getCurrentMonthExpenses()
        : graphController.getMonthlyExpensesForLastYear();

    // Ensure we have data to display
    if (expenses.isEmpty || expenses.every((e) => e == 0)) {
      // Return dummy data to show empty state
      return List.generate(isDaily ? 30 : 12, (index) {
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: 0.0,
              color: Colors.grey.shade300,
              width: isDaily ? 8 : 12,
              borderRadius: BorderRadius.circular(6),
            ),
          ],
        );
      });
    }

    return List.generate(expenses.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: expenses[index],
            color: expenses[index] > 0 ? widget.barColor : Colors.grey.shade300,
            width: isDaily ? 8 : 12,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      );
    });
  }

  (double, String) calculateScale(double maxValue) {
    if (maxValue <= 1000) return (1, '');
    if (maxValue <= 1000000) return (1000, 'K');
    return (1000000, 'M');
  }

  // Generate dynamic Y-axis labels based on max value
  List<double> generateYAxisLabels(double maxValue) {
    if (maxValue <= 0) return [0, 25, 50, 75, 100];

    // Find appropriate step size
    double step;
    if (maxValue <= 100) {
      step = 25;
    } else if (maxValue <= 500) {
      step = 100;
    } else if (maxValue <= 1000) {
      step = 200;
    } else if (maxValue <= 5000) {
      step = 1000;
    } else if (maxValue <= 10000) {
      step = 2000;
    } else if (maxValue <= 50000) {
      step = 10000;
    } else if (maxValue <= 100000) {
      step = 20000;
    } else if (maxValue <= 500000) {
      step = 100000;
    } else {
      step = 200000;
    }

    // Generate labels
    List<double> labels = [];
    double current = 0;
    while (current <= maxValue) {
      labels.add(current);
      current += step;
    }

    // Ensure we have at least 4 labels
    if (labels.length < 4) {
      labels = [0, maxValue * 0.25, maxValue * 0.5, maxValue * 0.75, maxValue];
    }

    return labels;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final expenses = isDaily
        ? graphController.getCurrentMonthExpenses()
        : graphController.getMonthlyExpensesForLastYear();

    // Handle empty data
    final maxValue = expenses.isEmpty || expenses.every((e) => e == 0)
        ? 100.0 // Default max value for empty state
        : expenses.reduce(max);

    final (scale, suffix) = calculateScale(maxValue);
    final yAxisLabels = generateYAxisLabels(maxValue);
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
                  children: yAxisLabels.reversed.map((label) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        '${(label / scale).toStringAsFixed(label >= 1000 ? 0 : 1)}$suffix',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }).toList(),
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
                                        final monthIndex = (currentMonthIndex -
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
                                    final amount = rod.toY;
                                    final formattedAmount = amount >= 1000
                                        ? 'PHP ${(amount / 1000).toStringAsFixed(1)}k'
                                        : 'PHP ${amount.toStringAsFixed(2)}';

                                    return BarTooltipItem(
                                      '${isDaily ? "Day" : "Month"} ${groupIndex + 1}\n$formattedAmount',
                                      const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    );
                                  },
                                  tooltipPadding: const EdgeInsets.all(12),
                                  tooltipMargin: 8,
                                ),
                                touchCallback: (
                                  FlTouchEvent event,
                                  BarTouchResponse? touchResponse,
                                ) {
                                  if (event is FlTapUpEvent &&
                                      touchResponse != null &&
                                      touchResponse.spot?.touchedBarGroup !=
                                          null) {
                                    final touchedGroup =
                                        touchResponse.spot!.touchedBarGroup;
                                    final amount =
                                        touchedGroup.barRods.first.toY;
                                    final formattedAmount = amount >= 1000
                                        ? 'PHP ${(amount / 1000).toStringAsFixed(1)}k'
                                        : 'PHP ${amount.toStringAsFixed(2)}';

                                    final period = isDaily
                                        ? "Day ${touchedGroup.x + 1}"
                                        : "Month ${touchedGroup.x + 1}";

                                    _showExpenseDetails(
                                        context, period, formattedAmount);
                                  }
                                },
                                handleBuiltInTouches: true,
                              ),
                              maxY: yAxisLabels.last,
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
                      onTap: () async {
                        setState(() => isDaily = true);
                        await graphController.refreshData();
                      },
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
                      onTap: () async {
                        setState(() => isDaily = false);
                        await graphController.refreshData();
                      },
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

  void _showExpenseDetails(BuildContext context, String period, String amount) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.bar_chart,
                color: widget.barColor,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Expense Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.barColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      period,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      amount,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: widget.barColor,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Click on any bar in the chart to view detailed expense information for that ${isDaily ? "day" : "month"}.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: widget.barColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                'Close',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
