import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snapwise/app/auth_screens/forgot_password/forgot_controller.dart';
import 'package:snapwise/app/auth_screens/forgot_password/verify_code.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final ForgotController controller = Get.put(ForgotController());
  bool isSubmitting = false;
  final _formKey = GlobalKey<FormState>();
  String? _emailError;
  final bool isTablet = MediaQueryData.fromView(
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
                child: Form(
                  key: _formKey,
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
                      TextFormField(
                        cursorColor: const Color.fromARGB(255, 3, 30, 53),
                        controller: controller.emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email address';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: "Enter your email address",
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: Colors.grey.shade600,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color.fromARGB(255, 3, 30, 53),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _emailError != null
                                  ? Colors.red
                                  : Colors.grey.shade300,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color.fromARGB(255, 3, 30, 53),
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.red,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        onChanged: (value) {
                          if (_emailError != null) {
                            setState(() {
                              _emailError = null;
                            });
                          }
                        },
                      ),
                      if (_emailError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _emailError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),

                      isSubmitting
                          ? Center(
                              child: Column(
                                children: [
                                  CircularProgressIndicator(
                                    color: const Color.fromARGB(255, 3, 30, 53),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Sending verification email...',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _handleResetPassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromARGB(255, 3, 30, 53),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text(
                                  "Send Reset Email",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.white),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleResetPassword() async {
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isSubmitting = true;
      _emailError = null;
    });

    try {
      await controller
          .sendVerificationEmail(controller.emailController.text.trim());

      if (controller.isUserFound.value) {
        // Navigate to verification screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                VerifyCode(email: controller.emailController.text.trim()),
          ),
        );
      } else {
        // Show error if user not found
        setState(() {
          _emailError = 'No account found with this email address';
        });
      }
    } catch (e) {
      setState(() {
        _emailError = 'Failed to send verification email. Please try again.';
      });
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }
}
