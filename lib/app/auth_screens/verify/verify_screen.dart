import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:snapwise/app/auth_screens/register/register_controller.dart';
import 'package:snapwise/app/auth_screens/login/login_controller.dart';
import 'package:snapwise/app/widget/bottomnavbar.dart';

class VerifyScreen extends StatefulWidget {
  final String email;
  final String username;
  final String password;
  final String phoneNumber;
  final bool
      isLoginVerification; // New parameter to distinguish login vs registration

  const VerifyScreen({
    super.key,
    required this.email,
    required this.username,
    required this.password,
    required this.phoneNumber,
    this.isLoginVerification =
        false, // Default to false for backward compatibility
  });

  @override
  VerifyScreenState createState() => VerifyScreenState();
}

class VerifyScreenState extends State<VerifyScreen> {
  late final dynamic _controller;
  final TextEditingController _pinController = TextEditingController();
  int _seconds = 30;
  late final dynamic timer;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    // Use appropriate controller based on verification type
    if (widget.isLoginVerification) {
      _controller = Get.put(LoginController());
    } else {
      _controller = Get.put(RegisterController());
    }

    timer = Future.delayed(Duration.zero, _startTimer);
  }

  void _startTimer() {
    Future.doWhile(() async {
      if (_seconds > 0) {
        await Future.delayed(Duration(seconds: 1));
        setState(() {
          _seconds--;
        });
        return true;
      }
      return false;
    });
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
              Text(
                "We've sent a verification code to\n${widget.email}",
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
                            setState(() {
                              _isSubmitting = true;
                            });
                            _verifyCode();
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
                        setState(() {
                          _seconds = 30;
                        });
                        _startTimer();
                        if (widget.isLoginVerification) {
                          _controller.sendVerificationEmail();
                        } else {
                          _controller.sendVerificationEmail();
                        }
                      }
                    : null,
                child: Text(
                  "Resend verification code  00:${_seconds.toString().padLeft(2, '0')}",
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

  void _verifyCode() async {
    _controller.username = widget.username;
    _controller.email = widget.email;
    _controller.password = widget.password;
    _controller.phoneNumber = widget.phoneNumber;
    if (_pinController.text.length != 6) {
      Get.snackbar('Error', 'Please enter the complete verification code');
      setState(() {
        _isSubmitting = false;
      });

      return;
    }

    bool success;
    if (widget.isLoginVerification) {
      success = await _controller.verifyCode(_pinController.text);
    } else {
      success = await _controller.verifyCode(_pinController.text);
    }
    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      if (widget.isLoginVerification) {
        Get.snackbar('Success', 'Login successful');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => BottomNavBar(initialIndex: 0)),
        );
      } else {
        // For registration verification, navigate to login screen
        Get.snackbar('Success', 'Account created successfully');
        Navigator.pushReplacementNamed(context, '/success');
      }
    } else {
      Get.snackbar('Error', 'Please check the code and try again');
    }
  }
}
