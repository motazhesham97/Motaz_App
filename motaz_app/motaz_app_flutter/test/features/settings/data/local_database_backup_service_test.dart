import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/features/settings/data/local_database_backup_service.dart';

void main() {
  group('LocalDatabaseBackupService', () {
    test('uses unrestricted picker on Android import', () {
      final options = LocalDatabaseBackupService.databaseImportPickerOptions(
        operatingSystem: 'android',
      );

      expect(options.type, FileType.any);
      expect(options.allowedExtensions, isNull);
    });

    test('keeps database extension filter on desktop import', () {
      final options = LocalDatabaseBackupService.databaseImportPickerOptions(
        operatingSystem: 'windows',
      );

      expect(options.type, FileType.custom);
      expect(options.allowedExtensions, const ['db', 'sqlite', 'backup']);
    });
  });
}
