import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:snapwise/web/landing_page.dart';
import 'package:snapwise/app/budget/budget.dart';
import 'package:snapwise/app/budget/edit_budget.dart';
import 'package:snapwise/app/budget/income/edit_income.dart';
import 'package:snapwise/app/budget/income/input_income.dart';
import 'package:snapwise/app/budget/create_budget.dart';
import 'package:snapwise/app/expense/expense.dart';
import 'package:snapwise/app/auth_screens/forgot_password/forgot.dart';
import 'package:snapwise/app/history/records.dart';
import 'package:snapwise/app/home/home_screens/home.dart';
import 'package:snapwise/app/home/predict_screens/predict.dart';
import 'package:snapwise/app/auth_screens/login/login.dart';
import 'package:snapwise/app/notification/notification.dart';
import 'package:snapwise/app/profile/settings/about.dart';
import 'package:snapwise/app/profile/settings/notification.dart';
import 'package:snapwise/app/profile/profile.dart';
import 'package:snapwise/app/profile/settings/setting.dart';
import 'package:flutter/material.dart';
import 'package:snapwise/app/auth_screens/register/register.dart';
import 'package:snapwise/app/auth_screens/register/success.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:snapwise/app/widget/bottomnavbar.dart';
import 'package:snapwise/services/firebase_options.dart';
import 'package:snapwise/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    // Initialize notification service
    Get.put(NotificationService());
  }

  runApp(kIsWeb ? WebScreen() : UserScreen());

  // try {
  //   // Initialize Firebase only if not in web or if web platform is supported
  //   if (!kIsWeb || (kIsWeb && Firebase.apps.isEmpty)) {
  //     await Firebase.initializeApp(
  //       options: DefaultFirebaseOptions.currentPlatform,
  //     );
  //   }

  //   // Initialize Firebase Messaging only if not web
  //   if (!kIsWeb) {
  //     final notificationService = NotificationService();
  //     await notificationService.initialize();
  //   }

  //   runApp(kIsWeb ? WebScreen() : UserScreen());
  // } catch (e) {
  //   log('Error during app initialization: $e');
  //   // Fallback to basic app initialization
  //   runApp(kIsWeb ? WebScreen() : UserScreen());
  // }
}

class UserScreen extends StatelessWidget {
  const UserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize SnackbarUtils after GetMaterialApp is created

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SplashScreen(),
      defaultTransition: Transition.fade,
      enableLog: true,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(1.0)),
          child: child!,
        );
      },
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

class WebScreen extends StatelessWidget {
  const WebScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize SnackbarUtils after GetMaterialApp is created

    return GetMaterialApp(
      initialRoute: '/',
      defaultTransition: Transition.fade,
      debugShowCheckedModeBanner: false,
      enableLog: true,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(1.0)),
          child: child!,
        );
      },
      getPages: [
        GetPage(name: '/', page: () => LandingPage()),
      ],
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
    // Reduce splash screen delay for web
    checkUserLoggedIn();
  }

  void checkUserLoggedIn() async {
    try {
      // Shorter delay for web platform
      await Future.delayed(Duration(seconds: kIsWeb ? 1 : 2));

      // Check if user is logged in
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => BottomNavBar()),
        );
      } else {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      // Handle any errors during authentication check
      log('Error during authentication check: $e');
      if (!mounted) return;
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
          return Center(
            child: Image.asset(
              'assets/logo.png',
              width: logoSize,
              // Add cacheWidth for better web performance
              cacheWidth:
                  (logoSize * MediaQuery.of(context).devicePixelRatio).toInt(),
            ),
          );
        },
      ),
    );
  }
}
