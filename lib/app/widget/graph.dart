// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api
import 'dart:math';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:snapwise/app/widget/graph_controller.dart';
import 'package:snapwise/app/home/home_screens/home_controller.dart';

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
  final HomeController homeController = Get.find<HomeController>();

  bool isDaily = true;

  List<BarChartGroupData> getGraphData() {
    List<double> expenses = isDaily
        ? graphController.getCurrentMonthExpenses()
        : graphController.getMonthlyExpensesForLastYear();

    // For monthly view, ensure we show the correct current month total
    if (!isDaily) {
      // Get the current month total to ensure accuracy
      double currentMonthTotal = graphController.getCurrentMonthTotal();
      dev.log('Current month total from graph controller: $currentMonthTotal');
    }

    // Calculate the max value for background bars
    double maxValue = expenses.isEmpty || expenses.every((e) => e == 0)
        ? (isDaily ? 100.0 : 1000.0) // Default max value for empty state
        : expenses.reduce(max);

    // Add some padding above the max value for better visualization
    double backgroundHeight = maxValue * 1.1;

    // Ensure we have data to display
    if (expenses.isEmpty || expenses.every((e) => e == 0)) {
      // Return dummy data to show empty state
      return List.generate(isDaily ? 30 : 12, (index) {
        return BarChartGroupData(
          x: index,
          barRods: [
            // Background bar (light blue, full height)
            BarChartRodData(
              toY: backgroundHeight,
              color: Colors.blue.shade50,
              width: isDaily ? 8 : 16,
              borderRadius: BorderRadius.circular(8),
            ),
            // Foreground bar (actual data, darker blue)
            BarChartRodData(
              toY: 0.0,
              color: Colors.grey.shade300,
              width: isDaily ? 6 : 12,
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
          // Background bar (light blue, full height)
          BarChartRodData(
            toY: backgroundHeight,
            color: Colors.blue.shade50,
            width: isDaily ? 8 : 16,
            borderRadius: BorderRadius.circular(8),
          ),
          // Foreground bar (actual data, darker blue)
          BarChartRodData(
            toY: expenses[index],
            color: expenses[index] > 0
                ? const Color(0xFF2196F3) // Bright blue color
                : Colors.grey.shade300,
            width: isDaily ? 6 : 12,
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

  // Generate Y-axis labels based on actual data range
  List<double> generateYAxisLabels(double maxValue) {
    // If no data, return default scale
    if (maxValue <= 0) {
      return isDaily ? [0, 25, 50, 75, 100] : [0, 1000, 2000, 3000, 4000];
    }

    // Calculate appropriate step size based on max value
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
    } else if (maxValue <= 1000000) {
      step = 200000;
    } else {
      step = 500000;
    }

    // Generate labels
    List<double> labels = [];
    double current = 0;
    while (current <= maxValue) {
      labels.add(current);
      current += step;
    }

    // Ensure we have at least 4 labels and add some padding above max value
    if (labels.length < 4) {
      double paddedMax = maxValue * 1.2; // Add 20% padding
      labels = [
        0,
        paddedMax * 0.25,
        paddedMax * 0.5,
        paddedMax * 0.75,
        paddedMax
      ];
    } else {
      // Add one more step above the max value for better visualization
      labels.add(labels.last + step);
    }

    // Limit to maximum 6 labels to prevent overflow
    if (labels.length > 6) {
      labels = labels.take(6).toList();
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

    final yAxisLabels = generateYAxisLabels(maxValue);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            constraints: BoxConstraints(
              minHeight: 200,
              maxHeight: screenWidth * 0.5,
            ),
            padding: EdgeInsets.only(top: 15, left: 20, bottom: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  spreadRadius: 0,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: yAxisLabels.reversed.map((label) {
                    String labelText;
                    if (label >= 100000) {
                      labelText = '${(label / 1000).toStringAsFixed(0)}k';
                    } else if (label >= 1000) {
                      labelText = '${(label / 1000).toStringAsFixed(1)}k';
                    } else {
                      labelText = label.toStringAsFixed(0);
                    }

                    return Container(
                      height: 20, // Fixed height to prevent overflow
                      alignment: Alignment.center,
                      child: Text(
                        labelText,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
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
                        width: isDaily ? 900 : 600,
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

                                    // Get the actual date for better tooltip
                                    String dateLabel;
                                    String totalAmount;

                                    if (isDaily) {
                                      final now = DateTime.now();
                                      final day = groupIndex + 1;
                                      final date =
                                          DateTime(now.year, now.month, day);
                                      dateLabel =
                                          '${date.day}/${date.month}/${date.year}';

                                      // For current day, use home controller's total
                                      if (day == now.day) {
                                        totalAmount =
                                            'PHP ${homeController.getTotalSpent()}';
                                      } else {
                                        totalAmount = formattedAmount;
                                      }
                                    } else {
                                      final now = DateTime.now();
                                      final monthIndex =
                                          (now.month - (11 - groupIndex)) % 12;
                                      final year =
                                          now.month - (11 - groupIndex) <= 0
                                              ? now.year - 1
                                              : now.year;
                                      final month =
                                          monthIndex == 0 ? 12 : monthIndex;
                                      final monthNames = [
                                        'JAN',
                                        'FEB',
                                        'MAR',
                                        'APR',
                                        'MAY',
                                        'JUN',
                                        'JUL',
                                        'AUG',
                                        'SEP',
                                        'OCT',
                                        'NOV',
                                        'DEC'
                                      ];
                                      dateLabel =
                                          '${monthNames[month - 1]} $year';

                                      // For current month, use home controller's total
                                      if (month == now.month &&
                                          year == now.year) {
                                        totalAmount =
                                            'PHP ${homeController.getTotalSpent()}';
                                      } else {
                                        totalAmount = formattedAmount;
                                      }
                                    }

                                    return BarTooltipItem(
                                      '$dateLabel\nTotal: $totalAmount\n(Expenses + Favorites)',
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

                                    // Get the actual date for better display
                                    String period;
                                    String displayAmount;

                                    if (isDaily) {
                                      final now = DateTime.now();
                                      final day = touchedGroup.x + 1;
                                      final date =
                                          DateTime(now.year, now.month, day);
                                      period =
                                          '${date.day}/${date.month}/${date.year}';

                                      // For current day, use home controller's total
                                      if (day == now.day) {
                                        displayAmount =
                                            'PHP ${homeController.getTotalSpent()}';
                                      } else {
                                        displayAmount = formattedAmount;
                                      }
                                    } else {
                                      final now = DateTime.now();
                                      final monthIndex =
                                          (now.month - (11 - touchedGroup.x)) %
                                              12;
                                      final year =
                                          now.month - (11 - touchedGroup.x) <= 0
                                              ? now.year - 1
                                              : now.year;
                                      final month =
                                          monthIndex == 0 ? 12 : monthIndex;
                                      final monthNames = [
                                        'JAN',
                                        'FEB',
                                        'MAR',
                                        'APR',
                                        'MAY',
                                        'JUN',
                                        'JUL',
                                        'AUG',
                                        'SEP',
                                        'OCT',
                                        'NOV',
                                        'DEC'
                                      ];
                                      period = '${monthNames[month - 1]} $year';

                                      // For current month, use home controller's total
                                      if (month == now.month &&
                                          year == now.year) {
                                        displayAmount =
                                            'PHP ${homeController.getTotalSpent()}';
                                      } else {
                                        displayAmount = formattedAmount;
                                      }
                                    }

                                    _showExpenseDetails(
                                        context, period, displayAmount);
                                  }
                                },
                                handleBuiltInTouches: true,
                              ),
                              maxY: yAxisLabels.last,
                              alignment: BarChartAlignment.spaceAround,
                              groupsSpace: isDaily ? 12 : 20,
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
          height: 45,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.grey[200]!),
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
                  height: 40,
                  margin: EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2196F3).withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 0,
                        offset: Offset(0, 2),
                      ),
                    ],
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
                            color: isDaily ? Colors.white : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
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
                            color: isDaily ? Colors.grey[600] : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
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
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.bar_chart,
                  color: const Color(0xFF2196F3),
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Expense Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Double bar visual representation
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    // Visual representation of double bar
                    Container(
                      height: 60,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Background bar (light blue)
                          Container(
                            width: 20,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          SizedBox(width: 4),
                          // Foreground bar (darker blue)
                          Container(
                            width: 16,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    // Period and amount
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
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2196F3),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              // Description with modern styling
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color(0xFF2196F3),
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This total includes both regular expenses and favorites payments for ${isDaily ? "this day" : "this month"}.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: Text(
                  'Close',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
