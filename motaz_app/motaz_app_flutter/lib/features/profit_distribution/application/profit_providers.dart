import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../data/distribution_repository.dart';
import '../data/profit_engine.dart';

final profitEngineProvider = Provider<ProfitEngine>((ref) {
  return ProfitEngine(ref.watch(appDatabaseProvider));
});

final financialChangesProvider = StreamProvider<int>((ref) {
  final db = ref.watch(appDatabaseProvider);
  var tick = 0;
  return db
      .customSelect(
        'SELECT 1',
        readsFrom: {
          db.salesInvoices,
          db.salesReturns,
          db.expenses,
          db.monthlyDistributions,
        },
      )
      .watch()
      .map((_) => tick++);
});

final monthlySettlementProvider =
    FutureProvider.family<MonthSettlement, ({int year, int month})>((
      ref,
      period,
    ) async {
      ref.watch(financialChangesProvider);
      return (await ref
              .watch(profitEngineProvider)
              .timeline(period.year, period.month))
          .last;
    });

final settlementReviewProvider = FutureProvider<List<MonthSettlement>>((
  ref,
) async {
  ref.watch(financialChangesProvider);
  final timeline = await ref
      .watch(distributionRepositoryProvider)
      .reviewTimeline();
  return timeline.where((entry) => entry.needsReview).toList();
});

final distributionRepositoryProvider = Provider<DistributionRepository>((ref) {
  return DistributionRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(profitEngineProvider),
  );
});

final distributionListProvider = StreamProvider<List<MonthlyDistribution>>((
  ref,
) {
  return ref.watch(distributionRepositoryProvider).watchAll();
});
