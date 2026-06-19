import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/core/database/app_database.dart';
import 'package:motaz_app_flutter/core/database/enums/enums.dart';
import 'package:motaz_app_flutter/features/returns/data/return_repository.dart';

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
const _invoiceId = 'd0eebc99-9c0b-4ef8-bb6d-6bb9bd380a14';
const _invoiceLineId = 'e0eebc99-9c0b-4ef8-bb6d-6bb9bd380a15';
final _now = DateTime(2026, 1, 1, 10);

Future<void> _seedReturnDependencies(AppDatabase db) async {
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
  await db
      .into(db.salesInvoiceLines)
      .insert(
        SalesInvoiceLinesCompanion(
          id: const Value(_invoiceLineId),
          invoiceId: const Value(_invoiceId),
          productId: const Value(_productId),
          quantity: const Value(2),
          unitPrice: const Value(125000),
          lineTotal: const Value(250000),
          createdAt: Value(_now),
          updatedAt: Value(_now),
        ),
      );
}

void main() {
  late AppDatabase db;
  late ReturnRepository repository;

  setUp(() async {
    db = _createInMemoryDatabase();
    repository = ReturnRepository(db);
    await _seedReturnDependencies(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ReturnRepository offline-first behavior', () {
    test(
      'saves return and line locally and enqueues sync before remote work',
      () async {
        final salesReturn = await repository.create(
          invoiceId: _invoiceId,
          returnDate: DateTime(2026, 1, 2),
          note: 'Return note',
          lines: const [
            (
              invoiceLineId: _invoiceLineId,
              returnedQuantity: 1,
              returnedAmount: 125000,
            ),
          ],
          deviceId: _deviceId,
        );

        final savedReturn = await repository.getById(salesReturn.id);
        final savedLines = await repository.getReturnLinesForReturn(
          salesReturn.id,
        );
        final returnedQuantity = await repository
            .getReturnedQuantityForInvoiceLine(_invoiceLineId);
        final device = await (db.select(
          db.devices,
        )..where((t) => t.id.equals(_deviceId))).getSingle();
        final outboxRows = await db.select(db.syncOutbox).get();
        final returnOutbox = outboxRows.singleWhere(
          (row) => row.entityType == ParentEntityType.SALES_RETURN,
        );
        final lineOutbox = outboxRows.singleWhere(
          (row) => row.entityType == ParentEntityType.SALES_RETURN_LINE,
        );
        final returnPayload =
            jsonDecode(returnOutbox.payload) as Map<String, dynamic>;
        final linePayload =
            jsonDecode(lineOutbox.payload) as Map<String, dynamic>;

        expect(savedReturn.localRef, 'RET-t001-001');
        expect(savedReturn.invoiceId, _invoiceId);
        expect(savedReturn.totalReturnedAmount, 125000);
        expect(savedReturn.note, 'Return note');
        expect(savedReturn.syncStatus, SyncStatus.PENDING);
        expect(savedLines, hasLength(1));
        expect(savedLines.single.invoiceLineId, _invoiceLineId);
        expect(savedLines.single.returnedQuantity, 1);
        expect(savedLines.single.returnedAmount, 125000);
        expect(returnedQuantity, 1);
        expect(device.nextReturnSequence, 2);
        expect(outboxRows, hasLength(2));
        expect(returnOutbox.operation, AuditOperation.CREATE);
        expect(returnOutbox.entityId, savedReturn.id);
        expect(returnOutbox.status, SyncOutboxStatus.PENDING);
        expect(returnPayload['totalReturnedAmount'], 125000);
        expect(returnPayload['syncStatus'], SyncStatus.PENDING.index);
        expect(lineOutbox.operation, AuditOperation.CREATE);
        expect(lineOutbox.entityId, savedLines.single.id);
        expect(lineOutbox.status, SyncOutboxStatus.PENDING);
        expect(linePayload['returnId'], savedReturn.id);
        expect(linePayload['returnedAmount'], 125000);
      },
    );
  });
}
