import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFFFFF8F0); // Cream
  static const Color primary = Color(0xFF2D6A4F); // Forest Green
  static const Color accent = Color(0xFFFFB703); // Tangerine Orange
  static const Color card = Color(0xFFFFEBD6);
  static const Color inputFill = Colors.white;

  static ThemeData get theme {
    return ThemeData(
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        background: background,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
        ),
      ),
      useMaterial3: true,
    );
  }
}
