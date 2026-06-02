import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../utils/app_preferences.dart';
import 'login.dart';
import '../dashboard/welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _startApp();
  }

  Future<void> _startApp() async {

    /// wait for animation
    await Future.delayed(const Duration(seconds: 3));

    int? userId = await AppPreferences.getUserId();

    if (!mounted) return;

    if (userId != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const WelcomeScreen(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFF4D2D),
      body: Center(
        child: Lottie.asset(
          "assets/animations/logo_animation.json",
          width: double.maxFinite,
        ),
      ),
    );
  }
}