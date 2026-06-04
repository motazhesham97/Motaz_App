import 'package:drift/drift.dart';
import '../enums/parent_entity_type.dart';

@TableIndex(name: 'idx_staging_upload_status', columns: {#uploadStatus})
class LocalAttachmentStaging extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();
  IntColumn get parentEntityType => intEnum<ParentEntityType>()();
  TextColumn get parentEntityId => text().withLength(min: 36, max: 36)();
  TextColumn get localFilePath => text()();
  TextColumn get fileType => text()();
  IntColumn get fileSize => integer().nullable()();
  TextColumn get uploadStatus =>
      text().withDefault(const Constant('PENDING'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
