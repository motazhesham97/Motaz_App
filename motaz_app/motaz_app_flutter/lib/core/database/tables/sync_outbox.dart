import 'package:drift/drift.dart';
import '../enums/parent_entity_type.dart';
import '../enums/audit_operation.dart';
import '../enums/sync_outbox_status.dart';
import 'devices.dart';

@TableIndex(name: 'idx_outbox_status', columns: {#status})
class SyncOutbox extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();
  IntColumn get entityType => intEnum<ParentEntityType>()();
  TextColumn get entityId => text().withLength(min: 36, max: 36)();
  IntColumn get operation => intEnum<AuditOperation>()();
  TextColumn get payload => text()();
  IntColumn get rowVersion => integer()();
  TextColumn get deviceId => text().withLength(min: 36, max: 36).references(Devices, #id)();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  IntColumn get status => intEnum<SyncOutboxStatus>().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
