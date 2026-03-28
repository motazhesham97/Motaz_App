import 'package:flutter/material.dart';

class AppTheme {
  static const _fontFallback = <String>[
    'Noto Sans Arabic',
    'Segoe UI',
    'Tahoma',
  ];

  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF005F73),
      onPrimary: Colors.white,
      secondary: Color(0xFF0A9396),
      onSecondary: Colors.white,
      error: Color(0xFFB3261E),
      onError: Colors.white,
      surface: Color(0xFFFFFBF5),
      onSurface: Color(0xFF1C1B1A),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF6F1E8),
      appBarTheme: const AppBarTheme(centerTitle: true),
      drawerTheme: const DrawerThemeData(backgroundColor: Colors.white),
      textTheme: Typography.material2021(platform: TargetPlatform.android).black
          .apply(
            fontFamilyFallback: _fontFallback,
          ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }

  static ThemeData dark() {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF94D2BD),
      onPrimary: Color(0xFF001219),
      secondary: Color(0xFF0A9396),
      onSecondary: Colors.white,
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      surface: Color(0xFF111B21),
      onSurface: Color(0xFFE7E2DA),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0B151A),
      appBarTheme: const AppBarTheme(centerTitle: true),
      drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFF132127)),
      textTheme: Typography.material2021(platform: TargetPlatform.android).white
          .apply(
            fontFamilyFallback: _fontFallback,
          ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}
