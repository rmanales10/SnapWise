import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:snapwise/services/snackbar_service.dart';
import 'dart:developer' as dev;
import 'dart:math';
import 'package:snapwise/app/widget/bottomnavbar.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';

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
  final RxBool isSaving = false.obs; // Loading state for saving prediction
  final RxInt dataDurationMonths = 0.obs; // Track actual data duration used
  final RxList<Map<String, dynamic>> savedPredictions =
      <Map<String, dynamic>>[].obs;

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
    fetchSavedPredictions();
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
      // Calculate 10 months ago properly, handling year boundaries
      DateTime tenMonthsAgo;
      if (now.month > 10) {
        tenMonthsAgo = DateTime(now.year, now.month - 10, 1);
      } else {
        tenMonthsAgo = DateTime(now.year - 1, now.month + 2, 1);
      }

      dev.log('=== FETCHING HISTORICAL DATA ===');
      dev.log('Current date: $now');
      dev.log('Ten months ago: $tenMonthsAgo');
      dev.log(
          'Date range: ${tenMonthsAgo.toIso8601String().split('T')[0]} to ${now.toIso8601String().split('T')[0]}');

      // Get expenses from last 10 months (using receiptDate like dashboard)
      final expensesQuery = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: user.uid)
          .where('receiptDate',
              isGreaterThanOrEqualTo:
                  tenMonthsAgo.toIso8601String().split('T')[0])
          .orderBy('receiptDate', descending: false)
          .get();

      dev.log('Total expenses found: ${expensesQuery.docs.length}');

      // Process expenses data by month
      Map<String, double> monthlyExpenses = {};
      Map<String, double> categoryTotals = {};

      for (var doc in expensesQuery.docs) {
        final data = doc.data();
        final receiptDateStr = data['receiptDate'] as String?;
        if (receiptDateStr == null || receiptDateStr.isEmpty) continue;

        final receiptDate = DateTime.parse(receiptDateStr);
        final monthKey =
            '${receiptDate.year}-${receiptDate.month.toString().padLeft(2, '0')}';
        final category = data['category'] ?? 'Others';
        final amount = _parseAmount(data['amount']);

        // Add to monthly totals
        monthlyExpenses[monthKey] = (monthlyExpenses[monthKey] ?? 0.0) + amount;

        // Add to category totals
        categoryTotals[category] = (categoryTotals[category] ?? 0.0) + amount;

        dev.log('Expense: $category - $amount - $monthKey');
      }

      dev.log('Monthly expenses before favorites: $monthlyExpenses');

      // Add favorites to monthly data properly
      await _addFavoritesToMonthlyData(monthlyExpenses, tenMonthsAgo, now);

      dev.log('Monthly expenses after favorites: $monthlyExpenses');

      // Store historical data (6-10 months for analysis)
      // Sort by month key to get the most recent months
      var sortedEntries = monthlyExpenses.entries.toList()
        ..sort(
            (a, b) => b.key.compareTo(a.key)); // Sort descending (newest first)

      // Take up to 10 months of data, or all available if less than 10
      // This ensures we use 6-10 months as specified
      var selectedEntries = sortedEntries.take(10).toList();

      historicalData.value = selectedEntries.map((entry) {
        return {
          'month': entry.key,
          'total': entry.value,
          'categories': categoryTotals,
        };
      }).toList();

      // Set the actual data duration used for prediction
      dataDurationMonths.value = historicalData.length;
      dev.log('Historical data fetched: ${historicalData.length} months');
      dev.log('Monthly expenses keys: ${monthlyExpenses.keys.toList()}');
      dev.log(
          'Selected entries: ${selectedEntries.map((e) => '${e.key}: ₱${e.value}').join(', ')}');
      dev.log(
          'Historical data: ${historicalData.map((d) => '${d['month']}: ₱${d['total']}').join(', ')}');
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

      // Get expenses from last 10 months (using receiptDate like dashboard)
      final expensesQuery = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: user.uid)
          .where('receiptDate',
              isGreaterThanOrEqualTo:
                  tenMonthsAgo.toIso8601String().split('T')[0])
          .orderBy('receiptDate', descending: false)
          .get();

      // Process expenses data by month
      Map<String, double> monthlyExpenses = {};

      for (var doc in expensesQuery.docs) {
        final data = doc.data();
        final receiptDateStr = data['receiptDate'] as String?;
        if (receiptDateStr == null || receiptDateStr.isEmpty) continue;

        final receiptDate = DateTime.parse(receiptDateStr);
        final monthKey =
            '${receiptDate.year}-${receiptDate.month.toString().padLeft(2, '0')}';
        final amount = _parseAmount(data['amount']);

        // Add to monthly totals
        monthlyExpenses[monthKey] = (monthlyExpenses[monthKey] ?? 0.0) + amount;
      }

      // Add favorites to monthly data properly
      await _addFavoritesToMonthlyData(monthlyExpenses, tenMonthsAgo, now);

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
      dev.log('Monthly expenses data: $monthlyExpenses');
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

  // Add favorites payments to monthly data properly
  Future<void> _addFavoritesToMonthlyData(Map<String, double> monthlyExpenses,
      DateTime startDate, DateTime endDate) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      dev.log('=== ADDING FAVORITES TO MONTHLY DATA ===');
      dev.log('Date range: $startDate to $endDate');

      // Get all favorites for the user
      final querySnapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: user.uid)
          .get();

      dev.log('Total favorites found: ${querySnapshot.docs.length}');

      // Process each favorite's payment history
      for (var doc in querySnapshot.docs) {
        final favoriteData = doc.data();
        String favoriteName = favoriteData['title'] ?? 'Unknown';
        List<Map<String, dynamic>> paymentHistory =
            List<Map<String, dynamic>>.from(
                favoriteData['paymentHistory'] ?? []);

        dev.log(
            'Processing favorite: $favoriteName with ${paymentHistory.length} payments');

        // Calculate payments made in each month
        for (var payment in paymentHistory) {
          final paymentDateRaw = payment['timestamp'];
          DateTime paymentDate;

          if (paymentDateRaw is Timestamp) {
            paymentDate = paymentDateRaw.toDate();
          } else if (paymentDateRaw is DateTime) {
            paymentDate = paymentDateRaw;
          } else {
            dev.log('Skipping invalid payment date: $paymentDateRaw');
            continue; // Skip invalid dates
          }

          // Check if payment is within the date range
          if (paymentDate
                  .isAfter(startDate.subtract(const Duration(days: 1))) &&
              paymentDate.isBefore(endDate)) {
            double amount = (payment['amount'] ?? 0.0).toDouble();
            final monthKey =
                '${paymentDate.year}-${paymentDate.month.toString().padLeft(2, '0')}';

            // Add to monthly expenses
            monthlyExpenses[monthKey] =
                (monthlyExpenses[monthKey] ?? 0.0) + amount;
            dev.log(
                'Added favorites payment: $favoriteName - $amount - $monthKey');
          } else {
            dev.log(
                'Payment outside date range: $favoriteName - ${payment['amount']} - $paymentDate');
          }
        }
      }

      dev.log('Final monthly expenses: $monthlyExpenses');
      dev.log('==========================================');
    } catch (e) {
      dev.log('Error adding favorites to monthly data: $e');
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
      // If no historical data, fetch current budget categories
      await _fetchCurrentBudgetCategories();
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

    // Fetch current budget categories from Firestore
    List<Map<String, dynamic>> currentBudgetCategories =
        await _fetchCurrentBudgetCategories();

    // Generate predictions only for categories that exist in current budget
    List<Map<String, dynamic>> predictions = [];
    double totalPredictedAmount = 0.0;

    for (var budgetCategory in currentBudgetCategories) {
      String categoryName = budgetCategory['name'];
      double categoryAmount = 0.0;
      double categoryPercentage = 0.0;

      if (categoryPercentages.containsKey(categoryName)) {
        // Category has historical data
        categoryPercentage =
            (categoryPercentages[categoryName]! / totalCategorySpending) * 100;
        categoryAmount = (predictedTotal * categoryPercentage) / 100;
      } else {
        // No historical data for this category, use a small default
        categoryPercentage = 5.0; // 5% default
        categoryAmount = predictedTotal * 0.05;
      }

      predictions.add({
        ...budgetCategory,
        'amount': categoryAmount,
        'prediction': true,
        'percentage': categoryPercentage,
      });

      totalPredictedAmount += categoryAmount;
    }

    // If no current budget categories exist, show empty state
    if (predictions.isEmpty) {
      budgetCategories.value = [];
      totalBudget.value = 0.0;
      dev.log('No current budget categories found');
      return;
    }

    budgetCategories.value = predictions;
    totalBudget.value = totalPredictedAmount;
    
    dev.log('Generated predictions for ${predictions.length} categories');
    dev.log('Total predicted budget: ${totalBudget.value}');
    dev.log(
        'Category percentages: ${budgetCategories.map((c) => '${c['name']}: ${c['percentage']}%').join(', ')}');
  }

  // Fetch current budget categories from Firestore
  Future<List<Map<String, dynamic>>> _fetchCurrentBudgetCategories() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      // Fetch all budgets for the user, ordered by most recent first
      final querySnapshot = await _firestore
          .collection('budget')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .get();

      // Group by category and keep only the most recent budget per category
      Map<String, Map<String, dynamic>> latestBudgets = {};
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final category = (data['category'] ?? '').toString();
        if (category.isEmpty) continue;

        // If this category hasn't been seen yet (or this is more recent due to ordering)
        if (!latestBudgets.containsKey(category)) {
          // Find matching template for icon and color
          Map<String, dynamic>? template = categoryTemplates.firstWhere(
            (t) => t['name'].toString().toLowerCase() == category.toLowerCase(),
            orElse: () => {
              'name': category,
              'icon': Icons.more_horiz,
              'color': Colors.grey
            },
          );

          latestBudgets[category] = {
            'name': category,
            'icon': template['icon'],
            'color': template['color'],
          };
        }
      }

      dev.log('Fetched ${latestBudgets.length} current budget categories');
      dev.log('Categories: ${latestBudgets.keys.join(', ')}');

      return latestBudgets.values.toList();
    } catch (e) {
      dev.log('Error fetching current budget categories: $e');
      return [];
    }
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

    // Use the tracked data duration for consistency
    int actualMonths = dataDurationMonths.value;
    String durationText =
        actualMonths == 1 ? "1 month" : "$actualMonths months";

    String insight =
        "Based on your spending patterns over the last $durationText:\n\n";
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

  // Save prediction to Firebase and prepare for next month
  // Can only be called on the last day of the month
  Future<void> savePrediction() async {
    try {
      // Check if it's the last day of the month
      final now = DateTime.now();
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
      
      if (now.day != lastDayOfMonth) {
        SnackbarService.showError(
            title: 'Not Available',
            message: 'You can only save predictions on the last day of the month (Day $lastDayOfMonth).');
        return;
      }

      isSaving.value = true;
      final user = _auth.currentUser;
      if (user != null) {
        // Save prediction data for next month
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
          'forMonth': '${now.year}-${(now.month + 1).toString().padLeft(2, '0')}', // Next month
          'appliedToNextMonth': false, // Will be set to true when applied
        }, SetOptions(merge: true));

        // Refresh saved predictions list
        await fetchSavedPredictions();

        SnackbarService.showSuccess(
            title: 'Success',
            message:
                'Prediction saved! Budget (₱${totalBudget.value.toStringAsFixed(2)}) will be automatically applied on the 1st of next month.');

        // Navigate back to home after successful save
        await Future.delayed(
            Duration(milliseconds: 500)); // Small delay to show success message
        Get.offAll(() =>
            BottomNavBar()); // Navigate to home and clear all previous routes
      }
    } catch (e) {
      SnackbarService.showError(
          title: 'Error', message: 'Failed to save prediction: $e');
    } finally {
      isSaving.value = false;
    }
  }

  // Check if today is the last day of the month
  bool isLastDayOfMonth() {
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
    return now.day == lastDayOfMonth;
  }



  // Fetch saved predictions
  Future<void> fetchSavedPredictions() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc =
          await _firestore.collection('predictionBudget').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        savedPredictions.value = [
          {
            'id': doc.id,
            'totalBudget': data['totalBudget'] ?? 0.0,
            'categories': data['categories'] ?? [],
            'insights': data['insights'] ?? '',
            'timestamp': data['timestamp'],
            'createdAt': data['createdAt'],
          }
        ];
        dev.log('Fetched saved predictions: ${savedPredictions.length}');
      } else {
        savedPredictions.value = [];
      }
    } catch (e) {
      dev.log('Error fetching saved predictions: $e');
      savedPredictions.value = [];
    }
  }

  // Generate PDF Report
  Future<void> generatePdfReport() async {
    try {
      isLoading.value = true;

      // Helper function to replace Unicode characters with ASCII equivalents for PDF
      String pdfSafeText(String text) {
        return text
            .replaceAll('₱', 'PHP ') // Replace peso sign with "PHP "
            .replaceAll('•', '*'); // Replace bullet with asterisk
      }

      // Load images
      final ByteData logoData = await rootBundle.load('assets/print/logo.png');
      final Uint8List logoBytes = logoData.buffer.asUint8List();
      final pw.MemoryImage logoImage = pw.MemoryImage(logoBytes);

      final ByteData printLogoData =
          await rootBundle.load('assets/print/print_logo.jpg');
      final Uint8List printLogoBytes = printLogoData.buffer.asUint8List();
      final pw.MemoryImage printLogoImage = pw.MemoryImage(printLogoBytes);

      // Create PDF document with font theme
      final pdf = pw.Document();

      // Get current date
      final now = DateTime.now();
      final dateFormat = DateFormat('MMMM dd, yyyy');
      final timeFormat = DateFormat('h:mm a');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          header: (pw.Context context) {
            return pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Image(logoImage, height: 50),
                pw.Image(printLogoImage, height: 50),
              ],
            );
          },
          footer: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.center,
              margin: const pw.EdgeInsets.only(top: 20),
              padding: const pw.EdgeInsets.symmetric(vertical: 10),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: PdfColors.grey300, width: 1),
                ),
              ),
              child: pw.Text(
                'Generated on ${dateFormat.format(now)} at ${timeFormat.format(now)}',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            );
          },
          build: (pw.Context context) {
            return [
              // Title
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Budget Prediction Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey900,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Summary Section
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Predicted Budget for Next Month',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'PHP ${totalBudget.value.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Based on your last ${dataDurationMonths.value} months of spending data',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Historical Data Section
              if (historicalData.isNotEmpty) ...[
                pw.Text(
                  'Historical Spending Summary',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Month',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Total Spent',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    ...historicalData.take(10).map((month) {
                      // Parse the month string (format: 'YYYY-MM') to DateTime
                      final monthStr = month['month'] as String;
                      DateTime monthDate;
                      try {
                        // Parse 'YYYY-MM' format and set to first day of month
                        final parts = monthStr.split('-');
                        if (parts.length == 2) {
                          monthDate = DateTime(
                            int.parse(parts[0]),
                            int.parse(parts[1]),
                            1,
                          );
                        } else {
                          monthDate = DateTime.now();
                        }
                      } catch (e) {
                        // Fallback to current date if parsing fails
                        monthDate = DateTime.now();
                      }
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              DateFormat('MMM yyyy').format(monthDate),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              pdfSafeText(
                                  '₱${(month['total'] as double).toStringAsFixed(2)}'),
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
                pw.SizedBox(height: 20),
              ],

              // Budget Categories Section
              pw.Text(
                'Predicted Budget by Category',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Category',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Amount',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Percentage',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  ...budgetCategories.map((category) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(category['name'] ?? 'N/A'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            pdfSafeText(
                                '₱${(category['amount'] as double?)?.toStringAsFixed(2) ?? '0.00'}'),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '${(category['percentage'] as double?)?.toStringAsFixed(1) ?? '0.0'}%',
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 20),

              // Insights Section
              if (insights.value.isNotEmpty) ...[
                pw.Text(
                  'Insights',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.blue200),
                  ),
                  child: pw.Text(
                    pdfSafeText(insights.value),
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey800,
                    ),
                  ),
                ),
              ],
            ];
          },
        ),
      );

      // Share or save PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );

      isLoading.value = false;
      SnackbarService.showSuccess(
        title: 'Success',
        message: 'PDF report generated successfully!',
      );
    } catch (e) {
      isLoading.value = false;
      dev.log('Error generating PDF: $e');
      SnackbarService.showError(
        title: 'Error',
        message: 'Failed to generate PDF report: $e',
      );
    }
  }
}
