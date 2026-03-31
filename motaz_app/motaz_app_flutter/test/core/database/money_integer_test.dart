// ignore_for_file: constant_identifier_names

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/core/database/app_database.dart';
import 'package:motaz_app_flutter/core/database/enums/enums.dart';

AppDatabase _createInMemoryDatabase() {
  return AppDatabase(NativeDatabase.memory());
}

const _deviceId = '10eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
const _productId = '20eebc99-9c0b-4ef8-bb6d-6bb9bd380a12';
const _clientId = '30eebc99-9c0b-4ef8-bb6d-6bb9bd380a13';
const _invoiceId = '40eebc99-9c0b-4ef8-bb6d-6bb9bd380a14';
const _invoiceLineOneId = '50eebc99-9c0b-4ef8-bb6d-6bb9bd380a15';
const _invoiceLineTwoId = '60eebc99-9c0b-4ef8-bb6d-6bb9bd380a16';
const _receiptId = '70eebc99-9c0b-4ef8-bb6d-6bb9bd380a17';
const _expenseId = '80eebc99-9c0b-4ef8-bb6d-6bb9bd380a18';

final _now = DateTime(2026, 2, 1, 10);

Future<void> _seedMoneyEntities(AppDatabase db) async {
  await db.into(db.devices).insert(
    DevicesCompanion(
      id: const Value(_deviceId),
      deviceName: const Value('Money Device'),
      platform: const Value(DevicePlatform.ANDROID),
      deviceCode: const Value('mon1'),
      createdAt: Value(_now),
      lastActiveAt: Value(_now),
    ),
  );

  await db.into(db.products).insert(
    ProductsCompanion(
      id: const Value(_productId),
      name: const Value('Money Product'),
      defaultSalePrice: const Value(123456789),
      createdAt: Value(_now),
      updatedAt: Value(_now),
      deviceId: const Value(_deviceId),
    ),
  );

  await db.into(db.clients).insert(
    ClientsCompanion(
      id: const Value(_clientId),
      displayName: const Value('Money Client'),
      createdAt: Value(_now),
      updatedAt: Value(_now),
      deviceId: const Value(_deviceId),
    ),
  );
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = _createInMemoryDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  group('Money integer tests', () {
    test('persists exact minor-unit values across tables', () async {
      await _seedMoneyEntities(db);

      await db.into(db.expenses).insert(
        ExpensesCompanion(
          id: const Value(_expenseId),
          category: const Value(ExpenseCategory.OPERATIONAL),
          amount: const Value(987654321),
          expenseDate: Value(_now),
          createdAt: Value(_now),
          updatedAt: Value(_now),
          deviceId: const Value(_deviceId),
        ),
      );

      final product = await db.select(db.products).getSingle();
      final expense = await db.select(db.expenses).getSingle();

      expect(product.defaultSalePrice, 123456789);
      expect(expense.amount, 987654321);
    });

    test('invoice line totals and discount round-trip with zero precision loss', () async {
      await _seedMoneyEntities(db);

      const unitPriceOne = 50000;
      const quantityOne = 2;
      const lineTotalOne = unitPriceOne * quantityOne;
      const unitPriceTwo = 125000;
      const quantityTwo = 1;
      const lineTotalTwo = unitPriceTwo * quantityTwo;
      const discount = 5000;
      const invoiceTotal = lineTotalOne + lineTotalTwo - discount;

      await db.into(db.salesInvoices).insert(
        SalesInvoicesCompanion(
          id: const Value(_invoiceId),
          localRef: const Value('INV-mon1-001'),
          clientId: const Value(_clientId),
          invoiceDate: Value(_now),
          discount: const Value(discount),
          total: const Value(invoiceTotal),
          createdAt: Value(_now),
          updatedAt: Value(_now),
          deviceId: const Value(_deviceId),
        ),
      );

      await db.into(db.salesInvoiceLines).insert(
        SalesInvoiceLinesCompanion(
          id: const Value(_invoiceLineOneId),
          invoiceId: const Value(_invoiceId),
          productId: const Value(_productId),
          quantity: const Value(quantityOne),
          unitPrice: const Value(unitPriceOne),
          lineTotal: const Value(lineTotalOne),
          createdAt: Value(_now),
          updatedAt: Value(_now),
        ),
      );
      await db.into(db.salesInvoiceLines).insert(
        SalesInvoiceLinesCompanion(
          id: const Value(_invoiceLineTwoId),
          invoiceId: const Value(_invoiceId),
          productId: const Value(_productId),
          quantity: const Value(quantityTwo),
          unitPrice: const Value(unitPriceTwo),
          lineTotal: const Value(lineTotalTwo),
          createdAt: Value(_now),
          updatedAt: Value(_now),
        ),
      );

      final invoice = await db.select(db.salesInvoices).getSingle();
      final lines = await db.select(db.salesInvoiceLines).get();
      final computedSubtotal = lines.fold<int>(0, (sum, line) => sum + line.lineTotal);

      expect(computedSubtotal, lineTotalOne + lineTotalTwo);
      expect(invoice.discount, discount);
      expect(invoice.total, invoiceTotal);
      expect(computedSubtotal - invoice.discount, invoice.total);
    });

    test('receipt allocation amount persists exactly', () async {
      await _seedMoneyEntities(db);

      await db.into(db.salesInvoices).insert(
        SalesInvoicesCompanion(
          id: const Value(_invoiceId),
          localRef: const Value('INV-mon1-002'),
          clientId: const Value(_clientId),
          invoiceDate: Value(_now),
          total: const Value(300000),
          createdAt: Value(_now),
          updatedAt: Value(_now),
          deviceId: const Value(_deviceId),
        ),
      );

      await db.into(db.receipts).insert(
        ReceiptsCompanion(
          id: const Value(_receiptId),
          receiptType: const Value(ReceiptType.INVOICE_LINKED),
          clientId: const Value(_clientId),
          invoiceId: const Value(_invoiceId),
          amount: const Value(300000),
          receiptDate: Value(_now),
          createdAt: Value(_now),
          updatedAt: Value(_now),
          deviceId: const Value(_deviceId),
        ),
      );

      await db.into(db.receiptAllocations).insert(
        ReceiptAllocationsCompanion(
          id: const Value('90eebc99-9c0b-4ef8-bb6d-6bb9bd380a19'),
          receiptId: const Value(_receiptId),
          invoiceId: const Value(_invoiceId),
          allocatedAmount: const Value(300000),
          createdAt: Value(_now),
          updatedAt: Value(_now),
        ),
      );

      final receipt = await db.select(db.receipts).getSingle();
      final allocation = await db.select(db.receiptAllocations).getSingle();

      expect(receipt.amount, 300000);
      expect(allocation.allocatedAmount, 300000);
    });
  });
}
