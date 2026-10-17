import 'package:flutter/material.dart';

class SaynColors {
  // Official SAYN Palette: Deep Maroon & Warm Cream (70% Near-Black #100709)
  static const Color darkBg = Color(0xFF100709);
  static const Color darkSurface = Color(0xFF180B0F);
  static const Color darkSurface2 = Color(0xFF240F16);
  static const Color darkElevated = Color(0xFF2E141D);
  static const Color darkText = Color(0xFFF5EBDD);
  static const Color darkSecondary = Color(0xFFD6C7B2);
  static const Color darkMuted = Color(0xFFA89F91);
  static const Color darkDivider = Color(0xFF3D1520);
  static const Color darkBorder = Color(0xFF3D1520);
  
  // Brand Primary & Accents
  static const Color deepMaroon = Color(0xFF6F1025);
  static const Color roseMaroon = Color(0xFFA83249);
  static const Color warmCream = Color(0xFFF5EBDD);
  
  static const Color darkAccent = Color(0xFF6F1025);
  static const Color darkSuccess = Color(0xFF30D158);
  static const Color darkWarning = Color(0xFFFFD60A);
  static const Color darkError = Color(0xFFFF453A);

  // Audio accent (strictly for waveform / mic activity)
  static const Color audioWave = Color(0xFFA83249);

  // Light Theme
  static const Color lightBg = Color(0xFFFAF4EB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurface2 = Color(0xFFF5EBDD);
  static const Color lightText = Color(0xFF100709);
  static const Color lightSecondary = Color(0xFF6E665A);
  static const Color lightDivider = Color(0xFFE5D6C2);
  static const Color lightAccent = Color(0xFF6F1025);
}

class SaynTheme {
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: SaynColors.darkBg,
    colorScheme: const ColorScheme.dark(
      surface: SaynColors.darkSurface,
      primary: SaynColors.warmCream,
      secondary: SaynColors.roseMaroon,
      onPrimary: Color(0xFF100709),
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
      secondary: SaynColors.roseMaroon,
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
