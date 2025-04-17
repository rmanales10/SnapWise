import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery to get the screen width
    final double screenWidth = MediaQuery.of(context).size.width;

    // For tablets, we might want to add larger icon sizes and more spacing
    final bool isTablet =
        screenWidth >= 600; // Adjust this threshold for tablets

    return SizedBox(
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(context, Icons.home_filled, "Home", 0, isTablet),
                _buildNavItem(
                  context,
                  Icons.receipt_long_sharp,
                  "Records",
                  1,
                  isTablet,
                ),
                const SizedBox(width: 40), // Center button gap
                _buildNavItem(
                  context,
                  Icons.pie_chart_rounded,
                  "Budget",
                  2,
                  isTablet,
                ),
                _buildNavItem(context, Icons.person, "Profile", 3, isTablet),
              ],
            ),
          ),
          Positioned(
            top: isTablet ? -45 : -25,
            child: _buildCenterButton(context, isTablet),
          ),
        ],
      ),
    );
  }

  // Pass isTablet to adjust the icons and text size for tablet screens
  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
    bool isTablet,
  ) {
    bool isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () {
        onTap(index); // optional, in case you track index in parent

        // Navigate based on index using pushReplacementNamed
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/home');
            break;
          case 1:
            Navigator.pushReplacementNamed(context, '/records');
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/budget');
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/profile');
            break;
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isTablet ? 30 : 24,
            color:
                isSelected ? const Color.fromARGB(255, 3, 30, 53) : Colors.grey,
          ),
          SizedBox(height: isTablet ? 6 : 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isTablet ? 14 : 10,
              color:
                  isSelected
                      ? const Color.fromARGB(255, 3, 30, 53)
                      : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // Adjust the center button size for tablets
  Widget _buildCenterButton(BuildContext context, bool isTablet) {
    return GestureDetector(
      onTap: () => Navigator.pushReplacementNamed(context, '/expense'),
      child: Container(
        padding: EdgeInsets.all(
          isTablet ? 20 : 15,
        ), // Larger padding for tablets
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 3, 30, 53),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 6, spreadRadius: 2),
          ],
        ),
        child: Icon(
          Icons.add,
          color: Colors.white,
          size: isTablet ? 36 : 28, // Larger icon for tablets
        ),
      ),
    );
  }
}
