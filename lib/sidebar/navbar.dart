import 'dart:typed_data';
import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:emperiosquartet/login/login1.dart';
import 'package:emperiosquartet/add/addbudgets.dart';
import 'package:emperiosquartet/dashboard/dashboard.dart';
import 'package:emperiosquartet/dashboard/expense.dart';
import 'package:emperiosquartet/add/add_receipt_page.dart';
import 'package:image_picker/image_picker.dart';

class Navbar extends StatefulWidget {
  const Navbar({super.key});

  @override
  _NavbarState createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  final ImagePicker _picker = ImagePicker();
  String userEmail = '';
  String userName = '';
  String profileImageUrl = '';
  int _selectedIndex = -1;
  Uint8List? _imageBytes; // To store the picked image in bytes

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  /// Fetches user data from Firestore
  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (docSnapshot.exists) {
        setState(() {
          userEmail = docSnapshot['email'] ?? 'No Email';
          userName = docSnapshot['name'] ?? 'Name';
          profileImageUrl = docSnapshot['profileImageUrl'] ?? '';
          _imageBytes = profileImageUrl.isNotEmpty
              ? base64Decode(profileImageUrl)
              : null; // Decode the profile image if available
        });
      }
    }
  }

  /// Allows the user to pick an image and upload it to Firestore
  Future<void> _pickImageAndUpload() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        Uint8List imageBytes = await pickedFile.readAsBytes();
        String base64Image =
            base64Encode(imageBytes); // Convert image to base64

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update(
                  {'profileImageUrl': base64Image}); // Save image to Firestore

          setState(() {
            _imageBytes = imageBytes; // Store the image bytes to persist in UI
            profileImageUrl =
                base64Image; // Update the profileImageUrl for future use
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Image uploaded successfully!")),
          );
        }
      } else {
        log("No image selected.");
      }
    } catch (e) {
      log("Error uploading image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading image: $e")),
      );
    }
  }

  // Update user status to "offline"
  Future<void> _updateUserStatus(User user, String status) async {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'status': status,
    });
  }

  // Logout function that updates status to offline and logs out the user
  Future<void> _logout() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Update user status to 'offline' when logging out
      await _updateUserStatus(user, 'offline');
    }

    // Sign out the user from Firebase
    await FirebaseAuth.instance.signOut();

    // Navigate back to the login screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Login()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              userName.isEmpty ? 'Loading...' : userName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(userEmail.isEmpty ? 'Loading...' : userEmail),
            currentAccountPicture: GestureDetector(
              onTap: _pickImageAndUpload, // Trigger image upload
              child: CircleAvatar(
                child: ClipOval(
                  child: _imageBytes == null
                      ? Image.asset(
                          'assets/p1.png', // Default placeholder
                          height: 90,
                          width: 90,
                          fit: BoxFit.cover,
                        )
                      : Image.memory(
                          _imageBytes!, // Show the uploaded image
                          height: 90,
                          width: 90,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ),
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 37, 52, 65),
            ),
          ),
          _buildMenuSection(context, 'MENU'),
          _buildMenuItem(context, 0, Icons.person, 'Profile', () {}),
          _buildMenuItem(context, 1, Icons.home, 'Home', () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => DashboardPage()));
          }),
          _buildMenuItem(context, 2, Icons.insights, 'Insight', () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => ExpenseInsightPage()));
          }),
          _buildMenuItem(context, 3, Icons.account_balance_wallet, 'Budget',
              () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const NewBudgetScreen()));
          }),
          _buildMenuItem(context, 4, Icons.receipt, 'Receipt', () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AddReceiptPage()));
          }),
          const SizedBox(height: 200),
          const Divider(),
          _buildMenuItem(context, 7, Icons.logout, 'Logout', () {
            _showLogoutDialog(context);
          }, color: Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, int index, IconData icon,
      String title, VoidCallback onTap,
      {Color color = Colors.black}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          color: _selectedIndex == index ? Colors.blue : color,
          fontWeight:
              _selectedIndex == index ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      tileColor: _selectedIndex == index ? Colors.blue[100] : null,
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        onTap();
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Are you sure you want to log out?'),
          content: const Text('You will be logged out of the app.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Log Out'),
              onPressed: () {
                Navigator.of(context).pop();
                _logout(); // Call logout method here
              },
            ),
          ],
        );
      },
    );
  }
}
