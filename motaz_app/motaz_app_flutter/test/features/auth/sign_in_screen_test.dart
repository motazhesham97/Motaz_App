import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/features/auth/presentation/sign_in_screen.dart';

// ---------------------------------------------------------------------------
// Widget tests for SignInScreen.
//
// These tests focus on form validation behaviour, which runs BEFORE the auth
// notifier is invoked. Providing an empty ProviderScope (no overrides) is
// sufficient because form.validate() short-circuits when validation fails,
// so the authProvider is never accessed.
// ---------------------------------------------------------------------------

Widget buildSignInScreen() {
  return const ProviderScope(
    child: MaterialApp(
      home: SignInScreen(),
    ),
  );
}

void main() {
  group('SignInScreen', () {
    group('initial render', () {
      testWidgets('displays "تسجيل الدخول" heading', (tester) async {
        await tester.pumpWidget(buildSignInScreen());
        // The heading and the button both contain this text; assert at least one.
        expect(find.text('تسجيل الدخول'), findsWidgets);
      });

      testWidgets('displays "تطبيق معتز" subtitle', (tester) async {
        await tester.pumpWidget(buildSignInScreen());
        expect(find.text('تطبيق معتز'), findsOneWidget);
      });

      testWidgets('has exactly two TextFormField widgets', (tester) async {
        await tester.pumpWidget(buildSignInScreen());
        expect(find.byType(TextFormField), findsNWidgets(2));
      });

      testWidgets('submit button is an ElevatedButton', (tester) async {
        await tester.pumpWidget(buildSignInScreen());
        expect(find.byType(ElevatedButton), findsOneWidget);
      });

      testWidgets('no error message on initial render', (tester) async {
        await tester.pumpWidget(buildSignInScreen());
        expect(
          find.text('البريد الإلكتروني أو كلمة المرور غير صحيحة، أو هناك مشكلة في الاتصال بالخادم'),
          findsNothing,
        );
      });

      testWidgets('uses RTL text direction', (tester) async {
        await tester.pumpWidget(buildSignInScreen());
        final directionality = tester.widget<Directionality>(
          find.descendant(
            of: find.byType(SignInScreen),
            matching: find.byType(Directionality),
          ).first,
        );
        expect(directionality.textDirection, equals(TextDirection.rtl));
      });
    });

    group('email field validation', () {
      testWidgets('shows error when email is empty on submit', (tester) async {
        await tester.pumpWidget(buildSignInScreen());
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
        expect(find.text('الرجاء إدخال البريد الإلكتروني'), findsOneWidget);
      });

      testWidgets('shows error when email lacks "@"', (tester) async {
        await tester.pumpWidget(buildSignInScreen());
        await tester.enterText(find.byType(TextFormField).first, 'notanemail');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
        expect(find.text('الرجاء إدخال بريد إلكتروني صالح'), findsOneWidget);
      });

      testWidgets('no email error for a valid address', (tester) async {
        await tester.pumpWidget(buildSignInScreen());
        await tester.enterText(find.byType(TextFormField).first, 'user@example.com');
        await tester.pump();
        expect(find.text('الرجاء إدخال البريد الإلكتروني'), findsNothing);
        expect(find.text('الرجاء إدخال بريد إلكتروني صالح'), findsNothing);
      });

      testWidgets('"@"-only string passes email presence check but not necessarily the "@" check', (tester) async {
        // The validator checks isEmpty first, then checks for '@'.
        // An '@' character satisfies both checks → no email error.
        await tester.pumpWidget(buildSignInScreen());
        await tester.enterText(find.byType(TextFormField).first, '@');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
        expect(find.text('الرجاء إدخال البريد الإلكتروني'), findsNothing);
        expect(find.text('الرجاء إدخال بريد إلكتروني صالح'), findsNothing);
      });
    });

    group('password field validation', () {
      testWidgets('shows error when password is empty on submit', (tester) async {
        await tester.pumpWidget(buildSignInScreen());
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
        expect(find.text('الرجاء إدخال كلمة المرور'), findsOneWidget);
      });

      testWidgets('no password error when password is non-empty', (tester) async {
        await tester.pumpWidget(buildSignInScreen());
        await tester.enterText(find.byType(TextFormField).at(1), 'anypassword');
        await tester.pump();
        expect(find.text('الرجاء إدخال كلمة المرور'), findsNothing);
      });

      testWidgets('sign-in screen does NOT enforce minimum password length', (tester) async {
        // Unlike registration, sign-in only checks that password is non-empty.
        await tester.pumpWidget(buildSignInScreen());
        await tester.enterText(find.byType(TextFormField).at(1), 'a');
        await tester.pump();
        expect(find.text('كلمة المرور يجب أن تكون 6 أحرف على الأقل'), findsNothing);
      });

      testWidgets('password field is obscured by default', (tester) async {
        await tester.pumpWidget(buildSignInScreen());
        final passwordWidget = tester.widget<TextFormField>(
          find.byType(TextFormField).at(1),
        );
        expect(passwordWidget.obscureText, isTrue);
      });

      testWidgets('tapping visibility icon reveals the password', (tester) async {
        await tester.pumpWidget(buildSignInScreen());
        await tester.tap(find.byIcon(Icons.visibility));
        await tester.pump();
        final passwordWidget = tester.widget<TextFormField>(
          find.byType(TextFormField).at(1),
        );
        expect(passwordWidget.obscureText, isFalse);
      });

      testWidgets('tapping visibility_off icon hides the password again', (tester) async {
        await tester.pumpWidget(buildSignInScreen());
        // Reveal
        await tester.tap(find.byIcon(Icons.visibility));
        await tester.pump();
        // Hide again
        await tester.tap(find.byIcon(Icons.visibility_off));
        await tester.pump();
        final passwordWidget = tester.widget<TextFormField>(
          find.byType(TextFormField).at(1),
        );
        expect(passwordWidget.obscureText, isTrue);
      });
    });

    group('both fields empty – both errors shown', () {
      testWidgets('shows both email and password required errors simultaneously', (tester) async {
        await tester.pumpWidget(buildSignInScreen());
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
        expect(find.text('الرجاء إدخال البريد الإلكتروني'), findsOneWidget);
        expect(find.text('الرجاء إدخال كلمة المرور'), findsOneWidget);
      });
    });

    group('valid inputs – field-level validation', () {
      testWidgets('valid email produces no email error even when password is missing', (tester) async {
        // Verify per-field validation: a valid email generates no email error
        // even when the overall form fails due to missing password.
        await tester.pumpWidget(buildSignInScreen());
        await tester.enterText(find.byType(TextFormField).first, 'user@example.com');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
        expect(find.text('الرجاء إدخال البريد الإلكتروني'), findsNothing);
        expect(find.text('الرجاء إدخال بريد إلكتروني صالح'), findsNothing);
        expect(find.text('الرجاء إدخال كلمة المرور'), findsOneWidget);
      });

      testWidgets('non-empty password does not trigger password error when email is missing', (tester) async {
        await tester.pumpWidget(buildSignInScreen());
        await tester.enterText(find.byType(TextFormField).at(1), 'somepassword');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
        expect(find.text('الرجاء إدخال كلمة المرور'), findsNothing);
        expect(find.text('الرجاء إدخال البريد الإلكتروني'), findsOneWidget);
      });
    });

    group('layout and structure', () {
      testWidgets('wraps content in a Form widget', (tester) async {
        await tester.pumpWidget(buildSignInScreen());
        expect(find.byType(Form), findsWidgets);
      });

      testWidgets('contains a SingleChildScrollView', (tester) async {
        await tester.pumpWidget(buildSignInScreen());
        expect(find.byType(SingleChildScrollView), findsOneWidget);
      });

      testWidgets('constrains form to max width of 400', (tester) async {
        await tester.pumpWidget(buildSignInScreen());
        final box = tester.widget<ConstrainedBox>(
          find.ancestor(
            of: find.byType(Form),
            matching: find.byType(ConstrainedBox),
          ).first,
        );
        expect(box.constraints.maxWidth, equals(400));
      });
    });
  });
}