import 'package:emperiosquartet/chart/month_function.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RevenueVsProfitMarginChart extends StatefulWidget {
  const RevenueVsProfitMarginChart({super.key});

  @override
  _RevenueVsProfitMarginChartState createState() =>
      _RevenueVsProfitMarginChartState();
}

class _RevenueVsProfitMarginChartState
    extends State<RevenueVsProfitMarginChart> {
  final IncomeController incomeController = Get.find(); // Get the controller
  bool isMonthlyTrend = true; // Toggle between daily and monthly trend

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Text(
            'Monthly Expenses',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                double barWidth = constraints.maxWidth > 600
                    ? 5.05 // Wider bars for larger screens
                    : 5.03; // Thinner bars for smaller screens
                return Obx(() {
                  incomeController.fetchMonthlyExpenses();
                  return _buildBarChart(
                    barWidth,
                    incomeController.monthlyExpenses,
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // Build the BarChart widget
  BarChart _buildBarChart(double barWidth, RxList<double> monthlyExpenses) {
    return BarChart(
      BarChartData(
        barGroups: _buildBarGroups(barWidth, monthlyExpenses),
        borderData: FlBorderData(show: false),
        titlesData: _buildChartTitles(),
        gridData: const FlGridData(
            show: false), // Remove grid lines for a cleaner look
        alignment: BarChartAlignment.spaceAround, // Space out the bars
        backgroundColor: Colors.grey[50], // Light background for the chart
      ),
    );
  }

  // Build bar groups data based on monthly expenses
  List<BarChartGroupData> _buildBarGroups(
      double barWidth, RxList<double> monthlyExpenses) {
    return List.generate(monthlyExpenses.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: monthlyExpenses[index], // Total for the month
            color: Colors.blue, // Set all bars to blue
            width: barWidth, // Adjust the width here
            borderRadius:
                BorderRadius.circular(10), // Rounded corners for a softer look
          ),
        ],
      );
    });
  }

  // Configure the axis titles for the chart
  FlTitlesData _buildChartTitles() {
    return FlTitlesData(
      leftTitles: const AxisTitles(
        sideTitles: SideTitles(
          showTitles: false, // Completely remove left axis labels
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 1, // Ensure bottom labels (months) are spaced correctly
          getTitlesWidget: (value, _) => _buildBottomTitle(value),
        ),
      ),
    );
  }

  // Bottom axis title (Month names)
  Widget _buildBottomTitle(double value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    // Ensure the value is within valid index range
    if (value.toInt() < 0 || value.toInt() >= months.length) return Container();
    return Text(
      months[value.toInt()],
      style: const TextStyle(fontSize: 10, color: Colors.black),
    );
  }
}
