import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:snapwise/screens/budget/budget.dart';
import 'package:snapwise/screens/budget/edit_budget.dart';
import 'package:snapwise/screens/budget/income/edit_income.dart';
import 'package:snapwise/screens/budget/income/input_income.dart';
import 'package:snapwise/screens/budget/create_budget.dart';
import 'package:snapwise/screens/expense/expense.dart';
import 'package:snapwise/screens/auth_screens/forgot_password/forgot.dart';
import 'package:snapwise/screens/history/records.dart';
import 'package:snapwise/screens/home/home_screens/home.dart';
import 'package:snapwise/screens/home/predict_screens/predict.dart';
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
import 'package:snapwise/screens/widget/bottomnavbar.dart';
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
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checkUserLoggedIn();
  }

  void checkUserLoggedIn() async {
    // Wait for 2 seconds to show the splash screen
    await Future.delayed(const Duration(seconds: 2));

    // Check if user is logged in
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // User is logged in, navigate to home
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => BottomNavBar()),
      );
    } else {
      // User is not logged in, navigate to login
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          double logoSize = constraints.maxWidth * 0.4;
          return Center(child: Image.asset('assets/logo.png', width: logoSize));
        },
      ),
    );
  }
}
