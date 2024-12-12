import 'package:emperiosquartet/dashboard/dashboard.dart';
import 'package:emperiosquartet/home_navigation/home_navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:flutter/material.dart';
import 'dart:async';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool obs = true; // Toggle for password visibility
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // FirebaseAuth and Firestore instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Timer? timer; // Timer to check for email verification
  bool isVerifying = false; // Track if we are waiting for verification

// Method to handle login
  Future<void> _login() async {
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showDialog('Error', 'Please fill in both fields.');
      return;
    }

    try {
      // Sign in the user with Firebase Authentication
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null && !user.emailVerified) {
        // Email is not verified, show a dialog to prompt verification
        _showDialog(
          'Verification Email Sent',
          'A verification email has been sent. Please check your inbox.',
          onOkPressed: () async {
            try {
              // Resend the verification email
              await user.sendEmailVerification();

              // Start a timer to periodically check for email verification
              setState(() {
                isVerifying = true; // Mark as verifying
              });

              timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
                // Reload the user to check if the email is verified
                await _auth.currentUser?.reload();
                if (_auth.currentUser != null &&
                    _auth.currentUser!.emailVerified) {
                  timer.cancel(); // Stop the timer when email is verified
                  setState(() {
                    isVerifying = false; // Stop verifying
                  });

                  // Show dialog when email is verified
                  _showDialog('Verified', 'Email verified successfully!',
                      onOkPressed: () {
                    // Proceed to the home screen after email is verified
                    Navigator.pushReplacementNamed(context, '/home');
                  });
                }
              });
            } catch (e) {
              _showDialog('Error', 'Failed to send verification email.');
            }
          },
        );
        return; // Exit if email is not verified, await verification
      }

      // If login is successful and email is verified, proceed
      if (user != null && user.emailVerified) {
        // Show success dialog for login
        _showDialog('Success', 'Login successful!');
        // Update user status to online
        _updateUserStatus(user, 'online');

        // Delay before navigating to home screen
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const HomeNavigation()));
        });
      }
    } on FirebaseAuthException catch (e) {
      // Handle errors during login
      _showDialog('Error', e.message ?? 'An error occurred.');
    }
  }

// Method to update user status in Firestore
  Future<void> _updateUserStatus(User user, String status) async {
    final userRef = _firestore.collection('users').doc(user.uid);

    // Set user status to the given status and last seen timestamp
    await userRef.set({
      'status': status,
      'last_seen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Listen for the status changes
    userRef.snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.data()?['status'] == 'offline') {
        // Update the status when disconnected or when app is closed
        userRef.update({
          'status': 'offline',
          'last_seen': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  // Method to show dialog with optional onOkPressed callback
  void _showDialog(String title, String message, {VoidCallback? onOkPressed}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: onOkPressed ?? () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            color: const Color.fromARGB(255, 37, 52, 65),
            width: screenWidth,
            child: Column(
              children: [
                // Logo or top image
                Image(
                  image: const AssetImage('assets/p1.png'),
                  height: isMobile ? screenHeight * 0.25 : screenHeight * 0.4,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: isMobile ? screenWidth * 0.9 : 400,
                        height: isMobile ? screenHeight * 0.65 : 500,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          children: [
                            SizedBox(height: isMobile ? 10 : 30),
                            // Email TextField
                            TextField(
                              controller: emailController,
                              cursorColor:
                                  const Color.fromARGB(255, 37, 52, 65),
                              style: const TextStyle(
                                  color: Color.fromARGB(255, 37, 52, 65)),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                filled: true,
                                fillColor: const Color.fromARGB(255, 37, 52, 65)
                                    .withOpacity(0.1),
                                prefixIcon: const Icon(Icons.email),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: const BorderSide(
                                    width: 2,
                                    color: Color.fromARGB(255, 37, 52, 65),
                                  ),
                                ),
                                hintText: 'Email',
                                hintStyle: const TextStyle(
                                    color: Color.fromARGB(255, 66, 65, 65)),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Password TextField
                            TextField(
                              controller: passwordController,
                              obscureText: obs,
                              cursorColor:
                                  const Color.fromARGB(255, 37, 52, 65),
                              style: const TextStyle(
                                  color: Color.fromARGB(255, 37, 52, 65)),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                filled: true,
                                fillColor: const Color.fromARGB(255, 37, 52, 65)
                                    .withOpacity(0.1),
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obs
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      obs = !obs;
                                    });
                                  },
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: const BorderSide(
                                    width: 2,
                                    color: Color.fromARGB(255, 37, 52, 65),
                                  ),
                                ),
                                hintText: 'Password',
                                hintStyle: const TextStyle(
                                    color: Color.fromARGB(255, 66, 65, 65)),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Forgot password button
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/forgot');
                                },
                                child: const Text('Forgot password?'),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Login button
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 37, 52, 65),
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30)),
                              ),
                              onPressed: _login,
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 30),
                            // Signup prompt
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Don\'t have an account?'),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/create');
                                  },
                                  child: const Text(
                                    'Sign up',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
