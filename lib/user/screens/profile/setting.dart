import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {


  @override
  Widget build(BuildContext context) {
    // Use MediaQuery to get the screen width
    final double screenWidth = MediaQuery.of(context).size.width;

    // Define tablet threshold (e.g., 600px for tablets)
    final bool isTablet = screenWidth >= 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 30 : 15,
          vertical: isTablet ? 60 : 50,
        ),
        child: Column(
          children: [
            // Header Section
            Container(
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 40 : 20),
              color: Colors.white,
              child: Column(
                children: [
                  const SizedBox(height: 25),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.arrow_back),
                        ),
                      ),
                      Text(
                        'Settings',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isTablet ? 25 : 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1),

                  // Setting items (Notification, About)
                  _buildSettingItem(
                    title: 'Notification',
                    onTap: () {
                      Navigator.pushNamed(context, '/notif-setting');
                    },
                  ),

                  _buildSettingItem(
                    title: 'About',
                    onTap: () {
                      Navigator.pushNamed(context, '/about');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // bottomNavigationBar: CustomBottomNavBar(
      //   currentIndex: _selectedIndex,
      //   onTap: _onNavItemTapped,
      // ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required VoidCallback onTap,
  }) {
    final double screenWidth = MediaQuery.of(context).size.width;

    final bool isTablet = screenWidth >= 600;
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 0),
      title: Text(
        title,
        style: TextStyle(
          fontSize: isTablet ? 20 : 17,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 28),
      onTap: onTap,
    );
  }
}
