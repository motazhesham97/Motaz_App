// ignore_for_file: constant_identifier_names

import 'package:drift/drift.dart';

enum SyncOutboxStatus {
  PENDING,
  IN_PROGRESS,
  COMPLETED,
  FAILED,
}

class SyncOutboxStatusConverter extends TypeConverter<SyncOutboxStatus, int> {
  const SyncOutboxStatusConverter();

  @override
  SyncOutboxStatus fromSql(int fromDb) {
    if (fromDb >= 0 && fromDb < SyncOutboxStatus.values.length) {
      return SyncOutboxStatus.values[fromDb];
    }

    assert(false, 'Unknown SyncOutboxStatus database value: $fromDb');
    return SyncOutboxStatus.PENDING;
  }

  @override
  int toSql(SyncOutboxStatus value) {
    return value.index;
  }
}
