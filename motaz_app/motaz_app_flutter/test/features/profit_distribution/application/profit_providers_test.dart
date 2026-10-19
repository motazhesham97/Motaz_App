import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/core/database/app_database.dart';
import 'package:motaz_app_flutter/core/database/database_provider.dart';
import 'package:motaz_app_flutter/core/database/enums/enums.dart';
import 'package:motaz_app_flutter/core/utils/date_range.dart';
import 'package:motaz_app_flutter/features/profit_distribution/application/profit_providers.dart';
import 'package:motaz_app_flutter/features/profit_distribution/data/distribution_repository.dart';
import 'package:motaz_app_flutter/features/profit_distribution/data/profit_engine.dart';
import 'package:motaz_app_flutter/features/reports/application/report_providers.dart';

void main() {
  test(
    'refreshes review state and reports after a historical edit without silently changing approved shares',
    () async {
      // Arrange: three approved months backed by a real, isolated local database.
      final db = AppDatabase(NativeDatabase.memory());
      final now = DateTime(2026, 4, 10);
      final engine = ProfitEngine(db, now: () => now);
      final repository = DistributionRepository(db, engine);
      const device = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
      const expense = 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          profitEngineProvider.overrideWithValue(engine),
          distributionRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
      await db
          .into(db.devices)
          .insert(
            DevicesCompanion.insert(
              id: device,
              deviceName: 'Test',
              platform: DevicePlatform.ANDROID,
              deviceCode: 'test',
              createdAt: now,
              lastActiveAt: now,
            ),
          );
      await db
          .into(db.expenses)
          .insert(
            ExpensesCompanion.insert(
              id: expense,
              category: ExpenseCategory.OPERATIONAL,
              amount: 500000,
              expenseDate: DateTime(2026, 1, 15),
              createdAt: now,
              updatedAt: now,
              deviceId: device,
            ),
          );
      await repository.distribute(year: 2026, month: 3, deviceId: device);
      final march = DateRange.custom(DateTime(2026, 3), DateTime(2026, 4));
      // Keep subscriptions active as ref.watch does for visible screens.
      final financialSubscription = container.listen(
        financialChangesProvider,
        (_, _) {},
      );
      final reportSubscription = container.listen(
        profitReportProvider(march),
        (_, _) {},
      );
      final reviewed = Completer<void>();
      final subscription = container.listen(settlementReviewProvider, (
        _,
        next,
      ) {
        if (next.asData?.value.length == 3 && !reviewed.isCompleted) {
          reviewed.complete();
        }
      });
      addTearDown(subscription.close);
      addTearDown(reportSubscription.close);
      addTearDown(financialSubscription.close);
      await container.read(financialChangesProvider.future);
      expect(await container.read(settlementReviewProvider.future), isEmpty);
      expect(
        (await container.read(profitReportProvider(march).future)).netProfit,
        -500000,
      );

      // Act: edit a source row; no manual provider invalidation or remote calls.
      await (db.update(db.expenses)..where((t) => t.id.equals(expense))).write(
        const ExpensesCompanion(amount: Value(700000)),
      );
      await reviewed.future.timeout(const Duration(seconds: 10));

      // Assert: the preview refreshes, but booked snapshots still require consent.
      final reviews = await container.read(settlementReviewProvider.future);
      expect(reviews.map((entry) => entry.profit.month), [1, 2, 3]);
      final report = await container.read(profitReportProvider(march).future);
      expect(report.needsReview, isTrue);
      expect(report.netProfit, -700000);
      expect((await repository.getForMonth(2026, 3))!.carriedLossOut, -500000);
    },
  );
}
