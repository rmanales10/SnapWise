import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery to get the screen width
    final double screenWidth = MediaQuery.of(context).size.width;

    // Define tablet threshold (e.g., 600px for tablets)
    final bool isTablet = screenWidth >= 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back, color: Colors.black),
            ),
            const SizedBox(width: 15),
            const Text(
              'About',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 40 : 24, vertical: isTablet ? 30 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: isTablet ? 60 : 40, // Larger avatar for tablets
                backgroundColor: const Color.fromARGB(255, 3, 30, 53),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 45, // Larger icon for tablets
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'SnapWise',
                style: TextStyle(
                  fontSize: isTablet ? 28 : 22, // Larger text for tablets
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'v1.0.0',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'About the App',
              style: TextStyle(
                fontSize: isTablet ? 20 : 16, // Larger title for tablets
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'SnapWise is a simple, elegant finance tracking app that helps you monitor your expenses, manage budgets, and stay on top of your spending habits.',
              style: TextStyle(
                fontSize: isTablet ? 16 : 14, // Larger text for tablets
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Developed by',
              style: TextStyle(
                fontSize: isTablet ? 20 : 16, // Larger text for tablets
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your Name or Company\nEmail: contact@example.com\nWebsite: www.example.com',
              style: TextStyle(
                fontSize: isTablet ? 16 : 14, // Larger text for tablets
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Center(
              child: Text(
                '© 2025 SnapWise. All rights reserved.',
                style: TextStyle(fontSize: isTablet ? 14 : 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
