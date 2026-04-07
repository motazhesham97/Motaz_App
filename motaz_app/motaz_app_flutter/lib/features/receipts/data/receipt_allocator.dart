import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/enums/record_status.dart';

class ReceiptAllocator {
  ReceiptAllocator(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  Future<List<ReceiptAllocationsCompanion>> allocateFifo(
    String clientId,
    int amount, {
    String? excludeInvoiceId,
  }) async {
    var query = _db.select(_db.salesInvoices)
      ..where((t) => t.clientId.equals(clientId) & t.status.equals(RecordStatus.ACTIVE.index))
      ..orderBy([
        (t) => OrderingTerm.asc(t.invoiceDate),
        (t) => OrderingTerm.asc(t.createdAt),
      ]);

    if (excludeInvoiceId != null) {
      query = query..where((t) => t.id.equals(excludeInvoiceId).not());
    }

    final invoices = await query.get();
    final allocations = <ReceiptAllocationsCompanion>[];
    var remaining = amount;
    final now = DateTime.now();

    for (final invoice in invoices) {
      if (remaining <= 0) break;

      final paidRow = await _db.customSelect(
        'SELECT COALESCE(SUM(ra.allocated_amount), 0) AS paid '
        'FROM receipt_allocations ra '
        'INNER JOIN receipts r ON ra.receipt_id = r.id '
        'WHERE ra.invoice_id = ? AND r.status = ?',
        variables: [
          Variable(invoice.id),
          Variable(RecordStatus.ACTIVE.index),
        ],
      ).getSingle();

      final paid = paidRow.read<int>('paid');
      final invoiceBalance = invoice.total - paid;

      if (invoiceBalance <= 0) continue;

      final toAllocate = remaining < invoiceBalance ? remaining : invoiceBalance;

      allocations.add(ReceiptAllocationsCompanion(
        id: Value(_uuid.v4()),
        receiptId: Value.absent(),
        invoiceId: Value(invoice.id),
        allocatedAmount: Value(toAllocate),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));

      remaining -= toAllocate;
    }

    return allocations;
  }
}
