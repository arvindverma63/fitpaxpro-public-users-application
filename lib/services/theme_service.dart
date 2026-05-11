import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _key = 'is_dark_mode';
  static final ValueNotifier<bool> isDarkMode = ValueNotifier<bool>(true);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode.value = prefs.getBool(_key) ?? true;
  }

  static Future<void> toggleTheme() async {
    isDarkMode.value = !isDarkMode.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, isDarkMode.value);
  }

  static Future<void> setDarkMode(bool value) async {
    isDarkMode.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}
