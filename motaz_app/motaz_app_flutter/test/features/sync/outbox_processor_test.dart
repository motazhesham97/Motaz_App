import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_client/motaz_app_client.dart' as server;
import 'package:motaz_app_flutter/core/database/app_database.dart';
import 'package:motaz_app_flutter/core/database/enums/enums.dart';
import 'package:motaz_app_flutter/features/sync/application/outbox_processor.dart';

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
const _outboxId = 'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a13';
const _olderUpdateOutboxId = 'd0eebc99-9c0b-4ef8-bb6d-6bb9bd380a14';
const _latestUpdateOutboxId = 'e0eebc99-9c0b-4ef8-bb6d-6bb9bd380a15';
final _now = DateTime(2026, 1, 1, 10);

Future<void> _seedPendingProduct(AppDatabase db) async {
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
      .into(db.products)
      .insert(
        ProductsCompanion(
          id: const Value(_productId),
          name: const Value('Offline Product'),
          defaultSalePrice: const Value(25000),
          createdAt: Value(_now),
          updatedAt: Value(_now),
          deviceId: const Value(_deviceId),
          syncStatus: const Value(SyncStatus.PENDING),
        ),
      );
  await db
      .into(db.syncOutbox)
      .insert(
        SyncOutboxCompanion.insert(
          id: _outboxId,
          entityType: ParentEntityType.PRODUCT,
          entityId: _productId,
          operation: AuditOperation.CREATE,
          payload: jsonEncode({
            'id': _productId,
            'name': 'Offline Product',
            'syncStatus': SyncStatus.PENDING.index,
          }),
          rowVersion: 1,
          deviceId: _deviceId,
          createdAt: _now,
          status: const Value(SyncOutboxStatus.PENDING),
        ),
      );
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = _createInMemoryDatabase();
    await _seedPendingProduct(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('OutboxProcessor failure behavior', () {
    test(
      'keeps local entity pending when server rejects push as unauthenticated',
      () async {
        final processor = OutboxProcessor(
          db: db,
          serverClient: server.Client('http://127.0.0.1:1/'),
          pushOverride: (request) async {
            expect(request.outboxId, _outboxId);
            expect(request.entityType, ParentEntityType.PRODUCT.name);
            expect(request.operation, AuditOperation.CREATE.name);
            return server.PushResponse(
              success: false,
              errorCode: 'UNAUTHENTICATED',
              errorMessage: 'Authentication required',
            );
          },
        );

        await processor.processPending();

        final product = await (db.select(
          db.products,
        )..where((t) => t.id.equals(_productId))).getSingle();
        final outbox = await (db.select(
          db.syncOutbox,
        )..where((t) => t.id.equals(_outboxId))).getSingle();

        expect(product.name, 'Offline Product');
        expect(product.syncStatus, SyncStatus.PENDING);
        expect(product.rowVersion, 1);
        expect(outbox.status, SyncOutboxStatus.FAILED);
        expect(outbox.retryCount, 0);
      },
    );

    test(
      'marks entity synced after successful server acknowledgement',
      () async {
        final processor = OutboxProcessor(
          db: db,
          serverClient: server.Client('http://127.0.0.1:1/'),
          pushOverride: (request) async {
            expect(request.outboxId, _outboxId);
            expect(request.entityType, ParentEntityType.PRODUCT.name);
            expect(request.operation, AuditOperation.CREATE.name);
            return server.PushResponse(success: true, newRowVersion: 2);
          },
        );

        await processor.processPending();

        final product = await (db.select(
          db.products,
        )..where((t) => t.id.equals(_productId))).getSingle();
        final outbox = await (db.select(
          db.syncOutbox,
        )..where((t) => t.id.equals(_outboxId))).getSingle();

        expect(product.syncStatus, SyncStatus.SYNCED);
        expect(product.rowVersion, 2);
        expect(outbox.status, SyncOutboxStatus.COMPLETED);
        expect(outbox.retryCount, 0);
      },
    );

    test(
      'keeps retryable server failure pending with incremented retry count',
      () async {
        final processor = OutboxProcessor(
          db: db,
          serverClient: server.Client('http://127.0.0.1:1/'),
          pushOverride: (request) async {
            expect(request.outboxId, _outboxId);
            return server.PushResponse(
              success: false,
              errorCode: 'TEMPORARY_UNAVAILABLE',
              errorMessage: 'Try again later',
            );
          },
        );

        await processor.processPending();

        final product = await (db.select(
          db.products,
        )..where((t) => t.id.equals(_productId))).getSingle();
        final outbox = await (db.select(
          db.syncOutbox,
        )..where((t) => t.id.equals(_outboxId))).getSingle();

        expect(product.syncStatus, SyncStatus.PENDING);
        expect(product.rowVersion, 1);
        expect(outbox.status, SyncOutboxStatus.PENDING);
        expect(outbox.retryCount, 1);
      },
    );

    test('marks entity conflicted when server returns a conflict id', () async {
      final processor = OutboxProcessor(
        db: db,
        serverClient: server.Client('http://127.0.0.1:1/'),
        pushOverride: (request) async {
          expect(request.outboxId, _outboxId);
          return server.PushResponse(
            success: false,
            conflictId: 'conflict-1',
            errorCode: 'VERSION_CONFLICT',
          );
        },
      );

      await processor.processPending();

      final product = await (db.select(
        db.products,
      )..where((t) => t.id.equals(_productId))).getSingle();
      final outbox = await (db.select(
        db.syncOutbox,
      )..where((t) => t.id.equals(_outboxId))).getSingle();

      expect(product.name, 'Offline Product');
      expect(product.syncStatus, SyncStatus.CONFLICT);
      expect(product.rowVersion, 1);
      expect(outbox.status, SyncOutboxStatus.COMPLETED);
      expect(outbox.retryCount, 0);
    });

    test(
      'coalesces duplicate pending updates and pushes only the latest entry',
      () async {
        await (db.delete(
          db.syncOutbox,
        )..where((t) => t.id.equals(_outboxId))).go();
        await db
            .into(db.syncOutbox)
            .insert(
              SyncOutboxCompanion.insert(
                id: _olderUpdateOutboxId,
                entityType: ParentEntityType.PRODUCT,
                entityId: _productId,
                operation: AuditOperation.UPDATE,
                payload: jsonEncode({
                  'id': _productId,
                  'name': 'Older Name',
                  'syncStatus': SyncStatus.PENDING.index,
                }),
                rowVersion: 2,
                deviceId: _deviceId,
                createdAt: _now.add(const Duration(seconds: 1)),
                status: const Value(SyncOutboxStatus.PENDING),
              ),
            );
        await db
            .into(db.syncOutbox)
            .insert(
              SyncOutboxCompanion.insert(
                id: _latestUpdateOutboxId,
                entityType: ParentEntityType.PRODUCT,
                entityId: _productId,
                operation: AuditOperation.UPDATE,
                payload: jsonEncode({
                  'id': _productId,
                  'name': 'Latest Name',
                  'syncStatus': SyncStatus.PENDING.index,
                }),
                rowVersion: 3,
                deviceId: _deviceId,
                createdAt: _now.add(const Duration(seconds: 2)),
                status: const Value(SyncOutboxStatus.PENDING),
              ),
            );
        final pushedOutboxIds = <String>[];
        final processor = OutboxProcessor(
          db: db,
          serverClient: server.Client('http://127.0.0.1:1/'),
          pushOverride: (request) async {
            pushedOutboxIds.add(request.outboxId);
            expect(request.outboxId, _latestUpdateOutboxId);
            expect(request.rowVersion, 2);
            return server.PushResponse(success: true, newRowVersion: 4);
          },
        );

        await processor.processPending();

        final product = await (db.select(
          db.products,
        )..where((t) => t.id.equals(_productId))).getSingle();
        final olderOutbox = await (db.select(
          db.syncOutbox,
        )..where((t) => t.id.equals(_olderUpdateOutboxId))).getSingle();
        final latestOutbox = await (db.select(
          db.syncOutbox,
        )..where((t) => t.id.equals(_latestUpdateOutboxId))).getSingle();

        expect(pushedOutboxIds, [_latestUpdateOutboxId]);
        expect(product.syncStatus, SyncStatus.SYNCED);
        expect(product.rowVersion, 4);
        expect(olderOutbox.status, SyncOutboxStatus.COMPLETED);
        expect(latestOutbox.status, SyncOutboxStatus.COMPLETED);
        expect(latestOutbox.rowVersion, 2);
      },
    );
  });
}
