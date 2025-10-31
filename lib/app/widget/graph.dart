// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api
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

    // Debug logging
    dev.log(
        'Graph data - isDaily: $isDaily, expenses length: ${expenses.length}');
    if (expenses.isNotEmpty) {
      dev.log('First few expenses: ${expenses.take(5).toList()}');
      dev.log(
          'Total expenses: ${expenses.fold(0.0, (sum, expense) => sum + expense)}');
    }

    // Use the actual length of the data (handles 28/29/30/31 correctly)
    int dataLength = expenses.length;

    // For monthly view, limit to 12 months
    if (!isDaily && dataLength > 12) {
      dataLength = 12;
    }

    return List.generate(dataLength, (index) {
      // Get the expense value for this index, or 0 if no data
      double expenseValue = index < expenses.length ? expenses[index] : 0.0;

      // Debug logging for first few values
      if (index < 5) {
        dev.log('Bar $index: expenseValue = $expenseValue');
      }

      // Always show single bars - no double bar design
      return BarChartGroupData(
        x: index,
        barRods: [
          // Single bar for all data
          BarChartRodData(
            toY: expenseValue,
            color: expenseValue > 0
                ? const Color(0xFF2196F3) // Blue for data
                : Colors.grey.shade300, // Gray for no data
            width: isDaily ? 8 : 16,
            borderRadius: BorderRadius.circular(8),
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
    dev.log(
        'Generating Y-axis labels - maxValue: $maxValue, isDaily: $isDaily');

    // If no data, return default scale
    if (maxValue <= 0) {
      dev.log('No data, returning default scale');
      return isDaily ? [0, 25, 50, 75, 100] : [0, 1000, 2000, 3000, 4000];
    }

    // Add 20% padding above max value for better visualization
    double paddedMax = maxValue * 1.2;

    // Calculate appropriate step size based on padded max value
    double step;
    if (paddedMax <= 50) {
      step = 10;
    } else if (paddedMax <= 100) {
      step = 20;
    } else if (paddedMax <= 200) {
      step = 50;
    } else if (paddedMax <= 500) {
      step = 100;
    } else if (paddedMax <= 1000) {
      step = 200;
    } else if (paddedMax <= 5000) {
      step = 1000;
    } else if (paddedMax <= 10000) {
      step = 2000;
    } else if (paddedMax <= 50000) {
      step = 10000;
    } else if (paddedMax <= 100000) {
      step = 20000;
    } else if (paddedMax <= 500000) {
      step = 100000;
    } else if (paddedMax <= 1000000) {
      step = 200000;
    } else {
      step = 500000;
    }

    // Generate labels from 0 to padded max
    List<double> labels = [];
    double current = 0;
    while (current <= paddedMax) {
      labels.add(current);
      current += step;
    }

    // Ensure we have at least 4 labels
    if (labels.length < 4) {
      double paddedMax = maxValue * 1.2; // Add 20% padding
      labels = [
        0,
        paddedMax * 0.25,
        paddedMax * 0.5,
        paddedMax * 0.75,
        paddedMax
      ];
    }

    // Round labels to nice numbers for better display
    labels = labels.map((label) => (label / step).round() * step).toList();
    labels = labels.where((label) => label >= 0).toList();

    // Remove duplicates while preserving order
    labels = labels.toSet().toList();
    labels.sort();

    // Limit to maximum 6 labels to prevent overflow
    if (labels.length > 6) {
      labels = labels.take(6).toList();
    }

    dev.log('Generated Y-axis labels: $labels');
    return labels;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate safe container height (ensure maxHeight >= minHeight)
    final double calculatedMaxHeight = screenWidth * 0.5;
    final double safeMaxHeight =
        calculatedMaxHeight < 200 ? 200 : calculatedMaxHeight;

    // Wrap graph data fetching in Obx for real-time updates
    return Obx(() {
      // Force refresh data when view changes - now reactive!
      final expenses = isDaily
          ? graphController.getCurrentMonthExpenses()
          : graphController.getMonthlyExpensesForLastYear();

      // Handle empty data and calculate max value properly
      double maxValue;
      if (expenses.isEmpty || expenses.every((e) => e == 0)) {
        maxValue = 100.0; // Default max value for empty state
      } else {
        // Use the maximum individual expense
        double maxIndividualExpense = expenses.reduce((a, b) => a > b ? a : b);

        // For daily view, use a reasonable scale based on individual expenses
        // For monthly view, use a larger scale
        if (isDaily) {
          // For daily view, use max individual expense * 1.5 for better visualization
          maxValue = maxIndividualExpense * 1.5;
        } else {
          // For monthly view, use max individual expense * 2 for better visualization
          maxValue = maxIndividualExpense * 2;
        }

        // Ensure minimum scale for better visualization
        if (maxValue < 100) maxValue = 100;

        dev.log('Max individual expense: $maxIndividualExpense');
        dev.log('Calculated maxValue: $maxValue');
      }

      dev.log('=== BUILD METHOD ===');
      dev.log('isDaily: $isDaily');
      dev.log('Expenses data: $expenses');
      dev.log('Calculated maxValue: $maxValue');

      final yAxisLabels = generateYAxisLabels(maxValue);

      // Removed loading state - data is already available, no need to show loading when switching views

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              constraints: BoxConstraints(
                minHeight: 200,
                maxHeight: safeMaxHeight,
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
                    key: ValueKey(
                        'yaxis_${isDaily ? 'daily' : 'monthly'}_${yAxisLabels.length}'),
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

                      dev.log('Y-axis label: $label -> $labelText');

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
                              key: ValueKey(
                                  '${isDaily ? 'daily' : 'monthly'}_${expenses.length}'),
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
                                          // Calculate the correct month and year based on the bar index
                                          int monthsBack = 11 - value.toInt();
                                          int targetMonth =
                                              now.month - monthsBack;

                                          // Handle negative months (go to previous year)
                                          while (targetMonth <= 0) {
                                            targetMonth += 12;
                                          }

                                          final monthIndex = targetMonth - 1;
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

                                        // Get the actual amount from the graph data for this specific day
                                        final expenses = graphController
                                            .getCurrentMonthExpenses();
                                        final actualAmount =
                                            groupIndex < expenses.length
                                                ? expenses[groupIndex]
                                                : 0.0;

                                        // Format the amount based on actual data
                                        if (actualAmount > 0) {
                                          totalAmount = actualAmount >= 1000
                                              ? 'PHP ${(actualAmount / 1000).toStringAsFixed(1)}k'
                                              : 'PHP ${actualAmount.toStringAsFixed(2)}';
                                        } else {
                                          totalAmount = 'PHP 0.00';
                                        }
                                      } else {
                                        final now = DateTime.now();
                                        // Calculate the correct month and year based on the bar index
                                        int monthsBack = 11 - groupIndex;
                                        int targetMonth =
                                            now.month - monthsBack;
                                        int targetYear = now.year;

                                        // Handle negative months (go to previous year)
                                        while (targetMonth <= 0) {
                                          targetMonth += 12;
                                          targetYear -= 1;
                                        }

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
                                            '${monthNames[targetMonth - 1]} $targetYear';

                                        // For current month, use home controller's total
                                        if (targetMonth == now.month &&
                                            targetYear == now.year) {
                                          totalAmount =
                                              'PHP ${homeController.getTotalSpent()}';
                                        } else {
                                          totalAmount = formattedAmount;
                                        }
                                      }

                                      // Show "No data" if amount is 0
                                      String displayText = amount == 0
                                          ? '$dateLabel\nTotal: PHP 0.00\n(No expenses recorded)'
                                          : '$dateLabel\nTotal: $totalAmount\n(Receipt-date expenses only)';

                                      return BarTooltipItem(
                                        displayText,
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

                                        // Get the actual amount from the graph data for this specific day
                                        final expenses = graphController
                                            .getCurrentMonthExpenses();
                                        final actualAmount =
                                            touchedGroup.x < expenses.length
                                                ? expenses[touchedGroup.x]
                                                : 0.0;

                                        // Format the amount based on actual data
                                        if (actualAmount > 0) {
                                          displayAmount = actualAmount >= 1000
                                              ? 'PHP ${(actualAmount / 1000).toStringAsFixed(1)}k'
                                              : 'PHP ${actualAmount.toStringAsFixed(2)}';
                                        } else {
                                          displayAmount = 'PHP 0.00';
                                        }
                                      } else {
                                        final now = DateTime.now();
                                        // Calculate the correct month and year based on the bar index
                                        int monthsBack = 11 - touchedGroup.x;
                                        int targetMonth =
                                            now.month - monthsBack;
                                        int targetYear = now.year;

                                        // Handle negative months (go to previous year)
                                        while (targetMonth <= 0) {
                                          targetMonth += 12;
                                          targetYear -= 1;
                                        }

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
                                        period =
                                            '${monthNames[targetMonth - 1]} $targetYear';

                                        // For current month, use home controller's total
                                        if (targetMonth == now.month &&
                                            targetYear == now.year) {
                                          displayAmount =
                                              'PHP ${homeController.getTotalSpent()}';
                                        } else {
                                          displayAmount = formattedAmount;
                                        }
                                      }

                                      // Show "0" if no data
                                      if (amount == 0) {
                                        displayAmount = 'PHP 0.00';
                                      }

                                      _showExpenseDetails(context, period,
                                          displayAmount, isDaily);
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
                        onTap: () {
                          // Instant switch - no loading needed, data is already cached
                          setState(() {
                            isDaily = true;
                          });
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
                        onTap: () {
                          // Instant switch - no loading needed, data is already cached
                          setState(() {
                            isDaily = false;
                          });
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
    }); // End of Obx wrapper
  }

  void _showExpenseDetails(
      BuildContext context, String period, String amount, bool isDailyView) {
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
                          // Foreground bar (darker blue or gray for zero)
                          Container(
                            width: 16,
                            height: amount == 'PHP 0.00' ? 10 : 40,
                            decoration: BoxDecoration(
                              color: amount == 'PHP 0.00'
                                  ? Colors.grey.shade400
                                  : const Color(0xFF2196F3),
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
                        amount == 'PHP 0.00'
                            ? 'No expenses were recorded for ${isDailyView ? "this day" : "this month"}.'
                            : 'This total includes both regular expenses and favorites payments for ${isDailyView ? "this day" : "this month"}.',
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
