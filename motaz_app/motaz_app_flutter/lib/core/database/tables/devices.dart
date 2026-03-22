import 'package:drift/drift.dart';

class Devices extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();
  TextColumn get deviceName => text().withLength(min: 1, max: 255)();
  TextColumn get platform => text().withLength(min: 1, max: 50)();
  IntColumn get createdAt => integer()();
  IntColumn get lastActiveAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
