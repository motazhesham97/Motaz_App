// ignore_for_file: constant_identifier_names

import 'package:drift/drift.dart';

enum ReceiptType {
  INVOICE_LINKED,
  GENERAL,
}

class ReceiptTypeConverter extends TypeConverter<ReceiptType, int> {
  const ReceiptTypeConverter();

  @override
  ReceiptType fromSql(int fromDb) {
    if (fromDb >= 0 && fromDb < ReceiptType.values.length) {
      return ReceiptType.values[fromDb];
    }
    assert(false, 'Unknown ReceiptType database value: $fromDb');
    return ReceiptType.GENERAL;
  }

  @override
  int toSql(ReceiptType value) {
    return value.index;
  }
}
