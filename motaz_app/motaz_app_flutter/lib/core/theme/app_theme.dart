import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Enforce dark theme
  static ThemeData get lightTheme => _buildTheme();
  static ThemeData get darkTheme => _buildTheme();

  static ThemeData _buildTheme() {
    // Spectacular Dark Mode Theme
    const primaryColor = Color(0xFF657F66); // Muted Green
    const secondaryColor = Color(0xFFF8B97E); // Peach
    const whiteColor = Color(0xFFFFFFFF);
    const scaffoldBg = Color(0xFF0D110E); // Deep dark green-black
    const surfaceColor = Color(0xFF151A16); // Slightly lighter
    const surfaceVariant = Color(0xFF1D241E); // For inputs, hovers
    const outlineColor = Color(0xFF28322A); // Subtle borders
    const textPrimary = Color(0xFFF3F5F3);
    const textSecondary = Color(0xFF9BAA9C);

    final colorScheme = const ColorScheme.dark(
      primary: primaryColor,
      onPrimary: whiteColor,
      secondary: secondaryColor,
      onSecondary: scaffoldBg,
      surface: surfaceColor,
      onSurface: textPrimary,
      surfaceContainerHighest: surfaceVariant,
      onSurfaceVariant: whiteColor,
      outline: outlineColor,
      outlineVariant: outlineColor,
      error: Color(0xFFEF4444),
      onError: whiteColor,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scaffoldBg, // Transparent feel
        foregroundColor: textPrimary,
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceColor,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: outlineColor, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: whiteColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: whiteColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: secondaryColor,
          side: const BorderSide(color: secondaryColor, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: secondaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          foregroundColor: textSecondary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: secondaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textSecondary),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        iconColor: secondaryColor,
        textColor: textPrimary,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: whiteColor,
        ),
        subtitleTextStyle: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: whiteColor,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
      dividerTheme: const DividerThemeData(
        color: outlineColor,
        space: 24,
        thickness: 1.5,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: surfaceVariant,
        contentTextStyle: const TextStyle(color: textPrimary),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        backgroundColor: secondaryColor,
        foregroundColor: scaffoldBg,
        elevation: 4,
      ),
    );

    final textTheme = GoogleFonts.cairoTextTheme(base.textTheme).copyWith(
      headlineLarge: GoogleFonts.cairo(
        textStyle: base.textTheme.headlineLarge,
        fontWeight: FontWeight.w800,
        color: textPrimary,
      ),
      headlineSmall: GoogleFonts.cairo(
        textStyle: base.textTheme.headlineSmall,
        fontWeight: FontWeight.w800,
        color: textPrimary,
      ),
      titleLarge: GoogleFonts.cairo(
        textStyle: base.textTheme.titleLarge,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      titleMedium: GoogleFonts.cairo(
        textStyle: base.textTheme.titleMedium,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      bodyLarge: GoogleFonts.cairo(
        textStyle: base.textTheme.bodyLarge,
        color: textPrimary,
      ),
      bodyMedium: GoogleFonts.cairo(
        textStyle: base.textTheme.bodyMedium,
        color: textSecondary, // Muted by default
      ),
      labelLarge: GoogleFonts.cairo(
        textStyle: base.textTheme.labelLarge,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: GoogleFonts.cairoTextTheme(base.primaryTextTheme).apply(
        bodyColor: whiteColor,
        displayColor: whiteColor,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(), // Modern zoom
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }

  static TextDirection get textDirection => TextDirection.rtl;

  static Locale get locale => const Locale('ar');
}
