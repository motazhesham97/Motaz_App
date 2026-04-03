// ignore_for_file: constant_identifier_names

import 'package:drift/drift.dart';

enum ExpenseCategory {
  OWNER_DRAW,
  PARTNER_DRAW,
  MARGIN_DRAW,
  OPERATIONAL,
  PRODUCTION,
}

class ExpenseCategoryConverter extends TypeConverter<ExpenseCategory, int> {
  const ExpenseCategoryConverter();

  @override
  ExpenseCategory fromSql(int fromDb) {
    if (fromDb >= 0 && fromDb < ExpenseCategory.values.length) {
      return ExpenseCategory.values[fromDb];
    }
    assert(false, 'Unknown ExpenseCategory database value: $fromDb');
    return ExpenseCategory.OPERATIONAL;
  }

  @override
  int toSql(ExpenseCategory value) {
    return value.index;
  }
}
