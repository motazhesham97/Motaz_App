import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/enums/parent_entity_type.dart';
import '../../../core/database/enums/record_status.dart';
import '../../../core/utils/date_range.dart';
import '../../../core/utils/document_reference_formatter.dart';
import 'report_models.dart';

class ClientStatementQueries {
  ClientStatementQueries(this._db);

  final AppDatabase _db;

  Future<ClientStatementData> getClientStatement(
    String clientId,
    DateRange range,
  ) async {
    final clientRow = await _db
        .customSelect(
          'SELECT display_name FROM clients WHERE id = ?',
          variables: [Variable(clientId)],
        )
        .getSingle();
    final clientName = clientRow.read<String>('display_name');

    final openingRow = await _db
        .customSelect(
          'SELECT '
          '  COALESCE((SELECT SUM(total) FROM sales_invoices WHERE client_id = ? AND status = ? AND invoice_date < ?), 0) '
          '  - COALESCE((SELECT SUM(amount) FROM receipts WHERE client_id = ? AND status = ? AND receipt_date < ?), 0) '
          '  - COALESCE((SELECT SUM(sr.total_returned_amount) FROM sales_returns sr JOIN sales_invoices si ON si.id = sr.invoice_id WHERE si.client_id = ? AND sr.status = ? AND sr.return_date < ?), 0) '
          'AS opening_balance',
          variables: [
            Variable(clientId),
            Variable(RecordStatus.ACTIVE.index),
            Variable<DateTime>(range.start),
            Variable(clientId),
            Variable(RecordStatus.ACTIVE.index),
            Variable<DateTime>(range.start),
            Variable(clientId),
            Variable(RecordStatus.ACTIVE.index),
            Variable<DateTime>(range.start),
          ],
        )
        .getSingle();
    final openingBalance = openingRow.read<int>('opening_balance');

    final txnRows = await _db
        .customSelect(
          "SELECT id AS entity_id, 'INVOICE' AS type, invoice_date AS txn_date, total AS amount, COALESCE(official_no, local_ref) AS ref, COALESCE(note, '') AS note "
          "FROM sales_invoices WHERE client_id = ? AND status = ? AND invoice_date >= ? AND invoice_date < ? "
          "UNION ALL "
          "SELECT id, 'RECEIPT', receipt_date, amount, COALESCE(official_no, local_ref), COALESCE(note, '') "
          "FROM receipts WHERE client_id = ? AND status = ? AND receipt_date >= ? AND receipt_date < ? "
          "UNION ALL "
          "SELECT sr.id, 'RETURN', sr.return_date, sr.total_returned_amount, COALESCE(sr.official_no, sr.local_ref), COALESCE(sr.note, '') "
          "FROM sales_returns sr JOIN sales_invoices si ON si.id = sr.invoice_id "
          "WHERE si.client_id = ? AND sr.status = ? AND sr.return_date >= ? AND sr.return_date < ? "
          "ORDER BY txn_date ASC, type ASC",
          variables: [
            Variable(clientId),
            Variable(RecordStatus.ACTIVE.index),
            Variable<DateTime>(range.start),
            Variable<DateTime>(range.end),
            Variable(clientId),
            Variable(RecordStatus.ACTIVE.index),
            Variable<DateTime>(range.start),
            Variable<DateTime>(range.end),
            Variable(clientId),
            Variable(RecordStatus.ACTIVE.index),
            Variable<DateTime>(range.start),
            Variable<DateTime>(range.end),
          ],
        )
        .get();

    int runningBalance = openingBalance;
    final entries = txnRows.map((row) {
      final typeStr = row.read<String>('type');
      final entryType = switch (typeStr) {
        'INVOICE' => StatementEntryType.invoice,
        'RECEIPT' => StatementEntryType.receipt,
        'RETURN' => StatementEntryType.returnItem,
        _ => StatementEntryType.invoice,
      };
      final parentEntityType = switch (entryType) {
        StatementEntryType.invoice => ParentEntityType.SALES_INVOICE,
        StatementEntryType.receipt => ParentEntityType.RECEIPT,
        StatementEntryType.returnItem => ParentEntityType.SALES_RETURN,
      };

      final amount = row.read<int>('amount');
      switch (entryType) {
        case StatementEntryType.invoice:
          runningBalance += amount;
        case StatementEntryType.receipt:
        case StatementEntryType.returnItem:
          runningBalance -= amount;
      }

      final ref = row.read<String>('ref');
      final displayRef = switch (entryType) {
        StatementEntryType.invoice => invoiceDisplayRef(ref),
        StatementEntryType.receipt => receiptDisplayRef(ref),
        StatementEntryType.returnItem => returnDisplayRef(ref),
      };

      return ClientStatementEntry(
        entityId: row.read<String>('entity_id'),
        parentEntityType: parentEntityType,
        type: entryType,
        date: row.read<DateTime>('txn_date'),
        reference: displayRef,
        note: row.read<String>('note'),
        amount: amount,
        runningBalance: runningBalance,
      );
    }).toList();

    return ClientStatementData(
      clientName: clientName,
      dateRange: range,
      openingBalance: openingBalance,
      entries: entries,
      closingBalance: runningBalance,
    );
  }
}
