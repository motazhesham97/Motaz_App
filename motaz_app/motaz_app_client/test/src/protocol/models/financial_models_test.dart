import 'package:test/test.dart';
import 'package:serverpod_client/serverpod_client.dart';
import 'package:motaz_app_client/src/protocol/expense.dart';
import 'package:motaz_app_client/src/protocol/receipt.dart';
import 'package:motaz_app_client/src/protocol/receipt_allocation.dart';
import 'package:motaz_app_client/src/protocol/sales_invoice.dart';
import 'package:motaz_app_client/src/protocol/sales_invoice_line.dart';
import 'package:motaz_app_client/src/protocol/enums/expense_category.dart';
import 'package:motaz_app_client/src/protocol/enums/record_status.dart';
import 'package:motaz_app_client/src/protocol/enums/sync_status.dart';
import 'package:motaz_app_client/src/protocol/enums/receipt_type.dart';

UuidValue _uuid(String s) => UuidValue.withoutValidation(s);

const _deviceId = '00000000-0000-0000-0000-000000000001';
const _clientId = '00000000-0000-0000-0000-000000000002';
const _invoiceId = '00000000-0000-0000-0000-000000000003';
const _receiptId = '00000000-0000-0000-0000-000000000004';
const _productId = '00000000-0000-0000-0000-000000000005';
const _entityId = '00000000-0000-0000-0000-000000000099';

final _now = DateTime.utc(2024, 6, 15, 12, 0, 0);
final _later = DateTime.utc(2024, 6, 15, 13, 0, 0);

