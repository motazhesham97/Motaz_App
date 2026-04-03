// ignore_for_file: constant_identifier_names

import 'package:drift/drift.dart';

enum AuditOperation {
  CREATE,
  UPDATE,
  VOID,
}

class AuditOperationConverter extends TypeConverter<AuditOperation, int> {
  const AuditOperationConverter();

  @override
  AuditOperation fromSql(int fromDb) {
    if (fromDb >= 0 && fromDb < AuditOperation.values.length) {
      return AuditOperation.values[fromDb];
    }
    assert(false, 'Unknown AuditOperation database value: $fromDb');
    return AuditOperation.CREATE;
  }

  @override
  int toSql(AuditOperation value) {
    return value.index;
  }
}
