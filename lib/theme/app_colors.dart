import 'package:flutter/material.dart';
import '../services/theme_service.dart';

class AppColors {
  static bool get isDark => ThemeService.isDarkMode.value;

  // Brand Colors
  static const Color primary = Color(0xFFDC2626); // Rich Crimson Red
  static const Color primaryLight = Color(0xFFEF4444); // Vibrant Red
  static const Color accent = Color(0xFFF59E0B); // Amber for ratings/stars

  // Background & Surface Colors
  static Color get scaffoldBg => isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC);
  static Color get cardBg => isDark ? const Color(0xFF1E1E1E) : Colors.white;

  // Text Colors
  static Color get textMain => isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B);
  static Color get textMuted => isDark ? const Color(0xFF9CA3AF) : const Color(0xFF64748B);

  // Status Colors
  static const Color verifiedIcon = Color(0xFF38BDF8); 
  static Color get sponsoredBg => isDark ? const Color(0xFF451A1A) : const Color(0xFFFEE2E2);
  static Color get sponsoredText => isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B);

  // Expanded Section Colors
  static Color get expandedBg => isDark ? const Color(0xFF262626) : const Color(0xFFF1F5F9);
  static Color get expandedText => isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155);

  // Border Colors
  static Color get borderColor => isDark ? Colors.white10 : Colors.black.withOpacity(0.08);
}