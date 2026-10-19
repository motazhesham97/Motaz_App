import 'dart:io';

import 'package:serverpod/serverpod.dart';

ServerpodConfig localTestConfig(ServerpodConfig config) {
  if (config.runMode != 'test') {
    throw StateError('Integration tests must use test mode');
  }
  return config.copyWith(
    // Never inherit a production connection from the shell or passwords file.
    database: DatabaseConfig(
      host: '127.0.0.1',
      port: 9090,
      user: 'postgres',
      name: 'motaz_app_test',
      password:
          Platform.environment['MOTAZ_TEST_POSTGRES_PASSWORD'] ??
          'motaz_test_password',
    ),
    futureCallExecutionEnabled: false,
  );
}
