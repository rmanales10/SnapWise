import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../login/login.dart';
import '../register/register.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              // Top spacer
              const Spacer(flex: 2),

              // Logo and Welcome Section
              Column(
                children: [
                  // Logo with actual icon
                  const Center(
                    child: Image(
                      image: AssetImage('assets/main_screen_logo.png'),
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  ),

                  // Welcome text
                  const Text(
                    'Welcome to Snapwise',
                    style: TextStyle(
                      color: Color(0xFF374151), // Dark grey
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              // Bottom spacer
              const Spacer(flex: 2),

              // Action Buttons
              Column(
                children: [
                  // Log In Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.to(() => const LoginPage());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Color.fromARGB(255, 3, 30, 53), // Dark purple-blue
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Log In',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Or separator
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(
                          color: Color(0xFFD1D5DB), // Light grey
                          thickness: 1,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Or',
                          style: TextStyle(
                            color: Color(0xFF9CA3AF), // Light grey
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Divider(
                          color: Color(0xFFD1D5DB), // Light grey
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Sign Up Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.to(() => const RegisterPage());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Color.fromARGB(255, 3, 30, 53), // Dark purple-blue
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Bottom spacer
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
