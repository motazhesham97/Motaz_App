import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../data/invoice_repository.dart';

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  return InvoiceRepository(ref.watch(appDatabaseProvider));
});

final invoiceListProvider = StreamProvider<List<SalesInvoice>>((ref) {
  final repo = ref.watch(invoiceRepositoryProvider);
  return repo.watchAll();
});

final invoiceSearchProvider =
    StreamProvider.family<List<SalesInvoice>, String>((ref, query) {
  final db = ref.watch(appDatabaseProvider);
  final q = query.trim().toLowerCase();

  final invoiceStream = (db.select(db.salesInvoices)
        ..orderBy([
          (t) => OrderingTerm.desc(t.invoiceDate),
          (t) => OrderingTerm.desc(t.createdAt),
        ])).watch();

  return invoiceStream.asyncMap((invoices) async {
    if (q.isEmpty) return invoices;
    final clients = await (db.select(db.clients)).get();
    final clientMap = {
      for (final c in clients) c.id: c.displayName.toLowerCase(),
    };
    return invoices
        .where((inv) =>
            inv.localRef.toLowerCase().contains(q) ||
            (clientMap[inv.clientId]?.contains(q) ?? false))
        .toList();
  });
});
