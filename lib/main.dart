import 'package:emperiosquartet/login/forgot1.dart';
import 'package:emperiosquartet/login/loadingScreen.dart';
import 'package:emperiosquartet/login/login1.dart';
import 'package:emperiosquartet/login/register1.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/login': (context) => const Login(),
        '/create': (context) => const CreateAcc(),
        '/forgot': (context) => const ForgotPass(),
      },
      debugShowCheckedModeBanner: false,
      title: 'SnapWise',
      home: const LoadingScreen(),
    );
  }
}
