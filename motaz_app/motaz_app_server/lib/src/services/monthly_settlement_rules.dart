class MonthlySettlementRules {
  static const financialFields = {
    'year',
    'month',
    'netSales',
    'operationalExpenses',
    'productionExpenses',
    'profitBeforeCarry',
    'currentMonthLoss',
    'carriedLossIn',
    'carriedLossOut',
    'netProfit',
    'ownerShare',
    'partnerShare',
    'marginShare',
    'status',
    'voidReason',
  };

  static bool sameFinancials(Map<String, dynamic> a, Map<String, dynamic> b) =>
      financialFields.every((key) => a[key] == b[key]);

  static void validate(Map<String, dynamic> payload, {DateTime? now}) {
    int number(String key) => switch (payload[key]) {
      int value => value,
      _ => throw FormatException('Missing integer settlement field: $key'),
    };
    final year = number('year');
    final month = number('month');
    final today = now ?? DateTime.now().toUtc().add(const Duration(hours: 3));
    if (year < 1 ||
        year > 9999 ||
        month < 1 ||
        month > 12 ||
        !DateTime(year, month).isBefore(DateTime(today.year, today.month))) {
      throw const FormatException(
        'Only completed calendar months may be settled',
      );
    }
    final sales = number('netSales');
    final operating = number('operationalExpenses');
    final production = number('productionExpenses');
    final incoming = number('carriedLossIn');
    if (operating < 0 || production < 0 || incoming > 0) {
      throw const FormatException('Invalid expense or signed loss');
    }
    final before = sales - operating - production;
    final net = before + incoming;
    final amount = net > 0 ? net : 0;
    final share = (amount ~/ 3 ~/ 1000) * 1000;
    final expected = {
      'profitBeforeCarry': before,
      'currentMonthLoss': before < 0 ? before : 0,
      'netProfit': net,
      'carriedLossOut': net < 0 ? net : 0,
      'ownerShare': share,
      'partnerShare': share,
      'marginShare': amount - share * 2,
    };
    for (final entry in expected.entries) {
      if (number(entry.key) != entry.value) {
        throw FormatException('Inconsistent settlement field: ${entry.key}');
      }
    }
  }
}
