import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

import 'app.dart';
import 'core/auth/auth_provider.dart';
import 'core/connectivity/server_service.dart';
import 'core/database/app_database.dart';
import 'core/database/database_provider.dart';
import 'core/database/device_service.dart';
import 'core/logging/app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  initLogging();
  AppLog.info('Application starting...');

  try {
    final serverUrl = await getServerUrl();
    final client = buildClient(serverUrl);
    final serverService = ServerService(client);

    AppDatabase database;
    try {
      database = await AppDatabase.createWithCorruptionDetection();
    } on DatabaseCorruptedException catch (e) {
      AppLog.error('Database corruption detected', e);
      runApp(
        _DatabaseErrorApp(
          message:
              '${e.message}\n\nتحذير: إعادة التعيين ستحذف أي بيانات محلية غير متزامنة.',
          actionLabel: 'إعادة تعيين البيانات المحلية',
          onAction: () async {
            await resetDatabaseFiles();
          },
        ),
      );
      return;
    } on FileSystemException catch (e, stackTrace) {
      AppLog.error(
        'Storage permission or filesystem access error',
        e,
        stackTrace,
      );
      runApp(
        const _DatabaseErrorApp(
          message:
              'تعذر الوصول إلى ملفات التطبيق المحلية. يرجى التأكد من منح صلاحيات التخزين أو تشغيل التطبيق من مجلد قابل للكتابة ثم إعادة المحاولة.',
        ),
      );
      return;
    }

    final deviceService = DeviceService(database);
    await deviceService.getOrCreateDevice();

    AppLog.info('Application initialized successfully');

    runApp(
      ProviderScope(
        overrides: [
          clientProvider.overrideWithValue(client),
          serverServiceProvider.overrideWithValue(serverService),
          appDatabaseProvider.overrideWithValue(database),
        ],
        child: const MotazApp(),
      ),
    );
  } catch (e, stackTrace) {
    AppLog.error('Failed to initialize application', e, stackTrace);
    runApp(
      _DatabaseErrorApp(
        message: 'حدث خطأ أثناء تشغيل التطبيق. يرجى إعادة تشغيل التطبيق.',
      ),
    );
  }
}

class _DatabaseErrorApp extends StatelessWidget {
  const _DatabaseErrorApp({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('ar'),
      debugShowCheckedModeBanner: false,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (onAction != null && actionLabel != null) ...[
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        await onAction!.call();
                      },
                      child: Text(actionLabel!),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
