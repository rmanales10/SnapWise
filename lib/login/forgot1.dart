import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgotPass extends StatefulWidget {
  const ForgotPass({super.key});

  @override
  State<ForgotPass> createState() => _ForgotPassState();
}

class _ForgotPassState extends State<ForgotPass> {
  final TextEditingController _emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Boolean for handling password visibility (if needed for other fields)
  bool obs = true;

  // Show a snackbar with the given message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // Function to handle password reset email
  Future<void> _resetPassword() async {
    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      _showSnackBar('Password reset email sent. Please check your inbox.');
      Navigator.pushNamed(context, '/login'); // Redirect user to login screen
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            color: const Color.fromARGB(255, 37, 52, 65),
            width: 500,
            child: Column(
              children: [
                // Header Section
                Container(
                  child: const Column(
                    children: [
                      SizedBox(height: 50),
                      Icon(
                        Icons.lock,
                        size: 100,
                        color: Colors.white,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Forgot',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 30,
                        ),
                      ),
                      Text(
                        'Password?',
                        style: TextStyle(
                          fontWeight: FontWeight.w100,
                          color: Colors.white,
                          fontSize: 30,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "No worries, We'll send you",
                        style: TextStyle(
                          fontWeight: FontWeight.w100,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'reset instructions',
                        style: TextStyle(
                          fontWeight: FontWeight.w100,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 50),
                    ],
                  ),
                ),

                // Form Section for Email Input
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 300,
                      height: 373,
                      child: Column(
                        children: [
                          const SizedBox(height: 100),
                          TextField(
                            controller: _emailController,
                            cursorColor: const Color.fromARGB(255, 37, 52, 65),
                            style: const TextStyle(
                              color: Color.fromARGB(255, 37, 52, 65),
                            ),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              filled: true,
                              fillColor: const Color.fromARGB(255, 37, 52, 65)
                                  .withOpacity(0.5),
                              prefixIcon: Icon(Icons.email),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                  width: 2,
                                  color: Color.fromARGB(255, 37, 52, 65),
                                ),
                              ),
                              hintText: 'Enter your Email',
                              hintStyle: const TextStyle(
                                color: Color.fromARGB(255, 66, 65, 65),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Reset Password Button
                          Container(
                            width: double.infinity,
                            height: 55,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 37, 52, 65),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                width: 2,
                                color: Colors.white,
                              ),
                            ),
                            child: TextButton(
                              onPressed:
                                  _resetPassword, // Trigger password reset
                              child: const Text(
                                'Reset Password',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          // Back to Login Button
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/login');
                            },
                            child: const Text(
                              'Back to Login',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
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
