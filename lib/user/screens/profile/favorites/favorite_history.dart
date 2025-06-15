import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:snapwise/user/screens/widget/bottomnavbar.dart';
import 'package:snapwise/user/screens/profile/favorites/favorite_controller.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteHistory extends StatefulWidget {
  const FavoriteHistory({Key? key}) : super(key: key);

  @override
  State<FavoriteHistory> createState() => _FavoriteHistoryState();
}

class _FavoriteHistoryState extends State<FavoriteHistory> {
  final _storage = GetStorage();
  RxString displayName = ''.obs;
  RxString photoUrl = ''.obs;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _fetchUserData() {
    displayName.value = _storage.read('displayName') ?? '';
    photoUrl.value = _storage.read('photoUrl') ?? '';
  }

  final controller = Get.put(FavoriteController());
  final formatter = NumberFormat.currency(
    locale: 'en_PH',
    symbol: 'PHP ',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed:
              () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => BottomNavBar(initialIndex: 14),
                ),
              ),
        ),
        title: const Text(
          'Favorites',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Obx(() {
              ImageProvider imageProvider =
                  photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl.value)
                      : AssetImage('assets/logo.png');
              return CircleAvatar(radius: 16, backgroundImage: imageProvider);
            }),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Obx(() {
        final allPayments = <Map<String, dynamic>>[];

        for (var fav in controller.favorites) {
          final title = fav['title'] ?? '';
          final history = fav['paymentHistory'] as List? ?? [];
          for (var payment in history) {
            final paymentDateRaw = payment['timestamp'];
            final paymentDate =
                paymentDateRaw is Timestamp
                    ? paymentDateRaw.toDate()
                    : paymentDateRaw as DateTime;
            allPayments.add({
              'title': title,
              'amount': payment['amount'],
              'date': paymentDate,
            });
          }
        }

        // Sort by date, newest first
        allPayments.sort((a, b) => b['date'].compareTo(a['date']));

        if (allPayments.isEmpty) {
          return Center(child: Text('No payment history found.'));
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: allPayments.length,
          itemBuilder: (context, index) {
            final payment = allPayments[index];
            return Card(
              margin: EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
              child: ListTile(
                leading: Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 28,
                ),
                title: Text(
                  payment['title'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B2E4A),
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  _getPaymentTimeText(payment['date']),
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                trailing: Text(
                  formatter.format(payment['amount']),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B2E4A),
                    fontSize: 16,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  // Helper function
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
      return 'Paid ${paymentDate.year}';
    }
  }
}
