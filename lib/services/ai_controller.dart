import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';

class AiController extends GetxController {
  late final FirebaseFirestore _firestore;
  RxString apiKey = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeFirestore();
  }

  void _initializeFirestore() {
    try {
      _firestore = FirebaseFirestore.instance;
      getApiKey();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Firestore: $e');
      }
      // For web platform, we might need to delay the initialization
      if (kIsWeb) {
        Future.delayed(const Duration(seconds: 1), () {
          try {
            _firestore = FirebaseFirestore.instance;
            getApiKey();
          } catch (e) {
            if (kDebugMode) {
              print('Error initializing Firestore on web: $e');
            }
          }
        });
      }
    }
  }

  Future<void> getApiKey() async {
    try {
      final snapshot =
          await _firestore.collection('aiService').doc('apiKey').get();
      apiKey.value = snapshot.data()?['gemini'] ?? '';
    } catch (e) {
      if (kDebugMode) {
        print('Error getting API key: $e');
      }
      // Set a default empty value if Firestore is not available
      apiKey.value = '';
    }
  }
}
