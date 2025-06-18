import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:snapwise/app/auth_screens/register/register_controller.dart';

class VerifyScreen extends StatefulWidget {
  final String email;
  final String username;
  final String password;
  const VerifyScreen({
    super.key,
    required this.email,
    required this.username,
    required this.password,
  });

  @override
  VerifyScreenState createState() => VerifyScreenState();
}

class VerifyScreenState extends State<VerifyScreen> {
  final _controller = Get.put(RegisterController());
  final TextEditingController _pinController = TextEditingController();
  int _seconds = 30;
  late final dynamic timer;


  @override
  void initState() {
    super.initState();
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
  void dispose() {
    _pinController.dispose();
    super.dispose();
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
                        onPressed: () => Navigator.of(context).pop(),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _verifyCode(),
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
                onTap:
                    _seconds == 0
                        ? () {
                          setState(() {
                            _seconds = 30;
                          });
                          _startTimer();
                          _controller.sendVerificationEmail();
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
    if (_pinController.text.length != 6) {
      Get.snackbar('Error', 'Please enter the complete verification code');
      return;
    }

    bool success = await _controller.verifyCode(_pinController.text);
    if (success) {
      Get.snackbar(
        'Success',
        'Account created successfully',
        duration: Duration(seconds: 3),
      );
      Get.offAllNamed(
        '/login',
      ); // Navigate to home screen after successful verification
    } else {
      Get.snackbar(
        'Invalid Code',
        'Please check the code and try again',
        duration: Duration(seconds: 3),
      );
    }
  }
}
