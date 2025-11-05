import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snapwise/app/auth_screens/register/register_controller.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:snapwise/app/auth_screens/verify/verify_screen.dart';
import 'package:snapwise/services/snackbar_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _controller = Get.put(RegisterController());
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _phoneNumber = '';
  bool _showPassword = false;
  bool _acceptTerms = false;
  bool _isSubmitting = false;

  final bool isTablet = MediaQueryData.fromView(
        // ignore: deprecated_member_use
        WidgetsBinding.instance.window,
      ).size.shortestSide >
      600;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 3, 30, 53),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 40 : 20,
                  vertical: 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "LET'S",
                      style: TextStyle(
                        fontSize: isTablet ? 40 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "CREATE",
                      style: TextStyle(
                        fontSize: isTablet ? 40 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "YOUR",
                      style: TextStyle(
                        fontSize: isTablet ? 40 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "ACCOUNT",
                      style: TextStyle(
                        fontSize: isTablet ? 40 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: isTablet ? 50 : 0),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 50 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Username
                    const Text(
                      "Username",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _usernameController,
                      cursorColor: const Color.fromARGB(255, 3, 30, 53),
                      decoration: _inputDecoration("Your username"),
                    ),
                    const SizedBox(height: 20),

                    // Email
                    const Text(
                      "Email",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      cursorColor: const Color.fromARGB(255, 3, 30, 53),
                      decoration: _inputDecoration("Your email"),
                    ),
                    const SizedBox(height: 20),

                    // Phone Number
                    const Text(
                      "Phone Number",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    IntlPhoneField(
                      initialCountryCode: 'PH',
                      flagsButtonPadding:
                          const EdgeInsets.symmetric(horizontal: 10),
                      showDropdownIcon: false,
                      onChanged: (phone) {
                        _phoneNumber = phone.completeNumber;
                      },
                      decoration: InputDecoration(
                        hintText: 'Phone Number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color.fromARGB(255, 3, 30, 53)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color.fromARGB(255, 3, 30, 53)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color.fromARGB(255, 3, 30, 53)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      cursorColor: const Color.fromARGB(255, 3, 30, 53),
                      keyboardType: TextInputType.phone,
                    ),

                    // Password
                    const Text(
                      "Password",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      cursorColor: const Color.fromARGB(255, 3, 30, 53),
                      decoration: _inputDecoration("Your password").copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Terms checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptTerms,
                          onChanged: (value) {
                            setState(() {
                              _acceptTerms = value ?? false;
                            });
                          },
                          activeColor: const Color.fromARGB(255, 3, 30, 53),
                        ),
                        const Text(
                          "I accept the ",
                          style: TextStyle(fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () => _showTermsDialog(context),
                          child: const Text(
                            "terms ",
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.blue,
                            ),
                          ),
                        ),
                        const Text("and ", style: TextStyle(fontSize: 14)),
                        GestureDetector(
                          onTap: () => _showPrivacyDialog(context),
                          child: const Text(
                            "privacy policy",
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Register Button
                    _isSubmitting
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _isSubmitting = true;
                                });
                                onSubmit();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 3, 30, 53),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text(
                                "Register",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ),
                    const SizedBox(height: 20),

                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(
                            color: Color.fromARGB(255, 3, 30, 53),
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/login');
                          },
                          child: const Text(
                            "Login",
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color.fromARGB(255, 3, 30, 53)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color.fromARGB(255, 3, 30, 53)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color.fromARGB(255, 3, 30, 53)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Terms of Service',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: const Text(
              'Welcome to Snapwise!\n\n'
              '1. Use of Service: Use Snapwise responsibly and lawfully.\n'
              '2. Account Responsibility: You\'re responsible for your account activity.\n'
              '3. Content Ownership: You own what you upload. We just store it.\n'
              '4. Termination: We can suspend accounts that break the rules.\n'
              '5. Updates: Terms may change. We\'ll let you know.\n'
              'Questions? Email us at support@snapwise.app.',
              textAlign: TextAlign.left,
            ),
          ),
          actions: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Privacy Policy',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: const Text(
              'Snapwise respects your privacy.\n\n'
              '1. Data Collected: We collect basic info like email, username, and photos.\n'
              '2. Usage: Data is used to improve your experience. No selling.\n'
              '3. Security: We use secure practices to protect your data.\n'
              '4. Your Control: You can delete your account and data anytime.\n'
              'Questions? Contact support@snapwise.app.',
              textAlign: TextAlign.left,
            ),
          ),
          actions: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // In your form submission:
  void onSubmit() async {
    // ignore: use_build_context_synchronously

    // Set the controller values
    _controller.username = _usernameController.text;
    _controller.email = _emailController.text;
    _controller.password = _passwordController.text;
    _controller.phoneNumber = _phoneNumber;

    // Debug: Log phone number before registration
    print('📱 Register Form: _phoneNumber value: $_phoneNumber');
    print('📱 Register Form: _phoneNumber length: ${_phoneNumber.length}');
    print('📱 Register Form: _phoneNumber isEmpty: ${_phoneNumber.isEmpty}');
    print(
        '📱 Register Form: Controller phoneNumber: ${_controller.phoneNumber}');

    // Validate phone number
    if (_phoneNumber.isEmpty) {
      SnackbarService.showError(
          title: 'Registration Error',
          message: 'Please enter a valid phone number');
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    // Call the registration method
    bool success = await _controller.register();

    if (success) {
      print(
          '📱 Register Form: Navigating to VerifyScreen with phone: $_phoneNumber');
      // Navigate to verify screen after successful registration
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => VerifyScreen(
                    email: _emailController.text,
                    username: _usernameController.text,
                    password: _passwordController.text,
                    phoneNumber: _phoneNumber,
                  )));
    } else {
      // Show error message if registration fails
      SnackbarService.showError(
          title: 'Registration Error', message: _controller.errorMessage.value);
    }
    setState(() {
      _isSubmitting = false;
    });
  }
}
