import 'package:flutter/material.dart';

abstract final class MidAutumnColors {
  static const night = Color(0xFF101B3A);
  static const moon = Color(0xFFFFD166);
  static const lantern = Color(0xFFF4A261);
  static const cream = Color(0xFFFFF8E7);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF6B7280);
  static const moonBorder = Color(0x99FFD166);
  static const softShadow = Color(0x1A101B3A);
}

abstract final class MidAutumnTheme {
  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: MidAutumnColors.night,
      onPrimary: Colors.white,
      secondary: MidAutumnColors.moon,
      onSecondary: MidAutumnColors.night,
      tertiary: MidAutumnColors.lantern,
      surface: MidAutumnColors.surface,
      onSurface: MidAutumnColors.textPrimary,
      error: Color(0xFFBA1A1A),
    );
    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: const BorderSide(color: MidAutumnColors.moonBorder),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: MidAutumnColors.cream,
      appBarTheme: const AppBarTheme(
        backgroundColor: MidAutumnColors.night,
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: MidAutumnColors.surface,
        elevation: 2,
        shadowColor: MidAutumnColors.softShadow,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: rounded,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: MidAutumnColors.night,
        indicatorColor: Color(0x33FFD166),
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(color: MidAutumnColors.moon),
        ),
        labelTextStyle: WidgetStatePropertyAll(TextStyle(color: Colors.white)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: MidAutumnColors.moon,
        foregroundColor: MidAutumnColors.night,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MidAutumnColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: MidAutumnColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    );
  }
}
