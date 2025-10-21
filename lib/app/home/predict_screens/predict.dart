import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:snapwise/app/home/predict_screens/predict_controller.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PredictBudgetPage extends StatefulWidget {
  const PredictBudgetPage({super.key});

  @override
  State<PredictBudgetPage> createState() => _PredictBudgetPageState();
}

class _PredictBudgetPageState extends State<PredictBudgetPage> {
  final _controller = Get.put(PredictController());

  bool get isTablet => MediaQuery.of(context).size.shortestSide > 600;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        title: Text(
          'Predict Budget',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isTablet ? 24 : 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: isTablet ? 28 : 24),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              icon: Icon(
                LucideIcons.refreshCw,
                color: Colors.black,
                size: isTablet ? 28 : 20,
              ),
              onPressed: () {
                _controller.generateDataDrivenPrediction();
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(
          () => _controller.isLoading.value
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: const Color.fromARGB(255, 3, 30, 53),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Analyzing your spending patterns...',
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
          padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 30 : 16,
            vertical: isTablet ? 25 : 15,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                      // Prediction Summary
                      _buildPredictionSummary(),
                      SizedBox(height: isTablet ? 30 : 20),

                      // Historical Graph
                      _buildHistoricalGraph(),
                      SizedBox(height: isTablet ? 30 : 20),

                      // Prediction Graph
                      _buildPredictionGraph(),
                      SizedBox(height: isTablet ? 30 : 20),

                      // Insights
                      _buildInsights(),
                      SizedBox(height: isTablet ? 30 : 20),

                      // Budget Categories
                      _buildBudgetCategories(),
                      SizedBox(height: isTablet ? 30 : 20),

                      // Saved Predictions
                      _buildSavedPredictions(),
                      SizedBox(height: isTablet ? 30 : 20),

                      // Save Button
                      _buildSaveButton(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPredictionSummary() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 20 : 15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.trendingUp,
                color: const Color.fromARGB(255, 3, 30, 53),
                size: isTablet ? 28 : 24,
              ),
              SizedBox(width: 10),
              Text(
                'Predicted Budget for Next Month',
                style: TextStyle(
                  fontSize: isTablet ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 3, 30, 53),
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 20 : 15),
          Obx(() => Text(
                'PHP ${_controller.totalBudget.value.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: isTablet ? 36 : 32,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 3, 30, 53),
                ),
              )),
          SizedBox(height: isTablet ? 10 : 8),
          Obx(() => Text(
                'Based on your last ${_controller.dataDurationMonths.value} months of spending data',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  color: Colors.grey[600],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildHistoricalGraph() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 20 : 15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.barChart3,
                color: const Color.fromARGB(255, 3, 30, 53),
                size: isTablet ? 28 : 24,
              ),
              SizedBox(width: 10),
              Text(
                'Historical Spending (Past 6-10 Mo.)',
                style: TextStyle(
                  fontSize: isTablet ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 3, 30, 53),
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 20 : 15),
          Obx(() => _controller.historicalGraph.isEmpty
              ? Container(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.barChart3,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No historical data available',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: isTablet ? 16 : 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start tracking expenses to see your spending history',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: isTablet ? 14 : 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _controller.historicalGraph.isNotEmpty
                  ? Container(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          barGroups: _controller.historicalGraph
                              .asMap()
                              .entries
                              .map((entry) {
                            return BarChartGroupData(
                              x: entry.key,
                              barRods: [
                                BarChartRodData(
                                  toY: entry.value['amount'] as double? ?? 0.0,
                                  color: const Color.fromARGB(255, 3, 30, 53),
                                  width: 16,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ],
                            );
                          }).toList(),
                          gridData: FlGridData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 35,
                                interval: _controller.historicalGraph.isNotEmpty
                                    ? (_controller.historicalGraph
                                                .map((d) =>
                                                    (d['amount'] as double? ??
                                                        0.0))
                                                .reduce(
                                                    (a, b) => a > b ? a : b) >
                                            0
                                        ? _controller.historicalGraph
                                                .map((d) =>
                                                    (d['amount'] as double? ??
                                                        0.0))
                                                .reduce(
                                                    (a, b) => a > b ? a : b) /
                                            5
                                        : 200)
                                    : 200,
                                getTitlesWidget: (value, meta) {
                                  if (value == 0) return Text('');
                                  // Show actual amount if less than 1000, otherwise show in thousands
                                  String displayText;
                                  if (value < 1000) {
                                    displayText =
                                        '₱${value.toStringAsFixed(0)}';
                                  } else {
                                    displayText =
                                        '₱${(value / 1000).toStringAsFixed(0)}k';
                                  }
                                  return Container(
                                    width: 30,
                                    child: Text(
                                      displayText,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.grey[600],
                                      ),
                                      textAlign: TextAlign.right,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  int index = value.toInt();
                                  if (index <
                                      _controller.historicalGraph.length) {
                                    String? monthName =
                                        _controller.historicalGraph[index]
                                            ['monthName'] as String?;
                                    if (monthName != null) {
                                      return Text(
                                        monthName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      );
                                    }
                                  }
                                  return Text('');
                                },
                              ),
                            ),
                            rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                        ),
                      ),
                    )
                  : Container(
                      height: 200,
                      child: Center(
                        child: Text(
                          'No historical data available',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: isTablet ? 16 : 14,
                          ),
                        ),
                      ),
                    )),
        ],
      ),
    );
  }

  Widget _buildPredictionGraph() {
    return Container(
                width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 20 : 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(isTablet ? 20 : 15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
            'Daily Spending Prediction for Next Month',
                      style: TextStyle(
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 3, 30, 53),
                      ),
                    ),
          SizedBox(height: isTablet ? 20 : 15),
          Obx(() => _controller.predictionGraph.isEmpty
                        ? Container(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.barChart3,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No prediction data available',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: isTablet ? 16 : 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start tracking expenses to see daily predictions',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: isTablet ? 14 : 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _controller.predictionGraph.isNotEmpty
                  ? Container(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          minX: 0,
                          maxX: (_controller.predictionGraph.length - 1)
                              .toDouble(),
                          minY: 0,
                          maxY: _controller.predictionGraph
                                  .map((d) => (d['amount'] as double? ?? 0.0))
                                  .reduce((a, b) => a > b ? a : b) *
                              1.1,
                          gridData: FlGridData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 35,
                                interval: _controller.predictionGraph.isNotEmpty
                                    ? _controller.predictionGraph
                                            .map((d) =>
                                                (d['amount'] as double? ?? 0.0))
                                            .reduce((a, b) => a > b ? a : b) /
                                        5
                                    : 200,
                                getTitlesWidget: (value, meta) {
                                  if (value == 0) return Text('');
                                  // Show actual amount if less than 1000, otherwise show in thousands
                                  String displayText;
                                  if (value < 1000) {
                                    displayText =
                                        '₱${value.toStringAsFixed(0)}';
                                  } else {
                                    displayText =
                                        '₱${(value / 1000).toStringAsFixed(0)}k';
                                  }
                                  return Container(
                                    width: 30,
                                    child: Text(
                                      displayText,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.grey[600],
                                      ),
                                      textAlign: TextAlign.right,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  int index = value.toInt();
                                  if (index <
                                      _controller.predictionGraph.length) {
                                    int? day = _controller
                                        .predictionGraph[index]['day'] as int?;
                                    if (day != null &&
                                        (day % 5 == 0 || day == 1)) {
                                      return Text(
                                        '$day',
                              style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      );
                                    }
                                  }
                                  return Text('');
                                },
                              ),
                            ),
                            rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: _controller.predictionGraph
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                return FlSpot(entry.key.toDouble(),
                                    entry.value['amount']);
                              }).toList(),
                              isCurved: true,
                              color: const Color.fromARGB(255, 3, 30, 53),
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  // Show dots only on every 5th day to avoid crowding
                                  if (index <
                                      _controller.predictionGraph.length) {
                                    int? day = _controller
                                        .predictionGraph[index]['day'] as int?;
                                    if (day != null &&
                                        day % 5 != 0 &&
                                        day != 1) {
                                      return FlDotCirclePainter(radius: 0);
                                    }
                                  }

                                  return FlDotCirclePainter(
                                    radius: 4,
                                color: const Color.fromARGB(255, 3, 30, 53),
                                    strokeWidth: 2,
                                    strokeColor: Colors.white,
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                color: const Color.fromARGB(255, 3, 30, 53)
                                    .withOpacity(0.1),
                              ),
                            ),
                          ],
                            ),
                          ),
                        )
                  : Container(
                      height: 200,
                      child: Center(
                        child: Text(
                          'No prediction data available',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: isTablet ? 16 : 14,
                          ),
                        ),
                      ),
                    )),
        ],
      ),
    );
  }

  Widget _buildInsights() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 20 : 15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.lightbulb,
                color: Colors.orange,
                size: isTablet ? 28 : 24,
              ),
              SizedBox(width: 10),
              Text(
                'Insights & Analysis',
                          style: TextStyle(
                  fontSize: isTablet ? 20 : 18,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 3, 30, 53),
                          ),
                        ),
                  ],
                ),
          SizedBox(height: isTablet ? 20 : 15),
          Obx(() => Text(
                _controller.insights.value,
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildBudgetCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
              Text(
          'Predicted Category Breakdown',
                style: TextStyle(
                  fontSize: isTablet ? 22 : 18,
                  fontWeight: FontWeight.bold,
            color: const Color.fromARGB(255, 3, 30, 53),
                ),
              ),
              SizedBox(height: isTablet ? 20 : 15),
        Obx(() => GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _controller.budgetCategories.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isTablet ? 3 : 2,
                  crossAxisSpacing: isTablet ? 20 : 15,
                  mainAxisSpacing: isTablet ? 20 : 15,
                childAspectRatio: isTablet ? 1.1 : 1.2,
                ),
                itemBuilder: (context, index) {
                  final category = _controller.budgetCategories[index];
                return _buildCategoryCard(category);
              },
            )),
      ],
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
        return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isTablet ? 15 : 12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (category['color'] as Color? ?? Colors.grey)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  category['icon'],
                  size: isTablet ? 20 : 18,
                  color: category['color'] as Color? ?? Colors.grey,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                    child: Text(
                  category['name'],
                      style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
          SizedBox(height: 12),
          Text(
            'PHP ${(category['amount'] as double? ?? 0.0).toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 3, 30, 53),
            ),
          ),
          SizedBox(height: 4),
          Text(
            '${(category['percentage'] as double? ?? 0.0).toStringAsFixed(1)}% of total',
            style: TextStyle(
              fontSize: isTablet ? 12 : 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedPredictions() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history,
                color: const Color.fromARGB(255, 3, 30, 53),
                size: isTablet ? 24 : 20,
              ),
              SizedBox(width: 10),
              Text(
                'Saved Predictions',
                    style: TextStyle(
                      fontSize: isTablet ? 20 : 18,
                      fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 3, 30, 53),
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 20 : 15),
          Obx(() => _controller.savedPredictions.isEmpty
              ? Container(
                  padding: EdgeInsets.all(isTablet ? 40 : 30),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          size: isTablet ? 60 : 50,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No saved predictions yet',
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Save your first prediction to see it here',
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12,
                            color: Colors.grey[500],
                    ),
                  ),
            ],
          ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _controller.savedPredictions.length,
                  itemBuilder: (context, index) {
                    final prediction = _controller.savedPredictions[index];
                    return _buildPredictionCard(prediction);
                  },
                )),
        ],
      ),
    );
  }

  Widget _buildPredictionCard(Map<String, dynamic> prediction) {
    final totalBudget = (prediction['totalBudget'] ?? 0.0).toDouble();
    final categories =
        List<Map<String, dynamic>>.from(prediction['categories'] ?? []);
    final timestamp = prediction['timestamp'] as Timestamp?;
    final date = timestamp != null ? timestamp.toDate() : DateTime.now();

    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Color(0xFFF8F9FE),
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Budget',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '₱${totalBudget.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: isTablet ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 3, 30, 53),
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 12 : 8),
              Text(
            'Categories:',
            style: TextStyle(
              fontSize: isTablet ? 14 : 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: isTablet ? 8 : 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((category) {
              final name = category['name'] ?? '';
              final amount = (category['amount'] ?? 0.0).toDouble();
              final percentage = (category['percentage'] ?? 0.0).toDouble();

              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 12 : 10,
                  vertical: isTablet ? 6 : 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Text(
                  '$name: ₱${amount.toStringAsFixed(0)} (${percentage.toStringAsFixed(1)}%)',
                style: TextStyle(
                    fontSize: isTablet ? 12 : 10,
                    color: Colors.grey[700],
                ),
              ),
              );
            }).toList(),
          ),
          SizedBox(height: isTablet ? 12 : 8),
              Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
              Text(
                'Saved on ${DateFormat('MMM d, yyyy').format(date)}',
                style: TextStyle(
                  fontSize: isTablet ? 12 : 10,
                  color: Colors.grey[500],
                ),
              ),
              Text(
                '${DateFormat('h:mm a').format(date)}',
                style: TextStyle(
                  fontSize: isTablet ? 12 : 10,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      child: Obx(
        () => ElevatedButton(
          onPressed: _controller.isSaving.value
              ? null
              : () {
                  _controller.savePrediction();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 3, 30, 53),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
              vertical: isTablet ? 18 : 16,
            ),
          ),
          child: _controller.isSaving.value
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Saving...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              : Text(
                  'Save Prediction',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
    );
  }
}
