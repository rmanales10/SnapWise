import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snapwise/screens/auth_screens/login/login_controller.dart';
import 'package:snapwise/screens/widget/bottom_nav_bar.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final LoginController controller = Get.put(LoginController());

  bool _showPassword = false;
  final bool _wrongPassword = false;

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: isTablet ? 20 : 0),
                    Center(
                      child: Image.asset(
                        'assets/logo.png',
                        width: isTablet ? 300 : 150,
                        height: isTablet ? 300 : 150,
                        fit: BoxFit.cover,
                      ),
                    ),

                    SizedBox(height: isTablet ? 0 : 20),

                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 50 : 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Email",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: controller.emailController,
                            cursorColor: Color.fromARGB(255, 3, 30, 53),
                            decoration: InputDecoration(
                              hintText: "Enter your email",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
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
                          const SizedBox(height: 10),

                          const Text(
                            "Password",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: controller.passwordController,
                            obscureText: !_showPassword,
                            cursorColor: Color.fromARGB(255, 3, 30, 53),
                            decoration: InputDecoration(
                              hintText: "Enter your password",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Color.fromARGB(255, 3, 30, 53),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color.fromARGB(255, 3, 30, 53),
                                ),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showPassword = !_showPassword;
                                  });
                                },
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          if (_wrongPassword)
                            const Text(
                              "Wrong password",
                              style: TextStyle(color: Colors.red, fontSize: 14),
                            ),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/forgot');
                              },
                              child: const Text(
                                "Forgot password?",
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 14,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.blue,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _handleLogin(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color.fromARGB(255, 3, 30, 53),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: const Text(
                                "Continue",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          Row(
                            children: [
                              const Expanded(
                                child: Divider(
                                  color: Color.fromARGB(255, 3, 30, 53),
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  "or",
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ),
                              const Expanded(
                                child: Divider(
                                  color: Color.fromARGB(255, 3, 30, 53),
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),

                    Container(
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(255, 3, 30, 53),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 50 : 20,
                        vertical: isTablet ? 65 : 40,
                      ),
                      child: Column(
                        children: [
                          OutlinedButton(
                            onPressed: () async {
                              bool success =
                                  await controller.signInWithGoogle();
                              if (success) {
                                Get.offAll(() => BottomNavBar(initialIndex: 0));
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                width: 2,
                                color: Colors.white,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/pngwing 2.png',
                                  height: 24,
                                  width: 24,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  "Login with Google",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: TextStyle(color: Colors.grey.shade300),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/register');
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                ),
                                child: const Text(
                                  "Sign up",
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleLogin() async {
    bool success = await controller.login();
    if (success) {
      Get.offAll(() => BottomNavBar(initialIndex: 0));
      controller.clearData();
    }
  }
}
