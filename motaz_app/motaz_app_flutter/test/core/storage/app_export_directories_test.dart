import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/core/storage/app_export_directories.dart';

void main() {
  group('AppExportDirectories', () {
    test(
      'sanitizeFileName keeps Arabic text and removes invalid separators',
      () {
        final fileName = AppExportDirectories.sanitizeFileName(
          'كشف/حساب:عميل*؟.pdf',
        );

        expect(fileName, 'كشف_حساب_عميل_؟.pdf');
      },
    );

    test('sanitizeFileName falls back when name is empty', () {
      final fileName = AppExportDirectories.sanitizeFileName(
        ' <>:"/\\|?* ',
        fallback: 'report.pdf',
      );

      expect(fileName, 'report.pdf');
    });
  });
}
