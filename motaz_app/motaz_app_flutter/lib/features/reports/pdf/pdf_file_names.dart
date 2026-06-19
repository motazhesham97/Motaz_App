class PdfReportFileNames {
  const PdfReportFileNames._();

  static String dated(
    String section, {
    String? subject,
    DateTime? date,
  }) {
    final cleanSubject = subject?.trim();
    final subjectPart = cleanSubject == null || cleanSubject.isEmpty
        ? ''
        : ' ($cleanSubject)';
    return '$section$subjectPart ${_dateStamp(date ?? DateTime.now())}.pdf';
  }

  static String monthly(
    String section, {
    required int year,
    required int month,
    DateTime? date,
  }) {
    final monthStamp = '${month.toString().padLeft(2, '0')}-$year';
    return dated(section, subject: monthStamp, date: date);
  }

  static String _dateStamp(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  }
}
