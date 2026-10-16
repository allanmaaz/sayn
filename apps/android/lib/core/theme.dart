import 'package:flutter/material.dart';

class SaynColors {
  // Dark Theme (Wispr Flow Obsidian & Volt Neon Green)
  static const Color darkBg = Color(0xFF0D0D12);
  static const Color darkSurface = Color(0xFF16161D);
  static const Color darkSurface2 = Color(0xFF1F1F27);
  static const Color darkElevated = Color(0xFF262631);
  static const Color darkText = Color(0xFFF5F5F7);
  static const Color darkSecondary = Color(0xFFA1A1AA);
  static const Color darkMuted = Color(0xFF71717A);
  static const Color darkDivider = Color(0xFF282832);
  
  // Brand Primary: Volt Neon Green (#CBFE00)
  static const Color darkAccent = Color(0xFFCBFE00);
  static const Color darkSuccess = Color(0xFFCBFE00);
  static const Color darkWarning = Color(0xFFFFD60A);
  static const Color darkError = Color(0xFFFF453A);

  // Audio accent (strictly for waveform / mic activity)
  static const Color audioWave = Color(0xFFCBFE00);

  // Light Theme
  static const Color lightBg = Color(0xFFF5F5F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurface2 = Color(0xFFF0F0F2);
  static const Color lightText = Color(0xFF1D1D1F);
  static const Color lightSecondary = Color(0xFF6E6E73);
  static const Color lightDivider = Color(0xFFD2D2D7);
  static const Color lightAccent = Color(0xFF9ECC00);
}

class SaynTheme {
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: SaynColors.darkBg,
    colorScheme: const ColorScheme.dark(
      surface: SaynColors.darkSurface,
      primary: SaynColors.darkAccent,
      onPrimary: Color(0xFF0D0D12),
      onSurface: SaynColors.darkText,
      outline: SaynColors.darkDivider,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: SaynColors.darkBg,
      foregroundColor: SaynColors.darkText,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    dividerTheme: const DividerThemeData(
      color: SaynColors.darkDivider,
      thickness: 1,
    ),
  );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: SaynColors.lightBg,
    colorScheme: const ColorScheme.light(
      surface: SaynColors.lightSurface,
      primary: SaynColors.lightAccent,
      onPrimary: Colors.white,
      onSurface: SaynColors.lightText,
      outline: SaynColors.lightDivider,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: SaynColors.lightBg,
      foregroundColor: SaynColors.lightText,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    dividerTheme: const DividerThemeData(
      color: SaynColors.lightDivider,
      thickness: 1,
    ),
  );
}
