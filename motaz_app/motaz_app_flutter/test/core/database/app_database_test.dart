import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/core/database/app_database.dart';

/// Opens a fresh in-memory [AppDatabase] for each test.
AppDatabase _openInMemory() {
  return AppDatabase.forTesting(
    DatabaseConnection(NativeDatabase.memory()),
  );
}

void main() {
  group('AppDatabase', () {
    late AppDatabase db;

    setUp(() {
      db = _openInMemory();
    });

    tearDown(() async {
      await db.close();
    });

    // ── Schema version ──────────────────────────────────────────────────────

    test('schema version is 1', () {
      expect(db.schemaVersion, equals(1));
    });

    // ── Database opens ───────────────────────────────────────────────────────

    test('database opens without error', () async {
      // Executing any query confirms the DB is open and tables exist
      final devices = await db.select(db.devices).get();
      expect(devices, isEmpty);
    });

    // ── Devices table ────────────────────────────────────────────────────────

    group('devices table', () {
      test('inserts and retrieves a device record', () async {
        final now = DateTime.now().millisecondsSinceEpoch;
        await db.into(db.devices).insert(DevicesCompanion.insert(
          id: '123e4567-e89b-12d3-a456-426614174000',
          deviceName: 'Test Device',
          platform: 'android',
          createdAt: now,
          lastActiveAt: now,
        ));

        final results = await db.select(db.devices).get();
        expect(results.length, equals(1));

        final device = results.first;
        expect(device.id, equals('123e4567-e89b-12d3-a456-426614174000'));
        expect(device.deviceName, equals('Test Device'));
        expect(device.platform, equals('android'));
        expect(device.createdAt, equals(now));
        expect(device.lastActiveAt, equals(now));
      });

      test('device id is the primary key — duplicate id is rejected', () async {
        final now = DateTime.now().millisecondsSinceEpoch;
        const id = '123e4567-e89b-12d3-a456-426614174000';

        await db.into(db.devices).insert(DevicesCompanion.insert(
          id: id,
          deviceName: 'Device 1',
          platform: 'android',
          createdAt: now,
          lastActiveAt: now,
        ));

        expect(
          () async => db.into(db.devices).insert(DevicesCompanion.insert(
                id: id,
                deviceName: 'Device 2',
                platform: 'windows',
                createdAt: now,
                lastActiveAt: now,
              )),
          throwsA(anything),
        );
      });

      test('inserts two devices with different ids', () async {
        final now = DateTime.now().millisecondsSinceEpoch;
        await db.into(db.devices).insert(DevicesCompanion.insert(
          id: '123e4567-e89b-12d3-a456-426614174001',
          deviceName: 'Phone',
          platform: 'android',
          createdAt: now,
          lastActiveAt: now,
        ));
        await db.into(db.devices).insert(DevicesCompanion.insert(
          id: '123e4567-e89b-12d3-a456-426614174002',
          deviceName: 'Desktop',
          platform: 'windows',
          createdAt: now,
          lastActiveAt: now,
        ));

        final results = await db.select(db.devices).get();
        expect(results.length, equals(2));
      });

      test('updates lastActiveAt field', () async {
        final createdAt = DateTime.now().millisecondsSinceEpoch;
        const id = '123e4567-e89b-12d3-a456-426614174003';

        await db.into(db.devices).insert(DevicesCompanion.insert(
          id: id,
          deviceName: 'Phone',
          platform: 'android',
          createdAt: createdAt,
          lastActiveAt: createdAt,
        ));

        final laterTime = createdAt + 1000;
        await (db.update(db.devices)..where((d) => d.id.equals(id)))
            .write(DevicesCompanion(lastActiveAt: Value(laterTime)));

        final device =
            await (db.select(db.devices)..where((d) => d.id.equals(id)))
                .getSingle();

        expect(device.lastActiveAt, equals(laterTime));
        expect(device.createdAt, equals(createdAt)); // unchanged
      });

      test('deletes a device record', () async {
        final now = DateTime.now().millisecondsSinceEpoch;
        const id = '123e4567-e89b-12d3-a456-426614174004';

        await db.into(db.devices).insert(DevicesCompanion.insert(
          id: id,
          deviceName: 'Phone',
          platform: 'android',
          createdAt: now,
          lastActiveAt: now,
        ));

        await (db.delete(db.devices)..where((d) => d.id.equals(id))).go();

        final results = await db.select(db.devices).get();
        expect(results, isEmpty);
      });
    });

    // ── SyncCursor table ──────────────────────────────────────────────────────

    group('syncCursor table', () {
      test('inserts and retrieves a sync cursor record', () async {
        final now = DateTime.now().millisecondsSinceEpoch;
        await db.into(db.syncCursor).insert(SyncCursorCompanion.insert(
          entityType: 'products',
          lastPulledAt: now,
        ));

        final results = await db.select(db.syncCursor).get();
        expect(results.length, equals(1));

        final cursor = results.first;
        expect(cursor.entityType, equals('products'));
        expect(cursor.lastPulledAt, equals(now));
        expect(cursor.lastRowVersion, equals(0)); // default
      });

      test('lastRowVersion defaults to 0', () async {
        final now = DateTime.now().millisecondsSinceEpoch;
        await db.into(db.syncCursor).insert(SyncCursorCompanion.insert(
          entityType: 'clients',
          lastPulledAt: now,
        ));

        final cursor =
            await (db.select(db.syncCursor)
                  ..where((c) => c.entityType.equals('clients')))
                .getSingle();
        expect(cursor.lastRowVersion, equals(0));
      });

      test('entityType is primary key — duplicate entity type is rejected', () async {
        final now = DateTime.now().millisecondsSinceEpoch;
        const entityType = 'invoices';

        await db.into(db.syncCursor).insert(SyncCursorCompanion.insert(
          entityType: entityType,
          lastPulledAt: now,
        ));

        expect(
          () async => db.into(db.syncCursor).insert(SyncCursorCompanion.insert(
                entityType: entityType,
                lastPulledAt: now + 1,
              )),
          throwsA(anything),
        );
      });

      test('inserts multiple cursors with different entity types', () async {
        final now = DateTime.now().millisecondsSinceEpoch;
        for (final type in ['products', 'clients', 'invoices']) {
          await db.into(db.syncCursor).insert(SyncCursorCompanion.insert(
            entityType: type,
            lastPulledAt: now,
          ));
        }

        final results = await db.select(db.syncCursor).get();
        expect(results.length, equals(3));
        expect(
          results.map((r) => r.entityType).toSet(),
          containsAll(['products', 'clients', 'invoices']),
        );
      });

      test('updates lastRowVersion and lastPulledAt', () async {
        final now = DateTime.now().millisecondsSinceEpoch;
        const entityType = 'receipts';

        await db.into(db.syncCursor).insert(SyncCursorCompanion.insert(
          entityType: entityType,
          lastPulledAt: now,
        ));

        await (db.update(db.syncCursor)
              ..where((c) => c.entityType.equals(entityType)))
            .write(SyncCursorCompanion(
          lastRowVersion: const Value(42),
          lastPulledAt: Value(now + 5000),
        ));

        final cursor =
            await (db.select(db.syncCursor)
                  ..where((c) => c.entityType.equals(entityType)))
                .getSingle();

        expect(cursor.lastRowVersion, equals(42));
        expect(cursor.lastPulledAt, equals(now + 5000));
      });

      test('upsert replaces existing cursor', () async {
        final now = DateTime.now().millisecondsSinceEpoch;
        const entityType = 'expenses';

        await db.into(db.syncCursor).insertOnConflictUpdate(
          SyncCursorCompanion.insert(
            entityType: entityType,
            lastPulledAt: now,
            lastRowVersion: const Value(1),
          ),
        );

        await db.into(db.syncCursor).insertOnConflictUpdate(
          SyncCursorCompanion.insert(
            entityType: entityType,
            lastPulledAt: now + 1000,
            lastRowVersion: const Value(5),
          ),
        );

        final results = await db.select(db.syncCursor).get();
        expect(results.length, equals(1));
        expect(results.first.lastRowVersion, equals(5));
        expect(results.first.lastPulledAt, equals(now + 1000));
      });
    });

    // ── SyncOutbox table ──────────────────────────────────────────────────────

    group('syncOutbox table', () {
      late String deviceId;
      late int now;

      setUp(() async {
        deviceId = '123e4567-e89b-12d3-a456-426614174000';
        now = DateTime.now().millisecondsSinceEpoch;
        // SyncOutbox references Devices via FK — insert the device first
        await db.into(db.devices).insert(DevicesCompanion.insert(
          id: deviceId,
          deviceName: 'Test Device',
          platform: 'android',
          createdAt: now,
          lastActiveAt: now,
        ));
      });

      test('inserts and retrieves an outbox record', () async {
        await db.into(db.syncOutbox).insert(SyncOutboxCompanion.insert(
          entityType: 'products',
          entityId: '223e4567-e89b-12d3-a456-426614174001',
          operation: 'CREATE',
          payload: '{"name":"Product A"}',
          rowVersion: 1,
          deviceId: deviceId,
          createdAt: now,
        ));

        final results = await db.select(db.syncOutbox).get();
        expect(results.length, equals(1));

        final record = results.first;
        expect(record.entityType, equals('products'));
        expect(record.entityId, equals('223e4567-e89b-12d3-a456-426614174001'));
        expect(record.operation, equals('CREATE'));
        expect(record.payload, equals('{"name":"Product A"}'));
        expect(record.rowVersion, equals(1));
        expect(record.deviceId, equals(deviceId));
        expect(record.createdAt, equals(now));
      });

      test('id is auto-incremented', () async {
        for (var i = 0; i < 3; i++) {
          await db.into(db.syncOutbox).insert(SyncOutboxCompanion.insert(
            entityType: 'clients',
            entityId: '223e4567-e89b-12d3-a456-42661417400$i',
            operation: 'CREATE',
            payload: '{}',
            rowVersion: i + 1,
            deviceId: deviceId,
            createdAt: now,
          ));
        }

        final results = await db.select(db.syncOutbox).get();
        final ids = results.map((r) => r.id).toList();
        expect(ids, equals([1, 2, 3]));
      });

      test('retryCount defaults to 0', () async {
        await db.into(db.syncOutbox).insert(SyncOutboxCompanion.insert(
          entityType: 'invoices',
          entityId: '323e4567-e89b-12d3-a456-426614174001',
          operation: 'UPDATE',
          payload: '{"total":100000}',
          rowVersion: 2,
          deviceId: deviceId,
          createdAt: now,
        ));

        final record = await db.select(db.syncOutbox).getSingle();
        expect(record.retryCount, equals(0));
      });

      test('status defaults to "pending"', () async {
        await db.into(db.syncOutbox).insert(SyncOutboxCompanion.insert(
          entityType: 'invoices',
          entityId: '323e4567-e89b-12d3-a456-426614174002',
          operation: 'CREATE',
          payload: '{}',
          rowVersion: 1,
          deviceId: deviceId,
          createdAt: now,
        ));

        final record = await db.select(db.syncOutbox).getSingle();
        expect(record.status, equals('pending'));
      });

      test('filters outbox records by status', () async {
        // Insert one "pending" and one "completed"
        await db.into(db.syncOutbox).insert(SyncOutboxCompanion.insert(
          entityType: 'products',
          entityId: '423e4567-e89b-12d3-a456-426614174001',
          operation: 'CREATE',
          payload: '{}',
          rowVersion: 1,
          deviceId: deviceId,
          createdAt: now,
          status: const Value('pending'),
        ));
        await db.into(db.syncOutbox).insert(SyncOutboxCompanion.insert(
          entityType: 'products',
          entityId: '423e4567-e89b-12d3-a456-426614174002',
          operation: 'CREATE',
          payload: '{}',
          rowVersion: 1,
          deviceId: deviceId,
          createdAt: now,
          status: const Value('completed'),
        ));

        final pending =
            await (db.select(db.syncOutbox)
                  ..where((o) => o.status.equals('pending')))
                .get();
        expect(pending.length, equals(1));

        final completed =
            await (db.select(db.syncOutbox)
                  ..where((o) => o.status.equals('completed')))
                .get();
        expect(completed.length, equals(1));
      });

      test('updates retryCount and status', () async {
        await db.into(db.syncOutbox).insert(SyncOutboxCompanion.insert(
          entityType: 'invoices',
          entityId: '523e4567-e89b-12d3-a456-426614174001',
          operation: 'CREATE',
          payload: '{}',
          rowVersion: 1,
          deviceId: deviceId,
          createdAt: now,
        ));

        final inserted = await db.select(db.syncOutbox).getSingle();

        await (db.update(db.syncOutbox)
              ..where((o) => o.id.equals(inserted.id)))
            .write(const SyncOutboxCompanion(
          retryCount: Value(3),
          status: Value('failed'),
        ));

        final updated = await db.select(db.syncOutbox).getSingle();
        expect(updated.retryCount, equals(3));
        expect(updated.status, equals('failed'));
      });

      test('payload stores arbitrary JSON text', () async {
        const largePayload =
            '{"id":"123","items":[{"qty":2,"price":50000},{"qty":1,"price":75000}],"discount":10000}';
        await db.into(db.syncOutbox).insert(SyncOutboxCompanion.insert(
          entityType: 'invoices',
          entityId: '623e4567-e89b-12d3-a456-426614174001',
          operation: 'CREATE',
          payload: largePayload,
          rowVersion: 1,
          deviceId: deviceId,
          createdAt: now,
        ));

        final record = await db.select(db.syncOutbox).getSingle();
        expect(record.payload, equals(largePayload));
      });
    });

    // ── Migration strategy ────────────────────────────────────────────────────

    group('migration strategy', () {
      test('onCreate creates all tables', () async {
        // Opening the in-memory DB and querying from all 3 tables confirms
        // the onCreate migration ran successfully
        await expectLater(db.select(db.devices).get(), completes);
        await expectLater(db.select(db.syncCursor).get(), completes);
        await expectLater(db.select(db.syncOutbox).get(), completes);
      });
    });
  });
}