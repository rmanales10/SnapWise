import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:snapwise/app/auth_screens/register/register_controller.dart';
import 'package:snapwise/app/auth_screens/login/login_controller.dart';
import 'package:snapwise/app/auth_screens/login/login.dart';
import 'package:snapwise/app/crypto/cryptograpy.dart';
import 'package:snapwise/app/widget/bottomnavbar.dart';
import 'package:snapwise/services/snackbar_service.dart';
import 'package:snapwise/app/auth_screens/sms_service/sms_service.dart';

class VerifyScreen extends StatefulWidget {
  final String username;
  final String password;
  final String phoneNumber;
  final String email;
  final bool
      isLoginVerification; // New parameter to distinguish login vs registration

  const VerifyScreen({
    super.key,
    required this.username,
    required this.password,
    required this.phoneNumber,
    required this.email,
    this.isLoginVerification =
        false, // Default to false for backward compatibility
  });

  @override
  VerifyScreenState createState() => VerifyScreenState();
}

class VerifyScreenState extends State<VerifyScreen> {
  late final dynamic _controller;
  final TextEditingController _pinController = TextEditingController();
  int _seconds = 180; // 3 minutes
  Timer? _timer;
  bool _isSubmitting = false;
  late final SmsService _smsService;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();

    // Use appropriate controller based on verification type
    if (widget.isLoginVerification) {
      _controller = Get.put(LoginController());
    } else {
      _controller = Get.put(RegisterController());
      SnackbarService.showSuccess(
          title: 'Success', message: 'Verification code sent to your phone');
    }

    // Initialize SMS service
    _smsService = Get.put(SmsService());

    // SMS verification code already sent during registration
    // No need to send again

