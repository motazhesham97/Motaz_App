import 'dart:io';

import 'package:motaz_app_server/server.dart';

/// This is the starting point for your Serverpod server. Typically, there is
/// no need to modify this file.
void main(List<String> args) {
  _validateDevelopmentDatabaseEnvironment();
  run(args);
}

void _validateDevelopmentDatabaseEnvironment() {
  final runMode = Platform.environment['SERVERPOD_RUN_MODE'] ?? 'development';
  if (runMode != 'development') {
    return;
  }

  const requiredEnvVars = [
    'SERVERPOD_DATABASE_HOST',
    'SERVERPOD_DATABASE_PORT',
    'SERVERPOD_DATABASE_NAME',
    'SERVERPOD_DATABASE_USER',
  ];

  final missing = requiredEnvVars
      .where((key) => (Platform.environment[key] ?? '').trim().isEmpty)
      .toList();

  if (missing.isNotEmpty) {
    throw StateError(
      'Missing required database environment variables for development: '
      '${missing.join(', ')}. '
      'Set them in your shell, IDE run configuration, or a local .env loader before starting the server.',
    );
  }
}
