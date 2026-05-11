import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';
import 'all_videos_screen.dart';
import 'ai_chat_screen.dart';
import 'profile_screen.dart';

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
    // <-- ADDED: Initialize pages here to pass the token down to HomeScreen and ProfileScreen
    _pages = [
      HomeScreen(token: widget.token),
      const AllVideosScreen(),
      const AiChatScreen(),
      ProfileScreen(token: widget.token),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // We only extend body for Home, Discover, and Profile. 
      // We disable it for Fit AI (index 2) so the input bar isn't covered.
      extendBody: _currentIndex != 2, 
      backgroundColor: AppColors.scaffoldBg,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildProfessionalNavBar(),
    );
  }

  Widget _buildProfessionalNavBar() {
    return Container(
      color: Colors.transparent, // Make outer container transparent
      child: SafeArea(
        child: Container(
          height: 70,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Home'),
              _buildNavItem(1, Icons.play_circle_fill_rounded, 'Discover'),
              _buildNavItem(2, Icons.smart_toy_rounded, 'Fit AI'),
              _buildNavItem(3, Icons.person_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryLight : AppColors.textMuted,
              size: isSelected ? 26 : 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primaryLight : AppColors.textMuted,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}