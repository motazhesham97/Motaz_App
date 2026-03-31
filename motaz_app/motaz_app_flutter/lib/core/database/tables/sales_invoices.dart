import 'package:drift/drift.dart';
import '../enums/sync_status.dart';
import '../enums/record_status.dart';
import 'devices.dart';
import 'clients.dart';

@TableIndex(name: 'idx_invoice_date', columns: {#invoiceDate})
@TableIndex(name: 'idx_invoice_client', columns: {#clientId})
@TableIndex(name: 'idx_invoice_status', columns: {#status})
class SalesInvoices extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();
  TextColumn get localRef => text().withLength(min: 1, max: 50).unique()();
  TextColumn get officialNo => text().nullable()();
  TextColumn get clientId => text().withLength(min: 36, max: 36).references(Clients, #id)();
  DateTimeColumn get invoiceDate => dateTime()();
  IntColumn get discount => integer().withDefault(const Constant(0))();
  IntColumn get total => integer()();
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

  @override
  List<Set<Column>> get uniqueKeys => [
    {localRef}
  ];
}
