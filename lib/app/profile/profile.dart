import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:snapwise/app/auth_screens/login/login_controller.dart';
import 'package:snapwise/app/widget/bottomnavbar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final loginController = Get.put(LoginController());
  final _storage = GetStorage();
  RxString displayName = ''.obs;
  RxString photoUrl = ''.obs;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _fetchUserData() {
    displayName.value = _storage.read('displayName') ?? '';
    photoUrl.value = _storage.read('photoUrl') ?? '';
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width to detect tablet size
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth >= 600; // Tablet size threshold

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal:
              isTablet ? 40 : 30, // Increase horizontal padding for tablets
          vertical: isTablet ? 40 : 20, // Increase vertical padding for tablets
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            Padding(
              padding: const EdgeInsets.only(top: 50),
              child: Obx(() {
                ImageProvider imageProvider = photoUrl.isNotEmpty
                    ? NetworkImage(photoUrl.value) as ImageProvider
                    : const AssetImage('assets/logo.png') as ImageProvider;

                return Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(
                        isTablet ? 5 : 3,
                      ), // Larger padding for tablets
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.blue, // Change color as needed
                          width: 3, // Border thickness
                        ),
                      ),
                      child: CircleAvatar(
                        backgroundImage: imageProvider,
                        backgroundColor: Colors.grey,
                        radius: isTablet ? 50 : 35, // Larger avatar for tablets
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Username',
                          style: TextStyle(
                            fontSize:
                                isTablet ? 20 : 15, // Larger text for tablets
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          displayName.value.isEmpty
                              ? 'Set Username'
                              : displayName.value,
                          style: TextStyle(
                            fontSize:
                                isTablet ? 25 : 20, // Larger text for tablets
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Spacer(),
                    Icon(
                      LucideIcons.edit2,
                      size: isTablet ? 30 : 20,
                    ), // Larger icon for tablets
                    const SizedBox(width: 20),
                  ],
                );
              }),
            ),

            const SizedBox(height: 40),

            // Menu items container
            Container(
              padding: EdgeInsets.all(
                isTablet ? 10 : 5,
              ), // Larger padding for tablets
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _buildMenuButton(
                    Icons.home,
                    'Home',
                    Colors.blue.shade100,
                    Colors.blue,
                    () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BottomNavBar(initialIndex: 0),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  _buildMenuButton(
                    Icons.star,
                    'Favorites',
                    Colors.yellow.withOpacity(0.3),
                    Colors.yellow.shade700,
                    () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BottomNavBar(initialIndex: 14),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  _buildMenuButton(
                    Icons.settings,
                    'Settings',
                    Colors.purple.shade100,
                    Colors.purple,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BottomNavBar(initialIndex: 7),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _buildMenuButton(
                    Icons.logout,
                    'Logout',
                    Colors.red.shade100,
                    Colors.red,
                    () {
                      _showLogoutConfirmation(context);
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

  Widget _buildMenuButton(
    IconData icon,
    String text,
    Color color,
    Color color1,
    VoidCallback onTap,
  ) {
    final double screenWidth = MediaQuery.of(context).size.width;

    final bool isTablet = screenWidth >= 600;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(
            isTablet ? 10 : 5,
          ), // Larger padding for tablets
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color1,
            size: isTablet ? 35 : 30,
          ), // Larger icon for tablets
        ),
        title: Text(
          text,
          style: TextStyle(
            fontSize: isTablet ? 20 : 18, // Larger text for tablets
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade500),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    // Get screen width to detect tablet size
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth >= 600; // Tablet size threshold

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 40 : 25, // More padding for tablets
            vertical: isTablet ? 30 : 20, // More vertical padding for tablets
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 5,
                width: 40,
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Text(
                'Logout?',
                style: TextStyle(
                  fontSize: isTablet ? 22 : 18, // Larger text for tablets
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Are you sure you want to logout?',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: isTablet ? 18 : 16, // Larger text for tablets
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 16 : 12,
                        ), // Larger padding for tablets
                      ),
                      child: Text(
                        'No',
                        style: TextStyle(
                          fontSize:
                              isTablet ? 18 : 16, // Larger text for tablets
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => loginController.logout(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 3, 30, 53),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 16 : 12,
                        ), // Larger padding for tablets
                      ),
                      child: Text(
                        'Yes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize:
                              isTablet ? 18 : 16, // Larger text for tablets
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
