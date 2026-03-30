// ignore_for_file: constant_identifier_names

import 'package:drift/drift.dart';

enum ParentEntityType {
  SALES_INVOICE,
  RECEIPT,
  PRODUCT,
  CLIENT,
  EXPENSE,
  SALES_RETURN,
}

class ParentEntityTypeConverter extends TypeConverter<ParentEntityType, int> {
  const ParentEntityTypeConverter();

  @override
  ParentEntityType fromSql(int fromDb) {
    return ParentEntityType.values[fromDb];
  }

  @override
  int toSql(ParentEntityType value) {
    return value.index;
  }
}
