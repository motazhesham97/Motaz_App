// ignore_for_file: constant_identifier_names

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:motaz_app_flutter/core/database/app_database.dart';
import 'package:motaz_app_flutter/core/database/enums/enums.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase _createInMemoryDatabase() {
  return AppDatabase(
    NativeDatabase.memory(
      setup: (rawDb) {
        rawDb.execute('PRAGMA foreign_keys = ON');
      },
    ),
  );
}

const _deviceId = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
const _productId = 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12';
const _clientId = 'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a13';
const _invoiceId = 'd0eebc99-9c0b-4ef8-bb6d-6bb9bd380a14';
const _invoiceLineId = 'e0eebc99-9c0b-4ef8-bb6d-6bb9bd380a15';
const _receiptId = 'f0eebc99-9c0b-4ef8-bb6d-6bb9bd380a16';
const _receiptAllocationId = 'a1eebc99-9c0b-4ef8-bb6d-6bb9bd380a17';
const _expenseId = 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a18';
const _salesReturnId = 'c1eebc99-9c0b-4ef8-bb6d-6bb9bd380a19';
const _salesReturnLineId = 'd1eebc99-9c0b-4ef8-bb6d-6bb9bd380a20';
const _attachmentId = 'e1eebc99-9c0b-4ef8-bb6d-6bb9bd380a21';
const _localAttachmentId = 'f1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22';
const _auditId = 'a2eebc99-9c0b-4ef8-bb6d-6bb9bd380a23';
const _conflictId = 'b2eebc99-9c0b-4ef8-bb6d-6bb9bd380a24';
const _outboxId = 'c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a25';
const _cursorId = 'd2eebc99-9c0b-4ef8-bb6d-6bb9bd380a26';

final _createdAt = DateTime(2026, 1, 1, 10);
final _updatedAt = DateTime(2026, 1, 2, 10);

Future<void> _insertDevice(AppDatabase db) {
  return db
      .into(db.devices)
      .insert(
        DevicesCompanion(
          id: const Value(_deviceId),
          deviceName: const Value('Test Device'),
          platform: const Value(DevicePlatform.ANDROID),
          deviceCode: const Value('abc1'),
          createdAt: Value(_createdAt),
          lastActiveAt: Value(_updatedAt),
        ),
      );
}

Future<void> _insertProduct(AppDatabase db) {
  return db
      .into(db.products)
      .insert(
        ProductsCompanion(
          id: const Value(_productId),
          name: const Value('Test Product'),
          description: const Value('Primary product'),
          defaultSalePrice: const Value(125000),
          createdAt: Value(_createdAt),
          updatedAt: Value(_updatedAt),
          deviceId: const Value(_deviceId),
        ),
      );
}

Future<void> _insertClient(AppDatabase db) {
  return db
      .into(db.clients)
      .insert(
        ClientsCompanion(
          id: const Value(_clientId),
          displayName: const Value('Test Client'),
          phone: const Value('+967700000000'),
          note: const Value('Preferred buyer'),
          clientCode: const Value('CL-001'),
          createdAt: Value(_createdAt),
          updatedAt: Value(_updatedAt),
          deviceId: const Value(_deviceId),
        ),
      );
}

Future<void> _insertSalesInvoice(AppDatabase db) {
  return db
      .into(db.salesInvoices)
      .insert(
        SalesInvoicesCompanion(
          id: const Value(_invoiceId),
          localRef: const Value('INV-abc1-001'),
          officialNo: const Value('OFF-001'),
          clientId: const Value(_clientId),
          invoiceDate: Value(_createdAt),
          discount: const Value(5000),
          total: const Value(245000),
          note: const Value('Invoice note'),
          createdAt: Value(_createdAt),
          updatedAt: Value(_updatedAt),
          deviceId: const Value(_deviceId),
        ),
      );
}

Future<void> _insertSalesInvoiceLine(AppDatabase db) {
  return db
      .into(db.salesInvoiceLines)
      .insert(
        SalesInvoiceLinesCompanion(
          id: const Value(_invoiceLineId),
          invoiceId: const Value(_invoiceId),
          productId: const Value(_productId),
          quantity: const Value(2),
          unitPrice: const Value(125000),
          lineTotal: const Value(250000),
          createdAt: Value(_createdAt),
          updatedAt: Value(_updatedAt),
        ),
      );
}

