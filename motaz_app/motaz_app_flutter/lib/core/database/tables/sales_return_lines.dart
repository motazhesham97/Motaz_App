import 'package:drift/drift.dart';
import 'sales_returns.dart';
import 'sales_invoice_lines.dart';

@TableIndex(name: 'idx_return_line_return', columns: {#returnId})
class SalesReturnLines extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();
  TextColumn get returnId => text().withLength(min: 36, max: 36).references(SalesReturns, #id)();
  TextColumn get invoiceLineId => text().withLength(min: 36, max: 36).references(SalesInvoiceLines, #id)();
  IntColumn get returnedQuantity => integer()();
  IntColumn get returnedAmount => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
