import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/features/auth/presentation/registration_screen.dart';

// ---------------------------------------------------------------------------
// Widget tests for RegistrationScreen.
//
// These tests focus on form validation behaviour, which runs BEFORE the auth
// notifier is invoked. Providing an empty ProviderScope (no overrides) is
// sufficient because form.validate() short-circuits when validation fails,
// so the authProvider is never accessed.
// ---------------------------------------------------------------------------

Widget buildRegistrationScreen() {
  return const ProviderScope(
    child: MaterialApp(
      home: RegistrationScreen(),
    ),
  );
}

void main() {
  group('RegistrationScreen', () {
    group('initial render', () {
      testWidgets('displays "إنشاء حساب جديد" heading', (tester) async {
        await tester.pumpWidget(buildRegistrationScreen());
        expect(find.text('إنشاء حساب جديد'), findsOneWidget);
      });

      testWidgets('displays "تطبيق معتز" subtitle', (tester) async {
        await tester.pumpWidget(buildRegistrationScreen());
        expect(find.text('تطبيق معتز'), findsOneWidget);
      });

      testWidgets('has exactly three TextFormField widgets', (tester) async {
        await tester.pumpWidget(buildRegistrationScreen());
        expect(find.byType(TextFormField), findsNWidgets(3));
      });

      testWidgets('submit button shows "إنشاء الحساب" text initially', (tester) async {
        await tester.pumpWidget(buildRegistrationScreen());
        expect(find.widgetWithText(ElevatedButton, 'إنشاء الحساب'), findsOneWidget);
      });

      testWidgets('no error message shown on initial render', (tester) async {
        await tester.pumpWidget(buildRegistrationScreen());
        expect(
          find.text('فشل في إنشاء الحساب. قد يكون الحساب موجوداً بالفعل أو هناك مشكلة في الاتصال بالخادم.'),
          findsNothing,
        );
      });

      testWidgets('uses RTL text direction', (tester) async {
        await tester.pumpWidget(buildRegistrationScreen());
        final directionality = tester.widget<Directionality>(
          find.descendant(
            of: find.byType(RegistrationScreen),
            matching: find.byType(Directionality),
          ).first,
        );
        expect(directionality.textDirection, equals(TextDirection.rtl));
      });
    });

    group('email field validation', () {
      testWidgets('shows error when email field is empty on submit', (tester) async {
        await tester.pumpWidget(buildRegistrationScreen());
        await tester.tap(find.widgetWithText(ElevatedButton, 'إنشاء الحساب'));
        await tester.pump();
        expect(find.text('الرجاء إدخال البريد الإلكتروني'), findsOneWidget);
      });

      testWidgets('shows error when email lacks "@"', (tester) async {
        await tester.pumpWidget(buildRegistrationScreen());
        await tester.enterText(
          find.byType(TextFormField).first,
          'notanemail',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'إنشاء الحساب'));
        await tester.pump();
        expect(find.text('الرجاء إدخال بريد إلكتروني صالح'), findsOneWidget);
      });

      testWidgets('no email error for a valid address', (tester) async {
        await tester.pumpWidget(buildRegistrationScreen());
        await tester.enterText(find.byType(TextFormField).first, 'user@example.com');
        await tester.pump();
        expect(find.text('الرجاء إدخال البريد الإلكتروني'), findsNothing);
        expect(find.text('الرجاء إدخال بريد إلكتروني صالح'), findsNothing);
      });
    });

    group('password field validation', () {
      testWidgets('shows error when password is empty on submit', (tester) async {
        await tester.pumpWidget(buildRegistrationScreen());
        await tester.tap(find.widgetWithText(ElevatedButton, 'إنشاء الحساب'));
        await tester.pump();
        expect(find.text('الرجاء إدخال كلمة المرور'), findsOneWidget);
      });

      testWidgets('shows error when password is fewer than 6 characters', (tester) async {
        await tester.pumpWidget(buildRegistrationScreen());
        await tester.enterText(find.byType(TextFormField).first, 'user@example.com');
        await tester.enterText(find.byType(TextFormField).at(1), 'abc');
        await tester.tap(find.widgetWithText(ElevatedButton, 'إنشاء الحساب'));
        await tester.pump();
        expect(find.text('كلمة المرور يجب أن تكون 6 أحرف على الأقل'), findsOneWidget);
      });

      testWidgets('no password-length error when password has exactly 6 chars', (tester) async {
        await tester.pumpWidget(buildRegistrationScreen());
        await tester.enterText(find.byType(TextFormField).at(1), 'abcdef');
        await tester.pump();
        expect(find.text('كلمة المرور يجب أن تكون 6 أحرف على الأقل'), findsNothing);
      });

      testWidgets('password field is obscured by default', (tester) async {
        await tester.pumpWidget(buildRegistrationScreen());
        final passwordWidget = tester.widget<TextFormField>(
          find.byType(TextFormField).at(1),
        );
        expect(passwordWidget.obscureText, isTrue);
      });

      testWidgets('tapping first visibility icon reveals the password', (tester) async {
        await tester.pumpWidget(buildRegistrationScreen());
        await tester.tap(find.byIcon(Icons.visibility).first);
        await tester.pump();
        final passwordWidget = tester.widget<TextFormField>(
          find.byType(TextFormField).at(1),
        );
        expect(passwordWidget.obscureText, isFalse);
      });
    });

    group('confirm password validation', () {
      testWidgets('shows error when confirm password is empty on submit', (tester) async {
        await tester.pumpWidget(buildRegistrationScreen());
        await tester.tap(find.widgetWithText(ElevatedButton, 'إنشاء الحساب'));
        await tester.pump();
        expect(find.text('الرجاء تأكيد كلمة المرور'), findsOneWidget);
      });

      testWidgets('shows mismatch error when passwords differ', (tester) async {
        await tester.pumpWidget(buildRegistrationScreen());
        await tester.enterText(find.byType(TextFormField).first, 'user@example.com');
        await tester.enterText(find.byType(TextFormField).at(1), 'password123');
        await tester.enterText(find.byType(TextFormField).at(2), 'different456');
        await tester.tap(find.widgetWithText(ElevatedButton, 'إنشاء الحساب'));
        await tester.pump();
        expect(find.text('كلمتا المرور غير متطابقتين'), findsOneWidget);
      });

      testWidgets('no mismatch error when passwords match exactly', (tester) async {
        await tester.pumpWidget(buildRegistrationScreen());
        await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
        await tester.enterText(find.byType(TextFormField).at(2), 'secret123');
        await tester.pump();
        expect(find.text('كلمتا المرور غير متطابقتين'), findsNothing);
      });

      testWidgets('confirm password field is obscured by default', (tester) async {
        await tester.pumpWidget(buildRegistrationScreen());
        final confirmWidget = tester.widget<TextFormField>(
          find.byType(TextFormField).at(2),
        );
        expect(confirmWidget.obscureText, isTrue);
      });

      testWidgets('tapping second visibility icon reveals the confirm password', (tester) async {
        await tester.pumpWidget(buildRegistrationScreen());
        await tester.tap(find.byIcon(Icons.visibility).last);
        await tester.pump();
        final confirmWidget = tester.widget<TextFormField>(
          find.byType(TextFormField).at(2),
        );
        expect(confirmWidget.obscureText, isFalse);
      });
    });

    group('all validation errors at once', () {
      testWidgets('shows all three required-field errors when form is empty', (tester) async {
        await tester.pumpWidget(buildRegistrationScreen());
        await tester.tap(find.widgetWithText(ElevatedButton, 'إنشاء الحساب'));
        await tester.pump();
        expect(find.text('الرجاء إدخال البريد الإلكتروني'), findsOneWidget);
        expect(find.text('الرجاء إدخال كلمة المرور'), findsOneWidget);
        expect(find.text('الرجاء تأكيد كلمة المرور'), findsOneWidget);
      });

      testWidgets('valid email does not trigger email validation error even when other fields fail', (tester) async {
        // Verify that when email is valid but password fields are empty,
        // only password errors appear (not email errors).
        await tester.pumpWidget(buildRegistrationScreen());
        await tester.enterText(find.byType(TextFormField).first, 'valid@example.com');
        await tester.tap(find.widgetWithText(ElevatedButton, 'إنشاء الحساب'));
        await tester.pump();
        // Email is valid → no email error
        expect(find.text('الرجاء إدخال البريد الإلكتروني'), findsNothing);
        expect(find.text('الرجاء إدخال بريد إلكتروني صالح'), findsNothing);
        // Password fields are empty → both password errors present
        expect(find.text('الرجاء إدخال كلمة المرور'), findsOneWidget);
        expect(find.text('الرجاء تأكيد كلمة المرور'), findsOneWidget);
      });

      testWidgets('matching passwords does not trigger a mismatch error when email is missing', (tester) async {
        await tester.pumpWidget(buildRegistrationScreen());
        await tester.enterText(find.byType(TextFormField).at(1), 'samepass');
        await tester.enterText(find.byType(TextFormField).at(2), 'samepass');
        await tester.tap(find.widgetWithText(ElevatedButton, 'إنشاء الحساب'));
        await tester.pump();
        // Passwords match → no mismatch error
        expect(find.text('كلمتا المرور غير متطابقتين'), findsNothing);
        // But email is missing → email error present
        expect(find.text('الرجاء إدخال البريد الإلكتروني'), findsOneWidget);
      });
    });

    group('layout and structure', () {
      testWidgets('wraps content in a Form widget', (tester) async {
        await tester.pumpWidget(buildRegistrationScreen());
        expect(find.byType(Form), findsWidgets);
      });

      testWidgets('contains a SingleChildScrollView', (tester) async {
        await tester.pumpWidget(buildRegistrationScreen());
        expect(find.byType(SingleChildScrollView), findsOneWidget);
      });
    });
  });
}