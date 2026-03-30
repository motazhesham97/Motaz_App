import 'package:test/test.dart';
import 'package:motaz_app_client/src/protocol/enums/audit_operation.dart';
import 'package:motaz_app_client/src/protocol/enums/conflict_status.dart';
import 'package:motaz_app_client/src/protocol/enums/device_platform.dart';
import 'package:motaz_app_client/src/protocol/enums/expense_category.dart';
import 'package:motaz_app_client/src/protocol/enums/parent_entity_type.dart';
import 'package:motaz_app_client/src/protocol/enums/receipt_type.dart';
import 'package:motaz_app_client/src/protocol/enums/record_status.dart';
import 'package:motaz_app_client/src/protocol/enums/sync_outbox_status.dart';
import 'package:motaz_app_client/src/protocol/enums/sync_status.dart';

void main() {
  group('AuditOperation', () {
    test('fromJson returns CREATE', () {
      expect(AuditOperation.fromJson('CREATE'), AuditOperation.CREATE);
    });

    test('fromJson returns UPDATE', () {
      expect(AuditOperation.fromJson('UPDATE'), AuditOperation.UPDATE);
    });

    test('fromJson returns VOID', () {
      expect(AuditOperation.fromJson('VOID'), AuditOperation.VOID);
    });

    test('fromJson throws ArgumentError for unknown value', () {
      expect(
        () => AuditOperation.fromJson('UNKNOWN'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('toJson returns enum name', () {
      expect(AuditOperation.CREATE.toJson(), 'CREATE');
      expect(AuditOperation.UPDATE.toJson(), 'UPDATE');
      expect(AuditOperation.VOID.toJson(), 'VOID');
    });

    test('toString returns enum name', () {
      expect(AuditOperation.CREATE.toString(), 'CREATE');
      expect(AuditOperation.UPDATE.toString(), 'UPDATE');
      expect(AuditOperation.VOID.toString(), 'VOID');
    });

    test('has exactly 3 values', () {
      expect(AuditOperation.values.length, 3);
    });

    test('fromJson throws ArgumentError for empty string', () {
      expect(
        () => AuditOperation.fromJson(''),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('ConflictStatus', () {
    test('fromJson returns PENDING', () {
      expect(ConflictStatus.fromJson('PENDING'), ConflictStatus.PENDING);
    });

    test('fromJson returns RESOLVED', () {
      expect(ConflictStatus.fromJson('RESOLVED'), ConflictStatus.RESOLVED);
    });

    test('fromJson throws ArgumentError for unknown value', () {
      expect(
        () => ConflictStatus.fromJson('UNKNOWN'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('toJson returns enum name', () {
      expect(ConflictStatus.PENDING.toJson(), 'PENDING');
      expect(ConflictStatus.RESOLVED.toJson(), 'RESOLVED');
    });

    test('toString returns enum name', () {
      expect(ConflictStatus.PENDING.toString(), 'PENDING');
      expect(ConflictStatus.RESOLVED.toString(), 'RESOLVED');
    });

    test('has exactly 2 values', () {
      expect(ConflictStatus.values.length, 2);
    });
  });

  group('DevicePlatform', () {
    test('fromJson returns ANDROID', () {
      expect(DevicePlatform.fromJson('ANDROID'), DevicePlatform.ANDROID);
    });

    test('fromJson returns WINDOWS', () {
      expect(DevicePlatform.fromJson('WINDOWS'), DevicePlatform.WINDOWS);
    });

    test('fromJson throws ArgumentError for unknown value', () {
      expect(
        () => DevicePlatform.fromJson('IOS'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('toJson returns enum name', () {
      expect(DevicePlatform.ANDROID.toJson(), 'ANDROID');
      expect(DevicePlatform.WINDOWS.toJson(), 'WINDOWS');
    });

    test('toString returns enum name', () {
      expect(DevicePlatform.ANDROID.toString(), 'ANDROID');
      expect(DevicePlatform.WINDOWS.toString(), 'WINDOWS');
    });

    test('has exactly 2 values', () {
      expect(DevicePlatform.values.length, 2);
    });
  });

  group('ExpenseCategory', () {
    test('fromJson returns OWNER_DRAW', () {
      expect(ExpenseCategory.fromJson('OWNER_DRAW'), ExpenseCategory.OWNER_DRAW);
    });

    test('fromJson returns PARTNER_DRAW', () {
      expect(
        ExpenseCategory.fromJson('PARTNER_DRAW'),
        ExpenseCategory.PARTNER_DRAW,
      );
    });

    test('fromJson returns MARGIN_DRAW', () {
      expect(
        ExpenseCategory.fromJson('MARGIN_DRAW'),
        ExpenseCategory.MARGIN_DRAW,
      );
    });

    test('fromJson returns OPERATIONAL', () {
      expect(
        ExpenseCategory.fromJson('OPERATIONAL'),
        ExpenseCategory.OPERATIONAL,
      );
    });

    test('fromJson returns PRODUCTION', () {
      expect(ExpenseCategory.fromJson('PRODUCTION'), ExpenseCategory.PRODUCTION);
    });

    test('fromJson throws ArgumentError for unknown value', () {
      expect(
        () => ExpenseCategory.fromJson('UNKNOWN'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('toJson returns enum name', () {
      expect(ExpenseCategory.OWNER_DRAW.toJson(), 'OWNER_DRAW');
      expect(ExpenseCategory.PARTNER_DRAW.toJson(), 'PARTNER_DRAW');
      expect(ExpenseCategory.MARGIN_DRAW.toJson(), 'MARGIN_DRAW');
      expect(ExpenseCategory.OPERATIONAL.toJson(), 'OPERATIONAL');
      expect(ExpenseCategory.PRODUCTION.toJson(), 'PRODUCTION');
    });

    test('toString returns enum name', () {
      expect(ExpenseCategory.OWNER_DRAW.toString(), 'OWNER_DRAW');
      expect(ExpenseCategory.PRODUCTION.toString(), 'PRODUCTION');
    });

    test('has exactly 5 values', () {
      expect(ExpenseCategory.values.length, 5);
    });
  });

  group('ParentEntityType', () {
    test('fromJson returns all values correctly', () {
      expect(
        ParentEntityType.fromJson('SALES_INVOICE'),
        ParentEntityType.SALES_INVOICE,
      );
      expect(ParentEntityType.fromJson('RECEIPT'), ParentEntityType.RECEIPT);
      expect(ParentEntityType.fromJson('PRODUCT'), ParentEntityType.PRODUCT);
      expect(ParentEntityType.fromJson('CLIENT'), ParentEntityType.CLIENT);
      expect(ParentEntityType.fromJson('EXPENSE'), ParentEntityType.EXPENSE);
      expect(
        ParentEntityType.fromJson('SALES_RETURN'),
        ParentEntityType.SALES_RETURN,
      );
    });

    test('fromJson throws ArgumentError for unknown value', () {
      expect(
        () => ParentEntityType.fromJson('INVOICE'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('toJson returns enum name', () {
      expect(ParentEntityType.SALES_INVOICE.toJson(), 'SALES_INVOICE');
      expect(ParentEntityType.RECEIPT.toJson(), 'RECEIPT');
      expect(ParentEntityType.PRODUCT.toJson(), 'PRODUCT');
      expect(ParentEntityType.CLIENT.toJson(), 'CLIENT');
      expect(ParentEntityType.EXPENSE.toJson(), 'EXPENSE');
      expect(ParentEntityType.SALES_RETURN.toJson(), 'SALES_RETURN');
    });

    test('toString returns enum name', () {
      expect(ParentEntityType.SALES_INVOICE.toString(), 'SALES_INVOICE');
      expect(ParentEntityType.CLIENT.toString(), 'CLIENT');
    });

    test('has exactly 6 values', () {
      expect(ParentEntityType.values.length, 6);
    });

    test('fromJson is case-sensitive — lowercase throws', () {
      expect(
        () => ParentEntityType.fromJson('sales_invoice'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('ReceiptType', () {
    test('fromJson returns INVOICE_LINKED', () {
      expect(
        ReceiptType.fromJson('INVOICE_LINKED'),
        ReceiptType.INVOICE_LINKED,
      );
    });

    test('fromJson returns GENERAL', () {
      expect(ReceiptType.fromJson('GENERAL'), ReceiptType.GENERAL);
    });

    test('fromJson throws ArgumentError for unknown value', () {
      expect(
        () => ReceiptType.fromJson('CASH'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('toJson returns enum name', () {
      expect(ReceiptType.INVOICE_LINKED.toJson(), 'INVOICE_LINKED');
      expect(ReceiptType.GENERAL.toJson(), 'GENERAL');
    });

    test('toString returns enum name', () {
      expect(ReceiptType.INVOICE_LINKED.toString(), 'INVOICE_LINKED');
      expect(ReceiptType.GENERAL.toString(), 'GENERAL');
    });

    test('has exactly 2 values', () {
      expect(ReceiptType.values.length, 2);
    });
  });

  group('RecordStatus', () {
    test('fromJson returns ACTIVE', () {
      expect(RecordStatus.fromJson('ACTIVE'), RecordStatus.ACTIVE);
    });

    test('fromJson returns VOIDED', () {
      expect(RecordStatus.fromJson('VOIDED'), RecordStatus.VOIDED);
    });

    test('fromJson throws ArgumentError for unknown value', () {
      expect(
        () => RecordStatus.fromJson('DELETED'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('toJson returns enum name', () {
      expect(RecordStatus.ACTIVE.toJson(), 'ACTIVE');
      expect(RecordStatus.VOIDED.toJson(), 'VOIDED');
    });

    test('toString returns enum name', () {
      expect(RecordStatus.ACTIVE.toString(), 'ACTIVE');
      expect(RecordStatus.VOIDED.toString(), 'VOIDED');
    });

    test('has exactly 2 values', () {
      expect(RecordStatus.values.length, 2);
    });
  });

  group('SyncOutboxStatus', () {
    test('fromJson returns PENDING', () {
      expect(SyncOutboxStatus.fromJson('PENDING'), SyncOutboxStatus.PENDING);
    });

    test('fromJson returns IN_PROGRESS', () {
      expect(
        SyncOutboxStatus.fromJson('IN_PROGRESS'),
        SyncOutboxStatus.IN_PROGRESS,
      );
    });

    test('fromJson returns COMPLETED', () {
      expect(SyncOutboxStatus.fromJson('COMPLETED'), SyncOutboxStatus.COMPLETED);
    });

    test('fromJson returns FAILED', () {
      expect(SyncOutboxStatus.fromJson('FAILED'), SyncOutboxStatus.FAILED);
    });

    test('fromJson throws ArgumentError for unknown value', () {
      expect(
        () => SyncOutboxStatus.fromJson('CANCELLED'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('toJson returns enum name', () {
      expect(SyncOutboxStatus.PENDING.toJson(), 'PENDING');
      expect(SyncOutboxStatus.IN_PROGRESS.toJson(), 'IN_PROGRESS');
      expect(SyncOutboxStatus.COMPLETED.toJson(), 'COMPLETED');
      expect(SyncOutboxStatus.FAILED.toJson(), 'FAILED');
    });

    test('toString returns enum name', () {
      expect(SyncOutboxStatus.PENDING.toString(), 'PENDING');
      expect(SyncOutboxStatus.IN_PROGRESS.toString(), 'IN_PROGRESS');
    });

    test('has exactly 4 values', () {
      expect(SyncOutboxStatus.values.length, 4);
    });
  });

  group('SyncStatus', () {
    test('fromJson returns PENDING', () {
      expect(SyncStatus.fromJson('PENDING'), SyncStatus.PENDING);
    });

    test('fromJson returns SYNCED', () {
      expect(SyncStatus.fromJson('SYNCED'), SyncStatus.SYNCED);
    });

    test('fromJson returns CONFLICT', () {
      expect(SyncStatus.fromJson('CONFLICT'), SyncStatus.CONFLICT);
    });

    test('fromJson returns FAILED', () {
      expect(SyncStatus.fromJson('FAILED'), SyncStatus.FAILED);
    });

    test('fromJson throws ArgumentError for unknown value', () {
      expect(
        () => SyncStatus.fromJson('SYNCING'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('toJson returns enum name', () {
      expect(SyncStatus.PENDING.toJson(), 'PENDING');
      expect(SyncStatus.SYNCED.toJson(), 'SYNCED');
      expect(SyncStatus.CONFLICT.toJson(), 'CONFLICT');
      expect(SyncStatus.FAILED.toJson(), 'FAILED');
    });

    test('toString returns enum name', () {
      expect(SyncStatus.PENDING.toString(), 'PENDING');
      expect(SyncStatus.SYNCED.toString(), 'SYNCED');
    });

    test('has exactly 4 values', () {
      expect(SyncStatus.values.length, 4);
    });

    test('toJson/fromJson round-trip for all values', () {
      for (final value in SyncStatus.values) {
        expect(SyncStatus.fromJson(value.toJson()), value);
      }
    });
  });
}