void main() {
  group('Expense', () {
    Expense _makeExpense({
      String? id,
      ExpenseCategory category = ExpenseCategory.OPERATIONAL,
      int amount = 500,
      String? note,
      RecordStatus? status,
      String? voidReason,
      int? rowVersion,
      SyncStatus? syncStatus,
    }) {
      return Expense(
        id: id != null ? _uuid(id) : null,
        category: category,
        amount: amount,
        expenseDate: _now,
        note: note,
        status: status,
        voidReason: voidReason,
        createdAt: _now,
        updatedAt: _later,
        deviceId: _uuid(_deviceId),
        rowVersion: rowVersion,
        syncStatus: syncStatus,
      );
    }

    group('construction', () {
      test('creates expense with required fields', () {
        final expense = _makeExpense(category: ExpenseCategory.PRODUCTION, amount: 1000);
        expect(expense.category, ExpenseCategory.PRODUCTION);
        expect(expense.amount, 1000);
        expect(expense.note, isNull);
        expect(expense.voidReason, isNull);
        expect(expense.id, isNull);
      });

      test('status defaults to ACTIVE', () {
        expect(_makeExpense().status, RecordStatus.ACTIVE);
      });

      test('rowVersion defaults to 1', () {
        expect(_makeExpense().rowVersion, 1);
      });

      test('syncStatus defaults to PENDING', () {
        expect(_makeExpense().syncStatus, SyncStatus.PENDING);
      });
    });

    group('toJson', () {
      test('includes __className__ = Expense', () {
        expect(_makeExpense().toJson()['__className__'], 'Expense');
      });

      test('omits optional null fields', () {
        final json = _makeExpense().toJson();
        expect(json.containsKey('id'), isFalse);
        expect(json.containsKey('note'), isFalse);
        expect(json.containsKey('voidReason'), isFalse);
        expect(json.containsKey('device'), isFalse);
      });

      test('includes required fields', () {
        final json = _makeExpense(amount: 999).toJson();
        expect(json['amount'], 999);
        expect(json['category'], 'OPERATIONAL');
        expect(json['status'], 'ACTIVE');
        expect(json['rowVersion'], 1);
        expect(json['syncStatus'], 'PENDING');
      });

      test('includes note and voidReason when set', () {
        final json = _makeExpense(
          note: 'lunch',
          voidReason: 'mistake',
          status: RecordStatus.VOIDED,
        ).toJson();
        expect(json['note'], 'lunch');
        expect(json['voidReason'], 'mistake');
        expect(json['status'], 'VOIDED');
      });
    });

    group('fromJson', () {
      test('round-trip preserves all fields', () {
        final original = _makeExpense(
          id: _entityId,
          category: ExpenseCategory.OWNER_DRAW,
          amount: 2500,
          note: 'owner draw',
          status: RecordStatus.VOIDED,
          voidReason: 'reversed',
          rowVersion: 3,
          syncStatus: SyncStatus.SYNCED,
        );
        final restored = Expense.fromJson(original.toJson());
        expect(restored.category, ExpenseCategory.OWNER_DRAW);
        expect(restored.amount, 2500);
        expect(restored.note, 'owner draw');
        expect(restored.status, RecordStatus.VOIDED);
        expect(restored.voidReason, 'reversed');
        expect(restored.rowVersion, 3);
        expect(restored.syncStatus, SyncStatus.SYNCED);
        expect(restored.id, original.id);
      });

      test('applies defaults when optional fields absent in JSON', () {
        final expense = Expense.fromJson({
          'category': 'OPERATIONAL',
          'amount': 100,
          'expenseDate': _now.toIso8601String(),
          'createdAt': _now.toIso8601String(),
          'updatedAt': _later.toIso8601String(),
          'deviceId': _deviceId,
          'rowVersion': 1,
        });
        expect(expense.status, RecordStatus.ACTIVE);
        expect(expense.syncStatus, SyncStatus.PENDING);
        expect(expense.note, isNull);
      });
    });

    group('copyWith', () {
      test('updates amount', () {
        final original = _makeExpense(amount: 100);
        final copy = original.copyWith(amount: 200);
        expect(copy.amount, 200);
        expect(copy.category, original.category);
      });

      test('updates category', () {
        final original = _makeExpense(category: ExpenseCategory.OPERATIONAL);
        final copy = original.copyWith(category: ExpenseCategory.PRODUCTION);
        expect(copy.category, ExpenseCategory.PRODUCTION);
      });

      test('can set note to null', () {
        final original = _makeExpense(note: 'note');
        final copy = original.copyWith(note: null);
        expect(copy.note, isNull);
      });

      test('updates status to VOIDED with voidReason', () {
        final original = _makeExpense();
        final copy = original.copyWith(
          status: RecordStatus.VOIDED,
          voidReason: 'error',
        );
        expect(copy.status, RecordStatus.VOIDED);
        expect(copy.voidReason, 'error');
      });

      test('preserves all fields when no arguments given', () {
        final original = _makeExpense(amount: 750, rowVersion: 2);
        final copy = original.copyWith();
        expect(copy.amount, 750);
        expect(copy.rowVersion, 2);
      });

      test('all expense categories can be used in copyWith', () {
        final original = _makeExpense();
        for (final cat in ExpenseCategory.values) {
          final copy = original.copyWith(category: cat);
          expect(copy.category, cat);
        }
      });
    });
  });

  group('SalesInvoice', () {
    SalesInvoice _makeInvoice({
      String? id,
      String localRef = 'INV-001',
      String? officialNo,
      String clientId = _clientId,
      int? discount,
      int total = 5000,
      String? note,
      RecordStatus? status,
      String? voidReason,
      int? rowVersion,
      SyncStatus? syncStatus,
    }) {
      return SalesInvoice(
        id: id != null ? _uuid(id) : null,
        localRef: localRef,
        officialNo: officialNo,
        clientId: _uuid(clientId),
        invoiceDate: _now,
        discount: discount,
        total: total,
        note: note,
        status: status,
        voidReason: voidReason,
        createdAt: _now,
        updatedAt: _later,
        deviceId: _uuid(_deviceId),
        rowVersion: rowVersion,
        syncStatus: syncStatus,
      );
    }

    group('construction', () {
      test('creates invoice with required fields', () {
        final inv = _makeInvoice(localRef: 'INV-100', total: 10000);
        expect(inv.localRef, 'INV-100');
        expect(inv.total, 10000);
        expect(inv.officialNo, isNull);
        expect(inv.note, isNull);
        expect(inv.client, isNull);
      });

      test('discount defaults to 0', () {
        expect(_makeInvoice().discount, 0);
      });

      test('status defaults to ACTIVE', () {
        expect(_makeInvoice().status, RecordStatus.ACTIVE);
      });

      test('rowVersion defaults to 1', () {
        expect(_makeInvoice().rowVersion, 1);
      });

      test('syncStatus defaults to PENDING', () {
        expect(_makeInvoice().syncStatus, SyncStatus.PENDING);
      });

      test('explicit discount is set', () {
        expect(_makeInvoice(discount: 100).discount, 100);
      });
    });

    group('toJson', () {
      test('includes __className__ = SalesInvoice', () {
        expect(_makeInvoice().toJson()['__className__'], 'SalesInvoice');
      });

      test('omits optional null fields', () {
        final json = _makeInvoice().toJson();
        expect(json.containsKey('id'), isFalse);
        expect(json.containsKey('officialNo'), isFalse);
        expect(json.containsKey('note'), isFalse);
        expect(json.containsKey('voidReason'), isFalse);
        expect(json.containsKey('client'), isFalse);
        expect(json.containsKey('device'), isFalse);
      });

      test('includes discount, total, status, rowVersion', () {
        final json = _makeInvoice(discount: 50, total: 2000).toJson();
        expect(json['discount'], 50);
        expect(json['total'], 2000);
        expect(json['status'], 'ACTIVE');
        expect(json['rowVersion'], 1);
        expect(json['localRef'], 'INV-001');
      });

      test('includes officialNo when set', () {
        final json = _makeInvoice(officialNo: 'OFF-001').toJson();
        expect(json['officialNo'], 'OFF-001');
      });
    });

    group('fromJson', () {
      test('round-trip preserves all fields', () {
        final original = _makeInvoice(
          id: _entityId,
          localRef: 'INV-999',
          officialNo: 'OFF-999',
          discount: 200,
          total: 9800,
          note: 'bulk order',
          status: RecordStatus.VOIDED,
          voidReason: 'cancelled',
          rowVersion: 4,
          syncStatus: SyncStatus.FAILED,
        );
        final restored = SalesInvoice.fromJson(original.toJson());
        expect(restored.localRef, 'INV-999');
        expect(restored.officialNo, 'OFF-999');
        expect(restored.discount, 200);
        expect(restored.total, 9800);
        expect(restored.note, 'bulk order');
        expect(restored.status, RecordStatus.VOIDED);
        expect(restored.voidReason, 'cancelled');
        expect(restored.rowVersion, 4);
        expect(restored.syncStatus, SyncStatus.FAILED);
      });

      test('discount defaults to 0 when null in JSON', () {
        final invoice = SalesInvoice.fromJson({
          'localRef': 'INV-001',
          'clientId': _clientId,
          'invoiceDate': _now.toIso8601String(),
          'total': 500,
          'createdAt': _now.toIso8601String(),
          'updatedAt': _later.toIso8601String(),
          'deviceId': _deviceId,
          'rowVersion': 1,
        });
        expect(invoice.discount, 0);
        expect(invoice.status, RecordStatus.ACTIVE);
      });
    });

    group('copyWith', () {
      test('updates localRef', () {
        final original = _makeInvoice(localRef: 'OLD');
        final copy = original.copyWith(localRef: 'NEW');
        expect(copy.localRef, 'NEW');
      });

      test('updates discount and total', () {
        final original = _makeInvoice(discount: 0, total: 1000);
        final copy = original.copyWith(discount: 100, total: 900);
        expect(copy.discount, 100);
        expect(copy.total, 900);
      });

      test('can set officialNo to null', () {
        final original = _makeInvoice(officialNo: 'OFF-1');
        final copy = original.copyWith(officialNo: null);
        expect(copy.officialNo, isNull);
      });

      test('updates status and adds voidReason', () {
        final original = _makeInvoice();
        final copy = original.copyWith(
          status: RecordStatus.VOIDED,
          voidReason: 'cancelled by client',
        );
        expect(copy.status, RecordStatus.VOIDED);
        expect(copy.voidReason, 'cancelled by client');
      });

      test('preserves all unspecified fields', () {
        final original = _makeInvoice(localRef: 'INV-X', total: 7777, rowVersion: 3);
        final copy = original.copyWith(syncStatus: SyncStatus.SYNCED);
        expect(copy.localRef, 'INV-X');
        expect(copy.total, 7777);
        expect(copy.rowVersion, 3);
        expect(copy.syncStatus, SyncStatus.SYNCED);
      });
    });
  });

  group('SalesInvoiceLine', () {
    SalesInvoiceLine _makeLine({
      String? id,
      String invoiceId = _invoiceId,
      String productId = _productId,
      int quantity = 2,
      int unitPrice = 1000,
      int lineTotal = 2000,
    }) {
      return SalesInvoiceLine(
        id: id != null ? _uuid(id) : null,
        invoiceId: _uuid(invoiceId),
        productId: _uuid(productId),
        quantity: quantity,
        unitPrice: unitPrice,
        lineTotal: lineTotal,
        createdAt: _now,
        updatedAt: _later,
      );
    }

    group('construction', () {
      test('creates line with required fields', () {
        final line = _makeLine(quantity: 3, unitPrice: 500, lineTotal: 1500);
        expect(line.quantity, 3);
        expect(line.unitPrice, 500);
        expect(line.lineTotal, 1500);
        expect(line.id, isNull);
        expect(line.invoice, isNull);
        expect(line.product, isNull);
      });
    });

    group('toJson', () {
      test('includes __className__ = SalesInvoiceLine', () {
        expect(_makeLine().toJson()['__className__'], 'SalesInvoiceLine');
      });

      test('omits id, invoice, product when null', () {
        final json = _makeLine().toJson();
        expect(json.containsKey('id'), isFalse);
        expect(json.containsKey('invoice'), isFalse);
        expect(json.containsKey('product'), isFalse);
      });

      test('includes quantity, unitPrice, lineTotal', () {
        final json = _makeLine(quantity: 5, unitPrice: 200, lineTotal: 1000).toJson();
        expect(json['quantity'], 5);
        expect(json['unitPrice'], 200);
        expect(json['lineTotal'], 1000);
        expect(json.containsKey('invoiceId'), isTrue);
        expect(json.containsKey('productId'), isTrue);
      });
    });

    group('fromJson', () {
      test('round-trip preserves all fields', () {
        final original = _makeLine(
          id: _entityId,
          quantity: 4,
          unitPrice: 750,
          lineTotal: 3000,
        );
        final restored = SalesInvoiceLine.fromJson(original.toJson());
        expect(restored.quantity, 4);
        expect(restored.unitPrice, 750);
        expect(restored.lineTotal, 3000);
        expect(restored.id, original.id);
        expect(restored.invoiceId, original.invoiceId);
        expect(restored.productId, original.productId);
      });

      test('invoice and product are null when absent from JSON', () {
        final line = SalesInvoiceLine.fromJson({
          'invoiceId': _invoiceId,
          'productId': _productId,
          'quantity': 1,
          'unitPrice': 100,
          'lineTotal': 100,
          'createdAt': _now.toIso8601String(),
          'updatedAt': _later.toIso8601String(),
        });
        expect(line.invoice, isNull);
        expect(line.product, isNull);
      });
    });

    group('copyWith', () {
      test('updates quantity and lineTotal', () {
        final original = _makeLine(quantity: 2, lineTotal: 2000);
        final copy = original.copyWith(quantity: 5, lineTotal: 5000);
        expect(copy.quantity, 5);
        expect(copy.lineTotal, 5000);
        expect(copy.unitPrice, original.unitPrice);
      });

      test('updates unitPrice', () {
        final original = _makeLine(unitPrice: 1000);
        final copy = original.copyWith(unitPrice: 1200);
        expect(copy.unitPrice, 1200);
      });

      test('preserves all fields when no args given', () {
        final original = _makeLine(quantity: 3, unitPrice: 400, lineTotal: 1200);
        final copy = original.copyWith();
        expect(copy.quantity, 3);
        expect(copy.unitPrice, 400);
        expect(copy.lineTotal, 1200);
      });
    });
  });

  group('Receipt', () {
    Receipt _makeReceipt({
      String? id,
      ReceiptType receiptType = ReceiptType.GENERAL,
      String clientId = _clientId,
      String? invoiceId,
      int amount = 3000,
      String? note,
      RecordStatus? status,
      String? voidReason,
      int? rowVersion,
      SyncStatus? syncStatus,
    }) {
      return Receipt(
        id: id != null ? _uuid(id) : null,
        receiptType: receiptType,
        clientId: _uuid(clientId),
        invoiceId: invoiceId != null ? _uuid(invoiceId) : null,
        amount: amount,
        receiptDate: _now,
        note: note,
        status: status,
        voidReason: voidReason,
        createdAt: _now,
        updatedAt: _later,
        deviceId: _uuid(_deviceId),
        rowVersion: rowVersion,
        syncStatus: syncStatus,
      );
    }

    group('construction', () {
      test('creates receipt with required fields', () {
        final receipt = _makeReceipt(amount: 1500);
        expect(receipt.amount, 1500);
        expect(receipt.receiptType, ReceiptType.GENERAL);
        expect(receipt.note, isNull);
        expect(receipt.invoiceId, isNull);
        expect(receipt.client, isNull);
        expect(receipt.invoice, isNull);
      });

      test('status defaults to ACTIVE', () {
        expect(_makeReceipt().status, RecordStatus.ACTIVE);
      });

      test('rowVersion defaults to 1', () {
        expect(_makeReceipt().rowVersion, 1);
      });

      test('syncStatus defaults to PENDING', () {
        expect(_makeReceipt().syncStatus, SyncStatus.PENDING);
      });

      test('INVOICE_LINKED type with invoiceId', () {
        final receipt = _makeReceipt(
          receiptType: ReceiptType.INVOICE_LINKED,
          invoiceId: _invoiceId,
        );
        expect(receipt.receiptType, ReceiptType.INVOICE_LINKED);
        expect(receipt.invoiceId, _uuid(_invoiceId));
      });
    });

    group('toJson', () {
      test('includes __className__ = Receipt', () {
        expect(_makeReceipt().toJson()['__className__'], 'Receipt');
      });

      test('omits optional null fields', () {
        final json = _makeReceipt().toJson();
        expect(json.containsKey('id'), isFalse);
        expect(json.containsKey('note'), isFalse);
        expect(json.containsKey('voidReason'), isFalse);
        expect(json.containsKey('invoiceId'), isFalse);
        expect(json.containsKey('client'), isFalse);
        expect(json.containsKey('invoice'), isFalse);
        expect(json.containsKey('device'), isFalse);
      });

      test('includes required fields', () {
        final json = _makeReceipt(amount: 2000).toJson();
        expect(json['amount'], 2000);
        expect(json['receiptType'], 'GENERAL');
        expect(json['status'], 'ACTIVE');
        expect(json['rowVersion'], 1);
        expect(json['syncStatus'], 'PENDING');
      });

      test('includes invoiceId when set', () {
        final json = _makeReceipt(invoiceId: _invoiceId).toJson();
        expect(json.containsKey('invoiceId'), isTrue);
      });
    });

    group('fromJson', () {
      test('round-trip preserves all fields', () {
        final original = _makeReceipt(
          id: _entityId,
          receiptType: ReceiptType.INVOICE_LINKED,
          invoiceId: _invoiceId,
          amount: 4500,
          note: 'payment',
          status: RecordStatus.VOIDED,
          voidReason: 'refunded',
          rowVersion: 2,
          syncStatus: SyncStatus.CONFLICT,
        );
        final restored = Receipt.fromJson(original.toJson());
        expect(restored.receiptType, ReceiptType.INVOICE_LINKED);
        expect(restored.amount, 4500);
        expect(restored.note, 'payment');
        expect(restored.status, RecordStatus.VOIDED);
        expect(restored.voidReason, 'refunded');
        expect(restored.rowVersion, 2);
        expect(restored.syncStatus, SyncStatus.CONFLICT);
        expect(restored.id, original.id);
        expect(restored.invoiceId, original.invoiceId);
      });

      test('applies defaults when optional fields absent', () {
        final receipt = Receipt.fromJson({
          'receiptType': 'GENERAL',
          'clientId': _clientId,
          'amount': 100,
          'receiptDate': _now.toIso8601String(),
          'createdAt': _now.toIso8601String(),
          'updatedAt': _later.toIso8601String(),
          'deviceId': _deviceId,
          'rowVersion': 1,
        });
        expect(receipt.status, RecordStatus.ACTIVE);
        expect(receipt.syncStatus, SyncStatus.PENDING);
        expect(receipt.note, isNull);
        expect(receipt.invoiceId, isNull);
      });
    });

    group('copyWith', () {
      test('updates amount', () {
        final original = _makeReceipt(amount: 1000);
        final copy = original.copyWith(amount: 2000);
        expect(copy.amount, 2000);
        expect(copy.receiptType, original.receiptType);
      });

      test('updates receiptType', () {
        final original = _makeReceipt(receiptType: ReceiptType.GENERAL);
        final copy = original.copyWith(receiptType: ReceiptType.INVOICE_LINKED);
        expect(copy.receiptType, ReceiptType.INVOICE_LINKED);
      });

      test('can set note to null', () {
        final original = _makeReceipt(note: 'some note');
        final copy = original.copyWith(note: null);
        expect(copy.note, isNull);
      });

      test('updates status to VOIDED', () {
        final original = _makeReceipt();
        final copy = original.copyWith(
          status: RecordStatus.VOIDED,
          voidReason: 'client request',
        );
        expect(copy.status, RecordStatus.VOIDED);
        expect(copy.voidReason, 'client request');
      });

      test('preserves all fields when no args given', () {
        final original = _makeReceipt(amount: 3333, rowVersion: 5);
        final copy = original.copyWith();
        expect(copy.amount, 3333);
        expect(copy.rowVersion, 5);
      });
    });
  });

  group('ReceiptAllocation', () {
    ReceiptAllocation _makeAllocation({
      String? id,
      String receiptId = _receiptId,
      String invoiceId = _invoiceId,
      int allocatedAmount = 2000,
    }) {
      return ReceiptAllocation(
        id: id != null ? _uuid(id) : null,
        receiptId: _uuid(receiptId),
        invoiceId: _uuid(invoiceId),
        allocatedAmount: allocatedAmount,
        createdAt: _now,
        updatedAt: _later,
      );
    }

    group('construction', () {
      test('creates allocation with required fields', () {
        final alloc = _makeAllocation(allocatedAmount: 1500);
        expect(alloc.allocatedAmount, 1500);
        expect(alloc.id, isNull);
        expect(alloc.receipt, isNull);
        expect(alloc.invoice, isNull);
      });

      test('receiptId and invoiceId are set correctly', () {
        final alloc = _makeAllocation();
        expect(alloc.receiptId, _uuid(_receiptId));
        expect(alloc.invoiceId, _uuid(_invoiceId));
      });
    });

    group('toJson', () {
      test('includes __className__ = ReceiptAllocation', () {
        expect(_makeAllocation().toJson()['__className__'], 'ReceiptAllocation');
      });

      test('omits id, receipt, invoice when null', () {
        final json = _makeAllocation().toJson();
        expect(json.containsKey('id'), isFalse);
        expect(json.containsKey('receipt'), isFalse);
        expect(json.containsKey('invoice'), isFalse);
      });

      test('includes allocatedAmount, receiptId, invoiceId', () {
        final json = _makeAllocation(allocatedAmount: 500).toJson();
        expect(json['allocatedAmount'], 500);
        expect(json.containsKey('receiptId'), isTrue);
        expect(json.containsKey('invoiceId'), isTrue);
        expect(json.containsKey('createdAt'), isTrue);
        expect(json.containsKey('updatedAt'), isTrue);
      });
    });

    group('fromJson', () {
      test('round-trip preserves all fields', () {
        final original = _makeAllocation(
          id: _entityId,
          allocatedAmount: 3000,
        );
        final restored = ReceiptAllocation.fromJson(original.toJson());
        expect(restored.allocatedAmount, 3000);
        expect(restored.id, original.id);
        expect(restored.receiptId, original.receiptId);
        expect(restored.invoiceId, original.invoiceId);
      });

      test('receipt and invoice are null when absent from JSON', () {
        final alloc = ReceiptAllocation.fromJson({
          'receiptId': _receiptId,
          'invoiceId': _invoiceId,
          'allocatedAmount': 1000,
          'createdAt': _now.toIso8601String(),
          'updatedAt': _later.toIso8601String(),
        });
        expect(alloc.receipt, isNull);
        expect(alloc.invoice, isNull);
        expect(alloc.id, isNull);
      });
    });

    group('copyWith', () {
      test('updates allocatedAmount', () {
        final original = _makeAllocation(allocatedAmount: 1000);
        final copy = original.copyWith(allocatedAmount: 2000);
        expect(copy.allocatedAmount, 2000);
        expect(copy.receiptId, original.receiptId);
      });

      test('updates receiptId', () {
        final original = _makeAllocation();
        final newReceiptId = _uuid('00000000-0000-0000-0000-000000000099');
        final copy = original.copyWith(receiptId: newReceiptId);
        expect(copy.receiptId, newReceiptId);
        expect(copy.invoiceId, original.invoiceId);
      });

      test('preserves all fields when no args given', () {
        final original = _makeAllocation(allocatedAmount: 777);
        final copy = original.copyWith();
        expect(copy.allocatedAmount, 777);
        expect(copy.receiptId, original.receiptId);
        expect(copy.invoiceId, original.invoiceId);
      });

      test('boundary: zero allocatedAmount is valid', () {
        final alloc = _makeAllocation(allocatedAmount: 0);
        expect(alloc.allocatedAmount, 0);
        final copy = alloc.copyWith(allocatedAmount: 0);
        expect(copy.allocatedAmount, 0);
      });
    });
  });
}