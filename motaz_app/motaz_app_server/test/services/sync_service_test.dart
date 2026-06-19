import 'package:motaz_app_server/src/services/sync_service.dart';
import 'package:test/test.dart';

void main() {
  group('SyncService pure sync rules', () {
    test('supports only independently syncable entity types', () {
      expect(SyncService.supportsEntityType('CLIENT'), isTrue);
      expect(SyncService.supportsEntityType('PRODUCT'), isTrue);
      expect(SyncService.supportsEntityType('SALES_INVOICE'), isTrue);

      expect(SyncService.supportsEntityType('OWNER_ACCOUNT'), isFalse);
      expect(SyncService.supportsEntityType('UNKNOWN'), isFalse);
    });

    test('classifies changed fields while ignoring local sync metadata', () {
      final changedFields = SyncService.classifyChangedFields(
        'PRODUCT',
        {
          'id': 'product-1',
          'name': 'Chocolate',
          'defaultSalePrice': 800,
          'status': 0,
          'rowVersion': 12,
          'syncStatus': 'PENDING',
          'updatedAt': '2026-06-14T10:00:00.000Z',
        },
        {
          'id': 'product-1',
          'name': 'Chocolate',
          'defaultSalePrice': 750,
          'status': 'ACTIVE',
          'rowVersion': 9,
          'syncStatus': 'SYNCED',
          'updatedAt': DateTime.utc(2026, 6, 14, 10),
        },
      );

      expect(changedFields, {'defaultSalePrice'});
      expect(
        SyncService.hasConflictRequiredFieldChanges('PRODUCT', changedFields),
        isTrue,
      );
    });

    test('distinguishes auto-merge fields from conflict-required fields', () {
      final noteOnly = SyncService.classifyChangedFields(
        'SALES_INVOICE',
        {'note': 'new note', 'total': 1200},
        {'note': 'old note', 'total': 1200},
      );

      expect(noteOnly, {'note'});
      expect(
        SyncService.hasConflictRequiredFieldChanges('SALES_INVOICE', noteOnly),
        isFalse,
      );

      final totalChanged = SyncService.classifyChangedFields(
        'SALES_INVOICE',
        {'note': 'new note', 'total': 1400},
        {'note': 'old note', 'total': 1200},
      );

      expect(totalChanged, {'note', 'total'});
      expect(
        SyncService.hasConflictRequiredFieldChanges(
          'SALES_INVOICE',
          totalChanged,
        ),
        isTrue,
      );
    });

    test('applies void-wins rule for text and generated enum indexes', () {
      expect(SyncService.applyVoidWinsRule('VOIDED', 'ACTIVE'), isTrue);
      expect(SyncService.applyVoidWinsRule('ACTIVE', 'VOIDED'), isTrue);
      expect(SyncService.applyVoidWinsRule(1, 'ACTIVE'), isTrue);
      expect(SyncService.applyVoidWinsRule(0, 'ACTIVE'), isFalse);
      expect(SyncService.isVoidedStatus(1), isTrue);
    });

    test('returns the latest row version from pulled rows', () {
      final latest = SyncService.latestRowVersionFromRows(
        const [
          '{"id":"a","rowVersion":2}',
          '{"id":"b","rowVersion":5.0}',
          '{"id":"c","rowVersion":4}',
        ],
        1,
      );

      expect(latest, 5);
      expect(SyncService.latestRowVersionFromRows(const [], 9), 9);
    });
  });
}
