import 'package:drift/drift.dart';
import '../enums/sync_status.dart';
import '../enums/record_status.dart';
import 'devices.dart';

@TableIndex(
  name: 'idx_distribution_year_month',
  columns: {#year, #month},
  unique: true,
)
@TableIndex(name: 'idx_distribution_status', columns: {#status})
class MonthlyDistributions extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();
  IntColumn get year => integer()();
  IntColumn get month => integer()();
  IntColumn get netProfit => integer()();
  IntColumn get ownerShare => integer()();
  IntColumn get partnerShare => integer()();
  IntColumn get marginShare => integer()();
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
}
