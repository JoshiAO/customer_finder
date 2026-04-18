import 'package:flutter/material.dart';

class KEPalette {
  static const Color logoBlue = Color(0xFF2F7FD1);
  static const Color logoBlueDark = Color(0xFF0E4A87);
  static const Color logoBlueLight = Color(0xFF6FB4FF);
  static const Color mist = Color(0xFFEAF3FF);
  static const Color cloud = Color(0xFFF5FAFF);
}

class KETheme {
  static ThemeData light() {
    const primary = KEPalette.logoBlue;
    const onPrimary = Colors.white;
    const secondary = KEPalette.logoBlueLight;
    const onSurface = Color(0xFF163250);

    final scheme = const ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: onPrimary,
      secondary: secondary,
      onSecondary: Color(0xFF0D325F),
      error: Color(0xFFB3261E),
      onError: Colors.white,
      surface: Colors.white,
      onSurface: onSurface,
      primaryContainer: Color(0xFFDCEBFF),
      onPrimaryContainer: Color(0xFF0E4A87),
      secondaryContainer: Color(0xFFEAF3FF),
      onSecondaryContainer: Color(0xFF0D325F),
      tertiary: Color(0xFF1E6FBE),
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFD9EAFF),
      onTertiaryContainer: Color(0xFF0D325F),
      outline: Color(0xFF9CB9DD),
      shadow: Color(0x33000000),
      surfaceTint: primary,
      inverseSurface: Color(0xFF203243),
      onInverseSurface: Colors.white,
      inversePrimary: Color(0xFF9ECAFF),
      scrim: Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: KEPalette.cloud,
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(210, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: Color(0xFFDCEBFF),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurface.withValues(alpha: 0.62),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 2,
      ),
    );
  }
}