import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';
import 'all_videos_screen.dart';
import 'ai_chat_screen.dart';

class MainScreen extends StatefulWidget {
  final String? token; // <-- ADDED: Accepts the token from Login/Registration

  const MainScreen({super.key, this.token});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // <-- CHANGED: Mark as late so we can initialize it in initState
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // <-- ADDED: Initialize pages here to pass the token down to HomeScreen
    _pages = [
      HomeScreen(token: widget.token), // Passing the token!
      const AllVideosScreen(),
      const AiChatScreen(),
      const Center(child: Text('Profile', style: TextStyle(color: Colors.white))),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.cardBg,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: AppColors.textMuted,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.play_circle_fill_rounded), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy_rounded), label: 'Fit AI'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}