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
    return ConflictStatus.values[fromDb];
  }

  @override
  int toSql(ConflictStatus value) {
    return value.index;
  }
}
