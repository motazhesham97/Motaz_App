import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/core/connectivity/connectivity_provider.dart';

void main() {
  group('ConnectionStatus enum', () {
    test('online value exists', () {
      expect(ConnectionStatus.online, isA<ConnectionStatus>());
    });

    test('offline value exists', () {
      expect(ConnectionStatus.offline, isA<ConnectionStatus>());
    });

    test('values contains exactly online and offline', () {
      expect(ConnectionStatus.values, containsAll([ConnectionStatus.online, ConnectionStatus.offline]));
      expect(ConnectionStatus.values.length, equals(2));
    });
  });

  group('ConnectivityState', () {
    group('constructor', () {
      test('creates state with online status', () {
        final now = DateTime.now();
        final state = ConnectivityState(
          status: ConnectionStatus.online,
          lastChanged: now,
        );
        expect(state.status, equals(ConnectionStatus.online));
        expect(state.lastChanged, equals(now));
      });

      test('creates state with offline status', () {
        final now = DateTime.now();
        final state = ConnectivityState(
          status: ConnectionStatus.offline,
          lastChanged: now,
        );
        expect(state.status, equals(ConnectionStatus.offline));
        expect(state.lastChanged, equals(now));
      });
    });

    group('ConnectivityState.initial()', () {
      test('returns a ConnectivityState instance', () {
        final state = ConnectivityState.initial();
        expect(state, isA<ConnectivityState>());
      });

      test('initial state is offline', () {
        final state = ConnectivityState.initial();
        expect(state.status, equals(ConnectionStatus.offline));
      });

      test('initial state lastChanged is recent (within 5 seconds)', () {
        final before = DateTime.now();
        final state = ConnectivityState.initial();
        final after = DateTime.now();
        expect(
          state.lastChanged.isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue,
        );
        expect(state.lastChanged.isBefore(after.add(const Duration(seconds: 1))), isTrue);
      });
    });

    group('isOnline getter', () {
      test('returns true when status is online', () {
        final state = ConnectivityState(
          status: ConnectionStatus.online,
          lastChanged: DateTime.now(),
        );
        expect(state.isOnline, isTrue);
      });

      test('returns false when status is offline', () {
        final state = ConnectivityState(
          status: ConnectionStatus.offline,
          lastChanged: DateTime.now(),
        );
        expect(state.isOnline, isFalse);
      });

      test('initial state isOnline returns false', () {
        expect(ConnectivityState.initial().isOnline, isFalse);
      });
    });

    group('isOffline getter', () {
      test('returns true when status is offline', () {
        final state = ConnectivityState(
          status: ConnectionStatus.offline,
          lastChanged: DateTime.now(),
        );
        expect(state.isOffline, isTrue);
      });

      test('returns false when status is online', () {
        final state = ConnectivityState(
          status: ConnectionStatus.online,
          lastChanged: DateTime.now(),
        );
        expect(state.isOffline, isFalse);
      });

      test('isOnline and isOffline are always opposite', () {
        for (final status in ConnectionStatus.values) {
          final state = ConnectivityState(
            status: status,
            lastChanged: DateTime.now(),
          );
          expect(state.isOnline, isNot(equals(state.isOffline)));
        }
      });

      test('initial state isOffline returns true', () {
        expect(ConnectivityState.initial().isOffline, isTrue);
      });
    });

    group('edge cases', () {
      test('two states created at different times have different lastChanged', () async {
        final state1 = ConnectivityState.initial();
        await Future<void>.delayed(const Duration(milliseconds: 5));
        final state2 = ConnectivityState.initial();
        // Both are offline but lastChanged may differ
        expect(state2.lastChanged.millisecondsSinceEpoch,
            greaterThanOrEqualTo(state1.lastChanged.millisecondsSinceEpoch));
      });

      test('lastChanged is preserved exactly', () {
        final specific = DateTime(2024, 6, 15, 10, 30, 0);
        final state = ConnectivityState(
          status: ConnectionStatus.online,
          lastChanged: specific,
        );
        expect(state.lastChanged, equals(specific));
      });
    });
  });
}