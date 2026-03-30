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
    return SyncStatus.values[fromDb];
  }

  @override
  int toSql(SyncStatus value) {
    return value.index;
  }
}
