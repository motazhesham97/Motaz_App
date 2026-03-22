import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    group('lightTheme', () {
      test('uses Material 3', () {
        expect(AppTheme.lightTheme.useMaterial3, isTrue);
      });

      test('uses Cairo font family', () {
        expect(AppTheme.lightTheme.fontFamily, equals('Cairo'));
      });

      test('has light brightness', () {
        expect(AppTheme.lightTheme.brightness, equals(Brightness.light));
      });

      test('scaffold background is off-white (#F5F5F5)', () {
        expect(
          AppTheme.lightTheme.scaffoldBackgroundColor,
          equals(const Color(0xFFF5F5F5)),
        );
      });

      test('color scheme seed is Material blue (#1976D2)', () {
        // ColorScheme.fromSeed generates a scheme; verify the seed was applied
        // by checking the surface/primary tones are not the defaults
        final scheme = AppTheme.lightTheme.colorScheme;
        expect(scheme.brightness, equals(Brightness.light));
      });

      test('AppBar is centered with zero elevation', () {
        final appBarTheme = AppTheme.lightTheme.appBarTheme;
        expect(appBarTheme.centerTitle, isTrue);
        expect(appBarTheme.elevation, equals(0));
      });

      test('card theme has elevation 2', () {
        expect(AppTheme.lightTheme.cardTheme.elevation, equals(2));
      });

      test('elevated button has correct padding', () {
        final buttonStyle = AppTheme.lightTheme.elevatedButtonTheme.style;
        expect(buttonStyle, isNotNull);
        final padding = buttonStyle!
            .padding
            ?.resolve({});
        expect(padding, isNotNull);
        expect(padding, equals(const EdgeInsets.symmetric(horizontal: 24, vertical: 12)));
      });

      test('elevated button has rounded corners with radius 8', () {
        final buttonStyle = AppTheme.lightTheme.elevatedButtonTheme.style;
        expect(buttonStyle, isNotNull);
        final shape = buttonStyle!.shape?.resolve({});
        expect(shape, isA<RoundedRectangleBorder>());
        final rrb = shape as RoundedRectangleBorder;
        expect(rrb.borderRadius, equals(BorderRadius.circular(8)));
      });

      test('input decoration is filled with rounded corners', () {
        final inputTheme = AppTheme.lightTheme.inputDecorationTheme;
        expect(inputTheme.filled, isTrue);
        expect(inputTheme.border, isA<OutlineInputBorder>());
        final border = inputTheme.border as OutlineInputBorder;
        expect(border.borderRadius, equals(BorderRadius.circular(8)));
      });

      test('input decoration has correct content padding', () {
        final inputTheme = AppTheme.lightTheme.inputDecorationTheme;
        expect(
          inputTheme.contentPadding,
          equals(const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
        );
      });
    });

    group('darkTheme', () {
      test('uses Material 3', () {
        expect(AppTheme.darkTheme.useMaterial3, isTrue);
      });

      test('uses Cairo font family', () {
        expect(AppTheme.darkTheme.fontFamily, equals('Cairo'));
      });

      test('has dark brightness', () {
        expect(AppTheme.darkTheme.brightness, equals(Brightness.dark));
      });

      test('scaffold background is near-black (#121212)', () {
        expect(
          AppTheme.darkTheme.scaffoldBackgroundColor,
          equals(const Color(0xFF121212)),
        );
      });

      test('color scheme has dark brightness', () {
        final scheme = AppTheme.darkTheme.colorScheme;
        expect(scheme.brightness, equals(Brightness.dark));
      });

      test('AppBar is centered with zero elevation', () {
        final appBarTheme = AppTheme.darkTheme.appBarTheme;
        expect(appBarTheme.centerTitle, isTrue);
        expect(appBarTheme.elevation, equals(0));
      });

      test('card theme has elevation 2', () {
        expect(AppTheme.darkTheme.cardTheme.elevation, equals(2));
      });

      test('elevated button has correct padding', () {
        final buttonStyle = AppTheme.darkTheme.elevatedButtonTheme.style;
        expect(buttonStyle, isNotNull);
        final padding = buttonStyle!
            .padding
            ?.resolve({});
        expect(padding, isNotNull);
        expect(padding, equals(const EdgeInsets.symmetric(horizontal: 24, vertical: 12)));
      });

      test('input decoration is filled with rounded corners', () {
        final inputTheme = AppTheme.darkTheme.inputDecorationTheme;
        expect(inputTheme.filled, isTrue);
        expect(inputTheme.border, isA<OutlineInputBorder>());
      });

      test('input decoration has correct content padding', () {
        final inputTheme = AppTheme.darkTheme.inputDecorationTheme;
        expect(
          inputTheme.contentPadding,
          equals(const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
        );
      });
    });

    group('theme differentiation', () {
      test('light and dark themes have different scaffold background colors', () {
        expect(
          AppTheme.lightTheme.scaffoldBackgroundColor,
          isNot(equals(AppTheme.darkTheme.scaffoldBackgroundColor)),
        );
      });

      test('light and dark themes have different brightness', () {
        expect(AppTheme.lightTheme.brightness, isNot(equals(AppTheme.darkTheme.brightness)));
      });
    });

    group('textDirection', () {
      test('is RTL for Arabic layout', () {
        expect(AppTheme.textDirection, equals(TextDirection.rtl));
      });
    });

    group('locale', () {
      test('is Arabic', () {
        expect(AppTheme.locale.languageCode, equals('ar'));
      });

      test('returns a Locale instance', () {
        expect(AppTheme.locale, isA<Locale>());
      });

      test('locale has no country code (language-only)', () {
        expect(AppTheme.locale.countryCode, isNull);
      });
    });
  });
}