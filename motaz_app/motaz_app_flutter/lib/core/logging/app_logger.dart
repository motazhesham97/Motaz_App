import 'dart:developer' as developer;

import 'package:logging/logging.dart';

final Logger appLogger = Logger('MotazApp');

void initLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    final message = '${record.level.name}: ${record.time}: ${record.message}';
    developer.log(
      record.message,
      time: record.time,
      sequenceNumber: record.sequenceNumber,
      level: record.level.value,
      name: record.loggerName,
      error: record.error,
      stackTrace: record.stackTrace,
    );
    if (record.level >= Level.SEVERE) {
      developer.log(
        message,
        error: record.error,
        stackTrace: record.stackTrace,
      );
    }
  });
}

class AppLog {
  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    appLogger.info(message, error, stackTrace);
  }

  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    appLogger.warning(message, error, stackTrace);
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    appLogger.severe(message, error, stackTrace);
  }

  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    appLogger.fine(message, error, stackTrace);
  }

  static void auth(String message) {
    appLogger.info('[AUTH] $message');
  }

  static void db(String message) {
    appLogger.info('[DB] $message');
  }

  static void connectivity(String message) {
    appLogger.info('[CONNECTIVITY] $message');
  }

  static void server(String message) {
    appLogger.info('[SERVER] $message');
  }
}
