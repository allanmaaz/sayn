import 'package:flutter/material.dart';

class SaynColors {
  // Dark Theme
  static const Color darkBg = Color(0xFF0B0B0D);
  static const Color darkSurface = Color(0xFF151518);
  static const Color darkSurface2 = Color(0xFF1C1C20);
  static const Color darkElevated = Color(0xFF242428);
  static const Color darkText = Color(0xFFF5F5F7);
  static const Color darkSecondary = Color(0xFFA1A1AA);
  static const Color darkMuted = Color(0xFF71717A);
  static const Color darkDivider = Color(0xFF303036);
  static const Color darkAccent = Color(0xFF0A84FF); // Apple system blue
  static const Color darkSuccess = Color(0xFF30D158);
  static const Color darkWarning = Color(0xFFFFD60A);
  static const Color darkError = Color(0xFFFF453A);

  // Audio accent (strictly for waveform / mic activity)
  static const Color audioWave = Color(0xFF5DE4FF);

  // Light Theme
  static const Color lightBg = Color(0xFFF5F5F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurface2 = Color(0xFFF0F0F2);
  static const Color lightText = Color(0xFF1D1D1F);
  static const Color lightSecondary = Color(0xFF6E6E73);
  static const Color lightDivider = Color(0xFFD2D2D7);
  static const Color lightAccent = Color(0xFF007AFF);
}

class SaynTheme {
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: SaynColors.darkBg,
    colorScheme: const ColorScheme.dark(
      surface: SaynColors.darkSurface,
      primary: SaynColors.darkAccent,
      onPrimary: Colors.white,
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
