import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'dart:developer' as developer;

class ProfileController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  RxString username = ''.obs;
  RxString email = ''.obs;
  RxString photoUrl = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProfileData();
  }

  Future<void> fetchProfileData() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        developer.log('No user authenticated');
        return;
      }

      developer.log('Fetching profile data for user: ${user.uid}');

      // Try to get data from Firestore first
      final DocumentSnapshot snapshot =
          await _firestore.collection('users').doc(user.uid).get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        developer.log('Firestore data: $data');

        // Priority: displayName (Google) > username (Email/Password) > Firebase Auth displayName > email
        username.value = data['displayName'] ??
            data['username'] ??
            user.displayName ??
            user.email?.split('@')[0] ??
            'User';

        email.value = data['email'] ?? user.email ?? '';
        photoUrl.value = data['photoUrl'] ?? user.photoURL ?? '';

        developer.log('Username set to: ${username.value}');
      } else {
        // Fallback to Firebase Auth data if Firestore doesn't have the user
        developer.log('No Firestore data, using Firebase Auth data');
        username.value =
            user.displayName ?? user.email?.split('@')[0] ?? 'User';
        email.value = user.email ?? '';
        photoUrl.value = user.photoURL ?? '';
      }
    } catch (e) {
      developer.log('Error fetching profile data: $e');
      // Set default values on error
      username.value = 'User';
    }
  }
}
