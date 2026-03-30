// ignore_for_file: constant_identifier_names

import 'package:drift/drift.dart';

enum SyncStatus {
  PENDING,
  SYNCED,
  CONFLICT,
  FAILED,
}

class SyncStatusConverter extends TypeConverter<SyncStatus, int> {
  const SyncStatusConverter();

  @override
  SyncStatus fromSql(int fromDb) {
    if (fromDb >= 0 && fromDb < SyncStatus.values.length) {
      return SyncStatus.values[fromDb];
    }

    assert(false, 'Unknown SyncStatus database value: $fromDb');
    return SyncStatus.PENDING;
  }

  @override
  int toSql(SyncStatus value) {
    return value.index;
  }
}
