import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../data/client_repository.dart';

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  return ClientRepository(ref.watch(appDatabaseProvider));
});

final clientListProvider = StreamProvider<List<Client>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(
    db.clients,
  )..orderBy([(t) => OrderingTerm.asc(t.displayName)])).watch();
});

final activeClientListProvider = StreamProvider<List<Client>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.clients)
        ..where((t) => t.isActive.equals(true))
        ..orderBy([(t) => OrderingTerm.asc(t.displayName)]))
      .watch();
});

final clientSearchProvider = StreamProvider.family<List<Client>, String>((
  ref,
  query,
) {
  final db = ref.watch(appDatabaseProvider);
  final q = query.trim();
  return (db.select(db.clients)
        ..where(
          (t) =>
              t.displayName.like('%$q%') |
              t.phone.like('%$q%') |
              t.clientCode.like('%$q%'),
        )
        ..orderBy([(t) => OrderingTerm.asc(t.displayName)]))
      .watch();
});
