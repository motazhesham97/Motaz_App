import 'package:drift/drift.dart';

class SyncCursor extends Table {
  TextColumn get entityType =>
      text().named('entity_type').withLength(min: 1, max: 100)();

  IntColumn get lastPulledAt => integer().named('last_pulled_at')();

  IntColumn get lastRowVersion =>
      integer().named('last_row_version').withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {entityType};
}
