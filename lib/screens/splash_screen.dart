import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // 1. Get the saved token
    final prefs = await SharedPreferences.getInstance();
    final String? savedToken = prefs.getString('auth_token');

    // 2. Add a tiny delay so the logo shows for at least 1 second
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // 3. Go to MainScreen, passing the token (it will be null if they aren't logged in, which is perfect for Guest Mode!)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => MainScreen(token: savedToken)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Center(
        child: Icon(
          Icons.fitness_center_rounded,
          size: 80,
          color: AppColors.primaryLight,
        ),
      ),
    );
  }
}