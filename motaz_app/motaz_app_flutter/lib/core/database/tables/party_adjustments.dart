import 'package:drift/drift.dart';

import '../enums/party_account.dart';
import '../enums/record_status.dart';
import '../enums/sync_status.dart';
import 'devices.dart';

@TableIndex(name: 'idx_party_adjustment_party', columns: {#party})
@TableIndex(name: 'idx_party_adjustment_date', columns: {#adjustmentDate})
@TableIndex(name: 'idx_party_adjustment_status', columns: {#status})
class PartyAdjustments extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();
  IntColumn get party => intEnum<PartyAccount>()();
  IntColumn get amount => integer()();
  DateTimeColumn get adjustmentDate => dateTime()();
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
}
