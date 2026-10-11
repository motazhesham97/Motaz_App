import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('official number sequences start after existing document numbers', () {
    final migration = File(
      'migrations/20261011151030753-sync-cursor-indexes/migration.sql',
    ).readAsStringSync();

    for (final table in [
      'sales_invoice',
      'receipt',
      'sales_return',
      'free_sample',
    ]) {
      final sequence = '${table}_official_no_seq';
      expect(migration, contains('CREATE SEQUENCE "$sequence";'));
      expect(migration, contains("SELECT setval('$sequence',"));
      expect(
        migration,
        contains('MAX("officialNo"::bigint) + 1 FROM "$table"'),
      );
    }
  });
}
