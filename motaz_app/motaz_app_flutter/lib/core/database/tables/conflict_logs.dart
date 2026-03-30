import 'package:drift/drift.dart';
import '../enums/parent_entity_type.dart';
import '../enums/conflict_status.dart';
import 'devices.dart';

@TableIndex(name: 'idx_conflict_entity', columns: {#entityType, #entityId})
@TableIndex(name: 'idx_conflict_status', columns: {#resolutionStatus})
class ConflictLogs extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();
  IntColumn get entityType => intEnum<ParentEntityType>()();
  TextColumn get entityId => text().withLength(min: 36, max: 36)();
  TextColumn get localPayload => text()();
  TextColumn get remotePayload => text()();
  TextColumn get conflictType => text()();
  IntColumn get resolutionStatus => intEnum<ConflictStatus>().withDefault(const Constant(0))();
  DateTimeColumn get resolvedAt => dateTime().nullable()();
  TextColumn get resolutionData => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get deviceId => text().withLength(min: 36, max: 36).references(Devices, #id)();

  @override
  Set<Column> get primaryKey => {id};
}
