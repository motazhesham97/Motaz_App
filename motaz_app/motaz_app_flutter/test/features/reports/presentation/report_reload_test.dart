import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/core/connectivity/connectivity_provider.dart';
import 'package:motaz_app_flutter/core/database/app_database.dart';
import 'package:motaz_app_flutter/core/database/database_provider.dart';
import 'package:motaz_app_flutter/features/reports/application/report_providers.dart';
import 'package:motaz_app_flutter/features/reports/data/report_models.dart';
import 'package:motaz_app_flutter/features/reports/presentation/sales_report_screen.dart';
import 'package:motaz_app_flutter/features/reports/presentation/client_statement_screen.dart';
import 'package:motaz_app_flutter/features/reports/presentation/client_receivables_report_screen.dart';
import 'package:motaz_app_flutter/features/reports/presentation/client_product_sales_report_screen.dart';
import 'package:motaz_app_flutter/features/reports/presentation/expense_report_screen.dart';
import 'package:motaz_app_flutter/features/reports/presentation/free_sample_report_screen.dart';
import 'package:motaz_app_flutter/features/reports/presentation/final_monthly_report_screen.dart';
import 'package:motaz_app_flutter/features/sync/application/sync_providers.dart';
import 'package:motaz_app_flutter/features/sync/domain/sync_state.dart';

class _Ticks extends Notifier<int> {
  @override
  int build() => 0;
  void tick() => state++;
}

final _ticks = NotifierProvider<_Ticks, int>(_Ticks.new);

SalesReportSummary _data(String client) => SalesReportSummary(
  rows: [
    SalesReportRow(
      invoiceId: 'invoice',
      localRef: 'INV-1',
      clientName: client,
      invoiceDate: DateTime(2026, 1, 1),
      total: 100,
      discount: 0,
    ),
  ],
  grossSales: 100,
  totalDiscounts: 0,
  totalReturns: 0,
  netSales: 100,
);

void main() {
  testWidgets(
    'database-driven report reload keeps existing content and export action',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final reload = Completer<SalesReportSummary>();
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          syncStateProvider.overrideWith(
            (ref) => Stream.value(const SyncState()),
          ),
          pendingCountProvider.overrideWith((ref) => Stream.value(0)),
          failedOutboxCountProvider.overrideWith((ref) => Stream.value(0)),
          unresolvedConflictCountProvider.overrideWith(
            (ref) => Stream.value(0),
          ),
          connectivityProvider.overrideWith(
            (ref) => Stream.value(ConnectivityStatus.offline),
          ),
          salesReportProvider.overrideWith(
            (ref, range) => ref.watch(_ticks) == 0
                ? Future.value(_data('Existing report client'))
                : reload.future,
          ),
        ],
      );
      addTearDown(container.dispose);
      const screens = [
        SalesReportScreen(),
        ClientStatementScreen(),
        ClientReceivablesReportScreen(),
        ClientProductSalesReportScreen(),
        ExpenseReportScreen(),
        FreeSampleReportScreen(),
        FinalMonthlyReportScreen(),
      ];
      expect(screens.length, 7);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: screens.first),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Existing report client'), findsOneWidget);

      container.read(_ticks.notifier).tick();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Existing report client'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('تصدير PDF'), findsOneWidget);
      reload.complete(_data('Updated report client'));
      await tester.pumpAndSettle();
      expect(find.text('Updated report client'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
