import 'package:flutter/material.dart';

class AppTheme {
  // Custom color palette
  static const Color lightBlue = Color(0xFFE3F2FD); // Light blue background
  static const Color lightGreen = Color(0xFFE8F5E8); // Light green background
  static const Color purpleHighlight = Color(0xFF836AB7); // Purple highlight
  static const Color purpleLight = Color(0xFFE8DDFF); // Light purple
  static const Color blueAccent = Color(0xFF2196F3); // Blue accent
  static const Color greenAccent = Color(0xFF4CAF50); // Green accent
  static const Color darkText = Color(0xFF212121); // Dark text
  static const Color lightText = Color(0xFF757575); // Light text
  static const Color white = Color(0xFFFFFFFF); // White
  static const Color surfaceColor = Color(0xFFFAFAFA); // Surface color

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color scheme
      colorScheme: const ColorScheme.light(
        primary: purpleHighlight,
        primaryContainer: purpleLight,
        secondary: blueAccent,
        secondaryContainer: lightBlue,
        tertiary: greenAccent,
        tertiaryContainer: lightGreen,
        surface: surfaceColor,
        onPrimary: white,
        onSecondary: white,
        onTertiary: white,
        onSurface: darkText,
      ),

      // App bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: purpleHighlight,
        foregroundColor: white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: white,
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: purpleHighlight,
          foregroundColor: white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: purpleHighlight,
        foregroundColor: white,
        elevation: 4,
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightBlue,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: blueAccent, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: blueAccent, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: purpleHighlight, width: 2),
        ),
        labelStyle: const TextStyle(color: darkText),
        hintStyle: const TextStyle(color: lightText),
      ),

      // Text theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: darkText,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: darkText,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkText,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: darkText,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: darkText),
        bodyMedium: TextStyle(fontSize: 14, color: darkText),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: darkText,
        ),
      ),

      // Icon theme
      iconTheme: const IconThemeData(color: purpleHighlight, size: 24),

      // List tile theme
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        tileColor: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: lightBlue,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
