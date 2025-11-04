import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snapwise/app/expense/view_expense.dart';
import 'package:snapwise/app/home/home_screens/home_controller.dart';
import 'package:snapwise/app/profile/favorites/favorite_controller.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  final HomeController controller = Get.put(HomeController());
  final FavoriteController favoriteController = Get.put(FavoriteController());
  final formatter = NumberFormat.currency(
    locale: 'en_PH',
    symbol: 'PHP ',
    decimalDigits: 2,
  );

  bool isSelecting = false;
  List<int> selectedIndices = [];
  bool get isTablet => MediaQuery.of(context).size.shortestSide > 600;

  // New variables for all records
  final RxList<Map<String, dynamic>> allRecords = <Map<String, dynamic>>[].obs;
  final RxBool isLoadingAllRecords = false.obs;
  bool showAllRecords = false;

  // Cache for favorites to avoid reactive dependency
  List<Map<String, dynamic>> _cachedFavorites = [];

  @override
  void initState() {
    super.initState();
    // Cache favorites data first, then load all records
    _cacheFavorites();

    // Ensure home controller data is loaded for today's transactions
    controller.refreshAllData();

    // Listen to favorites changes to update cache
    ever(favoriteController.favorites, (List<Map<String, dynamic>> favorites) {
      _cachedFavorites = List.from(favorites);
      if (showAllRecords) {
        fetchAllRecords();
      }
    });
  }

  // Cache favorites data to avoid reactive dependency
  void _cacheFavorites() {
    _cachedFavorites = List.from(favoriteController.favorites);
    fetchAllRecords();
  }

  // Function to fetch all records without any date filtering
  Future<void> fetchAllRecords() async {
    try {
      isLoadingAllRecords.value = true;
      allRecords.clear();

      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        isLoadingAllRecords.value = false;
        return;
      }

      // Fetch all expenses from Firestore
      final QuerySnapshot expensesSnapshot = await FirebaseFirestore.instance
          .collection('expenses')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .get();

      // Process regular expenses
      for (var doc in expensesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final timestamp = data['timestamp'] as Timestamp;
        final date = timestamp.toDate();

        // Parse receipt date and Posting Date
        DateTime? receiptDate;
        DateTime? transactionDate;

        if (data['receiptDate'] != null) {
          if (data['receiptDate'] is Timestamp) {
            receiptDate = (data['receiptDate'] as Timestamp).toDate();
          } else if (data['receiptDate'] is String) {
            receiptDate = DateTime.parse(data['receiptDate']);
          }
        }

        if (data['transactionDate'] != null) {
          if (data['transactionDate'] is Timestamp) {
            transactionDate = (data['transactionDate'] as Timestamp).toDate();
          } else if (data['transactionDate'] is String) {
            transactionDate = DateTime.parse(data['transactionDate']);
          }
        }

        allRecords.add({
          'id': doc.id,
          'type': 'expense',
          'title': data['category'] ?? 'Unknown',
          'amount': data['amount'] ?? 0.0,
          'date': receiptDate ??
              date, // Use receipt date if available, otherwise timestamp
          'icon': _getCategoryIcon(data['category'] ?? ''),
          'receiptDate': receiptDate,
          'transactionDate': transactionDate ??
              date, // Use Posting Date if available, otherwise timestamp
          'base64Image': data['base64Image'], // Add base64Image field
        });
      }

      // Fetch all favorites payments from cached data
      for (var favorite in _cachedFavorites) {
        final title = favorite['title'] ?? '';
        final history = favorite['paymentHistory'] as List? ?? [];

        for (var payment in history) {
          final paymentDateRaw = payment['timestamp'];
          final paymentDate = paymentDateRaw is Timestamp
              ? paymentDateRaw.toDate()
              : paymentDateRaw as DateTime;

          allRecords.add({
            'id': 'favorite_${favorite['id']}_${payment['timestamp']}',
            'type': 'favorite',
            'title': title,
            'amount': payment['amount'] ?? 0.0,
            'date': paymentDate,
            'icon': Icons.favorite,
            'favoriteId': favorite['id'],
            'receiptDate':
                paymentDate, // For favorites, receipt date is the same as payment date
            'transactionDate':
                paymentDate, // For favorites, Posting Date is the same as payment date
          });
        }
      }

      // Sort all records by date (newest first)
      allRecords.sort(
          (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

      isLoadingAllRecords.value = false;
    } catch (e) {
      isLoadingAllRecords.value = false;
      print('Error fetching all records: $e');
    }
  }

  // Helper function to get category icon
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'shopping':
        return Icons.shopping_bag;
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'rent':
        return Icons.home;
      case 'entertainment':
        return Icons.movie;
      default:
        return Icons.receipt;
    }
  }

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
        actions: [],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Beautiful Header Section
            _buildHeaderSection(),

            // Content based on toggle
            if (showAllRecords)
              Obx(() => _buildAllRecords())
            else
              FutureBuilder<Widget>(
                future: _buildTodayRecords(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(isTablet ? 32 : 24),
                        child: Column(
                          children: [
                            CircularProgressIndicator(
                              color: Colors.blue,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Loading today\'s transactions...',
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(isTablet ? 32 : 24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Error loading transactions',
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.red[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Please try again',
                              style: TextStyle(
                                fontSize: isTablet ? 14 : 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return snapshot.data ?? Container();
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Title and Record Count Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    showAllRecords ? 'All Records' : 'Payments Made Today',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isTablet ? 22 : 20,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  if (showAllRecords)
                    Obx(() => Text(
                          '${allRecords.length} total records',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: isTablet ? 16 : 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ))
                  else
                    Text(
                      'Recent transactions and today\'s payments',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              if (showAllRecords)
                IconButton(
                  onPressed: () {
                    _cacheFavorites(); // Refresh favorites cache and fetch records
                  },
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: Colors.blue,
                    size: 24,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: 20),

          // Toggle Switch Section
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today',
                  style: TextStyle(
                    color: !showAllRecords ? Colors.blue : Colors.grey[600],
                    fontWeight:
                        !showAllRecords ? FontWeight.bold : FontWeight.w500,
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
                Switch(
                  value: showAllRecords,
                  onChanged: (value) {
                    setState(() {
                      showAllRecords = value;
                    });
                    // Refresh cache when switching to All Records
                    if (value) {
                      _cacheFavorites();
                    }
                  },
                  activeColor: Colors.blue,
                  activeTrackColor: Colors.blue.shade200,
                  inactiveThumbColor: Colors.grey.shade400,
                  inactiveTrackColor: Colors.grey.shade300,
                ),
                Text(
                  'All Records',
                  style: TextStyle(
                    color: showAllRecords ? Colors.blue : Colors.grey[600],
                    fontWeight:
                        showAllRecords ? FontWeight.bold : FontWeight.w500,
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Fetch today's expenses directly from Firestore
  Future<void> _fetchTodayExpenses(List<Map<String, dynamic>> todayRecords,
      DateTime startOfToday, DateTime endOfToday) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Fetch all expenses from Firestore
      final QuerySnapshot expensesSnapshot = await FirebaseFirestore.instance
          .collection('expenses')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .get();

      print('Fetched ${expensesSnapshot.docs.length} expenses from Firestore');

      for (var doc in expensesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Check if expense is from today based on receipt date (preferred) or timestamp
        bool isToday = false;
        DateTime? expenseDate;

        // First try receipt date
        if (data['receiptDate'] != null &&
            data['receiptDate'].toString().isNotEmpty) {
          try {
            if (data['receiptDate'] is Timestamp) {
              expenseDate = (data['receiptDate'] as Timestamp).toDate();
            } else if (data['receiptDate'] is String) {
              expenseDate = DateTime.parse(data['receiptDate']);
            }

            if (expenseDate != null) {
              isToday = expenseDate
                      .isAfter(startOfToday.subtract(Duration(seconds: 1))) &&
                  expenseDate.isBefore(endOfToday.add(Duration(seconds: 1)));
              print('Checking receipt date: $expenseDate - isToday: $isToday');
            }
          } catch (e) {
            print('Error parsing receipt date: $e');
          }
        }

        // If receipt date is not available or not today, check timestamp
        if (!isToday) {
          try {
            DateTime timestamp = (data['timestamp'] as Timestamp).toDate();
            isToday = timestamp
                    .isAfter(startOfToday.subtract(Duration(seconds: 1))) &&
                timestamp.isBefore(endOfToday.add(Duration(seconds: 1)));
            expenseDate = timestamp;
            print('Checking timestamp: $timestamp - isToday: $isToday');
          } catch (e) {
            print('Error parsing timestamp: $e');
          }
        }

        if (isToday && expenseDate != null) {
          // Get category icon
          IconData categoryIcon = _getCategoryIcon(data['category'] ?? '');

          todayRecords.add({
            'id': doc.id,
            'type': 'expense',
            'title': data['category'] ?? 'Unknown',
            'amount': '-${data['amount'].toStringAsFixed(2)}',
            'date': expenseDate,
            'icon': categoryIcon,
            'isClickable': true,
          });

          print(
              'Added expense: ${data['category']} - ${data['amount']} - $expenseDate');
        }
      }
    } catch (e) {
      print('Error fetching today expenses: $e');
    }
  }

  // REMOVED: Duplicate _getCategoryIcon method

  // Build today's records (both expenses and favorite payments)
  Future<Widget> _buildTodayRecords() async {
    final todayRecords = <Map<String, dynamic>>[];
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // Debug logging
    print('=== BUILDING TODAY RECORDS ===');
    print('Current time: $now');
    print('Start of today: $startOfToday');
    print('End of today: $endOfToday');
    print(
        'Transactions from home controller: ${controller.transactionsHistory.length}');

    // Fetch today's expenses directly from Firestore
    // This ensures we get expenses based on their receipt date, not creation date
    await _fetchTodayExpenses(todayRecords, startOfToday, endOfToday);

    // Add today's favorite payments
    for (var fav in favoriteController.favorites) {
      final title = fav['title'] ?? '';
      final history = fav['paymentHistory'] as List? ?? [];
      for (var payment in history) {
        final paymentDateRaw = payment['timestamp'];
        final paymentDate = paymentDateRaw is Timestamp
            ? paymentDateRaw.toDate()
            : paymentDateRaw as DateTime;

        if (paymentDate.isAfter(startOfToday.subtract(Duration(seconds: 1))) &&
            paymentDate.isBefore(endOfToday.add(Duration(seconds: 1)))) {
          todayRecords.add({
            'id': 'favorite_${fav['id']}_${payment['timestamp']}',
            'type': 'favorite',
            'title': title,
            'amount': payment['amount'],
            'date': paymentDate,
            'icon': Icons.favorite,
            'isClickable': true,
          });
        }
      }
    }

    // Sort by date (newest first)
    todayRecords.sort(
        (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    // Debug logging
    print('Final today records count: ${todayRecords.length}');
    for (var record in todayRecords) {
      print(
          'Record: ${record['type']} - ${record['title']} - ${record['date']}');
    }
    print('===============================');

    if (todayRecords.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 32 : 24),
          child: Column(
            children: [
              Icon(
                Icons.today,
                size: 64,
                color: Colors.grey[400],
              ),
              SizedBox(height: 16),
              Text(
                'No transactions today',
                style: TextStyle(
                  fontSize: isTablet ? 20 : 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Your transactions for today will appear here',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: todayRecords.length,
      itemBuilder: (context, index) {
        final record = todayRecords[index];
        return GestureDetector(
          onTap: () {
            if (record['isClickable'] == true) {
              if (record['type'] == 'expense') {
                // Navigate to expense details
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ViewExpense(expenseId: record['id']),
                  ),
                );
              } else if (record['type'] == 'favorite') {
                // Show favorite payment details
                _showFavoritePaymentDetails(record);
              }
            }
          },
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: record['type'] == 'favorite'
                              ? Colors.pink.shade50
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          record['icon'],
                          color: record['type'] == 'favorite'
                              ? Colors.pink
                              : Colors.blue,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record['title'],
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: isTablet ? 16 : 14,
                              color: Colors.grey[800],
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            DateFormat('MMM d, yyyy • h:mm a')
                                .format(record['date']),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: isTablet ? 14 : 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        record['type'] == 'favorite'
                            ? '₱${record['amount'].toStringAsFixed(2)}'
                            : record['amount'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isTablet ? 16 : 14,
                          color: record['type'] == 'favorite'
                              ? Colors.pink
                              : Colors.red,
                        ),
                      ),
                      SizedBox(height: 2),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: record['type'] == 'favorite'
                              ? Colors.pink.shade50
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          record['type'] == 'favorite' ? 'Favorite' : 'Expense',
                          style: TextStyle(
                            color: record['type'] == 'favorite'
                                ? Colors.pink
                                : Colors.blue,
                            fontSize: isTablet ? 12 : 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAllRecords() {
    if (isLoadingAllRecords.value) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(50.0),
          child: CircularProgressIndicator(
            color: Colors.blue,
          ),
        ),
      );
    }

    if (allRecords.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(50.0),
          child: Column(
            children: [
              Icon(
                Icons.history,
                size: 64,
                color: Colors.grey[400],
              ),
              SizedBox(height: 16),
              Text(
                'No records found',
                style: TextStyle(
                  fontSize: isTablet ? 20 : 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Start adding expenses to see your history',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: allRecords.length,
      itemBuilder: (context, index) {
        final record = allRecords[index];
        return GestureDetector(
          onTap: () {
            if (record['type'] == 'favorite') {
              _showFavoritePaymentDetails(record);
            } else {
              _showExpenseDetails(record);
            }
          },
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: record['type'] == 'favorite'
                              ? Colors.pink.shade50
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          record['icon'],
                          color: record['type'] == 'favorite'
                              ? Colors.pink
                              : Colors.blue,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                record['title'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: record['type'] == 'favorite'
                                      ? Colors.pink.shade100
                                      : Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  record['type'] == 'favorite'
                                      ? 'Favorite'
                                      : 'Expense',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: record['type'] == 'favorite'
                                        ? Colors.pink.shade700
                                        : Colors.blue.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            DateFormat('MMM d, yyyy • h:mm a')
                                .format(record['date']),
                            style:
                                TextStyle(color: Colors.black45, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    '-${formatter.format(record['amount']).replaceAll('PHP ', '')}',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // REMOVED: _buildTransactionsList method - replaced with _buildTodayRecords

  // Show favorite payment details with modern UI
  void _showFavoritePaymentDetails(Map<String, dynamic> payment) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: isTablet ? MediaQuery.of(context).size.width * 0.6 : null,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(isTablet ? 28 : 24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Beautiful Header Section
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isTablet ? 24 : 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isTablet ? 28 : 24),
                        topRight: Radius.circular(isTablet ? 28 : 24),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Header Row
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(isTablet ? 12 : 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius:
                                    BorderRadius.circular(isTablet ? 16 : 12),
                              ),
                              child: Icon(
                                Icons.favorite,
                                color: Colors.white,
                                size: isTablet ? 28 : 24,
                              ),
                            ),
                            SizedBox(width: isTablet ? 16 : 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Favorite Payment Details',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isTablet ? 24 : 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Payment Information',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: isTablet ? 16 : 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Custom Close Button
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                padding: EdgeInsets.all(isTablet ? 8 : 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius:
                                      BorderRadius.circular(isTablet ? 12 : 8),
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: isTablet ? 20 : 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Content Section
                  Padding(
                    padding: EdgeInsets.all(isTablet ? 24 : 20),
                    child: Column(
                      children: [
                        // Amount Spent Card
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(isTablet ? 24 : 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFE91E63).withOpacity(0.1),
                                Color(0xFF9C27B0).withOpacity(0.1)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius:
                                BorderRadius.circular(isTablet ? 20 : 16),
                            border: Border.all(
                              color: Color(0xFFE91E63).withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Amount Paid',
                                style: TextStyle(
                                  color: Color(0xFFE91E63),
                                  fontSize: isTablet ? 16 : 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: isTablet ? 8 : 6),
                              Text(
                                '₱${payment['amount'].toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Color(0xFF2c3e50),
                                  fontSize: isTablet ? 32 : 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: isTablet ? 24 : 20),

                        // Payment Details Section
                        Text(
                          'Payment Details',
                          style: TextStyle(
                            fontSize: isTablet ? 20 : 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2c3e50),
                          ),
                        ),
                        SizedBox(height: isTablet ? 16 : 12),

                        // Modern Detail Rows
                        _buildModernDetailRow(
                          Icons.title,
                          'Payment Title',
                          payment['title'] ?? 'N/A',
                          Color(0xFFE91E63),
                        ),
                        _buildModernDetailRow(
                          Icons.calendar_today,
                          'Payment Date',
                          DateFormat('MMM d, yyyy • h:mm a')
                              .format(payment['date']),
                          Color(0xFF9C27B0),
                        ),
                        if (payment['transactionDate'] != null)
                          _buildModernDetailRow(
                            Icons.schedule,
                            'Posting Date',
                            DateFormat('MMM d, yyyy • h:mm a')
                                .format(payment['transactionDate']),
                            Color(0xFF673AB7),
                          ),
                        _buildModernDetailRow(
                          Icons.favorite,
                          'Payment Type',
                          'Favorite Payment',
                          Color(0xFFE91E63),
                        ),

                        SizedBox(height: isTablet ? 24 : 20),

                        // Close Button
                        Container(
                          width: double.infinity,
                          height: isTablet ? 56 : 48,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFE91E63),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(isTablet ? 16 : 12),
                              ),
                            ),
                            child: Text(
                              'Close',
                              style: TextStyle(
                                fontSize: isTablet ? 18 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Show expense details
  void _showExpenseDetails(Map<String, dynamic> expense) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.85,
              maxWidth: isTablet ? screenWidth * 0.6 : screenWidth * 0.9,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient background
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF667eea),
                        Color(0xFF764ba2),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isTablet ? 24 : 20),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isTablet ? 12 : 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            expense['icon'],
                            color: Colors.white,
                            size: isTablet ? 32 : 28,
                          ),
                        ),
                        SizedBox(width: isTablet ? 16 : 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Expense Details',
                                style: TextStyle(
                                  fontSize: isTablet ? 26 : 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Transaction Information',
                                style: TextStyle(
                                  fontSize: isTablet ? 16 : 14,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: isTablet ? 24 : 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Content area
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isTablet ? 24 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Amount card
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(isTablet ? 20 : 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFff6b6b),
                                Color(0xFFee5a24),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFFff6b6b).withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 0,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Amount Spent',
                                style: TextStyle(
                                  fontSize: isTablet ? 18 : 16,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '₱${expense['amount'].toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: isTablet ? 32 : 28,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: isTablet ? 24 : 20),

                        // Details section
                        Text(
                          'Transaction Details',
                          style: TextStyle(
                            fontSize: isTablet ? 20 : 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2c3e50),
                          ),
                        ),
                        SizedBox(height: isTablet ? 16 : 12),

                        _buildModernDetailRow(
                          Icons.category,
                          'Category',
                          expense['title'],
                          Color(0xFF3498db),
                        ),
                        _buildModernDetailRow(
                          Icons.calendar_today,
                          'Receipt Date',
                          DateFormat('MMM d, yyyy • h:mm a')
                              .format(expense['date']),
                          Color(0xFF9b59b6),
                        ),
                        if (expense['transactionDate'] != null)
                          _buildModernDetailRow(
                            Icons.access_time,
                            'Posting Date',
                            DateFormat('MMM d, yyyy • h:mm a')
                                .format(expense['transactionDate']),
                            Color(0xFFe67e22),
                          ),
                        _buildModernDetailRow(
                          Icons.receipt,
                          'Type',
                          'Expense',
                          Color(0xFF27ae60),
                        ),

                        // Add image section if image is available
                        if (expense['base64Image'] != null &&
                            expense['base64Image'].toString().isNotEmpty &&
                            expense['base64Image'] != 'No Image')
                          Column(
                            children: [
                              SizedBox(height: isTablet ? 24 : 20),
                              Text(
                                'Receipt Image',
                                style: TextStyle(
                                  fontSize: isTablet ? 20 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2c3e50),
                                ),
                              ),
                              SizedBox(height: isTablet ? 16 : 12),
                              GestureDetector(
                                onTap: () =>
                                    _showImagePopup(expense['base64Image']),
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxHeight: screenHeight * 0.25,
                                    maxWidth: double.infinity,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        spreadRadius: 0,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Stack(
                                      children: [
                                        Builder(
                                          builder: (context) {
                                            try {
                                              return Image.memory(
                                                base64Decode(
                                                    expense['base64Image']),
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                              );
                                            } catch (e) {
                                              return Container(
                                                height: 120,
                                                color: Colors.grey.shade100,
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.broken_image,
                                                      color:
                                                          Colors.grey.shade400,
                                                      size: isTablet ? 40 : 30,
                                                    ),
                                                    SizedBox(height: 8),
                                                    Text(
                                                      'Unable to display image',
                                                      style: TextStyle(
                                                        color: Colors
                                                            .grey.shade500,
                                                        fontSize:
                                                            isTablet ? 16 : 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                        // Add overlay to indicate image is clickable
                                        Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.black.withOpacity(0.3),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Center(
                                              child: Container(
                                                padding: EdgeInsets.all(
                                                    isTablet ? 12 : 8),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.9),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.zoom_in,
                                                      color: Color(0xFF667eea),
                                                      size: isTablet ? 20 : 16,
                                                    ),
                                                    SizedBox(width: 6),
                                                    Text(
                                                      'Tap to view',
                                                      style: TextStyle(
                                                        color:
                                                            Color(0xFF667eea),
                                                        fontSize:
                                                            isTablet ? 14 : 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),

                // Footer with close button
                Container(
                  padding: EdgeInsets.fromLTRB(
                    isTablet ? 24 : 20,
                    isTablet ? 16 : 12,
                    isTablet ? 24 : 20,
                    isTablet ? 24 : 20,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF667eea),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 18 : 16,
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isTablet ? 18 : 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Show image popup dialog
  void _showImagePopup(String base64Image) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.9,
              maxWidth: isTablet ? screenWidth * 0.8 : screenWidth * 0.95,
            ),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with close button
                Container(
                  padding: EdgeInsets.all(isTablet ? 20 : 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Receipt Image',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? 22 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: isTablet ? 24 : 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Image content
                Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: isTablet ? 20 : 16,
                      vertical: isTablet ? 10 : 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Builder(
                        builder: (context) {
                          try {
                            return InteractiveViewer(
                              panEnabled: true,
                              boundaryMargin: EdgeInsets.all(20),
                              minScale: 0.5,
                              maxScale: 4.0,
                              child: Image.memory(
                                base64Decode(base64Image),
                                fit: BoxFit.contain,
                              ),
                            );
                          } catch (e) {
                            return Container(
                              height: 200,
                              color: Colors.grey.shade300,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    color: Colors.grey.shade600,
                                    size: isTablet ? 60 : 40,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Unable to display image',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: isTablet ? 18 : 16,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ),

                // Bottom padding
                SizedBox(height: isTablet ? 20 : 16),
              ],
            ),
          ),
        );
      },
    );
  }

  // REMOVED: Old _buildDetailRow method - replaced with modern _buildModernDetailRow

  // Modern detail row with icons and better styling
  Widget _buildModernDetailRow(
      IconData icon, String label, String value, Color iconColor) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 10 : 8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: isTablet ? 20 : 18,
            ),
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2c3e50),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
