import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'theme/app_colors.dart';
import 'screens/main_screen.dart';
import 'screens/splash_screen.dart';
import 'services/ai_api_service.dart';
import 'services/api_service.dart';
import 'services/theme_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Services
  await AiApiService.init();
  await ApiService.init();
  await ThemeService.init();

  runApp(const GymFinderApp());
}

class GymFinderApp extends StatelessWidget {
  const GymFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeService.isDarkMode,
      builder: (context, isDark, child) {
        return MaterialApp(
          key: ValueKey(isDark), // This forces the entire app to rebuild when theme changes
          title: 'FitPax Pro',
          debugShowCheckedModeBanner: false,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          
          // --- LIGHT THEME ---
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: AppColors.primary,
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            cardColor: Colors.white,
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: false,
              iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
              titleTextStyle: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              surface: Colors.white,
              background: const Color(0xFFF8FAFC),
            ),
            useMaterial3: true,
          ),

          // --- DARK THEME ---
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: AppColors.primary,
            scaffoldBackgroundColor: AppColors.scaffoldBg,
            cardColor: AppColors.cardBg,
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: false,
              iconTheme: IconThemeData(color: AppColors.textMain),
              titleTextStyle: TextStyle(
                color: AppColors.textMain,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.cardBg,
              background: AppColors.scaffoldBg,
            ),
            useMaterial3: true,
          ),
          
          home: const SplashScreen(),
        );
      },
    );
  }
}