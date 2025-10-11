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
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 40 : 24, vertical: isTablet ? 30 : 20),
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
                'About SnapWise',
                style: TextStyle(
                  fontSize: isTablet ? 20 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'SnapWise is a comprehensive personal finance management app designed to help you take control of your financial life. With AI-powered expense tracking, intelligent budget management, and smart notifications, SnapWise makes managing your money simple and effective.',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'Key Features',
                style: TextStyle(
                  fontSize: isTablet ? 20 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildFeatureItem('📱', 'AI-Powered Receipt Scanning', isTablet),
              _buildFeatureItem('💰', 'Smart Budget Management', isTablet),
              _buildFeatureItem('📊', 'Expense Analytics & Reports', isTablet),
              _buildFeatureItem('🔔', 'Intelligent Notifications', isTablet),
              _buildFeatureItem('⭐', 'Favorites & Payment Tracking', isTablet),
              const SizedBox(height: 20),
              Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: isTablet ? 20 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'SnapWise Development Team\nEmail: support@snapwise.app\nWebsite: www.snapwise.app\nVersion: 1.0.0',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  '© 2025 SnapWise. All rights reserved.',
                  style: TextStyle(
                      fontSize: isTablet ? 14 : 12, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 20), // Add bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String emoji, String feature, bool isTablet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
