import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:snapwise/services/snackbar_service.dart';
import 'package:snapwise/app/profile/favorites/favorite_controller.dart';
import 'dart:developer' as dev;
import 'dart:math';

class PredictController extends GetxController {
  final RxDouble totalBudget = 0.0.obs;
  final RxList<Map<String, dynamic>> budgetCategories =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> historicalData =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> historicalGraph =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> predictionGraph =
      <Map<String, dynamic>>[].obs;
  final RxString insights = ''.obs;
  final RxBool isLoading = false.obs;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<Map<String, dynamic>> categoryTemplates = [
    {'name': 'Food', 'icon': Icons.restaurant, 'color': Colors.green},
    {'name': 'Transport', 'icon': Icons.directions_car, 'color': Colors.blue},
    {'name': 'Shopping', 'icon': Icons.shopping_bag, 'color': Colors.purple},
    {'name': 'Utilities', 'icon': Icons.bolt, 'color': Colors.orange},
    {'name': 'Entertainment', 'icon': Icons.movie, 'color': Colors.red},
    {'name': 'Others', 'icon': Icons.more_horiz, 'color': Colors.grey},
  ];

  @override
  void onInit() {
    super.onInit();
    generateDataDrivenPrediction();
  }

  // Generate prediction based on historical data from last 6 months
  Future<void> generateDataDrivenPrediction() async {
    isLoading.value = true;
    try {
      await _fetchHistoricalData();
      await _createHistoricalGraph();
      await _analyzeSpendingPatterns();
      await _generatePredictions();
      await _createPredictionGraph();
      await _generateInsights();
    } catch (e) {
      dev.log('Error generating prediction: $e');
      SnackbarService.showError(
          title: 'Error', message: 'Failed to generate prediction: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch historical data from last 6-10 months
  Future<void> _fetchHistoricalData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final tenMonthsAgo = DateTime(now.year, now.month - 10, now.day);

      // Get expenses from last 10 months
      final expensesQuery = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: user.uid)
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(tenMonthsAgo))
          .orderBy('timestamp', descending: true)
          .get();

      // Get favorites payments from last 10 months
      double favoritesTotal =
          await _getFavoritesPaymentsForPeriod(tenMonthsAgo, now);

      // Process expenses data by month
      Map<String, double> monthlyExpenses = {};
      Map<String, double> categoryTotals = {};

      for (var doc in expensesQuery.docs) {
        final data = doc.data();
        final timestamp = (data['timestamp'] as Timestamp).toDate();
        final monthKey =
            '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}';
        final category = data['category'] ?? 'Others';
        final amount = _parseAmount(data['amount']);

        // Add to monthly totals
        monthlyExpenses[monthKey] = (monthlyExpenses[monthKey] ?? 0.0) + amount;

        // Add to category totals
        categoryTotals[category] = (categoryTotals[category] ?? 0.0) + amount;
      }

      // Add favorites to monthly data
      double monthlyFavorites = favoritesTotal /
          monthlyExpenses.length; // Distribute across available months
      monthlyExpenses.forEach((key, value) {
        monthlyExpenses[key] = value + monthlyFavorites;
      });

      // Store historical data (last 6 months for analysis)
      final sixMonthsAgo = DateTime(now.year, now.month - 6, now.day);
      historicalData.value = monthlyExpenses.entries.where((entry) {
        final parts = entry.key.split('-');
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final entryDate = DateTime(year, month, 1);
        return entryDate.isAfter(sixMonthsAgo);
      }).map((entry) {
        return {
          'month': entry.key,
          'total': entry.value,
          'categories': categoryTotals,
        };
      }).toList();

      dev.log('Historical data fetched: ${historicalData.length} months');
    } catch (e) {
      dev.log('Error fetching historical data: $e');
    }
  }

  // Create historical graph data for past 6-10 months
  Future<void> _createHistoricalGraph() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final tenMonthsAgo = DateTime(now.year, now.month - 10, now.day);

      // Get expenses from last 10 months
      final expensesQuery = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: user.uid)
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(tenMonthsAgo))
          .orderBy('timestamp', descending: false)
          .get();

      // Get favorites payments from last 10 months
      double favoritesTotal =
          await _getFavoritesPaymentsForPeriod(tenMonthsAgo, now);

      // Process expenses data by month
      Map<String, double> monthlyExpenses = {};

      for (var doc in expensesQuery.docs) {
        final data = doc.data();
        final timestamp = (data['timestamp'] as Timestamp).toDate();
        final monthKey =
            '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}';
        final amount = _parseAmount(data['amount']);

        // Add to monthly totals
        monthlyExpenses[monthKey] = (monthlyExpenses[monthKey] ?? 0.0) + amount;
      }

      // Add favorites to monthly data
      double monthlyFavorites = favoritesTotal /
          monthlyExpenses.length; // Distribute across available months
      monthlyExpenses.forEach((key, value) {
        monthlyExpenses[key] = value + monthlyFavorites;
      });

      // Create graph data for all available months (up to 10 months)
      List<Map<String, dynamic>> graphData = [];
      List<String> monthNames = [];

      // Generate month names for the past 10 months
      for (int i = 9; i >= 0; i--) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        final monthKey =
            '${monthDate.year}-${monthDate.month.toString().padLeft(2, '0')}';
        final monthName = _getMonthName(monthDate.month);

        monthNames.add(monthName);

        graphData.add({
          'month': monthKey,
          'monthName': monthName,
          'amount': monthlyExpenses[monthKey] ?? 0.0,
          'type': 'historical',
        });
      }

      // Show all months, even with zero data, for better visualization
      historicalGraph.value = graphData;
      dev.log('Historical graph created: ${graphData.length} months');
      dev.log('Month names: $monthNames');
      dev.log(
          'Graph data: ${graphData.map((d) => '${d['monthName']}: ₱${d['amount']}').join(', ')}');

      // Log the maximum amount for debugging
      if (graphData.isNotEmpty) {
        double maxAmount = graphData
            .map((d) => d['amount'] as double)
            .reduce((a, b) => a > b ? a : b);
        dev.log('Maximum amount in historical data: ₱$maxAmount');
      }
    } catch (e) {
      dev.log('Error creating historical graph: $e');
    }
  }

  // Helper method to get month name
  String _getMonthName(int month) {
    const monthNames = [
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
    return monthNames[month - 1];
  }

  // Analyze spending patterns
  Future<void> _analyzeSpendingPatterns() async {
    if (historicalData.isEmpty) return;

    // Calculate average monthly spending
    double totalSpent =
        historicalData.fold(0.0, (sum, month) => sum + month['total']);
    double averageMonthly = totalSpent / historicalData.length;

    // Calculate trend (increasing, decreasing, stable)
    double trend = 0.0;
    if (historicalData.length >= 2) {
      double firstMonth = historicalData.last['total'];
      double lastMonth = historicalData.first['total'];
      trend = ((lastMonth - firstMonth) / firstMonth) * 100;
    }

    // Calculate category percentages
    Map<String, double> categoryPercentages = {};
    double totalCategorySpending = 0.0;

    for (var month in historicalData) {
      Map<String, double> categories =
          Map<String, double>.from(month['categories']);
      categories.forEach((category, amount) {
        categoryPercentages[category] =
            (categoryPercentages[category] ?? 0.0) + amount;
        totalCategorySpending += amount;
      });
    }

    // Convert to percentages
    categoryPercentages.forEach((category, amount) {
      categoryPercentages[category] = (amount / totalCategorySpending) * 100;
    });

    dev.log('Average monthly spending: $averageMonthly');
    dev.log('Trend: ${trend.toStringAsFixed(2)}%');
    dev.log('Category percentages: $categoryPercentages');
  }

  // Generate predictions for next month
  Future<void> _generatePredictions() async {
    if (historicalData.isEmpty) {
      // If no historical data, use default categories
      budgetCategories.value = categoryTemplates.map((template) {
        return {
          ...template,
          'amount': 1000.0, // Default amount
          'prediction': true,
          'percentage': 100.0 / categoryTemplates.length,
          'color': template['color'] ?? Colors.grey,
        };
      }).toList();
      totalBudget.value = 6000.0;
      return;
    }

    // Calculate average monthly spending
    double totalSpent =
        historicalData.fold(0.0, (sum, month) => sum + month['total']);
    double averageMonthly = totalSpent / historicalData.length;

    // Apply trend factor (5% increase for next month)
    double predictedTotal = averageMonthly * 1.05;

    // Calculate category predictions based on historical percentages
    Map<String, double> categoryPercentages = {};
    double totalCategorySpending = 0.0;

    for (var month in historicalData) {
      Map<String, double> categories =
          Map<String, double>.from(month['categories']);
      categories.forEach((category, amount) {
        categoryPercentages[category] =
            (categoryPercentages[category] ?? 0.0) + amount;
        totalCategorySpending += amount;
      });
    }

    // Generate predictions for each category
    budgetCategories.value = categoryTemplates.map((template) {
      String categoryName = template['name'];
      double categoryAmount = 0.0;
      double categoryPercentage = 0.0;

      if (categoryPercentages.containsKey(categoryName)) {
        categoryPercentage =
            (categoryPercentages[categoryName]! / totalCategorySpending) * 100;
        categoryAmount = (predictedTotal * categoryPercentage) / 100;
      } else {
        // If no historical data for this category, use average
        categoryPercentage = 100.0 / categoryTemplates.length;
        categoryAmount = predictedTotal / categoryTemplates.length;
      }

      return {
        ...template,
        'amount': categoryAmount,
        'prediction': true,
        'percentage': categoryPercentage,
        'color': template['color'] ?? Colors.grey,
      };
    }).toList();

    totalBudget.value = predictedTotal;
    dev.log('Generated predictions: ${totalBudget.value}');
    dev.log(
        'Category percentages: ${budgetCategories.map((c) => '${c['name']}: ${c['percentage']}%').join(', ')}');
  }

  // Create prediction graph data for daily predictions
  Future<void> _createPredictionGraph() async {
    List<Map<String, dynamic>> graphData = [];

    // Get current month's data for comparison
    DateTime now = DateTime.now();

    // Get current month's daily expenses
    Map<int, double> currentMonthDaily = {};
    if (historicalData.isNotEmpty) {
      // Use the most recent month's data to create daily pattern
      var recentMonth = historicalData.first;
      double monthlyTotal = recentMonth['total'] as double;

      // Distribute monthly total across 30 days with some variation
      Random random = Random(42); // Fixed seed for consistent results
      double dailyAverage = monthlyTotal / 30;

      for (int day = 1; day <= 30; day++) {
        // Add some random variation (±20%)
        double variation = (random.nextDouble() - 0.5) * 0.4;
        double dailyAmount = dailyAverage * (1 + variation);
        currentMonthDaily[day] = dailyAmount;
      }
    }

    // Generate daily predictions for next month
    DateTime nextMonth = DateTime(now.year, now.month + 1, 1);
    int daysInNextMonth = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;

    // Calculate daily budget based on predicted total
    double dailyBudget = totalBudget.value / daysInNextMonth;

    Random random = Random(123); // Fixed seed for consistent results

    for (int day = 1; day <= daysInNextMonth; day++) {
      // Add some realistic variation to daily spending
      double variation = (random.nextDouble() - 0.5) * 0.3; // ±15% variation
      double predictedAmount = dailyBudget * (1 + variation);

      // Ensure minimum spending on some days
      if (random.nextDouble() < 0.1) {
        // 10% chance of very low spending
        predictedAmount = dailyBudget * 0.2;
      }

      graphData.add({
        'day': day,
        'amount': predictedAmount,
        'type': 'prediction',
        'date':
            '${nextMonth.year}-${nextMonth.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
      });
    }

    predictionGraph.value = graphData;
    dev.log('Created daily prediction graph with ${graphData.length} days');
    dev.log(
        'Daily budget: ${dailyBudget.toStringAsFixed(2)}, Total: ${totalBudget.value}');
  }

  // Generate insights based on data analysis
  Future<void> _generateInsights() async {
    if (historicalData.isEmpty) {
      insights.value =
          "No historical data available. Start tracking your expenses to get personalized predictions!";
      return;
    }

    double totalSpent =
        historicalData.fold(0.0, (sum, month) => sum + month['total']);
    double averageMonthly = totalSpent / historicalData.length;
    double predictedTotal = totalBudget.value;
    double increase =
        ((predictedTotal - averageMonthly) / averageMonthly) * 100;

    String insight =
        "Based on your spending patterns over the last ${historicalData.length} months:\n\n";
    insight +=
        "• Average monthly spending: ₱${averageMonthly.toStringAsFixed(2)}\n";
    insight +=
        "• Predicted next month: ₱${predictedTotal.toStringAsFixed(2)}\n";
    insight +=
        "• Expected change: ${increase > 0 ? '+' : ''}${increase.toStringAsFixed(1)}%\n\n";

    // Find top spending category
    Map<String, double> categoryTotals = {};
    for (var month in historicalData) {
      Map<String, double> categories =
          Map<String, double>.from(month['categories']);
      categories.forEach((category, amount) {
        categoryTotals[category] = (categoryTotals[category] ?? 0.0) + amount;
      });
    }

    if (categoryTotals.isNotEmpty) {
      String topCategory = categoryTotals.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      double topAmount = categoryTotals[topCategory]!;
      double topPercentage = (topAmount / totalSpent) * 100;

      insight +=
          "• Top spending category: $topCategory (${topPercentage.toStringAsFixed(1)}%)\n";
    }

    insights.value = insight;
  }

  // Helper method to get favorites payments for a period
  Future<double> _getFavoritesPaymentsForPeriod(
      DateTime startDate, DateTime endDate) async {
    try {
      FavoriteController favoriteController;
      try {
        favoriteController = Get.find<FavoriteController>();
      } catch (e) {
        favoriteController = Get.put(FavoriteController());
        await favoriteController.setupFavoritesStream();
      }

      double totalFavoritesExpenses = 0.0;

      for (var favorite in favoriteController.favorites) {
        List<Map<String, dynamic>> paymentHistory =
            List<Map<String, dynamic>>.from(favorite['paymentHistory'] ?? []);

        for (var payment in paymentHistory) {
          final paymentDateRaw = payment['timestamp'];
          DateTime paymentDate;

          if (paymentDateRaw is Timestamp) {
            paymentDate = paymentDateRaw.toDate();
          } else if (paymentDateRaw is DateTime) {
            paymentDate = paymentDateRaw;
          } else {
            continue;
          }

          if (paymentDate.isAfter(startDate) && paymentDate.isBefore(endDate)) {
            double amount = (payment['amount'] ?? 0.0).toDouble();
            totalFavoritesExpenses += amount;
          }
        }
      }

      return totalFavoritesExpenses;
    } catch (e) {
      dev.log('Error getting favorites payments: $e');
      return 0.0;
    }
  }

  // Helper method to parse amount
  double _parseAmount(dynamic amount) {
    if (amount is num) {
      return amount.toDouble();
    } else if (amount is String) {
      String cleanAmount = amount.replaceAll('-', '');
      return double.tryParse(cleanAmount) ?? 0.0;
    }
    return 0.0;
  }

  // Save prediction to Firebase
  Future<void> savePrediction() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('predictionBudget').doc(user.uid).set({
          'totalBudget': totalBudget.value,
          'categories': budgetCategories
              .map((category) => {
                    'name': category['name'],
                    'amount': category['amount'],
                    'percentage': category['percentage'],
                  })
              .toList(),
          'insights': insights.value,
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        SnackbarService.showSuccess(
            title: 'Success', message: 'Prediction saved successfully');
      }
    } catch (e) {
      SnackbarService.showError(
          title: 'Error', message: 'Failed to save prediction: $e');
    }
  }
}
