String _documentNumber(String localRef, {String? officialNo}) {
  final official = officialNo?.trim();
  if (official != null && official.isNotEmpty) {
    return official;
  }

  final local = localRef.trim();
  if (RegExp(r'^\d+$').hasMatch(local)) {
    return local;
  }

  final parts = localRef.split('-');
  if (parts.length >= 3 && parts[1].toUpperCase() == 'LEG') {
    return '\u0642\u062f\u064a\u0645';
  }

  return '\u0642\u064a\u062f \u0627\u0644\u062a\u0631\u0642\u064a\u0645';
}

String invoiceDisplayRef(String localRef, {String? officialNo}) {
  return '\u0627\u0644\u0641\u0627\u062a\u0648\u0631\u0629 \u0631\u0642\u0645 ${_documentNumber(localRef, officialNo: officialNo)}';
}

String receiptDisplayRef(String localRef, {String? officialNo}) {
  return '\u0633\u0646\u062f \u0642\u0628\u0636 \u0631\u0642\u0645 ${_documentNumber(localRef, officialNo: officialNo)}';
}

String returnDisplayRef(String localRef, {String? officialNo}) {
  return '\u0645\u0631\u062a\u062c\u0639 \u0631\u0642\u0645 ${_documentNumber(localRef, officialNo: officialNo)}';
}

String freeSampleDisplayRef(String localRef, {String? officialNo}) {
  return '\u0639\u064a\u0646\u0629 \u0631\u0642\u0645 ${_documentNumber(localRef, officialNo: officialNo)}';
}
