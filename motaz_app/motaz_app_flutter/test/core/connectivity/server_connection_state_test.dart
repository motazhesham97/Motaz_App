import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/core/connectivity/server_service.dart';

void main() {
  group('ServerConnectionStatus enum', () {
    test('has connected value', () {
      expect(ServerConnectionStatus.connected, isA<ServerConnectionStatus>());
    });

    test('has disconnected value', () {
      expect(ServerConnectionStatus.disconnected, isA<ServerConnectionStatus>());
    });

    test('has error value', () {
      expect(ServerConnectionStatus.error, isA<ServerConnectionStatus>());
    });

    test('has exactly 3 values', () {
      expect(ServerConnectionStatus.values.length, equals(3));
    });
  });

  group('ServerConnectionState', () {
    group('direct constructor', () {
      test('stores status, errorMessage, and lastChecked', () {
        final now = DateTime.now();
        final state = ServerConnectionState(
          status: ServerConnectionStatus.connected,
          errorMessage: null,
          lastChecked: now,
        );
        expect(state.status, equals(ServerConnectionStatus.connected));
        expect(state.errorMessage, isNull);
        expect(state.lastChecked, equals(now));
      });

      test('stores errorMessage when provided', () {
        final state = ServerConnectionState(
          status: ServerConnectionStatus.error,
          errorMessage: 'Network error',
          lastChecked: DateTime.now(),
        );
        expect(state.errorMessage, equals('Network error'));
      });
    });

    group('ServerConnectionState.initial()', () {
      test('returns a ServerConnectionState', () {
        final state = ServerConnectionState.initial();
        expect(state, isA<ServerConnectionState>());
      });

      test('status is disconnected', () {
        final state = ServerConnectionState.initial();
        expect(state.status, equals(ServerConnectionStatus.disconnected));
      });

      test('errorMessage is null', () {
        final state = ServerConnectionState.initial();
        expect(state.errorMessage, isNull);
      });

      test('lastChecked is recent', () {
        final before = DateTime.now();
        final state = ServerConnectionState.initial();
        final after = DateTime.now();
        expect(state.lastChecked.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
        expect(state.lastChecked.isBefore(after.add(const Duration(seconds: 1))), isTrue);
      });
    });

    group('ServerConnectionState.connected()', () {
      test('status is connected', () {
        final state = ServerConnectionState.connected();
        expect(state.status, equals(ServerConnectionStatus.connected));
      });

      test('errorMessage is null', () {
        final state = ServerConnectionState.connected();
        expect(state.errorMessage, isNull);
      });

      test('lastChecked is recent', () {
        final before = DateTime.now();
        final state = ServerConnectionState.connected();
        final after = DateTime.now();
        expect(state.lastChecked.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
        expect(state.lastChecked.isBefore(after.add(const Duration(seconds: 1))), isTrue);
      });
    });

    group('ServerConnectionState.error()', () {
      test('status is error', () {
        final state = ServerConnectionState.error('Something went wrong');
        expect(state.status, equals(ServerConnectionStatus.error));
      });

      test('errorMessage contains the provided message', () {
        const message = 'فشل الاتصال بالخادم';
        final state = ServerConnectionState.error(message);
        expect(state.errorMessage, equals(message));
      });

      test('lastChecked is recent', () {
        final before = DateTime.now();
        final state = ServerConnectionState.error('err');
        final after = DateTime.now();
        expect(state.lastChecked.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
        expect(state.lastChecked.isBefore(after.add(const Duration(seconds: 1))), isTrue);
      });

      test('empty error message is stored', () {
        final state = ServerConnectionState.error('');
        expect(state.errorMessage, equals(''));
      });
    });

    group('isConnected getter', () {
      test('returns true when connected', () {
        expect(ServerConnectionState.connected().isConnected, isTrue);
      });

      test('returns false when disconnected', () {
        expect(ServerConnectionState.initial().isConnected, isFalse);
      });

      test('returns false when error', () {
        expect(ServerConnectionState.error('err').isConnected, isFalse);
      });
    });

    group('isDisconnected getter', () {
      test('returns true when disconnected (initial)', () {
        expect(ServerConnectionState.initial().isDisconnected, isTrue);
      });

      test('returns false when connected', () {
        expect(ServerConnectionState.connected().isDisconnected, isFalse);
      });

      test('returns false when error', () {
        expect(ServerConnectionState.error('err').isDisconnected, isFalse);
      });
    });

    group('hasError getter', () {
      test('returns true when error', () {
        expect(ServerConnectionState.error('err').hasError, isTrue);
      });

      test('returns false when connected', () {
        expect(ServerConnectionState.connected().hasError, isFalse);
      });

      test('returns false when disconnected', () {
        expect(ServerConnectionState.initial().hasError, isFalse);
      });
    });

    group('mutually exclusive boolean getters', () {
      test('only one of isConnected, isDisconnected, hasError is true at a time', () {
        final states = [
          ServerConnectionState.connected(),
          ServerConnectionState.initial(),
          ServerConnectionState.error('test'),
        ];
        for (final state in states) {
          final trueCount = [
            state.isConnected,
            state.isDisconnected,
            state.hasError,
          ].where((b) => b).length;
          expect(trueCount, equals(1),
              reason: 'Expected exactly one boolean getter to be true for status ${state.status}');
        }
      });
    });

    group('Arabic error messages', () {
      test('Arabic timeout message is stored correctly', () {
        const msg = 'انتهت مهلة الاتصال بالخادم';
        final state = ServerConnectionState.error(msg);
        expect(state.errorMessage, equals(msg));
      });

      test('Arabic unexpected response message is stored correctly', () {
        const msg = 'استجابة غير متوقعة من الخادم';
        final state = ServerConnectionState.error(msg);
        expect(state.errorMessage, equals(msg));
      });
    });
  });
}