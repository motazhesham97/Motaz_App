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
    return SyncOutboxStatus.values[fromDb];
  }

  @override
  int toSql(SyncOutboxStatus value) {
    return value.index;
  }
}
