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
    return ReceiptType.values[fromDb];
  }

  @override
  int toSql(ReceiptType value) {
    return value.index;
  }
}
