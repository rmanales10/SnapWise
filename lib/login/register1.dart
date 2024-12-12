import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:io'; // For IP address fetching
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreateAcc extends StatefulWidget {
  const CreateAcc({super.key});

  @override
  State<CreateAcc> createState() => _CreateAccState();
}

class _CreateAccState extends State<CreateAcc> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true; // For confirm password field
  bool _agreeToTerms = false;

  // Common colors for styling
  final Color primaryColor = const Color(0xFF232F3E);
  final Color inputFillColor = const Color(0xFF232F3E).withOpacity(0.1);

  void _signUp() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Passwords do not match');
      return;
    }

    if (!_agreeToTerms) {
      _showSnackBar('You must agree to the terms and conditions');
      return;
    }

    try {
      // Create the user
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }

      String userId = user!.uid;
      String ipAddress = await _getIpAddress();

      // Generate unique idNumber
      int idNumber = await _generateIdNumber();

      // Save user data to Firestore
      await _firestore.collection('users').doc(userId).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'idNumber': idNumber,
        'ipAddress': ipAddress,
        'signUpDate': Timestamp.now(),
        'signUpTime': Timestamp.now(),
        'emailVerified': user.emailVerified,
        'status': 'offline', // Initial status set to offline
      });

      _showSnackBar('Signup successful! Check your email for verification.');
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar('Signup failed: $e');
    }
  }

  Future<int> _generateIdNumber() async {
    const idTrackerDoc =
        'idTracker'; // Name of the document tracking the idNumber
    const trackerField = 'latestId';

    try {
      // Reference to the tracker document
      DocumentReference trackerRef =
          _firestore.collection('metadata').doc(idTrackerDoc);

      // Update the `latestId` atomically using Firestore transactions
      int newIdNumber = await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(trackerRef);

        if (!snapshot.exists) {
          // Initialize the tracker document if it doesn't exist
          transaction.set(trackerRef, {trackerField: 1});
          return 1;
        }

        // Increment the `latestId`
        int currentId = snapshot[trackerField] ?? 0;
        int updatedId = currentId + 1;
        transaction.update(trackerRef, {trackerField: updatedId});
        return updatedId;
      });

      return newIdNumber;
    } catch (e) {
      // Handle errors (e.g., insufficient permissions)
      _showSnackBar('Error generating ID number: $e');
      return 0; // Default to 0 if error occurs
    }
  }

  Future<String> _getIpAddress() async {
    try {
      // First, try to fetch the public IP address
      final response =
          await http.get(Uri.parse('https://api.ipify.org?format=json'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['ip'] ?? 'Unknown'; // Return public IP
      }
    } catch (e) {
      // Public IP fetch failed; fall back to local IP
      print('Error fetching public IP: $e');
    }

    try {
      // If fetching the public IP fails, get the local IP address
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4) {
            return addr.address; // Return the first IPv4 address found
          }
        }
      }
      return 'Unknown'; // If no local IP is found
    } catch (e) {
      return 'Error retrieving IP: $e';
    }
  }

  void _showTermsAndPolicy() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Get screen dimensions
        final double screenWidth = MediaQuery.of(context).size.width;
        final double screenHeight = MediaQuery.of(context).size.height;

        // Dynamic padding and font size based on screen width
        final double padding =
            screenWidth < 600 ? 16 : 24; // Smaller padding for smaller screens
        final double fontSize =
            screenWidth < 600 ? 14 : 16; // Adjust font size dynamically

        // Dialog dimensions
        final double dialogWidth = screenWidth < 600
            ? screenWidth * 0.9
            : 600; // Max width for large screens
        final double dialogHeight =
            screenHeight * 0.7; // Set height to 70% of the screen

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          contentPadding: EdgeInsets.all(padding),
          title: Center(
            child: Text(
              'Terms & Policy',
              style: TextStyle(
                fontSize: fontSize + 2, // Slightly larger font for title
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          content: SizedBox(
            width: dialogWidth,
            height: dialogHeight, // Set height to 70% of the screen
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Text(
                  '''
Here are the terms and policies for the app. Please read carefully.

*SnapWise Terms and Conditions*

Welcome to SnapWise! By downloading, accessing,
or using the SnapWise app, you agree to comply
with these Terms and Conditions. Please read
them carefully, as your continued use of the app
signifies your acceptance of these terms. If
you do not agree to these terms, you are not
authorized to use the app.

1.By using SnapWise, you confirm that you have read,
understood, and agreed to these terms. To use SnapWise,

2.you must be at least 13 years old or meet the minimum
age requirement in your jurisdiction. You are responsible
for providing accurate and up-to-date information when
using the app. SnapWise is designed to offer receipt

3.tracking and budget management features for personal
use. Users are prohibited from using the app for
illegal or unauthorized purposes, reverse-engineering,

4.decompiling, or tampering with its functionalities. While
SnapWise strives to provide accurate results, the app
cannot guarantee 100% error-free functionality, and users
are responsible for verifying the accuracy of scanned and
categorized data.
                ''',
                  style: TextStyle(fontSize: fontSize, height: 1.5),
                  textAlign:
                      TextAlign.justify, // Justified text for readability
                ),
              ),
            ),
          ),
          actions: [
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: const Text(
                  'Close',
                  style: TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final containerWidth = isMobile ? screenWidth * 0.9 : 500.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Center(
          child: SizedBox(
            width: containerWidth,
            child: Column(
              children: [
                _buildHeader(isMobile),
                const SizedBox(height: 15),
                _buildForm(isMobile, screenWidth),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    final screenWidth =
        MediaQuery.of(context).size.width; // Get the screen width

    return Container(
      width: double.infinity,
      height: 200,
      decoration: const BoxDecoration(
        color: Color(0xFF232F3E),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(50),
          bottomRight: Radius.circular(50),
        ),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          0,
          30,
          isMobile
              ? screenWidth * 0.4
              : 265, // Adjusting the right padding dynamically
          0,
        ),
        child: Text(
          "Let's \n Create Your \n Account",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize:
                isMobile ? 20 : 24, // Font size adjusts based on screen width
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildForm(bool isMobile, double screenWidth) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildTextField(
            controller: _nameController,
            hint: 'Full Name',
            icon: Icons.person,
          ),
          const SizedBox(height: 15),
          _buildTextField(
            controller: _emailController,
            hint: 'Email',
            icon: Icons.email,
          ),
          const SizedBox(height: 15),
          _buildTextField(
            controller: _passwordController,
            hint: 'Password',
            icon: Icons.lock,
            obscureText: _obscurePassword,
            toggleVisibility: _togglePasswordVisibility,
          ),
          const SizedBox(height: 15),
          _buildTextField(
            controller: _confirmPasswordController,
            hint: 'Retype Password',
            icon: Icons.lock,
            obscureText: _obscureConfirmPassword,
            toggleVisibility: _toggleConfirmPasswordVisibility,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Checkbox(
                activeColor: primaryColor,
                value: _agreeToTerms,
                onChanged: (bool? newValue) {
                  setState(() {
                    _agreeToTerms = newValue!;
                  });
                },
              ),
              const Text('I agree to the'),
              TextButton(
                onPressed: _showTermsAndPolicy,
                child: const Text(
                  'Terms & Privacy',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildButton(
            text: 'Create an account',
            onPressed: _agreeToTerms
                ? _signUp
                : null, // Button disabled if terms are not agreed
            isMobile: isMobile,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Have an account?'),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                child: const Text(
                  'Sign In',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController? controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    VoidCallback? toggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        filled: true,
        fillColor: inputFillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: toggleVisibility != null
            ? IconButton(
                icon:
                    Icon(obscureText ? Icons.visibility : Icons.visibility_off),
                onPressed: toggleVisibility,
              )
            : null,
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required VoidCallback? onPressed,
    required bool isMobile,
  }) {
    return Container(
      width: isMobile ? 300 : 500,
      height: 50,
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
