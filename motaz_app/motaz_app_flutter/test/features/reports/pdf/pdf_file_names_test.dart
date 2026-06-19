import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/features/reports/pdf/pdf_file_names.dart';

void main() {
  group('PdfReportFileNames', () {
    test('builds dated client statement file name', () {
      final fileName = PdfReportFileNames.dated(
        'كشف حساب',
        subject: 'ظمران سنتر',
        date: DateTime(2026, 6, 20),
      );

      expect(fileName, 'كشف حساب (ظمران سنتر) 20-06-2026.pdf');
    });

    test('builds monthly report file name', () {
      final fileName = PdfReportFileNames.monthly(
        'التقرير الشهري النهائي',
        year: 2026,
        month: 6,
        date: DateTime(2026, 6, 20),
      );

      expect(fileName, 'التقرير الشهري النهائي (06-2026) 20-06-2026.pdf');
    });
  });
}
