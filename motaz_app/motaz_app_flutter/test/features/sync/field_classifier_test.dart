import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/features/sync/domain/field_classifier.dart';

void main() {
  group('FieldClassifier', () {
    test('getConflictRequiredFields for PRODUCT includes pricing fields', () {
      final fields = FieldClassifier.getConflictRequiredFields('PRODUCT');
      expect(
        fields,
        containsAll(['name', 'defaultSalePrice', 'shelfLifeDays']),
      );
      expect(fields, isNot(contains('costPrice')));
    });

    test('getConflictRequiredFields for CLIENT returns empty', () {
      final fields = FieldClassifier.getConflictRequiredFields('CLIENT');
      expect(fields, isEmpty);
    });

    test('hasConflictRequiredFieldChanges detects sale price change', () {
      expect(
        FieldClassifier.hasConflictRequiredFieldChanges(
          'PRODUCT',
          {'defaultSalePrice'},
        ),
        isTrue,
      );
    });

    test('hasConflictRequiredFieldChanges ignores auto-merge fields', () {
      expect(
        FieldClassifier.hasConflictRequiredFieldChanges(
          'PRODUCT',
          {'description', 'unit', 'sku'},
        ),
        isFalse,
      );
    });

    test('hasOnlyAutoMergeFieldChanges returns true for auto-merge only', () {
      expect(
        FieldClassifier.hasOnlyAutoMergeFieldChanges(
          'PRODUCT',
          {'description', 'isActive', 'unit', 'sku'},
        ),
        isTrue,
      );
    });

    test('hasOnlyAutoMergeFieldChanges returns false for conflict field', () {
      expect(
        FieldClassifier.hasOnlyAutoMergeFieldChanges(
          'PRODUCT',
          {'name'},
        ),
        isFalse,
      );
    });

    test('PRODUCT autoMergeFields includes unit and sku', () {
      expect(
        FieldClassifier.autoMergeFields['PRODUCT'],
        containsAll(['description', 'isActive', 'unit', 'sku']),
      );
    });

    test('CLIENT autoMergeFields includes email and address', () {
      expect(
        FieldClassifier.autoMergeFields['CLIENT'],
        containsAll([
          'displayName',
          'phone',
          'note',
          'clientCode',
          'email',
          'address',
        ]),
      );
    });
  });
}
