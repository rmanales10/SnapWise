import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class Controller extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  RxList<Map> data = [{}].obs;
  RxInt totalUsers = 0.obs;
  RxInt totalInactiveUsers = 0.obs;
  RxInt totalActiveUsers = 0.obs;
  RxBool isLoading = false.obs; // Add this line

  Future<void> fetchData() async {
    isLoading.value = true; // Set loading to true when starting to fetch data
    try {
      QuerySnapshot users = await _firestore.collection('users').get();
      data.value =
          users.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      totalUsers.value = users.docs.length;
      totalInactiveUsers.value =
          data.where((user) => user['status'] == 'inactive').length;
      totalActiveUsers.value = totalUsers.value - totalInactiveUsers.value;
    } catch (e) {
      log('Error fetching data: $e');
    } finally {
      isLoading.value =
          false; // Set loading to false when fetch operation is complete
    }
  }
}
