String formatMoney(int minorUnits) {
  final sign = minorUnits < 0 ? '-' : '';
  final amount = (minorUnits.abs() / 100).toStringAsFixed(2);
  return '$sign$amount ر.ي.';
}

String formatMoneyPlain(int minorUnits) {
  final sign = minorUnits < 0 ? '-' : '';
  return '$sign${(minorUnits.abs() / 100).toStringAsFixed(2)}';
}
