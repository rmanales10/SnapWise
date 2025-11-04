import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:developer' as developer;

class ProfileController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GetStorage _storage = GetStorage();
  RxString username = ''.obs;
  RxString email = ''.obs;
  RxString photoUrl = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Set immediate fallback values to avoid showing "Loading..."
    _setInitialValues();
    fetchProfileData();
  }

  void _setInitialValues() {
    final User? user = _auth.currentUser;
    if (user != null) {
      // Set immediate fallback from local storage or email
      final storedUsername = _storage.read<String>('userDisplayName');
      username.value = storedUsername ??
          user.displayName ??
          user.email?.split('@')[0] ??
          'User';
      email.value = user.email ?? '';
      photoUrl.value = user.photoURL ?? '';
    }
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

        // Priority: displayName (Google) > username (Email/Password) > Local Storage > Firebase Auth displayName > email prefix
        username.value = data['displayName'] ??
            data['username'] ??
            _storage.read<String>('userDisplayName') ??
            user.displayName ??
            user.email?.split('@')[0] ??
            'User';

        email.value = data['email'] ?? user.email ?? '';
        photoUrl.value = data['photoUrl'] ?? user.photoURL ?? '';

        // Update local storage with the fetched username
        if (username.value.isNotEmpty && username.value != 'User') {
          await _storage.write('userDisplayName', username.value);
        }

        developer.log('Username set to: ${username.value}');
      } else {
        // Fallback to local storage or Firebase Auth data if Firestore doesn't have the user
        developer.log(
            'No Firestore data, using local storage or Firebase Auth data');
        final storedUsername = _storage.read<String>('userDisplayName');
        username.value = storedUsername ??
            user.displayName ??
            user.email?.split('@')[0] ??
            'User';
        email.value = user.email ?? '';
        photoUrl.value = user.photoURL ?? '';
      }
    } catch (e) {
      developer.log('Error fetching profile data: $e');
      // Set default values on error, but keep existing values if they exist
      final User? user = _auth.currentUser;
      if (username.value.isEmpty || username.value == 'Loading...') {
        final storedUsername = _storage.read<String>('userDisplayName');
        username.value = storedUsername ??
            user?.displayName ??
            user?.email?.split('@')[0] ??
            'User';
      }
      if (email.value.isEmpty && user?.email != null) {
        email.value = user!.email!;
      }
    }
  }
}
