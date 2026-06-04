import 'package:drift/drift.dart';
import '../enums/parent_entity_type.dart';
import '../enums/audit_operation.dart';
import 'devices.dart';

@TableIndex(name: 'idx_audit_entity', columns: {#entityType, #entityId})
@TableIndex(name: 'idx_audit_created', columns: {#createdAt})
class AuditEvents extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();
  IntColumn get entityType => intEnum<ParentEntityType>()();
  TextColumn get entityId => text().withLength(min: 36, max: 36)();
  IntColumn get operation => intEnum<AuditOperation>()();
  TextColumn get diffData => text()();
  TextColumn get deviceId =>
      text().withLength(min: 36, max: 36).references(Devices, #id)();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
