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
    return RecordStatus.values[fromDb];
  }

  @override
  int toSql(RecordStatus value) {
    return value.index;
  }
}
