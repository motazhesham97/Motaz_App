// ignore_for_file: constant_identifier_names

import 'package:drift/drift.dart';

enum ConflictStatus {
  PENDING,
  RESOLVED,
}

class ConflictStatusConverter extends TypeConverter<ConflictStatus, int> {
  const ConflictStatusConverter();

  @override
  ConflictStatus fromSql(int fromDb) {
    if (fromDb >= 0 && fromDb < ConflictStatus.values.length) {
      return ConflictStatus.values[fromDb];
    }
    assert(false, 'Unknown ConflictStatus database value: $fromDb');
    return ConflictStatus.PENDING;
  }

  @override
  int toSql(ConflictStatus value) {
    return value.index;
  }
}
