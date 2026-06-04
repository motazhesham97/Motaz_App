import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_identity.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/follow_up/application/follow_up_notification_service.dart';
import 'features/follow_up/application/follow_up_providers.dart';
import 'features/sync/application/server_database_binding_service.dart';
import 'features/sync/application/sync_providers.dart';
import 'features/sync/domain/sync_state.dart';

class FastikaApp extends ConsumerWidget {
  const FastikaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    ref.listen(followUpTasksProvider, (_, next) {
      final tasks = next.asData?.value;
      if (tasks == null || tasks.isEmpty) return;
      unawaited(FollowUpNotificationService.notifyForTasks(tasks));
    });

    return MaterialApp.router(
      title: AppIdentity.displayName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      locale: AppTheme.locale,
      supportedLocales: const [
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) {
        return Directionality(
          textDirection: AppTheme.textDirection,
          child: _ServerDatabaseChangeListener(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

class _ServerDatabaseChangeListener extends ConsumerStatefulWidget {
  const _ServerDatabaseChangeListener({required this.child});

  final Widget child;

  @override
  ConsumerState<_ServerDatabaseChangeListener> createState() =>
      _ServerDatabaseChangeListenerState();
}

class _ServerDatabaseChangeListenerState
    extends ConsumerState<_ServerDatabaseChangeListener> {
  bool _dialogVisible = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<SyncState>>(syncStateProvider, (_, next) {
      final syncState = next.asData?.value;
      final isServerChanged =
          syncState?.status == SyncPhase.error &&
          ServerDatabaseBindingService.isServerFingerprintChangedMessage(
            syncState?.errorMessage,
          );
      if (isServerChanged) {
        _showServerChangedDialog();
      }
    });

    return widget.child;
  }

  void _showServerChangedDialog() {
    if (_dialogVisible) return;
    _dialogVisible = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (!mounted) return;
        final navigatorContext =
            rootNavigatorKey.currentState?.overlay?.context;
        if (navigatorContext == null) return;
        final scaffoldMessenger = ScaffoldMessenger.maybeOf(navigatorContext);

        final shouldReset = await showDialog<bool>(
          context: navigatorContext,
          barrierDismissible: false,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('تم تغيير قاعدة البيانات السحابية'),
              content: const Text(
                'التطبيق اكتشف أن قاعدة نيون الحالية تختلف عن القاعدة التي ترتبط بها البيانات المحلية. '
                'يمكنك تصفير البيانات المحلية وتنزيل بيانات القاعدة الحالية، أو إلغاء العملية وترك البيانات كما هي.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('تصفير المحلي والتنزيل'),
                ),
              ],
            );
          },
        );

        if (!mounted || shouldReset != true) return;
        await ref
            .read(syncCoordinatorProvider)
            .resetLocalDataForCurrentServerAndSync();
        if (!mounted) return;
        scaffoldMessenger?.showSnackBar(
          const SnackBar(
            content: Text(
              'تم تصفير البيانات المحلية وبدأ تنزيل بيانات السحابة.',
            ),
          ),
        );
      } finally {
        if (mounted) {
          _dialogVisible = false;
        }
      }
    });
  }
}

class StartupFailureApp extends StatelessWidget {
  const StartupFailureApp({
    super.key,
    required this.errorMessage,
    required this.onReset,
  });

  final String errorMessage;
  final Future<void> Function() onReset;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    'تعذر تشغيل التطبيق',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    errorMessage,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: onReset,
                    child: const Text('إعادة ضبط البيانات المحلية'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
