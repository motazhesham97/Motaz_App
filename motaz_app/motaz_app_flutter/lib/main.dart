import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motaz_app_client/motaz_app_client.dart' as api;
import 'package:serverpod_auth_client/serverpod_auth_client.dart' as auth;
import 'package:serverpod_auth_shared_flutter/serverpod_auth_shared_flutter.dart';

import 'app.dart';
import 'core/database/app_database.dart';
import 'core/database/database_provider.dart';
import 'core/database/device_service.dart';
import 'core/logging/app_logger.dart';
import 'core/server/app_config.dart';
import 'core/server/server_client_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppLogger.initialize();

  try {
    final config = await AppConfig.load();

    final database = AppDatabase.connect();
    await database.customSelect('SELECT 1').get();
    await DeviceService(database).ensureCurrentDevice();

    final client = api.Client(
      config.effectiveApiUrl,
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
    client.authKeyProvider = FlutterAuthenticationKeyManager(
      runMode: config.runMode,
    );
    final sessionManager = SessionManager(caller: auth.Caller(client));
    await sessionManager.initialize();

    runApp(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          appConfigProvider.overrideWithValue(config),
          serverpodClientProvider.overrideWithValue(client),
          sessionManagerProvider.overrideWithValue(sessionManager),
        ],
        child: const MotazApp(),
      ),
    );
  } catch (error) {
    runApp(
      StartupFailureApp(
        errorMessage:
            'تعذر الوصول إلى قاعدة البيانات أو ملفات التطبيق. قد تكون البيانات المحلية تالفة أو هناك مشكلة في الصلاحيات.\n\n$error',
        onReset: () async {
          await deleteLocalDatabase();
        },
      ),
    );
  }
}
