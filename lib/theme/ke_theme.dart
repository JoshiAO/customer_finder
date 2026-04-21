import 'package:flutter/material.dart';

class KEPalette {
  static const Color logoBlue = Color(0xFF2F7FD1);
  static const Color logoBlueDark = Color(0xFF0E4A87);
  static const Color logoBlueLight = Color(0xFF6FB4FF);
  static const Color mist = Color(0xFFEAF3FF);
  static const Color cloud = Color(0xFFF5FAFF);
}

class KETheme {
  static ThemeData fromSeed({
    required Color seedColor,
    required Brightness brightness,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    final scaffoldBackground = brightness == Brightness.dark
        ? Color.alphaBlend(seedColor.withValues(alpha: 0.14), const Color(0xFF111417))
        : Color.alphaBlend(seedColor.withValues(alpha: 0.08), Colors.white);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
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
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primaryContainer,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurface.withValues(alpha: 0.62),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 2,
      ),
    );
  }

  static ThemeData light() {
    return fromSeed(seedColor: KEPalette.logoBlue, brightness: Brightness.light);
  }
}