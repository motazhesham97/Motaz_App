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
    return ExpenseCategory.values[fromDb];
  }

  @override
  int toSql(ExpenseCategory value) {
    return value.index;
  }
}
