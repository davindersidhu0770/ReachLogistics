import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/auth/login.dart';
import 'screens/dashboard/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final int? userId = prefs.getInt("USER_ID");

  runApp(ReachApp(userId: userId));
}

class ReachApp extends StatelessWidget {
  final int? userId;

  const ReachApp({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Reach Logistics',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF4F4F4),
        fontFamily: 'Poppins',
      ),

      /// AUTO LOGIN
      home: userId != null
          ? const WelcomeScreen()
          : const LoginScreen(),
    );
  }
}