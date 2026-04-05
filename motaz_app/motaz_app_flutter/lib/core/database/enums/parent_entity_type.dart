// ignore_for_file: constant_identifier_names

import 'package:drift/drift.dart';

enum ParentEntityType {
  SALES_INVOICE,
  SALES_INVOICE_LINE,
  RECEIPT,
  RECEIPT_ALLOCATION,
  PRODUCT,
  CLIENT,
  EXPENSE,
  SALES_RETURN,
  SALES_RETURN_LINE,
  ATTACHMENT_METADATA,
}

class ParentEntityTypeConverter extends TypeConverter<ParentEntityType, int> {
  const ParentEntityTypeConverter();

  @override
  ParentEntityType fromSql(int fromDb) {
    if (fromDb >= 0 && fromDb < ParentEntityType.values.length) {
      return ParentEntityType.values[fromDb];
    }
    assert(false, 'Unknown ParentEntityType database value: $fromDb');
    return ParentEntityType.PRODUCT;
  }

  @override
  int toSql(ParentEntityType value) {
    return value.index;
  }
}
