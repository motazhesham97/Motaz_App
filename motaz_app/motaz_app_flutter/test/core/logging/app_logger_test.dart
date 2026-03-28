import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:motaz_app_flutter/core/logging/app_logger.dart';

void main() {
  group('AppLog', () {
    final records = <LogRecord>[];
    late StreamSubscription<LogRecord> subscription;

    setUp(() {
      records.clear();
      // Ensure all log levels pass through so tests can capture FINE/DEBUG records.
      Logger.root.level = Level.ALL;
      subscription = appLogger.onRecord.listen(records.add);
    });

    tearDown(() async {
      await subscription.cancel();
      records.clear();
    });

    group('info', () {
      test('logs at INFO level', () {
        AppLog.info('test info message');
        expect(records.where((r) => r.level == Level.INFO).length, greaterThanOrEqualTo(1));
      });

      test('message is preserved', () {
        AppLog.info('hello world');
        expect(records.any((r) => r.message == 'hello world'), isTrue);
      });

      test('accepts optional error and stackTrace', () {
        final error = Exception('test error');
        final stackTrace = StackTrace.current;
        expect(() => AppLog.info('msg with error', error, stackTrace), returnsNormally);
      });
    });

    group('warning', () {
      test('logs at WARNING level', () {
        AppLog.warning('test warning');
        expect(records.any((r) => r.level == Level.WARNING && r.message == 'test warning'), isTrue);
      });

      test('accepts optional error and stackTrace', () {
        expect(() => AppLog.warning('w', Exception('e'), StackTrace.current), returnsNormally);
      });
    });

    group('error', () {
      test('logs at SEVERE level', () {
        AppLog.error('test error message');
        expect(records.any((r) => r.level == Level.SEVERE && r.message == 'test error message'), isTrue);
      });

      test('attaches error object', () {
        final err = Exception('db failure');
        AppLog.error('db error', err);
        final record = records.firstWhere((r) => r.level == Level.SEVERE);
        expect(record.error, equals(err));
      });

      test('attaches stackTrace', () {
        final st = StackTrace.current;
        AppLog.error('err', Exception('x'), st);
        final record = records.firstWhere((r) => r.level == Level.SEVERE);
        expect(record.stackTrace, equals(st));
      });
    });

    group('debug', () {
      test('logs at FINE level', () {
        AppLog.debug('test debug');
        expect(records.any((r) => r.level == Level.FINE && r.message == 'test debug'), isTrue);
      });
    });

    group('auth', () {
      test('message is prefixed with [AUTH]', () {
        AppLog.auth('signing in');
        expect(records.any((r) => r.message == '[AUTH] signing in'), isTrue);
      });

      test('logs at INFO level', () {
        AppLog.auth('auth event');
        expect(records.any((r) => r.level == Level.INFO && r.message.startsWith('[AUTH]')), isTrue);
      });
    });

    group('db', () {
      test('message is prefixed with [DB]', () {
        AppLog.db('query executed');
        expect(records.any((r) => r.message == '[DB] query executed'), isTrue);
      });

      test('logs at INFO level', () {
        AppLog.db('open db');
        expect(records.any((r) => r.level == Level.INFO && r.message.startsWith('[DB]')), isTrue);
      });
    });

    group('connectivity', () {
      test('message is prefixed with [CONNECTIVITY]', () {
        AppLog.connectivity('connected');
        expect(records.any((r) => r.message == '[CONNECTIVITY] connected'), isTrue);
      });

      test('logs at INFO level', () {
        AppLog.connectivity('offline');
        expect(records.any((r) => r.level == Level.INFO && r.message.startsWith('[CONNECTIVITY]')), isTrue);
      });
    });

    group('server', () {
      test('message is prefixed with [SERVER]', () {
        AppLog.server('ping sent');
        expect(records.any((r) => r.message == '[SERVER] ping sent'), isTrue);
      });

      test('logs at INFO level', () {
        AppLog.server('health check');
        expect(records.any((r) => r.level == Level.INFO && r.message.startsWith('[SERVER]')), isTrue);
      });
    });

    group('appLogger', () {
      test('appLogger name is MotazApp', () {
        expect(appLogger.name, equals('MotazApp'));
      });
    });

    group('initLogging', () {
      test('can be called without throwing', () {
        expect(() => initLogging(), returnsNormally);
      });

      test('sets Logger.root level to ALL after call', () {
        initLogging();
        expect(Logger.root.level, equals(Level.ALL));
      });

      test('can be called multiple times without error', () {
        expect(() {
          initLogging();
          initLogging();
        }, returnsNormally);
      });
    });
  });
}