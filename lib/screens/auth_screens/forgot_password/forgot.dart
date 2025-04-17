import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snapwise/screens/auth_screens/login/login_controller.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final LoginController controller = Get.put(LoginController());
  final bool isTablet =
      MediaQueryData.fromView(
        // ignore: deprecated_member_use
        WidgetsBinding.instance.window,
      ).size.shortestSide >
      600;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: isTablet ? 300 : 200,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 3, 30, 53),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 40 : 20,
                  vertical: 40,
                ),
                child: Stack(
                  children: [
                    // Header Text
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "FORGOT",
                          style: TextStyle(
                            fontSize: isTablet ? 40 : 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "PASSWORD?",
                          style: TextStyle(
                            fontSize: isTablet ? 40 : 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 50 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: isTablet ? 100 : 40),
                    // Description Text
                    Text(
                      "Don't worry! It happens. Please enter the email associated with your account.",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Email Field
                    const Text(
                      "Email address",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      cursorColor: const Color.fromARGB(255, 3, 30, 53),
                      controller: controller.emailController,
                      decoration: InputDecoration(
                        hintText: "Enter your email address",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color.fromARGB(255, 3, 30, 53),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color.fromARGB(255, 3, 30, 53),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color.fromARGB(255, 3, 30, 53),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Send Code Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _handleResetPassword(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 3, 30, 53),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          "Submit",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Remember Password Prompt
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Remember password? ",
                          style: TextStyle(
                            color: Color.fromARGB(255, 3, 30, 53),
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "Login",
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleResetPassword() {
    controller.resetPassword();
    if (controller.isSuccess.value == true) {
      Get.offAllNamed('/login');
      controller.clearData();
    }
  }
}
