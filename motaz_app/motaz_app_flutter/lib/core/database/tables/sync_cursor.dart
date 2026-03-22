import 'package:drift/drift.dart';

class SyncCursor extends Table {
  TextColumn get entityType => text().withLength(min: 1, max: 100)();
  IntColumn get lastPulledAt => integer()();
  IntColumn get lastRowVersion => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {entityType};
}
