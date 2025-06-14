import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:snapwise/user/screens/widget/bottomnavbar.dart';

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Loan Bills',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[400],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Paid',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'PHP 20,000.00',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Weekly',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'End Date : January 27 2026',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        GestureDetector(
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          BottomNavBar(initialIndex: 14),
                                ),
                              ),
                          child: Text(
                            'View Details',
                            style: TextStyle(
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
