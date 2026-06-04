import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../data/beneficiary_repository.dart';
import '../data/free_sample_repository.dart';

final beneficiaryRepositoryProvider = Provider<BeneficiaryRepository>((ref) {
  return BeneficiaryRepository(ref.watch(appDatabaseProvider));
});

final freeSampleRepositoryProvider = Provider<FreeSampleRepository>((ref) {
  return FreeSampleRepository(ref.watch(appDatabaseProvider));
});

final beneficiaryListProvider = StreamProvider<List<Beneficiary>>((ref) {
  return ref.watch(beneficiaryRepositoryProvider).watchAll();
});

final freeSampleRecentProvider = StreamProvider<List<FreeSampleSummary>>((ref) {
  return ref.watch(freeSampleRepositoryProvider).watchRecent();
});

final freeSampleReportProvider = StreamProvider<List<FreeSampleSummary>>((ref) {
  return ref.watch(freeSampleRepositoryProvider).watchAllSummaries();
});
