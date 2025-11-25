import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snapwise/app/profile/favorites/favorite_controller.dart';
import 'package:snapwise/app/widget/bottomnavbar.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/snackbar_service.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({Key? key}) : super(key: key);

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> with SingleTickerProviderStateMixin {
  int selectedTab = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final controller = Get.put(FavoriteController());
  late AnimationController _animationController;

  List<String> get statusTabs => ['Paid', 'Pending', 'Missed'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return Scaffold(
      backgroundColor: Color(0xFFF8F9FE),
      appBar: AppBar(
        leading: Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => BottomNavBar(initialIndex: 3),
              ),
            ),
          ),
        ),
        title: Text(
          'Favorites',
          style: TextStyle(
            color: Color(0xFF2B2E4A),
            fontSize: isTablet ? 26 : 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFFF8F9FE),
        foregroundColor: Color(0xFF2B2E4A),
      ),
      body: Obx(() {
        final filteredBills = controller.favorites.where((bill) {
          final matchesTab = bill['status'] == statusTabs[selectedTab];
          final matchesSearch = bill['title']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
          return matchesTab && matchesSearch;
        }).toList();

        double totalAmount = 0;
        double totalPaid = 0;
        for (var bill in controller.favorites) {
          totalAmount += (bill['totalAmount'] ?? 0).toDouble();
          totalPaid += (bill['paidAmount'] ?? 0).toDouble();
        }

        return SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 24 : 16,
            vertical: isTablet ? 16 : 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeTransition(
                opacity: _animationController,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final availableWidth = constraints.maxWidth;
                    final isVerySmallScreen = availableWidth < 350;

                    if (isVerySmallScreen) {
                      return Column(
                        children: [
                          _modernSummaryCard(
                            'Total Payment',
                            totalAmount,
                            Icons.account_balance_wallet_rounded,
                            [Color(0xFF1E3A5F), Color(0xFF2B2E4A)],
                            isTablet: isTablet,
                          ),
                          SizedBox(height: 16),
                          _modernSummaryCard(
                            'Total Paid',
                            totalPaid,
                            Icons.check_circle_rounded,
                            [Color(0xFF10B981), Color(0xFF059669)],
                            isTablet: isTablet,
                          ),
                        ],
                      );
                    } else {
                      return Row(
                        children: [
                          Expanded(
                            child: _modernSummaryCard(
                              'Total Payment',
                              totalAmount,
                              Icons.account_balance_wallet_rounded,
                              [Color(0xFF1E3A5F), Color(0xFF2B2E4A)],
                              isTablet: isTablet,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: _modernSummaryCard(
                              'Total Paid',
                              totalPaid,
                              Icons.check_circle_rounded,
                              [Color(0xFF10B981), Color(0xFF059669)],
                              isTablet: isTablet,
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
              SizedBox(height: isTablet ? 28 : 24),
              _modernSearchBar(isTablet: isTablet),
              SizedBox(height: isTablet ? 24 : 20),
              _modernTabBar(isTablet: isTablet),
              SizedBox(height: isTablet ? 20 : 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'All your upcoming payments',
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      _modernIconButton(
                        Icons.add_circle_outline_rounded,
                        () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BottomNavBar(initialIndex: 15),
                          ),
                        ),
                        isTablet: isTablet,
                      ),
                      SizedBox(width: 8),
                      _modernIconButton(
                        Icons.history_rounded,
                        () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BottomNavBar(initialIndex: 13),
                          ),
                        ),
                        isTablet: isTablet,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: isTablet ? 16 : 12),
              if (filteredBills.isEmpty)
                _emptyState(isTablet: isTablet)
              else
                ...filteredBills.asMap().entries.map((entry) {
                  final index = entry.key;
                  final bill = entry.value;
                  return TweenAnimationBuilder(
                    duration: Duration(milliseconds: 300 + (index * 50)),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, double value, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      );
                    },
                    child: _modernBillCard(bill, isTablet: isTablet),
                  );
                }),
              SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }

  String _formatCompactCurrency(double amount) {
    if (amount >= 1000000000) {
      return 'PHP ${(amount / 1000000000).toStringAsFixed(2)}B';
    } else if (amount >= 1000000) {
      return 'PHP ${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 10000) { // Only compact if >= 10k to keep precision for smaller amounts
      return 'PHP ${(amount / 1000).toStringAsFixed(2)}K';
    } else {
      return NumberFormat.currency(
        locale: 'en_PH',
        symbol: 'PHP ',
        decimalDigits: 2,
      ).format(amount);
    }
  }

  Widget _modernSummaryCard(
    String title,
    double amount,
    IconData icon,
    List<Color> gradientColors, {
    bool isTablet = false,
  }) {
    return Container(
      height: isTablet ? 140 : 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: EdgeInsets.all(isTablet ? 18 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: isTablet ? 14 : 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.all(isTablet ? 9 : 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: isTablet ? 20 : 16,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _formatCompactCurrency(amount),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 22 : 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              SizedBox(height: 2),
              Text(
                'This Month',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: isTablet ? 11 : 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modernSearchBar({bool isTablet = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Color(0xFF2B2E4A),
            size: isTablet ? 26 : 22,
          ),
          hintText: 'Search payments...',
          hintStyle: TextStyle(
            fontSize: isTablet ? 16 : 14,
            color: Colors.grey[400],
          ),
          filled: false,
          contentPadding: EdgeInsets.symmetric(
            vertical: isTablet ? 18 : 16,
            horizontal: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        style: TextStyle(fontSize: isTablet ? 16 : 14),
      ),
    );
  }

  Widget _modernTabBar({bool isTablet = false}) {
    final tabs = [
      {'icon': Icons.check_circle_rounded, 'label': 'Paid'},
      {'icon': Icons.schedule_rounded, 'label': 'Pending'},
      {'icon': Icons.error_outline_rounded, 'label': 'Missed'},
    ];

    return Container(
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = selectedTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedTab = index),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: isTablet ? 14 : 12),
                decoration: selected
                    ? BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1E3A5F), Color(0xFF2B2E4A)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF2B2E4A).withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      )
                    : null,
                child: Column(
                  children: [
                    Icon(
                      tabs[index]['icon'] as IconData,
                      size: isTablet ? 24 : 20,
                      color: selected ? Colors.white : Colors.grey[400],
                    ),
                    SizedBox(height: isTablet ? 6 : 4),
                    Text(
                      tabs[index]['label'] as String,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.grey[600],
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: isTablet ? 14 : 12,
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

  Widget _modernIconButton(IconData icon, VoidCallback onPressed, {bool isTablet = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Color(0xFF2B2E4A)),
        iconSize: isTablet ? 24 : 20,
        onPressed: onPressed,
      ),
    );
  }

  Widget _emptyState({bool isTablet = false}) {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: isTablet ? 60 : 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 32 : 24),
              decoration: BoxDecoration(
                color: Color(0xFF2B2E4A).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: isTablet ? 64 : 48,
                color: Color(0xFF2B2E4A),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'No bills found',
              style: TextStyle(
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2B2E4A),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Start adding your payment reminders',
              style: TextStyle(
                fontSize: isTablet ? 15 : 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _modernBillCard(Map<String, dynamic> bill, {bool isTablet = false}) {
    Color statusColor;
    Color statusBgColor;
    switch (bill['status']) {
      case 'Paid':
        statusColor = Color(0xFF10B981);
        statusBgColor = Color(0xFF10B981).withOpacity(0.1);
        break;
      case 'Missed':
        statusColor = Color(0xFFEF4444);
        statusBgColor = Color(0xFFEF4444).withOpacity(0.1);
        break;
      default:
        statusColor = Color(0xFFF59E0B);
        statusBgColor = Color(0xFFF59E0B).withOpacity(0.1);
    }

    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showBillDetails(context, bill),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 24 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bill['title'] ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isTablet ? 20 : 18,
                              color: Color(0xFF2B2E4A),
                            ),
                          ),
                          if (bill['status'] == 'Paid' &&
                              (bill['paymentHistory'] as List?)?.isNotEmpty == true)
                            Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                _getPaymentDateText(bill['paymentHistory'] as List),
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: isTablet ? 13 : 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 16 : 14,
                        vertical: isTablet ? 8 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        bill['status'] ?? 'Pending',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: isTablet ? 14 : 13,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isTablet ? 16 : 14),
                Text(
                  _formatCompactCurrency((bill['totalAmount'] ?? 0).toDouble()),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isTablet ? 28 : 24,
                    color: Color(0xFF2B2E4A),
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFF2B2E4A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    bill['frequency'] ?? '',
                    style: TextStyle(
                      color: Color(0xFF2B2E4A),
                      fontSize: isTablet ? 14 : 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: isTablet ? 16 : 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: isTablet ? 16 : 14,
                          color: Colors.grey[500],
                        ),
                        SizedBox(width: 6),
                        Text(
                          DateFormat('MMM d, yyyy').format(DateTime.parse(bill['endDate'] ?? '')),
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: isTablet ? 16 : 14,
                      color: Color(0xFF2B2E4A),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBillDetails(BuildContext context, Map<String, dynamic> bill) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    final formatter = NumberFormat.currency(
      locale: 'en_PH',
      symbol: 'PHP ',
      decimalDigits: 2,
    );
    double totalAmount = (bill['totalAmount'] ?? 0).toDouble();
    double amountToPay = (bill['amountToPay'] ?? 0).toDouble();
    double remaining = totalAmount - amountToPay;

    bool paidToday = false;
    if ((bill['paymentHistory'] as List?)?.isNotEmpty ?? false) {
      paidToday = (bill['paymentHistory'] as List).any((payment) {
        final paymentDateRaw = payment['timestamp'];
        final paymentDate = paymentDateRaw is Timestamp
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
        bool isPaying = false;
        return StatefulBuilder(
          builder: (context, setState) {

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isTablet ? 28 : 24),
              ),
              child: Container(
                width: isTablet ? screenWidth * 0.6 : null,
                padding: EdgeInsets.all(isTablet ? 32 : 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isTablet ? 24 : 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF1E3A5F), Color(0xFF2B2E4A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                bill['title'] ?? '',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isTablet ? 28 : 24,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 16 : 12,
                                vertical: isTablet ? 8 : 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
                              ),
                              child: Text(
                                bill['status'] ?? 'Pending',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: isTablet ? 16 : 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 15),
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
                                  _formatCompactCurrency(totalAmount),
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
                                    color: Color(0xFF2B2E4A).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    bill['frequency'] ?? '',
                                    style: TextStyle(
                                      color: Color(0xFF2B2E4A),
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
                              _formatCompactCurrency(amountToPay),
                            ),
                            Divider(height: 24),
                            _buildDetailRow(
                              'Paid Amount',
                              _formatCompactCurrency(bill['paidAmount'] ?? 0.0),
                            ),
                            Divider(height: 24),
                            _buildDetailRow(
                              'Remaining',
                              _formatCompactCurrency(remaining),
                            ),
                            Divider(height: 24),
                            _buildDetailRow(
                              bill['status'] == 'Paid' ? 'Status' : 'Final Status',
                              bill['status'] ?? 'Pending',
                              valueColor: bill['status'] == 'Paid'
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: (bill['paidAmount'] ?? 0.0) /
                                  (bill['totalAmount'] ?? 1.0),
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                (bill['paidAmount'] ?? 0.0) >=
                                        (bill['totalAmount'] ?? 0.0)
                                    ? Colors.green
                                    : Color(0xFF2B2E4A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
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
                      else if (bill['status'] == 'Missed')
                        Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'Payment Missed',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () async {
                                await controller.resetMissedPayment(bill['id']);
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(double.infinity, 50),
                                backgroundColor: Colors.orange.shade500,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 16),
                                elevation: 0,
                              ),
                              child: Text(
                                'Retry Payment',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            ElevatedButton(
                              onPressed: paidToday || isPaying
                                  ? null
                                  : () async {
                                      setState(() => isPaying = true);
                                      try {
                                        await controller.updatePaymentStatus(
                                          bill['id'],
                                          bill['amountToPay'] ?? 0.0,
                                        );
                                        Navigator.pop(context);
                                      } catch (e) {
                                        setState(() => isPaying = false);
                                        SnackbarService.showFavoritesError('Payment failed: $e');
                                      }
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
                              child: isPaying
                                  ? SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      paidToday ? 'Already Paid Today' : 'Pay Now',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                            SizedBox(height: 12),
                            if ((bill['paidAmount'] ?? 0.0) >=
                                (bill['totalAmount'] ?? 0.0))
                              ElevatedButton(
                                onPressed: () async {
                                  await controller.markAsPaid(bill['id']);
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: Size(double.infinity, 50),
                                  backgroundColor: Color(0xFF2B2E4A),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'Mark as Paid',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                          ],
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
                                final paymentDate = paymentDateRaw is Timestamp
                                    ? paymentDateRaw.toDate()
                                    : paymentDateRaw as DateTime;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          _getPaymentTimeText(paymentDate),
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Flexible(
                                        flex: 2,
                                        child: Text(
                                          _formatCompactCurrency((payment['amount'] ?? 0).toDouble()),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Color(0xFF2B2E4A),
                                          ),
                                          textAlign: TextAlign.right,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
                                SnackbarService.showFavoritesSuccess(
                                    'Favorite deleted successfully');
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
      return 'Paid Today at ${DateFormat('h:mm a').format(paymentDate)}';
    } else if (difference.inDays == 1) {
      return 'Paid Yesterday at ${DateFormat('h:mm a').format(paymentDate)}';
    } else if (difference.inDays < 7) {
      return 'Paid ${DateFormat('EEEE').format(paymentDate)} at ${DateFormat('h:mm a').format(paymentDate)}';
    } else if (difference.inDays < 30) {
      return 'Paid ${DateFormat('MMM d').format(paymentDate)} at ${DateFormat('h:mm a').format(paymentDate)}';
    } else if (difference.inDays < 365) {
      return 'Paid ${DateFormat('MMM d, yyyy').format(paymentDate)}';
    } else {
      return 'Paid ${DateFormat('MMM d, yyyy').format(paymentDate)}';
    }
  }

  String _getPaymentDateText(List paymentHistory) {
    if (paymentHistory.isEmpty) return '';

    final mostRecentPayment = paymentHistory.last;
    final paymentDateRaw = mostRecentPayment['timestamp'];
    final paymentDate = paymentDateRaw is Timestamp
        ? paymentDateRaw.toDate()
        : paymentDateRaw as DateTime;

    final now = DateTime.now();
    final difference = now.difference(paymentDate);

    if (difference.inDays == 0) {
      return 'Paid Today at ${DateFormat('h:mm a').format(paymentDate)}';
    } else if (difference.inDays == 1) {
      return 'Paid Yesterday at ${DateFormat('h:mm a').format(paymentDate)}';
    } else if (difference.inDays < 7) {
      return 'Paid ${DateFormat('EEEE').format(paymentDate)} at ${DateFormat('h:mm a').format(paymentDate)}';
    } else if (difference.inDays < 30) {
      return 'Paid ${DateFormat('MMM d').format(paymentDate)} at ${DateFormat('h:mm a').format(paymentDate)}';
    } else if (difference.inDays < 365) {
      return 'Paid ${DateFormat('MMM d, yyyy').format(paymentDate)}';
    } else {
      return 'Paid ${DateFormat('MMM d, yyyy').format(paymentDate)}';
    }
  }
}
