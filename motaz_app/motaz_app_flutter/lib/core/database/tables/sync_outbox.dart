import 'package:drift/drift.dart';

import 'devices.dart';

class SyncOutbox extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get entityType =>
      text().named('entity_type').withLength(min: 1, max: 100)();

  TextColumn get entityId =>
      text().named('entity_id').withLength(min: 36, max: 36)();

  TextColumn get operation => text().withLength(min: 1, max: 20)();

  TextColumn get payload => text()();

  IntColumn get rowVersion => integer().named('row_version')();

  TextColumn get deviceId => text()
      .named('device_id')
      .withLength(min: 36, max: 36)
      .references(Devices, #id)();

  IntColumn get retryCount =>
      integer().named('retry_count').withDefault(const Constant(0))();

  TextColumn get status => text()
      .withLength(min: 1, max: 20)
      .withDefault(const Constant('pending'))();

  IntColumn get createdAt => integer().named('created_at')();
}
