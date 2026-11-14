import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:motaz_app_flutter/core/connectivity/connectivity_provider.dart';
import 'package:motaz_app_flutter/core/database/device_provider.dart';
import 'package:motaz_app_flutter/core/utils/money_formatter.dart';
import 'package:motaz_app_flutter/features/dashboard/application/dashboard_providers.dart';
import 'package:motaz_app_flutter/features/home/presentation/home_screen.dart';
import 'package:motaz_app_flutter/features/sync/application/sync_providers.dart';
import 'package:motaz_app_flutter/features/sync/domain/sync_state.dart';

void main() {
  testWidgets(
    'home keeps metric values and positions during background reload',
    (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1100, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var revision = 0;
      final refresh = Provider<int>((ref) => revision);
      final pending = <int, Completer<int>>{};
      final container = ProviderContainer(
        overrides: [
          currentDeviceProvider.overrideWith((ref) => Stream.value(null)),
          dashboardTodayNetSalesProvider.overrideWith((ref) async {
            ref.watch(refresh);
            return pending[0]?.future ?? 100000;
          }),
          dashboardThisMonthNetSalesProvider.overrideWith((ref) async {
            ref.watch(refresh);
            return pending[1]?.future ?? 300000;
          }),
          dashboardReceivablesTotalProvider.overrideWith((ref) async {
            ref.watch(refresh);
            return pending[2]?.future ?? 500000;
          }),
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
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      final positions = [
        for (final amount in [100000, 300000, 500000])
          tester.getTopLeft(find.text(formatMoney(amount))),
      ];

      for (var i = 0; i < 3; i++) {
        pending[i] = Completer<int>();
      }
      revision++;
      container.invalidate(refresh);
      await tester.pump();
      await tester.pump();

      for (var i = 0; i < 3; i++) {
        final amount = [100000, 300000, 500000][i];
        expect(find.text(formatMoney(amount)), findsOneWidget);
        expect(tester.getTopLeft(find.text(formatMoney(amount))), positions[i]);
      }
      expect(find.byType(CircularProgressIndicator), findsNothing);

      for (var i = 0; i < 3; i++) {
        pending[i]!.complete([200000, 400000, 600000][i]);
      }
      await tester.pumpAndSettle();
      for (final amount in [200000, 400000, 600000]) {
        expect(find.text(formatMoney(amount)), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

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
