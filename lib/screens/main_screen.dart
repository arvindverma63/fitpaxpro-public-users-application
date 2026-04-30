import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_bottom_nav.dart';
import 'home_screen.dart';
import 'all_videos_screen.dart'; // We will create this next

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // List of screens for the Bottom Nav
  final List<Widget> _screens = [
    const HomeScreen(),
    const AllVideosScreen(),
    const Center(child: Text('Saved (Coming Soon)', style: TextStyle(color: Colors.white))),
    const Center(child: Text('Profile (Coming Soon)', style: TextStyle(color: Colors.white))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      extendBody: true, // Crucial for floating bottom nav
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}