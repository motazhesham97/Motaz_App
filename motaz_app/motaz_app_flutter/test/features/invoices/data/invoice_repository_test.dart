import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/core/database/app_database.dart';
import 'package:motaz_app_flutter/core/database/enums/enums.dart';
import 'package:motaz_app_flutter/features/invoices/data/invoice_repository.dart';

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
const _clientId = 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12';
const _productId = 'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a13';
final _now = DateTime(2026, 1, 1, 10);

Future<void> _seedInvoiceDependencies(AppDatabase db) async {
  await db
      .into(db.devices)
      .insert(
        DevicesCompanion(
          id: const Value(_deviceId),
          deviceName: const Value('Test Device'),
          platform: const Value(DevicePlatform.ANDROID),
          deviceCode: const Value('t001'),
          createdAt: Value(_now),
          lastActiveAt: Value(_now),
        ),
      );
  await db
      .into(db.clients)
      .insert(
        ClientsCompanion(
          id: const Value(_clientId),
          displayName: const Value('Test Client'),
          createdAt: Value(_now),
          updatedAt: Value(_now),
          deviceId: const Value(_deviceId),
        ),
      );
  await db
      .into(db.products)
      .insert(
        ProductsCompanion(
          id: const Value(_productId),
          name: const Value('Test Product'),
          defaultSalePrice: const Value(125000),
          createdAt: Value(_now),
          updatedAt: Value(_now),
          deviceId: const Value(_deviceId),
        ),
      );
}

void main() {
  late AppDatabase db;
  late InvoiceRepository repository;

  setUp(() async {
    db = _createInMemoryDatabase();
    repository = InvoiceRepository(db);
    await _seedInvoiceDependencies(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('InvoiceRepository offline-first behavior', () {
    test(
      'saves invoice and line locally and enqueues sync before remote work',
      () async {
        final invoice = await repository.create(
          clientId: _clientId,
          invoiceDate: DateTime(2026, 1, 2),
          discount: 5000,
          note: 'Invoice note',
          lines: const [
            SalesInvoiceLinesCompanion(
              productId: Value(_productId),
              quantity: Value(2),
              unitPrice: Value(125000),
            ),
          ],
          paidAmount: 0,
          deviceId: _deviceId,
        );

        final savedInvoice = await repository.getById(invoice.id);
        final savedLines = await repository.getLinesForInvoice(invoice.id);
        final device = await (db.select(
          db.devices,
        )..where((t) => t.id.equals(_deviceId))).getSingle();
        final outboxRows = await db.select(db.syncOutbox).get();
        final invoiceOutbox = outboxRows.singleWhere(
          (row) => row.entityType == ParentEntityType.SALES_INVOICE,
        );
        final lineOutbox = outboxRows.singleWhere(
          (row) => row.entityType == ParentEntityType.SALES_INVOICE_LINE,
        );
        final invoicePayload =
            jsonDecode(invoiceOutbox.payload) as Map<String, dynamic>;
        final linePayload =
            jsonDecode(lineOutbox.payload) as Map<String, dynamic>;

        expect(savedInvoice.localRef, 'INV-t001-001');
        expect(savedInvoice.clientId, _clientId);
        expect(savedInvoice.discount, 5000);
        expect(savedInvoice.total, 245000);
        expect(savedInvoice.syncStatus, SyncStatus.PENDING);
        expect(savedLines, hasLength(1));
        expect(savedLines.single.productId, _productId);
        expect(savedLines.single.quantity, 2);
        expect(savedLines.single.unitPrice, 125000);
        expect(savedLines.single.lineTotal, 250000);
        expect(device.nextInvoiceSequence, 2);
        expect(outboxRows, hasLength(2));
        expect(invoiceOutbox.operation, AuditOperation.CREATE);
        expect(invoiceOutbox.entityId, savedInvoice.id);
        expect(invoiceOutbox.status, SyncOutboxStatus.PENDING);
        expect(invoicePayload['total'], savedInvoice.total);
        expect(invoicePayload['syncStatus'], SyncStatus.PENDING.index);
        expect(lineOutbox.operation, AuditOperation.CREATE);
        expect(lineOutbox.entityId, savedLines.single.id);
        expect(lineOutbox.status, SyncOutboxStatus.PENDING);
        expect(linePayload['invoiceId'], savedInvoice.id);
        expect(linePayload['lineTotal'], savedLines.single.lineTotal);
      },
    );

    test(
      'saves paid invoice receipt and allocation locally before remote work',
      () async {
        final invoice = await repository.create(
          clientId: _clientId,
          invoiceDate: DateTime(2026, 1, 2),
          discount: 0,
          note: '',
          lines: const [
            SalesInvoiceLinesCompanion(
              productId: Value(_productId),
              quantity: Value(2),
              unitPrice: Value(125000),
            ),
          ],
          paidAmount: 100000,
          deviceId: _deviceId,
        );

        final receipts = await repository.getReceiptsForInvoice(invoice.id);
        final allocations = await (db.select(
          db.receiptAllocations,
        )..where((t) => t.invoiceId.equals(invoice.id))).get();
        final device = await (db.select(
          db.devices,
        )..where((t) => t.id.equals(_deviceId))).getSingle();
        final outboxRows = await db.select(db.syncOutbox).get();
        final receiptOutbox = outboxRows.singleWhere(
          (row) => row.entityType == ParentEntityType.RECEIPT,
        );
        final allocationOutbox = outboxRows.singleWhere(
          (row) => row.entityType == ParentEntityType.RECEIPT_ALLOCATION,
        );
        final receiptPayload =
            jsonDecode(receiptOutbox.payload) as Map<String, dynamic>;
        final allocationPayload =
            jsonDecode(allocationOutbox.payload) as Map<String, dynamic>;

        expect(receipts, hasLength(1));
        expect(receipts.single.localRef, 'REC-t001-001');
        expect(receipts.single.amount, 100000);
        expect(receipts.single.syncStatus, SyncStatus.PENDING);
        expect(allocations, hasLength(1));
        expect(allocations.single.receiptId, receipts.single.id);
        expect(allocations.single.allocatedAmount, 100000);
        expect(device.nextInvoiceSequence, 2);
        expect(device.nextReceiptSequence, 2);
        expect(outboxRows, hasLength(4));
        expect(receiptOutbox.operation, AuditOperation.CREATE);
        expect(receiptOutbox.entityId, receipts.single.id);
        expect(receiptOutbox.status, SyncOutboxStatus.PENDING);
        expect(receiptPayload['amount'], receipts.single.amount);
        expect(allocationOutbox.operation, AuditOperation.CREATE);
        expect(allocationOutbox.entityId, allocations.single.id);
        expect(allocationOutbox.status, SyncOutboxStatus.PENDING);
        expect(allocationPayload['receiptId'], receipts.single.id);
        expect(allocationPayload['allocatedAmount'], 100000);
      },
    );
  });
}
