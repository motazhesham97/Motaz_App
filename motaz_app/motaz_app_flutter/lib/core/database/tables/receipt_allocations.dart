import 'package:drift/drift.dart';
import 'receipts.dart';
import 'sales_invoices.dart';

@TableIndex(name: 'idx_allocation_receipt', columns: {#receiptId})
@TableIndex(name: 'idx_allocation_invoice', columns: {#invoiceId})
class ReceiptAllocations extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();
  TextColumn get receiptId => text().withLength(min: 36, max: 36).references(Receipts, #id)();
  TextColumn get invoiceId => text().withLength(min: 36, max: 36).references(SalesInvoices, #id)();
  IntColumn get allocatedAmount => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
