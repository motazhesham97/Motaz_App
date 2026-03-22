import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/core/database/app_database.dart';
import 'package:motaz_app_flutter/core/database/database_provider.dart';

void main() {
  group('appDatabaseProvider', () {
    test('provides an AppDatabase instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final db = container.read(appDatabaseProvider);
      expect(db, isA<AppDatabase>());
    });

    test('returns the same instance on repeated reads (singleton)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final db1 = container.read(appDatabaseProvider);
      final db2 = container.read(appDatabaseProvider);

      // Riverpod Provider caches the instance — both reads return identical object
      expect(identical(db1, db2), isTrue);
    });

    test('two separate containers produce separate instances', () {
      final container1 = ProviderContainer();
      final container2 = ProviderContainer();
      addTearDown(container1.dispose);
      addTearDown(container2.dispose);

      final db1 = container1.read(appDatabaseProvider);
      final db2 = container2.read(appDatabaseProvider);

      // Different containers maintain independent state
      expect(identical(db1, db2), isFalse);
    });

    test('AppDatabase has schemaVersion 1', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final db = container.read(appDatabaseProvider);
      expect(db.schemaVersion, equals(1));
    });

    test('provider is a non-autoDispose Provider (not AsyncProvider)', () {
      // Ensure the provider type is correct — synchronous, non-async
      expect(appDatabaseProvider, isA<Provider<AppDatabase>>());
    });
  });
}