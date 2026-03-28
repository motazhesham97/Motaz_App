import 'package:drift/drift.dart';

class Devices extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();

  TextColumn get deviceName =>
      text().named('device_name').withLength(min: 1, max: 255)();

  TextColumn get platform => text().withLength(min: 1, max: 50)();

  IntColumn get createdAt => integer().named('created_at')();

  IntColumn get lastActiveAt => integer().named('last_active_at')();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
