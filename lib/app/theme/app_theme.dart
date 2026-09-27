import 'package:flutter/material.dart';

class AsamTheme {
  AsamTheme._();

  static const navy = Color(0xFF294B68);
  static const gold = Color(0xFFD5A14E);
  static const ink = Color(0xFF202B26);
  static const muted = Color(0xFF69736D);
  static const canvas = Color(0xFFF4F6F4);
  static const line = Color(0xFFD9DEDA);
  static const selected = Color(0xFFE5EEF4);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: navy,
      brightness: Brightness.light,
    ).copyWith(
      primary: navy,
      secondary: gold,
      surface: Colors.white,
      onSurface: ink,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      fontFamily: 'Arial',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 36, height: 1.08, fontWeight: FontWeight.w800, color: ink),
        headlineMedium: TextStyle(fontSize: 30, height: 1.1, fontWeight: FontWeight.w800, color: ink),
        titleLarge: TextStyle(fontSize: 22, height: 1.2, fontWeight: FontWeight.w800, color: ink),
        titleMedium: TextStyle(fontSize: 17, height: 1.2, fontWeight: FontWeight.w700, color: ink),
        bodyLarge: TextStyle(fontSize: 16, height: 1.45, color: ink),
        bodyMedium: TextStyle(fontSize: 15, height: 1.4, color: muted),
        labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ink),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: navy, width: 1.5),
        ),
      ),
      dividerTheme: const DividerThemeData(color: line, thickness: 1, space: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
