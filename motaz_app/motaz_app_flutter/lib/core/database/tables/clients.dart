import 'package:drift/drift.dart';
import '../enums/sync_status.dart';
import 'devices.dart';

@TableIndex(name: 'idx_client_display_name', columns: {#displayName})
class Clients extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();
  TextColumn get displayName => text().withLength(min: 1, max: 255)();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get clientCode => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get deviceId => text().withLength(min: 36, max: 36).references(Devices, #id)();
  IntColumn get rowVersion => integer().withDefault(const Constant(1))();
  IntColumn get syncStatus => intEnum<SyncStatus>().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
