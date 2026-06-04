import 'package:drift/drift.dart';
import '../enums/sync_status.dart';
import '../enums/parent_entity_type.dart';
import 'devices.dart';

@TableIndex(
  name: 'idx_attachment_parent',
  columns: {#parentEntityType, #parentEntityId},
)
class AttachmentMetadata extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();
  IntColumn get parentEntityType => intEnum<ParentEntityType>()();
  TextColumn get parentEntityId => text().withLength(min: 36, max: 36)();
  TextColumn get storageReference => text()();
  TextColumn get secureUrl => text().nullable()();
  TextColumn get fileType => text()();
  IntColumn get fileSize => integer().nullable()();
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
