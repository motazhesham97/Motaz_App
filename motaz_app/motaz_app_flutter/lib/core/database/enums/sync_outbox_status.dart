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
    switch (fromDb) {
      case 0:
        return SyncOutboxStatus.PENDING;
      case 1:
        return SyncOutboxStatus.IN_PROGRESS;
      case 2:
        return SyncOutboxStatus.COMPLETED;
      case 3:
        return SyncOutboxStatus.FAILED;
    }

    throw ArgumentError.value(
      fromDb,
      'fromDb',
      'Unknown SyncOutboxStatus database value',
    );
  }

  @override
  int toSql(SyncOutboxStatus value) {
    switch (value) {
      case SyncOutboxStatus.PENDING:
        return 0;
      case SyncOutboxStatus.IN_PROGRESS:
        return 1;
      case SyncOutboxStatus.COMPLETED:
        return 2;
      case SyncOutboxStatus.FAILED:
        return 3;
    }
  }
}
