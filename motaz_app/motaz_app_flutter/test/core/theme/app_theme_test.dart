import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    group('light()', () {
      late ThemeData theme;

      setUp(() {
        theme = AppTheme.light();
      });

      test('returns a ThemeData instance', () {
        expect(theme, isA<ThemeData>());
      });

      test('uses Material 3', () {
        expect(theme.useMaterial3, isTrue);
      });

      test('brightness is light', () {
        expect(theme.colorScheme.brightness, equals(Brightness.light));
      });

      test('primary color is correct', () {
        expect(theme.colorScheme.primary, equals(const Color(0xFF005F73)));
      });

      test('onPrimary color is white', () {
        expect(theme.colorScheme.onPrimary, equals(Colors.white));
      });

      test('secondary color is correct', () {
        expect(theme.colorScheme.secondary, equals(const Color(0xFF0A9396)));
      });

      test('error color is correct', () {
        expect(theme.colorScheme.error, equals(const Color(0xFFB3261E)));
      });

      test('surface color is correct', () {
        expect(theme.colorScheme.surface, equals(const Color(0xFFFFFBF5)));
      });

      test('onSurface color is correct', () {
        expect(theme.colorScheme.onSurface, equals(const Color(0xFF1C1B1A)));
      });

      test('scaffoldBackgroundColor is correct', () {
        expect(theme.scaffoldBackgroundColor, equals(const Color(0xFFF6F1E8)));
      });

      test('appBarTheme is centered', () {
        expect(theme.appBarTheme.centerTitle, isTrue);
      });

      test('drawerTheme background is white', () {
        expect(theme.drawerTheme.backgroundColor, equals(Colors.white));
      });

      test('inputDecorationTheme has OutlineInputBorder', () {
        expect(theme.inputDecorationTheme.border, isA<OutlineInputBorder>());
      });

      test('textTheme is not null', () {
        expect(theme.textTheme, isNotNull);
      });
    });

    group('dark()', () {
      late ThemeData theme;

      setUp(() {
        theme = AppTheme.dark();
      });

      test('returns a ThemeData instance', () {
        expect(theme, isA<ThemeData>());
      });

      test('uses Material 3', () {
        expect(theme.useMaterial3, isTrue);
      });

      test('brightness is dark', () {
        expect(theme.colorScheme.brightness, equals(Brightness.dark));
      });

      test('primary color is correct', () {
        expect(theme.colorScheme.primary, equals(const Color(0xFF94D2BD)));
      });

      test('onPrimary color is correct', () {
        expect(theme.colorScheme.onPrimary, equals(const Color(0xFF001219)));
      });

      test('secondary color is correct', () {
        expect(theme.colorScheme.secondary, equals(const Color(0xFF0A9396)));
      });

      test('error color is correct', () {
        expect(theme.colorScheme.error, equals(const Color(0xFFFFB4AB)));
      });

      test('onError color is correct', () {
        expect(theme.colorScheme.onError, equals(const Color(0xFF690005)));
      });

      test('surface color is correct', () {
        expect(theme.colorScheme.surface, equals(const Color(0xFF111B21)));
      });

      test('onSurface color is correct', () {
        expect(theme.colorScheme.onSurface, equals(const Color(0xFFE7E2DA)));
      });

      test('scaffoldBackgroundColor is correct', () {
        expect(theme.scaffoldBackgroundColor, equals(const Color(0xFF0B151A)));
      });

      test('appBarTheme is centered', () {
        expect(theme.appBarTheme.centerTitle, isTrue);
      });

      test('drawerTheme background is correct dark color', () {
        expect(theme.drawerTheme.backgroundColor, equals(const Color(0xFF132127)));
      });

      test('inputDecorationTheme has OutlineInputBorder', () {
        expect(theme.inputDecorationTheme.border, isA<OutlineInputBorder>());
      });

      test('textTheme is not null', () {
        expect(theme.textTheme, isNotNull);
      });
    });

    group('light() vs dark() comparison', () {
      test('light and dark have opposite brightness', () {
        final light = AppTheme.light();
        final dark = AppTheme.dark();
        expect(light.colorScheme.brightness, isNot(equals(dark.colorScheme.brightness)));
      });

      test('both have useMaterial3=true', () {
        expect(AppTheme.light().useMaterial3, isTrue);
        expect(AppTheme.dark().useMaterial3, isTrue);
      });

      test('both share same secondary color (brand color)', () {
        final light = AppTheme.light();
        final dark = AppTheme.dark();
        expect(light.colorScheme.secondary, equals(dark.colorScheme.secondary));
      });

      test('light and dark have different scaffold backgrounds', () {
        final light = AppTheme.light();
        final dark = AppTheme.dark();
        expect(light.scaffoldBackgroundColor, isNot(equals(dark.scaffoldBackgroundColor)));
      });

      test('light() creates a new instance on each call', () {
        final a = AppTheme.light();
        final b = AppTheme.light();
        // Not identical objects (factory creates new instances)
        expect(identical(a, b), isFalse);
      });

      test('dark() creates a new instance on each call', () {
        final a = AppTheme.dark();
        final b = AppTheme.dark();
        expect(identical(a, b), isFalse);
      });
    });
  });
}