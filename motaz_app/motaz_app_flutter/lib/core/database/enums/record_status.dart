// ignore_for_file: constant_identifier_names

import 'package:drift/drift.dart';

enum RecordStatus {
  ACTIVE,
  VOIDED,
}

class RecordStatusConverter extends TypeConverter<RecordStatus, int> {
  const RecordStatusConverter();

  @override
  RecordStatus fromSql(int fromDb) {
    if (fromDb >= 0 && fromDb < RecordStatus.values.length) {
      return RecordStatus.values[fromDb];
    }
    assert(false, 'Unknown RecordStatus database value: $fromDb');
    return RecordStatus.ACTIVE;
  }

  @override
  int toSql(RecordStatus value) {
    return value.index;
  }
}
