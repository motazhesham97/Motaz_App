import 'package:drift/drift.dart';
import '../enums/sync_status.dart';
import '../enums/record_status.dart';
import 'devices.dart';
import 'sales_invoices.dart';

@TableIndex(name: 'idx_return_invoice', columns: {#invoiceId})
@TableIndex(name: 'idx_return_date', columns: {#returnDate})
@TableIndex(name: 'idx_return_status', columns: {#status})
class SalesReturns extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();
  TextColumn get invoiceId => text().withLength(min: 36, max: 36).references(SalesInvoices, #id)();
  DateTimeColumn get returnDate => dateTime()();
  IntColumn get totalReturnedAmount => integer()();
  TextColumn get note => text().nullable()();
  IntColumn get status => intEnum<RecordStatus>().withDefault(const Constant(0))();
  TextColumn get voidReason => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get deviceId => text().withLength(min: 36, max: 36).references(Devices, #id)();
  IntColumn get rowVersion => integer().withDefault(const Constant(1))();
  IntColumn get syncStatus => intEnum<SyncStatus>().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
