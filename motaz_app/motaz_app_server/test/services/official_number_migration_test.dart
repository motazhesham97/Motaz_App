import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('Railway image copies and applies registered migrations', () {
    final railway = File('../railway.toml').readAsStringSync();
    final dockerfile = File('Dockerfile').readAsStringSync();
    final registry = File('migrations/migration_registry.txt').readAsStringSync();

    expect(
      railway,
      contains('dockerfilePath = "motaz_app_server/Dockerfile"'),
    );
    expect(
      dockerfile,
      contains('COPY --from=build /app/motaz_app_server/migrations/ ./migrations/'),
    );
    expect(dockerfile, contains('CMD ["--apply-migrations"]'));
    expect(registry, contains('20261011151030753-sync-cursor-indexes'));
  });

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
