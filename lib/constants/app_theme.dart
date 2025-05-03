import 'package:flutter/material.dart';

/// App color constants
class AppColors {
  // Primary colors
  static const netflixRed = Color(0xFFE50914);
  static const netflixBlack = Color(0xFF000000);
  static const netflixDarkGrey = Color(0xFF333333);
  static const netflixMediumGrey = Color(0xFF6D6D6D);
  static const netflixLightGrey = Color(0xFFB3B3B3);

  // Background colors
  static const netflixBackground = Color(0xFF000000); // Pure black
  static const netflixCardBackground = Color(0xFF121212); // Very dark grey

  // Text colors
  static const netflixTextPrimary = Colors.white;
  static const netflixTextSecondary = Color(0xFFB3B3B3);

  // Status colors
  static const netflixSuccess = Color(0xFF46D369);
  static const netflixWarning = Color(0xFFFFA00A);
  static const netflixError = Color(0xFFE50914);
}

/// App theme
class AppTheme {
  // Dark theme (Netflix-like)
  static final ThemeData darkTheme = ThemeData.dark().copyWith(
    colorScheme: ColorScheme.dark(
      primary: AppColors.netflixRed,
      secondary: AppColors.netflixRed,
      surface: AppColors.netflixCardBackground,
      onSurface: AppColors.netflixTextPrimary,
      error: AppColors.netflixError,
    ),
    scaffoldBackgroundColor: AppColors.netflixBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.netflixBackground,
      selectedItemColor: Colors.white,
      unselectedItemColor: AppColors.netflixLightGrey,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    cardTheme: CardTheme(
      color: AppColors.netflixCardBackground,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.netflixRed,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Colors.white,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: AppColors.netflixTextSecondary,
      ),
    ),
  );
}
