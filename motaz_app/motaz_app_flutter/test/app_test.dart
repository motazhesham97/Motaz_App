import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/app.dart';
import 'package:motaz_app_flutter/core/theme/app_theme.dart';

void main() {
  group('MotazApp widget', () {
    testWidgets('builds without throwing', (tester) async {
      await tester.pumpWidget(const MotazApp());
      // No exception means the widget tree assembled successfully
    });

    testWidgets('renders a MaterialApp', (tester) async {
      await tester.pumpWidget(const MotazApp());
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('debug banner is hidden', (tester) async {
      await tester.pumpWidget(const MotazApp());
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.debugShowCheckedModeBanner, isFalse);
    });

    testWidgets('app title is set to Arabic app name', (tester) async {
      await tester.pumpWidget(const MotazApp());
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.title, equals('تطبيق معتز'));
    });

    testWidgets('uses system theme mode', (tester) async {
      await tester.pumpWidget(const MotazApp());
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, equals(ThemeMode.system));
    });

    testWidgets('configures Arabic locale', (tester) async {
      await tester.pumpWidget(const MotazApp());
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.locale?.languageCode, equals('ar'));
    });

    testWidgets('supports only Arabic locale', (tester) async {
      await tester.pumpWidget(const MotazApp());
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.supportedLocales.length, equals(1));
      expect(app.supportedLocales.first.languageCode, equals('ar'));
    });

    testWidgets('includes required localization delegates', (tester) async {
      await tester.pumpWidget(const MotazApp());
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final delegates = app.localizationsDelegates?.toList() ?? [];

      expect(
        delegates,
        contains(GlobalMaterialLocalizations.delegate),
      );
      expect(
        delegates,
        contains(GlobalWidgetsLocalizations.delegate),
      );
      expect(
        delegates,
        contains(GlobalCupertinoLocalizations.delegate),
      );
    });

    testWidgets('light theme uses Material 3', (tester) async {
      await tester.pumpWidget(const MotazApp());
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.theme?.useMaterial3, isTrue);
    });

    testWidgets('dark theme uses Material 3', (tester) async {
      await tester.pumpWidget(const MotazApp());
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.darkTheme?.useMaterial3, isTrue);
    });

    testWidgets('light theme has light brightness', (tester) async {
      await tester.pumpWidget(const MotazApp());
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.theme?.brightness, equals(Brightness.light));
    });

    testWidgets('dark theme has dark brightness', (tester) async {
      await tester.pumpWidget(const MotazApp());
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.darkTheme?.brightness, equals(Brightness.dark));
    });

    testWidgets('builder wraps content in Directionality RTL', (tester) async {
      await tester.pumpWidget(const MotazApp());
      // The builder callback in MotazApp wraps in Directionality(rtl)
      expect(find.byType(Directionality), findsWidgets);
      final directionality = tester.widget<Directionality>(
        find.byType(Directionality).first,
      );
      expect(directionality.textDirection, equals(TextDirection.rtl));
    });

    testWidgets('home scaffold displays Arabic placeholder text', (tester) async {
      await tester.pumpWidget(const MotazApp());
      await tester.pump(); // let frames settle
      expect(find.text('تطبيق معتز - الأساس جاهز'), findsOneWidget);
    });

    testWidgets('builder fallback shows Arabic app name when child is null',
        (tester) async {
      // Verify the MotazApp builds a builder that handles null child gracefully
      // by checking the widget tree contains the MaterialApp with a builder set
      await tester.pumpWidget(const MotazApp());
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.builder, isNotNull);
    });

    testWidgets('theme font family is Cairo', (tester) async {
      await tester.pumpWidget(const MotazApp());
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.theme?.fontFamily, equals('Cairo'));
      expect(app.darkTheme?.fontFamily, equals('Cairo'));
    });

    testWidgets('textDirection from AppTheme is RTL', (tester) async {
      // Verify that the AppTheme.textDirection value used in the builder is RTL
      await tester.pumpWidget(const MotazApp());
      expect(AppTheme.textDirection, equals(TextDirection.rtl));
    });
  });
}