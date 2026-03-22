import 'package:drift/drift.dart';
import 'devices.dart';

class SyncOutbox extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text().withLength(min: 1, max: 100)();
  TextColumn get entityId => text().withLength(min: 36, max: 36)();
  TextColumn get operation => text().withLength(min: 1, max: 20)();
  TextColumn get payload => text()();
  IntColumn get rowVersion => integer()();
  TextColumn get deviceId => text().withLength(min: 36, max: 36).references(Devices, #id)();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withLength(min: 1, max: 20).withDefault(const Constant('pending'))();
  IntColumn get createdAt => integer()();
}
