import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:motaz_app_flutter/core/connectivity/connectivity_provider.dart';
import 'package:motaz_app_flutter/core/database/device_provider.dart';
import 'package:motaz_app_flutter/features/dashboard/application/dashboard_providers.dart';
import 'package:motaz_app_flutter/features/home/presentation/home_screen.dart';
import 'package:motaz_app_flutter/features/sync/application/sync_providers.dart';
import 'package:motaz_app_flutter/features/sync/domain/sync_state.dart';

void main() {
  testWidgets('quick action opens expenses section', (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/expenses',
          builder: (context, state) => const Scaffold(
            body: Center(
              child: Text(
                'expenses destination',
                key: ValueKey('expenses.destination'),
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentDeviceProvider.overrideWith((ref) => Stream.value(null)),
          dashboardTodayNetSalesProvider.overrideWith((ref) async => 0),
          dashboardThisMonthNetSalesProvider.overrideWith((ref) async => 0),
          dashboardReceivablesTotalProvider.overrideWith((ref) async => 0),
          syncStateProvider.overrideWith(
            (ref) => Stream.value(const SyncState(status: SyncPhase.idle)),
          ),
          pendingCountProvider.overrideWith((ref) => Stream.value(0)),
          failedOutboxCountProvider.overrideWith((ref) => Stream.value(0)),
          unresolvedConflictCountProvider.overrideWith(
            (ref) => Stream.value(0),
          ),
          connectivityProvider.overrideWith(
            (ref) => Stream.value(ConnectivityStatus.online),
          ),
        ],
        child: MaterialApp.router(
          locale: const Locale('ar'),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final expensesAction = find.byKey(
      const ValueKey('home.quickAction.expenses'),
    );

    await tester.scrollUntilVisible(
      expensesAction,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('إضافة مصروف'), findsOneWidget);
    expect(find.text('منتج جديد'), findsNothing);

    await tester.tap(expensesAction);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('expenses.destination')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
