import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../data/distribution_repository.dart';
import '../data/profit_engine.dart';

final profitEngineProvider = Provider<ProfitEngine>((ref) {
  return ProfitEngine(ref.watch(appDatabaseProvider));
});

final distributionRepositoryProvider = Provider<DistributionRepository>((ref) {
  return DistributionRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(profitEngineProvider),
  );
});

final distributionListProvider = StreamProvider<List<MonthlyDistribution>>(
    (ref) {
  return ref.watch(distributionRepositoryProvider).watchAll();
});
