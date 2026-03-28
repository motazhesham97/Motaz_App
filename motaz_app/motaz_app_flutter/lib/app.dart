import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/connectivity_badge.dart';

class MotazApp extends ConsumerWidget {
  const MotazApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'تطبيق معتز',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Stack(
            children: [
              child ??
                  const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  ),
              const PositionedDirectional(
                top: 16,
                start: 16,
                child: SafeArea(
                  child: ConnectivityBadge(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
