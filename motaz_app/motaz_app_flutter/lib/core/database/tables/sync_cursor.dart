import 'package:drift/drift.dart';
import '../enums/parent_entity_type.dart';

class SyncCursor extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();
  IntColumn get entityType => intEnum<ParentEntityType>().unique()();
  DateTimeColumn get lastPulledAt => dateTime().nullable()();
  IntColumn get lastRowVersion => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
