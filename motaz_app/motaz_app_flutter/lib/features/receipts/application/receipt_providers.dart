import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../data/receipt_repository.dart';

final receiptRepositoryProvider = Provider<ReceiptRepository>((ref) {
  return ReceiptRepository(ref.watch(appDatabaseProvider));
});

final receiptListProvider = StreamProvider<List<Receipt>>((ref) {
  final repo = ref.watch(receiptRepositoryProvider);
  return repo.watchAll();
});

final receiptSearchProvider =
    StreamProvider.family<List<Receipt>, String>((ref, query) {
  final db = ref.watch(appDatabaseProvider);
  final q = query.trim().toLowerCase();

  final receiptStream = (db.select(db.receipts)
        ..orderBy([
          (t) => OrderingTerm.desc(t.receiptDate),
          (t) => OrderingTerm.desc(t.createdAt),
        ])).watch();

  return receiptStream.asyncMap((receipts) async {
    if (q.isEmpty) return receipts;
    final clients = await (db.select(db.clients)).get();
    final clientMap = {
      for (final c in clients) c.id: c.displayName.toLowerCase(),
    };
    return receipts
        .where((r) => clientMap[r.clientId]?.contains(q) ?? false)
        .toList();
  });
});
