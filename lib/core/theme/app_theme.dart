import 'package:flutter/material.dart';

class AppTheme {
  static const Color deepRed = Color(0xFFE53935);
  static const Color darkBackground = Color(0xFF121212);
  static const Color cardColor = Color(0xFF1E1E1E);

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,
    primaryColor: deepRed,
    colorScheme: const ColorScheme.dark(
      primary: deepRed,
      secondary: deepRed,
      surface: cardColor,
      background: darkBackground,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: cardColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: deepRed,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: cardColor,
      selectedItemColor: deepRed,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white70),
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
  );
}
