import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snapwise/app/profile/favorites/favorite_controller.dart';
import 'package:snapwise/app/widget/bottomnavbar.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({Key? key}) : super(key: key);

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  int selectedTab = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final controller = Get.put(FavoriteController());

  List<String> get statusTabs => ['Paid', 'Pending', 'Missed'];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed:
              () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => BottomNavBar(initialIndex: 3),
                ),
              ),
        ),
        title: Text(
          'Favorites',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Obx(() {
        // Filter bills based on selected tab and search query
        final filteredBills =
            controller.favorites.where((bill) {
              final matchesTab = bill['status'] == statusTabs[selectedTab];
              final matchesSearch = bill['title']
                  .toString()
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase());
              return matchesTab && matchesSearch;
            }).toList();

        // Calculate totals
        double totalAmount = 0;
        double totalPaid = 0;
        for (var bill in controller.favorites) {
          totalAmount += (bill['totalAmount'] ?? 0).toDouble();
          totalPaid += (bill['paidAmount'] ?? 0).toDouble();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _summaryCard(
                    'Total\nPayment',
                    'PHP ${totalAmount.toStringAsFixed(2)}',
                  ),
                  _summaryCard(
                    'Total Paid\nPayment',
                    'PHP ${totalPaid.toStringAsFixed(2)}',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _searchBar(),
              const SizedBox(height: 16),
              _tabBar(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All your upcoming payments Displayed here',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.add_box_outlined),
                        onPressed:
                            () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => BottomNavBar(initialIndex: 15),
                              ),
                            ),
                      ),
                      IconButton(
                        icon: Icon(Icons.history_rounded),
                        onPressed:
                            () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => BottomNavBar(initialIndex: 13),
                              ),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (filteredBills.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      'No bills found.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...filteredBills.map((bill) => _billCard(bill)),
            ],
          ),
        );
      }),
    );
  }

  Widget _summaryCard(String title, String amount) {
    return Container(
      width: 180,
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Color(0xFF2B2E4A), Color(0xFF6A4DFE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(2, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            'This Month',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      decoration: InputDecoration(
        suffixIcon: Icon(Icons.search),
        hintText: 'Search',
        filled: true,
        fillColor: Color(0xFFF3F3F3),
        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _tabBar() {
    final tabs = [
      {'icon': Icons.assignment_rounded, 'label': 'Paid'},
      {'icon': Icons.access_time, 'label': 'Pending'},
      {'icon': Icons.credit_card_off, 'label': 'Missed'},
    ];
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(tabs.length, (index) {
          final selected = selectedTab == index;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => setState(() => selectedTab = index),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration:
                    selected
                        ? BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        )
                        : null,
                child: Column(
                  children: [
                    Icon(
                      tabs[index]['icon'] as IconData,
                      size: 20,
                      color: selected ? Color(0xFF6A4DFE) : Colors.black54,
                    ),
                    SizedBox(height: 4),
                    Text(
                      tabs[index]['label'] as String,
                      style: TextStyle(
                        color: selected ? Color(0xFF6A4DFE) : Colors.black54,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _billCard(Map<String, dynamic> bill) {
    Color statusColor;
    switch (bill['status']) {
      case 'Paid':
        statusColor = Colors.green;
        break;
      case 'Missed':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  bill['title'] ?? '',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    bill['status'] ?? 'Pending',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'PHP ${bill['totalAmount']?.toStringAsFixed(2) ?? '0.00'}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            SizedBox(height: 4),
            Text(
              bill['frequency'] ?? '',
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'End Date: ${DateFormat('MMMM d, yyyy').format(DateTime.parse(bill['endDate'] ?? ''))}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                TextButton(
                  onPressed: () => _showBillDetails(context, bill),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size(80, 30),
                  ),
                  child: Text('View Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBillDetails(BuildContext context, Map<String, dynamic> bill) {
    final formatter = NumberFormat.currency(
      locale: 'en_PH',
      symbol: 'PHP ',
      decimalDigits: 2,
    );
    double totalAmount = (bill['totalAmount'] ?? 0).toDouble();
    double amountToPay = (bill['amountToPay'] ?? 0).toDouble();
    double remaining = totalAmount - amountToPay;

    // Check if paid today
    bool paidToday = false;
    if ((bill['paymentHistory'] as List?)?.isNotEmpty ?? false) {
      paidToday = (bill['paymentHistory'] as List).any((payment) {
        final paymentDateRaw = payment['timestamp'];
        final paymentDate =
            paymentDateRaw is Timestamp
                ? paymentDateRaw.toDate()
                : paymentDateRaw as DateTime;
        final now = DateTime.now();
        return paymentDate.year == now.year &&
            paymentDate.month == now.month &&
            paymentDate.day == now.day;
      });
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with gradient background
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2B2E4A), Color(0xFF6A4DFE)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          bill['title'] ?? '',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            bill['status'] ?? 'Pending',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 15),

                  // Amount Section
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFFF8F9FE),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Amount',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              formatter.format(totalAmount),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                color: Color(0xFF2B2E4A),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFF6A4DFE).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                bill['frequency'] ?? '',
                                style: TextStyle(
                                  color: Color(0xFF6A4DFE),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Payment Details
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFFF8F9FE),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          'Amount to Pay',
                          formatter.format(amountToPay),
                        ),
                        Divider(height: 24),
                        _buildDetailRow(
                          'Paid Amount',
                          formatter.format(bill['paidAmount'] ?? 0.0),
                        ),
                        Divider(height: 24),
                        _buildDetailRow(
                          'Remaining',
                          formatter.format(remaining),
                        ),
                        Divider(height: 24),
                        _buildDetailRow(
                          bill['status'] == 'Paid' ? 'Status' : 'Final Status',
                          bill['status'] ?? 'Pending',
                          valueColor:
                              bill['status'] == 'Paid'
                                  ? Colors.green
                                  : Colors.orange,
                        ),
                        SizedBox(height: 16),
                        LinearProgressIndicator(
                          value:
                              (bill['paidAmount'] ?? 0.0) /
                              (bill['totalAmount'] ?? 1.0),
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            (bill['paidAmount'] ?? 0.0) >=
                                    (bill['totalAmount'] ?? 0.0)
                                ? Colors.green
                                : Color(0xFF6A4DFE),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Date Details
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFFF8F9FE),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          'Start Date',
                          bill['startDate'] != null &&
                                  bill['startDate'].toString().isNotEmpty
                              ? DateFormat(
                                'MMMM d, yyyy',
                              ).format(DateTime.parse(bill['startDate']))
                              : 'Not set',
                        ),
                        Divider(height: 24),
                        _buildDetailRow(
                          'End Date',
                          bill['endDate'] != null &&
                                  bill['endDate'].toString().isNotEmpty
                              ? DateFormat(
                                'MMMM d, yyyy',
                              ).format(DateTime.parse(bill['endDate']))
                              : 'Not set',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 15),
                  if (bill['status'] == 'Paid')
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Fully Paid',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  else
                    ElevatedButton(
                      onPressed:
                          paidToday
                              ? null
                              : () async {
                                await controller.updatePaymentStatus(
                                  bill['id'],
                                  bill['amountToPay'] ?? 0.0,
                                );
                                Navigator.pop(context);
                              },
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                        backgroundColor: Colors.green.shade500,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      child: Text(
                        paidToday ? 'Already Paid Today' : 'Pay Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  SizedBox(height: 15),
                  if ((bill['paymentHistory'] as List?)?.isNotEmpty ?? false)
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFFF8F9FE),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment History',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF2B2E4A),
                            ),
                          ),
                          SizedBox(height: 12),
                          ...(bill['paymentHistory'] as List).map((payment) {
                            final paymentDateRaw = payment['timestamp'];
                            final paymentDate =
                                paymentDateRaw is Timestamp
                                    ? paymentDateRaw.toDate()
                                    : paymentDateRaw as DateTime;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _getPaymentTimeText(paymentDate),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    formatter.format(payment['amount']),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF2B2E4A),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  SizedBox(height: 15),
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF2B2E4A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                          ),
                          child: Text(
                            'Close',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await controller.deleteFavorite(bill['id']);
                            await controller.setupFavoritesStream();
                            Get.snackbar(
                              'Success',
                              'Favorite deleted successfully',
                            );
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                          ),
                          child: Text(
                            'Delete',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
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
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: valueColor ?? Color(0xFF2B2E4A),
          ),
        ),
      ],
    );
  }

  String _getPaymentTimeText(DateTime paymentDate) {
    final now = DateTime.now();
    final difference = now.difference(paymentDate);

    if (difference.inDays == 0) {
      return 'Paid Today';
    } else if (difference.inDays < 7) {
      return 'Paid This Week';
    } else if (difference.inDays < 30) {
      return 'Paid This Month';
    } else if (difference.inDays < 365) {
      return 'Paid This Year';
    } else {
      return 'Paid ${DateFormat('yyyy').format(paymentDate)}';
    }
  }
}
