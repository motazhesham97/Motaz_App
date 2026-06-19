import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/core/database/app_database.dart';
import 'package:motaz_app_flutter/core/database/enums/enums.dart';
import 'package:motaz_app_flutter/features/receipts/data/receipt_repository.dart';

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
const _invoiceId = 'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a13';
final _now = DateTime(2026, 1, 1, 10);

Future<void> _seedInvoice(AppDatabase db) async {
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
      .into(db.salesInvoices)
      .insert(
        SalesInvoicesCompanion(
          id: const Value(_invoiceId),
          localRef: const Value('INV-t001-001'),
          clientId: const Value(_clientId),
          invoiceDate: Value(_now),
          discount: const Value(0),
          total: const Value(250000),
          createdAt: Value(_now),
          updatedAt: Value(_now),
          deviceId: const Value(_deviceId),
        ),
      );
}

void main() {
  late AppDatabase db;
  late ReceiptRepository repository;

  setUp(() async {
    db = _createInMemoryDatabase();
    repository = ReceiptRepository(db);
    await _seedInvoice(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ReceiptRepository offline-first behavior', () {
    test(
      'saves invoice-linked receipt and allocation locally before remote work',
      () async {
        final receipt = await repository.createInvoiceLinked(
          clientId: _clientId,
          invoiceId: _invoiceId,
          amount: 100000,
          receiptDate: DateTime(2026, 1, 2),
          note: 'Receipt note',
          deviceId: _deviceId,
        );

        final savedReceipt = await repository.getById(receipt.id);
        final allocations = await repository.getAllocationsForReceipt(
          receipt.id,
        );
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

        expect(savedReceipt.localRef, 'REC-t001-001');
        expect(savedReceipt.receiptType, ReceiptType.INVOICE_LINKED);
        expect(savedReceipt.clientId, _clientId);
        expect(savedReceipt.invoiceId, _invoiceId);
        expect(savedReceipt.amount, 100000);
        expect(savedReceipt.syncStatus, SyncStatus.PENDING);
        expect(allocations, hasLength(1));
        expect(allocations.single.invoiceId, _invoiceId);
        expect(allocations.single.allocatedAmount, 100000);
        expect(device.nextReceiptSequence, 2);
        expect(outboxRows, hasLength(2));
        expect(receiptOutbox.operation, AuditOperation.CREATE);
        expect(receiptOutbox.entityId, savedReceipt.id);
        expect(receiptOutbox.status, SyncOutboxStatus.PENDING);
        expect(receiptPayload['amount'], savedReceipt.amount);
        expect(receiptPayload['syncStatus'], SyncStatus.PENDING.index);
        expect(allocationOutbox.operation, AuditOperation.CREATE);
        expect(allocationOutbox.entityId, allocations.single.id);
        expect(allocationOutbox.status, SyncOutboxStatus.PENDING);
        expect(allocationPayload['receiptId'], savedReceipt.id);
        expect(allocationPayload['allocatedAmount'], 100000);
      },
    );

    test(
      'saves general receipt and FIFO allocation locally before remote work',
      () async {
        final receipt = await repository.createGeneral(
          clientId: _clientId,
          amount: 125000,
          receiptDate: DateTime(2026, 1, 3),
          note: 'General payment',
          deviceId: _deviceId,
        );

        final savedReceipt = await repository.getById(receipt.id);
        final allocations = await repository.getAllocationsForReceipt(
          receipt.id,
        );
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

        expect(savedReceipt.localRef, 'REC-t001-001');
        expect(savedReceipt.receiptType, ReceiptType.GENERAL);
        expect(savedReceipt.invoiceId, null);
        expect(savedReceipt.amount, 125000);
        expect(savedReceipt.syncStatus, SyncStatus.PENDING);
        expect(allocations, hasLength(1));
        expect(allocations.single.invoiceId, _invoiceId);
        expect(allocations.single.allocatedAmount, 125000);
        expect(device.nextReceiptSequence, 2);
        expect(outboxRows, hasLength(2));
        expect(receiptOutbox.operation, AuditOperation.CREATE);
        expect(receiptOutbox.entityId, savedReceipt.id);
        expect(receiptOutbox.status, SyncOutboxStatus.PENDING);
        expect(receiptPayload['receiptType'], ReceiptType.GENERAL.index);
        expect(receiptPayload['amount'], savedReceipt.amount);
        expect(allocationOutbox.operation, AuditOperation.CREATE);
        expect(allocationOutbox.entityId, allocations.single.id);
        expect(allocationOutbox.status, SyncOutboxStatus.PENDING);
        expect(allocationPayload['invoiceId'], _invoiceId);
        expect(allocationPayload['allocatedAmount'], 125000);
      },
    );
  });
}
