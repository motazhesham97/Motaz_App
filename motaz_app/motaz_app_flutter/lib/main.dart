import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motaz_app_client/motaz_app_client.dart' as api;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as auth_core;
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/auth/shared_preferences_auth_storage.dart';
import 'core/database/app_database.dart';
import 'core/database/database_provider.dart';
import 'core/database/device_service.dart';
import 'core/logging/app_logger.dart';
import 'core/server/app_config.dart';
import 'core/server/local_server_launcher.dart';
import 'core/server/server_client_provider.dart';
import 'features/follow_up/application/follow_up_notification_service.dart';
import 'features/settings/data/local_database_backup_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppLogger.initialize();
  await FollowUpNotificationService.initialize();
  try {
    await LocalDatabaseBackupService.ensureBackupDirectory();
    await LocalDatabaseBackupService.applyPendingImportIfAny();
  } catch (error, stackTrace) {
    AppLogger.database.warning(
      'Could not prepare local database backup/restore paths: $error',
      error,
      stackTrace,
    );
  }

  AppDatabase? database;
  try {
    final config = await AppConfig.load();
    unawaited(LocalServerLauncher(config).ensureStarted());

    database = AppDatabase.connect();
    await database.customSelect('SELECT 1').get();
    await DeviceService(database).ensureCurrentDevice();

    final client = api.Client(
      config.effectiveApiUrl,
      connectionTimeout: const Duration(seconds: 90),
      streamingConnectionTimeout: const Duration(seconds: 30),
      onSucceededCall: (context) {
        AppLogger.server.info(
          'Server call succeeded: ${context.endpointName}.${context.methodName}',
        );
      },
      onFailedCall: (context, error, stackTrace) {
        AppLogger.server.warning(
          'Server call failed: ${context.endpointName}.${context.methodName} => $error',
        );
      },
    );
    final sessionManager = auth_core.ClientAuthSessionManager(
      caller: auth_core.Caller(client),
      storage: auth_core.CachedClientAuthSuccessStorage(
        delegate: auth_core.KeyValueClientAuthSuccessStorage(
          keyValueStorage: SharedPreferencesAuthStorage(
            await SharedPreferences.getInstance(),
          ),
        ),
      ),
    );
    client.authKeyProvider = sessionManager;
    try {
      await sessionManager.restore();
    } catch (error, stackTrace) {
      AppLogger.server.warning(
        'Auth session restore failed; starting in offline mode: $error',
        error,
        stackTrace,
      );
    }

    runApp(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          appConfigProvider.overrideWithValue(config),
          serverpodClientProvider.overrideWithValue(client),
          sessionManagerProvider.overrideWithValue(sessionManager),
        ],
        child: const FastikaApp(),
      ),
    );
  } catch (error) {
    await database?.close();
    runApp(
      StartupFailureApp(
        errorMessage:
            'Could not open the local database or application configuration. Local data may be corrupted or file permissions may be blocking startup.\n\n$error',
        onReset: () async {
          await deleteLocalDatabase();
        },
      ),
    );
  }
}
