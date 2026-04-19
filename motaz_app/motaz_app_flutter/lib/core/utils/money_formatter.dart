String formatMoney(int minorUnits) {
  return '${(minorUnits / 100).toStringAsFixed(2)} ر.ي.';
}

String formatMoneyPlain(int minorUnits) {
  return (minorUnits / 100).toStringAsFixed(2);
}