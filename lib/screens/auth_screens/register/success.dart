import 'package:flutter/material.dart';

class RegistrationSuccessPage extends StatelessWidget {
  final bool isTablet =
      MediaQueryData.fromView(
        // ignore: deprecated_member_use
        WidgetsBinding.instance.window,
      ).size.shortestSide >
      600;
  RegistrationSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding:  EdgeInsets.symmetric(horizontal: isTablet ? 50 : 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 40, color: Colors.green),
                ),
                const SizedBox(height: 20),

                // Title Text
                const Text(
                  "REGISTERED",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const Text(
                  "SUCCESSFULLY",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),

                // Description Text
                const Text(
                  "Your account has been created",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const Text(
                  "successfully",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 40),

                // Back to Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 3, 30, 53),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      "Back to login",
                      style: TextStyle(fontSize: 16, color: Colors.white),
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
