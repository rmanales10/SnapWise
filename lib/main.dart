import 'package:get/get.dart';
import 'package:snapwise/screens/budget/budget.dart';
import 'package:snapwise/screens/budget/edit_budget.dart';
import 'package:snapwise/screens/budget/edit_budget_category.dart';
import 'package:snapwise/screens/budget/income/edit_income.dart';
import 'package:snapwise/screens/budget/income/input_income.dart';
import 'package:snapwise/screens/budget/create_budget.dart';
import 'package:snapwise/screens/expense/expense.dart';
import 'package:snapwise/screens/auth_screens/forgot_password/forgot.dart';
import 'package:snapwise/screens/history/records.dart';
import 'package:snapwise/screens/home/home.dart';
import 'package:snapwise/screens/home/predict.dart';
import 'package:snapwise/screens/auth_screens/login/login.dart';
import 'package:snapwise/screens/notification/notification.dart';
import 'package:snapwise/screens/profile/about.dart';
import 'package:snapwise/screens/profile/notification.dart';
import 'package:snapwise/screens/profile/profile.dart';
import 'package:snapwise/screens/profile/setting.dart';
import 'package:flutter/material.dart';
import 'package:snapwise/screens/auth_screens/register/register.dart';
import 'package:snapwise/screens/auth_screens/register/success.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:snapwise/services/firebase_options.dart';
import 'package:snapwise/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Firebase Messaging
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Retrieve and print the FCM token
  String? token = await notificationService.getToken();
  print('FCM Token: $token');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SplashScreen(),
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/success': (context) => RegistrationSuccessPage(),
        '/forgot': (context) => ForgotPasswordPage(),
        '/home': (context) => HomePage(),
        '/records': (context) => TransactionHistoryPage(),
        '/notification': (context) => NotificationPage(),
        '/expense': (context) => ExpenseManualPage(),
        '/profile': (context) => ProfilePage(),
        '/budget': (context) => BudgetPage(),
        '/setting': (context) => SettingsPage(),
        '/notif-setting': (context) => NotificationSettingsPage(),
        '/about': (context) => AboutPage(),
        '/predict': (context) => PredictBudgetPage(),
        '/input-income': (context) => InputIncome(),
        '/edit-income': (context) => IncomeEditPage(),
        '/create-budget': (context) => CreateBudget(),
        '/edit-budget': (context) => EditBudgetPage(),
        // '/edit-budget-category': (context) => EditBudgetCategoryPage(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Wait for 5 seconds and navigate to home screen
    Future.delayed(const Duration(seconds: 5), () {
      // ignore: use_build_context_synchronously
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          double logoSize = constraints.maxWidth * 0.4;
          return Center(
            child: Image.asset(
              'assets/logo.png', // Ensure logo.png is in assets folder
              width: logoSize,
            ),
          );
        },
      ),
    );
  }
}
