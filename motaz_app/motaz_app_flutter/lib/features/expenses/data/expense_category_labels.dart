import '../../../core/database/enums/expense_category.dart';

String expenseCategoryLabel(ExpenseCategory category) {
  return switch (category) {
    ExpenseCategory.OPERATIONAL => 'تشغيلي',
    ExpenseCategory.PRODUCTION => 'إنتاجي',
    ExpenseCategory.OWNER_DRAW => 'امي',
    ExpenseCategory.PARTNER_DRAW => 'معتز',
    ExpenseCategory.MARGIN_DRAW => 'الهامش',
  };
}
