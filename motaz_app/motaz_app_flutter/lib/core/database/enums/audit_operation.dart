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
    return AuditOperation.values[fromDb];
  }

  @override
  int toSql(AuditOperation value) {
    return value.index;
  }
}
