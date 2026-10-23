import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/core/connectivity/connectivity_provider.dart';
import 'package:motaz_app_flutter/core/database/app_database.dart';
import 'package:motaz_app_flutter/features/profit_distribution/application/profit_providers.dart';
import 'package:motaz_app_flutter/features/profit_distribution/data/profit_engine.dart';
import 'package:motaz_app_flutter/features/profit_distribution/domain/monthly_profit.dart';
import 'package:motaz_app_flutter/features/profit_distribution/presentation/distribution_screen.dart';
import 'package:motaz_app_flutter/features/sync/application/sync_providers.dart';
import 'package:motaz_app_flutter/features/sync/domain/sync_state.dart';

MonthSettlement _review(int year, int month) => (
  profit: MonthlyProfit(
    year: year,
    month: month,
    netSales: 100000,
    operationalExpenses: 0,
    productionExpenses: 0,
    carriedLossIn: 0,
  ),
  recorded: null,
  needsReview: true,
);

void main() {
  late AppDatabase db;
  final requested = <({int year, int month})>[];

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    requested.clear();
  });
  tearDown(() => db.close());

  Future<void> pumpScreen(
    WidgetTester tester, {
    DateTime? initialPeriod,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settlementReviewProvider.overrideWith(
            (ref) async => [
              _review(2026, 8),
              _review(2026, 9),
            ],
          ),
          monthlySettlementProvider.overrideWith((ref, period) async {
            requested.add(period);
            return _review(period.year, period.month);
          }),
          distributionListProvider.overrideWith((ref) => Stream.value([])),
          profitEngineProvider.overrideWithValue(
            ProfitEngine(db, now: () => DateTime(2026, 10, 24)),
          ),
          syncStateProvider.overrideWith(
            (ref) => Stream.value(const SyncState(status: SyncPhase.idle)),
          ),
          pendingCountProvider.overrideWith((ref) => Stream.value(0)),
          failedOutboxCountProvider.overrideWith((ref) => Stream.value(0)),
          unresolvedConflictCountProvider.overrideWith(
            (ref) => Stream.value(0),
          ),
          connectivityProvider.overrideWith(
            (ref) => Stream.value(ConnectivityStatus.offline),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: DistributionScreen(initialPeriod: initialPeriod),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'lists affected months and initially selects the oldest for review',
    (tester) async {
      await pumpScreen(tester);
      expect(find.text('أغسطس 2026'), findsOneWidget);
      expect(find.text('سبتمبر 2026'), findsOneWidget);
      expect(requested.last, (year: 2026, month: 8));
      expect(
        tester
            .widget<ListTile>(find.widgetWithText(ListTile, 'أغسطس 2026'))
            .selected,
        isTrue,
      );

      await tester.tap(find.widgetWithText(ListTile, 'سبتمبر 2026'));
      await tester.pumpAndSettle();

      expect(requested, contains((year: 2026, month: 9)));
      expect(
        tester
            .widget<ListTile>(find.widgetWithText(ListTile, 'سبتمبر 2026'))
            .selected,
        isTrue,
      );
      expect(
        tester
            .state<FormFieldState<int>>(
              find.byKey(const ValueKey('settlement-month-9')),
            )
            .value,
        9,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'respects a linked month and names affected months before approval',
    (tester) async {
      await pumpScreen(tester, initialPeriod: DateTime(2026, 9));
      expect(requested.single, (year: 2026, month: 9));
      expect(
        tester
            .widget<ListTile>(find.widgetWithText(ListTile, 'سبتمبر 2026'))
            .selected,
        isTrue,
      );

      await tester.tap(find.text('مراجعة واعتماد الأشهر'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('أغسطس 2026، سبتمبر 2026'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'إلغاء'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(await db.select(db.monthlyDistributions).get(), isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
