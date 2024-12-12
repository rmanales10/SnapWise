import 'dart:async';

import 'package:emperiosquartet/login/login1.dart';
import 'package:flutter/material.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Login(),
          )); // Navigate to your home screen or desired screen
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Background color
      body: Center(
        child: Image.asset(
          'assets/logo.jpg', // Path to the first image (fish image)
          width: 150, // Adjust size as necessary
          height: 150,
        ),
      ),
    );
  }
}
