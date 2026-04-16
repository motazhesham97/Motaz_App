import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../data/return_repository.dart';

final returnRepositoryProvider = Provider<ReturnRepository>((ref) {
  return ReturnRepository(ref.watch(appDatabaseProvider));
});

final returnListProvider = StreamProvider<List<SalesReturn>>((ref) {
  final repo = ref.watch(returnRepositoryProvider);
  return repo.watchAll();
});

final returnSearchProvider =
    StreamProvider.family<List<SalesReturn>, String>((ref, query) {
  final repo = ref.watch(returnRepositoryProvider);
  return repo.searchByText(query);
});