// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class TransactionsGraph extends StatefulWidget {
  @override
  _TransactionsGraphState createState() => _TransactionsGraphState();
}

class _TransactionsGraphState extends State<TransactionsGraph> {
  bool isDaily = true; 

  List<BarChartGroupData> getGraphData() {
    if (isDaily) {
      // Daily expenses for a month (30 days)
      List<double> dailyExpenses = [
        50, 80, 40, 100, 120, 90, 110, 130, 70, 60, 100, 90, 150, 120, 80, 70, 50, 110, 130, 140, 150, 160, 90, 80, 70, 60, 100, 90, 50, 40
      ];
      return List.generate(dailyExpenses.length, (index) {
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: dailyExpenses[index],
              color: Colors.blue,
              width: 12,
              borderRadius: BorderRadius.circular(6),
            ),
          ],
        );
      });
    } else {
      // Daily expenses (12 months)
      List<double> dailyExpenses = [500, 700, 650, 800, 900, 850, 1000, 950, 900, 1100, 1050, 1200];
      return List.generate(12, (index) {
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: dailyExpenses[index],
              color: Colors.blue,
              width: 12,
              borderRadius: BorderRadius.circular(6),
            ),
          ],
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            height: 200,
            padding: EdgeInsets.only(top: 20, left: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 8, spreadRadius: 2),
              ],
            ),
            child: Row(
              children: [
                // Static left labels
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(5, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        '${(200 * index / 4).toInt()}',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 10),
                      ),
                    );
                  }).reversed.toList(),
                ),
                SizedBox(width: 8),
                // Scrollable Bar Chart
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal, // Enables left-right scrolling
                      child: SizedBox(
                        width: isDaily ? 900 : 500, // Adjust width to prevent stacking
                        child: BarChart(
                          BarChartData(
                            barGroups: getGraphData(),
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(show: false), // Removed grid lines
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hides left titles
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  getTitlesWidget: (value, meta) {
                                    if (isDaily) {
                                      return Text("${value.toInt() + 1}", style: TextStyle(color: Colors.grey.shade600, fontSize: 8));
                                    } else {
                                      List<String> months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];
                                      return Text(months[value.toInt()], style: TextStyle(color: Colors.grey.shade600, fontSize: 8));
                                    }
                                  },
                                ),
                              ),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                alignment: isDaily ? Alignment.centerLeft : Alignment.centerRight,
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
                            color: isDaily ? Colors.white : Colors.grey.shade600,
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
                            color: isDaily ? Colors.grey.shade600 : Colors.white,
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