    // Start the countdown timer
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_seconds > 0) {
            _seconds--;
          } else {
            timer.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: Color(0xFF2D2C44),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 16,
                      left: 16,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(
                            Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 36,
                      top: 90,
                      child: Text(
                        "ENTER\nCODE",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),

              // SMS Icon and Title
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.sms_outlined,
                  color: Colors.blue.shade600,
                  size: 40,
                ),
              ),

              SizedBox(height: 16),
              Text(
                "SMS Verification",
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 8),
              Text(
                "We've sent a verification code to\n${widget.phoneNumber}",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black87, fontSize: 15),
              ),
              SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: PinCodeTextField(
                  appContext: context,
                  length: 6,
                  controller: _pinController,
                  obscureText: false,
                  animationType: AnimationType.none,
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(10),
                    fieldHeight: 56,
                    fieldWidth: 40,
                    activeFillColor: Colors.white,
                    inactiveFillColor: Colors.white,
                    selectedFillColor: Colors.white,
                    activeColor: Colors.black,
                    selectedColor: Colors.black,
                    inactiveColor: Colors.black26,
                  ),
                  backgroundColor: Colors.transparent,
                  enableActiveFill: true,
                  onChanged: (value) {},
                ),
              ),
              SizedBox(height: 32),
              _isSubmitting
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            if (mounted) {
                              setState(() {
                                _isSubmitting = true;
                              });
                              _verifyCode();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF2D2C44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            "Verify",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
              SizedBox(height: 16),
              GestureDetector(
                onTap: _seconds == 0
                    ? () {
                        if (mounted) {
                          setState(() {
                            _seconds = 180; // 3 minutes
                          });
                          _startTimer();
                          _resendSmsCode();
                        }
                      }
                    : null,
                child: Text(
                  "Resend SMS code  ${_formatTime(_seconds)}",
                  style: TextStyle(
                    color: _seconds == 0 ? Colors.blue : Colors.black54,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resendSmsCode() async {
    // Check if widget is still mounted before proceeding
    if (!mounted) return;

    // Generate new verification code
    String newVerificationCode = _generateNewVerificationCode();

    // Update the controller with new code
    _controller.verificationCode = newVerificationCode;

    bool smsSuccess = await _smsService.sendVerificationCode(
      phoneNumber: widget.phoneNumber,
      code: newVerificationCode,
    );

    if (!mounted) return;

    if (smsSuccess) {
      SnackbarService.showSuccess(
        title: 'SMS Sent',
        message: 'New verification code sent to your phone',
      );
    } else {
      SnackbarService.showError(
        title: 'SMS Failed',
        message: 'Failed to send SMS. Please try again.',
      );
    }
  }

  String _generateNewVerificationCode() {
    final random = Random();
    String code = '';
    for (int i = 0; i < 6; i++) {
      code += random.nextInt(10).toString();
    }
    return code;
  }

  void _verifyCode() async {
    // Check if widget is still mounted before proceeding
    if (!mounted) return;

    _controller.username = widget.username;
    _controller.password = widget.password;
    _controller.phoneNumber = widget.phoneNumber;
    _controller.email = widget.email;

    // If this is login verification and phone number is provided, store it in temp storage
    if (widget.isLoginVerification && widget.phoneNumber.isNotEmpty) {
      final storage = GetStorage();
      await storage.write('tempUserPhoneNumber', widget.phoneNumber);
    }

    // Check if controller is still valid before accessing text
    if (_pinController.text.length != 6) {
      SnackbarService.showError(
          title: 'Error',
          message: 'Please enter the complete verification code');
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }

      return;
    }

    bool success;
    if (widget.isLoginVerification) {
      success = await _controller.verifyCode(_pinController.text);
    } else {
      success = await _controller.verifyCode(_pinController.text);
    }

    // Check if widget is still mounted before updating UI
    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      if (widget.isLoginVerification) {
        SnackbarService.showSuccess(
            title: 'Success', message: 'Login successful');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => BottomNavBar(initialIndex: 0)),
        );
      } else {
        // Complete user registration after successful verification
        await _completeUserRegistration();
      }
    } else {
      SnackbarService.showError(
          title: 'Error', message: 'Please check the code and try again');
    }
  }

  Future<void> _completeUserRegistration() async {
    try {
      // Check if widget is still mounted before proceeding
      if (!mounted) return;

      // Debug: Log phone number before registration
      print('📱 Registration: Phone number from widget: ${widget.phoneNumber}');
      print(
          '📱 Registration: Phone number length: ${widget.phoneNumber.length}');
      print(
          '📱 Registration: Phone number isEmpty: ${widget.phoneNumber.isEmpty}');

      // Create user with email and password after successful verification
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );

      User? currentUser = userCredential.user;

      if (currentUser != null) {
        // Ensure phone number is not empty, use the widget value or fallback to controller
        String phoneNumberToStore = widget.phoneNumber.trim();

        // If widget phone number is empty, try to get it from controller
        if (phoneNumberToStore.isEmpty && !widget.isLoginVerification) {
          if (_controller is RegisterController) {
            phoneNumberToStore =
                (_controller as RegisterController).phoneNumber.trim();
            print(
                '📱 Registration: Using phone number from controller: $phoneNumberToStore');
          }
        }

        print(
            '📱 Registration: Final phone number to store: $phoneNumberToStore');

        // Create user document in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .set({
          'username': widget.username,
          'email': widget.email,
          'phoneNumber': phoneNumberToStore,
          'isVerified': true,
          'verifiedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'password': encryptText(widget.password),
        });

        print(
            '📱 Registration: User document created with phone number: $phoneNumberToStore');

        // Store user data in local storage
        final storage = GetStorage();
        await storage.write('isLoggedIn', true);
        await storage.write('userUid', currentUser.uid);
        await storage.write('userEmail', currentUser.email);
        await storage.write('userDisplayName', widget.username);
        await storage.write('userPhoneNumber', phoneNumberToStore);
        await storage.write('userPhotoUrl', currentUser.photoURL ?? '');

        // Check if widget is still mounted before showing success message
        if (!mounted) return;

        SnackbarService.showSuccess(
          title: 'Registration Successful',
          message: 'User Registration Successfully! Please login to continue.',
        );

        // Check if widget is still mounted before navigation
        if (!mounted) return;

        // Navigate to login page
        _auth.signOut();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } else {
        if (!mounted) return;

        SnackbarService.showError(
          title: 'Error',
          message: 'Failed to create user account. Please try again.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      SnackbarService.showError(
        title: 'Registration Error',
        message: 'Failed to complete registration: ${e.toString()}',
      );
    }
  }
}
