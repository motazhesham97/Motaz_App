import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/core/auth/auth_state.dart';

void main() {
  group('AuthState sealed class', () {
    group('AuthInitial', () {
      test('is an AuthState', () {
        const state = AuthInitial();
        expect(state, isA<AuthState>());
      });

      test('const constructor works and two instances are equal via identity', () {
        const a = AuthInitial();
        const b = AuthInitial();
        expect(identical(a, b), isTrue);
      });
    });

    group('Unauthenticated', () {
      test('is an AuthState', () {
        const state = Unauthenticated(hasAccount: true);
        expect(state, isA<AuthState>());
      });

      test('hasAccount=true is stored correctly', () {
        const state = Unauthenticated(hasAccount: true);
        expect(state.hasAccount, isTrue);
      });

      test('hasAccount=false is stored correctly', () {
        const state = Unauthenticated(hasAccount: false);
        expect(state.hasAccount, isFalse);
      });

      test('two Unauthenticated with same hasAccount are distinguishable from AuthInitial', () {
        const state = Unauthenticated(hasAccount: false);
        expect(state, isNot(isA<AuthInitial>()));
      });
    });

    group('Authenticated', () {
      test('is an AuthState', () {
        const state = Authenticated();
        expect(state, isA<AuthState>());
      });

      test('email defaults to null when not provided', () {
        const state = Authenticated();
        expect(state.email, isNull);
      });

      test('email is stored when provided', () {
        const state = Authenticated(email: 'user@example.com');
        expect(state.email, equals('user@example.com'));
      });

      test('email can be an empty string', () {
        const state = Authenticated(email: '');
        expect(state.email, equals(''));
      });

      test('is not an Unauthenticated state', () {
        const state = Authenticated(email: 'test@test.com');
        expect(state, isNot(isA<Unauthenticated>()));
      });

      test('is not an AuthInitial state', () {
        const state = Authenticated();
        expect(state, isNot(isA<AuthInitial>()));
      });
    });

    group('Pattern matching exhaustiveness', () {
      test('switch on AuthInitial hits correct branch', () {
        final AuthState state = const AuthInitial();
        final result = switch (state) {
          AuthInitial() => 'initial',
          Unauthenticated() => 'unauthenticated',
          Authenticated() => 'authenticated',
        };
        expect(result, equals('initial'));
      });

      test('switch on Unauthenticated hits correct branch', () {
        final AuthState state = const Unauthenticated(hasAccount: false);
        final result = switch (state) {
          AuthInitial() => 'initial',
          Unauthenticated() => 'unauthenticated',
          Authenticated() => 'authenticated',
        };
        expect(result, equals('unauthenticated'));
      });

      test('switch on Authenticated hits correct branch', () {
        final AuthState state = const Authenticated(email: 'a@b.com');
        final result = switch (state) {
          AuthInitial() => 'initial',
          Unauthenticated() => 'unauthenticated',
          Authenticated() => 'authenticated',
        };
        expect(result, equals('authenticated'));
      });

      test('type-check cast from AuthState to Authenticated works', () {
        final AuthState state = const Authenticated(email: 'cast@example.com');
        final authenticated = state as Authenticated;
        expect(authenticated.email, equals('cast@example.com'));
      });

      test('Unauthenticated with hasAccount reflects route decision', () {
        // hasAccount=true means user should go to sign-in; false means registration
        const withAccount = Unauthenticated(hasAccount: true);
        const withoutAccount = Unauthenticated(hasAccount: false);
        expect(withAccount.hasAccount, isTrue);
        expect(withoutAccount.hasAccount, isFalse);
      });
    });
  });
}