Future<void> _seedCoreEntities(AppDatabase db) async {
  await _insertDevice(db);
  await _insertProduct(db);
  await _insertClient(db);
  await _insertSalesInvoice(db);
  await _insertSalesInvoiceLine(db);
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = _createInMemoryDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  group('Drift smoke tests', () {
    test('insert and retrieve all 16 entities', () async {
      await _seedCoreEntities(db);

      await db
          .into(db.receipts)
          .insert(
            ReceiptsCompanion(
              id: const Value(_receiptId),
              receiptType: const Value(ReceiptType.INVOICE_LINKED),
              clientId: const Value(_clientId),
              invoiceId: const Value(_invoiceId),
              amount: const Value(245000),
              receiptDate: Value(_createdAt),
              note: const Value('Receipt note'),
              createdAt: Value(_createdAt),
              updatedAt: Value(_updatedAt),
              deviceId: const Value(_deviceId),
            ),
          );

      await db
          .into(db.receiptAllocations)
          .insert(
            ReceiptAllocationsCompanion(
              id: const Value(_receiptAllocationId),
              receiptId: const Value(_receiptId),
              invoiceId: const Value(_invoiceId),
              allocatedAmount: const Value(245000),
              createdAt: Value(_createdAt),
              updatedAt: Value(_updatedAt),
            ),
          );

      await db
          .into(db.expenses)
          .insert(
            ExpensesCompanion(
              id: const Value(_expenseId),
              category: const Value(ExpenseCategory.OPERATIONAL),
              amount: const Value(50000),
              expenseDate: Value(_createdAt),
              note: const Value('Fuel'),
              createdAt: Value(_createdAt),
              updatedAt: Value(_updatedAt),
              deviceId: const Value(_deviceId),
            ),
          );

      await db
          .into(db.salesReturns)
          .insert(
            SalesReturnsCompanion(
              id: const Value(_salesReturnId),
              invoiceId: const Value(_invoiceId),
              returnDate: Value(_updatedAt),
              totalReturnedAmount: const Value(125000),
              note: const Value('One item returned'),
              createdAt: Value(_createdAt),
              updatedAt: Value(_updatedAt),
              deviceId: const Value(_deviceId),
            ),
          );

      await db
          .into(db.salesReturnLines)
          .insert(
            SalesReturnLinesCompanion(
              id: const Value(_salesReturnLineId),
              returnId: const Value(_salesReturnId),
              invoiceLineId: const Value(_invoiceLineId),
              returnedQuantity: const Value(1),
              returnedAmount: const Value(125000),
              createdAt: Value(_createdAt),
              updatedAt: Value(_updatedAt),
            ),
          );

      await db
          .into(db.attachmentMetadata)
          .insert(
            AttachmentMetadataCompanion(
              id: const Value(_attachmentId),
              parentEntityType: const Value(ParentEntityType.SALES_INVOICE),
              parentEntityId: const Value(_invoiceId),
              storageReference: const Value('cloudinary/invoice-1'),
              secureUrl: const Value('https://cdn.example.com/invoice-1.jpg'),
              fileType: const Value('image/jpeg'),
              fileSize: const Value(2048),
              createdAt: Value(_createdAt),
              updatedAt: Value(_updatedAt),
              deviceId: const Value(_deviceId),
            ),
          );

      await db
          .into(db.localAttachmentStaging)
          .insert(
            LocalAttachmentStagingCompanion(
              id: const Value(_localAttachmentId),
              parentEntityType: const Value(ParentEntityType.RECEIPT),
              parentEntityId: const Value(_receiptId),
              localFilePath: const Value('C:/tmp/receipt.jpg'),
              fileType: const Value('image/jpeg'),
              fileSize: const Value(1024),
              createdAt: Value(_createdAt),
              updatedAt: Value(_updatedAt),
            ),
          );

      await db
          .into(db.auditEvents)
          .insert(
            AuditEventsCompanion(
              id: const Value(_auditId),
              entityType: const Value(ParentEntityType.SALES_INVOICE),
              entityId: const Value(_invoiceId),
              operation: const Value(AuditOperation.CREATE),
              diffData: const Value('{"total":245000}'),
              deviceId: const Value(_deviceId),
              createdAt: Value(_createdAt),
            ),
          );

      await db
          .into(db.conflictLogs)
          .insert(
            ConflictLogsCompanion(
              id: const Value(_conflictId),
              entityType: const Value(ParentEntityType.PRODUCT),
              entityId: const Value(_productId),
              localPayload: const Value('{"name":"Local"}'),
              remotePayload: const Value('{"name":"Remote"}'),
              conflictType: const Value('name_mismatch'),
              createdAt: Value(_createdAt),
              deviceId: const Value(_deviceId),
            ),
          );

      await db
          .into(db.syncOutbox)
          .insert(
            SyncOutboxCompanion(
              id: const Value(_outboxId),
              entityType: const Value(ParentEntityType.PRODUCT),
              entityId: const Value(_productId),
              operation: const Value(AuditOperation.UPDATE),
              payload: const Value('{"name":"Updated Product"}'),
              rowVersion: const Value(2),
              deviceId: const Value(_deviceId),
              createdAt: Value(_createdAt),
            ),
          );

      await db
          .into(db.syncCursor)
          .insert(
            SyncCursorCompanion(
              id: const Value(_cursorId),
              entityType: const Value(ParentEntityType.PRODUCT),
              lastPulledAt: Value(_updatedAt),
              lastRowVersion: const Value(2),
              updatedAt: Value(_updatedAt),
            ),
          );

      expect((await db.select(db.devices).getSingle()).deviceCode, 'abc1');
      expect(
        (await db.select(db.products).getSingle()).defaultSalePrice,
        125000,
      );
      expect(
        (await db.select(db.clients).getSingle()).displayName,
        'Test Client',
      );
      expect(
        (await db.select(db.salesInvoices).getSingle()).localRef,
        'INV-abc1-001',
      );
      expect(
        (await db.select(db.salesInvoiceLines).getSingle()).lineTotal,
        250000,
      );
      expect((await db.select(db.receipts).getSingle()).amount, 245000);
      expect(
        (await db.select(db.receiptAllocations).getSingle()).allocatedAmount,
        245000,
      );
      expect(
        (await db.select(db.expenses).getSingle()).category,
        ExpenseCategory.OPERATIONAL,
      );
      expect(
        (await db.select(db.salesReturns).getSingle()).totalReturnedAmount,
        125000,
      );
      expect(
        (await db.select(db.salesReturnLines).getSingle()).returnedQuantity,
        1,
      );
      expect(
        (await db.select(db.attachmentMetadata).getSingle()).storageReference,
        'cloudinary/invoice-1',
      );
      expect(
        (await db.select(db.localAttachmentStaging).getSingle()).uploadStatus,
        'PENDING',
      );
      expect(
        (await db.select(db.auditEvents).getSingle()).operation,
        AuditOperation.CREATE,
      );
      expect(
        (await db.select(db.conflictLogs).getSingle()).resolutionStatus,
        ConflictStatus.PENDING,
      );
      expect(
        (await db.select(db.syncOutbox).getSingle()).status,
        SyncOutboxStatus.PENDING,
      );
      expect((await db.select(db.syncCursor).getSingle()).lastRowVersion, 2);
    });

    test(
      'void flow updates invoice, receipt, expense, and sales return',
      () async {
        await _seedCoreEntities(db);

        await db
            .into(db.receipts)
            .insert(
              ReceiptsCompanion(
                id: const Value(_receiptId),
                receiptType: const Value(ReceiptType.INVOICE_LINKED),
                clientId: const Value(_clientId),
                invoiceId: const Value(_invoiceId),
                amount: const Value(245000),
                receiptDate: Value(_createdAt),
                createdAt: Value(_createdAt),
                updatedAt: Value(_updatedAt),
                deviceId: const Value(_deviceId),
              ),
            );

        await db
            .into(db.expenses)
            .insert(
              ExpensesCompanion(
                id: const Value(_expenseId),
                category: const Value(ExpenseCategory.OPERATIONAL),
                amount: const Value(50000),
                expenseDate: Value(_createdAt),
                createdAt: Value(_createdAt),
                updatedAt: Value(_updatedAt),
                deviceId: const Value(_deviceId),
              ),
            );

        await db
            .into(db.salesReturns)
            .insert(
              SalesReturnsCompanion(
                id: const Value(_salesReturnId),
                invoiceId: const Value(_invoiceId),
                returnDate: Value(_updatedAt),
                totalReturnedAmount: const Value(125000),
                createdAt: Value(_createdAt),
                updatedAt: Value(_updatedAt),
                deviceId: const Value(_deviceId),
              ),
            );

        await (db.update(
          db.salesInvoices,
        )..where((t) => t.id.equals(_invoiceId))).write(
          const SalesInvoicesCompanion(
            status: Value(RecordStatus.VOIDED),
            voidReason: Value('Customer cancelled'),
          ),
        );
        await (db.update(
          db.receipts,
        )..where((t) => t.id.equals(_receiptId))).write(
          const ReceiptsCompanion(
            status: Value(RecordStatus.VOIDED),
            voidReason: Value('Payment reversed'),
          ),
        );
        await (db.update(
          db.expenses,
        )..where((t) => t.id.equals(_expenseId))).write(
          const ExpensesCompanion(
            status: Value(RecordStatus.VOIDED),
            voidReason: Value('Duplicate entry'),
          ),
        );
        await (db.update(
          db.salesReturns,
        )..where((t) => t.id.equals(_salesReturnId))).write(
          const SalesReturnsCompanion(
            status: Value(RecordStatus.VOIDED),
            voidReason: Value('Invalid return'),
          ),
        );

        final invoice = await (db.select(
          db.salesInvoices,
        )..where((t) => t.id.equals(_invoiceId))).getSingle();
        final receipt = await (db.select(
          db.receipts,
        )..where((t) => t.id.equals(_receiptId))).getSingle();
        final expense = await (db.select(
          db.expenses,
        )..where((t) => t.id.equals(_expenseId))).getSingle();
        final salesReturn = await (db.select(
          db.salesReturns,
        )..where((t) => t.id.equals(_salesReturnId))).getSingle();

        expect(invoice.status, RecordStatus.VOIDED);
        expect(invoice.voidReason, 'Customer cancelled');
        expect(receipt.status, RecordStatus.VOIDED);
        expect(receipt.voidReason, 'Payment reversed');
        expect(expense.status, RecordStatus.VOIDED);
        expect(expense.voidReason, 'Duplicate entry');
        expect(salesReturn.status, RecordStatus.VOIDED);
        expect(salesReturn.voidReason, 'Invalid return');
      },
    );

    test('rejects duplicate product name', () async {
      await _insertDevice(db);
      await _insertProduct(db);

      await expectLater(
        () => db
            .into(db.products)
            .insert(
              ProductsCompanion(
                id: const Value('duplicate-name-product-id'),
                name: const Value('Test Product'),
                defaultSalePrice: const Value(99900),
                createdAt: Value(_createdAt),
                updatedAt: Value(_updatedAt),
                deviceId: const Value(_deviceId),
              ),
            ),
        throwsA(isA<Exception>()),
      );
    });

    test('accepts zero-price product as boundary value', () async {
      await _insertDevice(db);

      await db
          .into(db.products)
          .insert(
            ProductsCompanion(
              id: const Value(_productId),
              name: const Value('Free Sample'),
              defaultSalePrice: const Value(0),
              createdAt: Value(_createdAt),
              updatedAt: Value(_updatedAt),
              deviceId: const Value(_deviceId),
            ),
          );

      final product = await db.select(db.products).getSingle();
      expect(product.defaultSalePrice, 0);
    });

    test('rejects invoice with non-existent clientId', () async {
      await _insertDevice(db);

      await expectLater(
        () => db
            .into(db.salesInvoices)
            .insert(
              SalesInvoicesCompanion(
                id: const Value(_invoiceId),
                localRef: const Value('INV-abc1-002'),
                clientId: const Value('non-existent-client-id-0000000000000'),
                invoiceDate: Value(_createdAt),
                total: const Value(100000),
                createdAt: Value(_createdAt),
                updatedAt: Value(_updatedAt),
                deviceId: const Value(_deviceId),
              ),
            ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
