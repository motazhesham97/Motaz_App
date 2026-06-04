import 'package:drift/drift.dart';
import '../enums/sync_status.dart';
import '../enums/record_status.dart';
import '../enums/receipt_type.dart';
import 'devices.dart';
import 'clients.dart';
import 'sales_invoices.dart';

@TableIndex(name: 'idx_receipt_client', columns: {#clientId})
@TableIndex(name: 'idx_receipt_date', columns: {#receiptDate})
@TableIndex(name: 'idx_receipt_status', columns: {#status})
class Receipts extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();
  TextColumn get localRef =>
      text().withLength(min: 0, max: 50).withDefault(const Constant(''))();
  TextColumn get officialNo => text().nullable()();
  IntColumn get receiptType => intEnum<ReceiptType>()();
  TextColumn get clientId =>
      text().withLength(min: 36, max: 36).references(Clients, #id)();
  TextColumn get invoiceId => text()
      .withLength(min: 36, max: 36)
      .nullable()
      .references(SalesInvoices, #id)();
  IntColumn get amount => integer()();
  DateTimeColumn get receiptDate => dateTime()();
  TextColumn get note => text().nullable()();
  IntColumn get status =>
      intEnum<RecordStatus>().withDefault(const Constant(0))();
  TextColumn get voidReason => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get deviceId =>
      text().withLength(min: 36, max: 36).references(Devices, #id)();
  IntColumn get rowVersion => integer().withDefault(const Constant(1))();
  IntColumn get syncStatus =>
      intEnum<SyncStatus>().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {localRef},
  ];
}
