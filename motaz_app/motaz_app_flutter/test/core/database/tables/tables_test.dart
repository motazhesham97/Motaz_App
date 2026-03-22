import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/core/database/app_database.dart';

/// Shared helper: creates a fresh in-memory database for each test.
AppDatabase _openInMemory() =>
    AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));

void main() {
  // ── Devices table definition ──────────────────────────────────────────────

  group('Devices table definition', () {
    late AppDatabase db;

    setUp(() {
      db = _openInMemory();
    });

    tearDown(() async {
      await db.close();
    });

    test('id column accepts exactly 36-character UUID strings', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      // 36 chars (standard UUID v4 format)
      const validId = 'aaaabbbb-cccc-dddd-eeee-ffffffffffff';
      expect(validId.length, equals(36));

      await db.into(db.devices).insert(DevicesCompanion.insert(
        id: validId,
        deviceName: 'Device',
        platform: 'android',
        createdAt: now,
        lastActiveAt: now,
      ));

      final result = await db.select(db.devices).getSingle();
      expect(result.id, equals(validId));
    });

    test('deviceName stores up to 255 characters', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final longName = 'A' * 255;

      await db.into(db.devices).insert(DevicesCompanion.insert(
        id: 'aaaabbbb-cccc-dddd-eeee-111111111111',
        deviceName: longName,
        platform: 'android',
        createdAt: now,
        lastActiveAt: now,
      ));

      final result = await db.select(db.devices).getSingle();
      expect(result.deviceName, equals(longName));
      expect(result.deviceName.length, equals(255));
    });

    test('platform column stores platform string', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      for (final platform in ['android', 'windows']) {
        final id = 'aaaabbbb-cccc-dddd-eeee-${platform.padRight(12, '0').substring(0, 12)}';
        await db.into(db.devices).insert(DevicesCompanion.insert(
          id: id,
          deviceName: 'Device-$platform',
          platform: platform,
          createdAt: now,
          lastActiveAt: now,
        ));
      }

      final results = await db.select(db.devices).get();
      final platforms = results.map((r) => r.platform).toSet();
      expect(platforms, containsAll(['android', 'windows']));
    });

    test('createdAt and lastActiveAt store Unix epoch milliseconds', () async {
      final ts = DateTime(2024, 1, 15, 10, 30).millisecondsSinceEpoch;

      await db.into(db.devices).insert(DevicesCompanion.insert(
        id: 'aaaabbbb-cccc-dddd-eeee-222222222222',
        deviceName: 'TimestampDevice',
        platform: 'android',
        createdAt: ts,
        lastActiveAt: ts + 3600000,
      ));

      final result = await db.select(db.devices).getSingle();
      expect(result.createdAt, equals(ts));
      expect(result.lastActiveAt, equals(ts + 3600000));
    });

    test('primary key prevents duplicate device ids', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      const id = 'aaaabbbb-cccc-dddd-eeee-333333333333';

      await db.into(db.devices).insert(DevicesCompanion.insert(
        id: id,
        deviceName: 'Device 1',
        platform: 'android',
        createdAt: now,
        lastActiveAt: now,
      ));

      expect(
        () => db.into(db.devices).insert(DevicesCompanion.insert(
              id: id,
              deviceName: 'Device 2',
              platform: 'windows',
              createdAt: now,
              lastActiveAt: now,
            )),
        throwsA(anything),
      );
    });
  });

  // ── SyncCursor table definition ────────────────────────────────────────────

  group('SyncCursor table definition', () {
    late AppDatabase db;

    setUp(() {
      db = _openInMemory();
    });

    tearDown(() async {
      await db.close();
    });

    test('entityType is the primary key', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.into(db.syncCursor).insert(SyncCursorCompanion.insert(
        entityType: 'products',
        lastPulledAt: now,
      ));

      // Trying to insert the same entityType again must fail
      expect(
        () => db.into(db.syncCursor).insert(SyncCursorCompanion.insert(
              entityType: 'products',
              lastPulledAt: now + 1,
            )),
        throwsA(anything),
      );
    });

    test('lastRowVersion has default value of 0', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.into(db.syncCursor).insert(SyncCursorCompanion.insert(
        entityType: 'clients',
        lastPulledAt: now,
        // lastRowVersion NOT specified — should default to 0
      ));

      final cursor = await db.select(db.syncCursor).getSingle();
      expect(cursor.lastRowVersion, equals(0));
    });

    test('lastRowVersion can be set to non-zero value', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.into(db.syncCursor).insert(SyncCursorCompanion.insert(
        entityType: 'invoices',
        lastPulledAt: now,
        lastRowVersion: const Value(99),
      ));

      final cursor = await db.select(db.syncCursor).getSingle();
      expect(cursor.lastRowVersion, equals(99));
    });

    test('entityType accepts strings up to 100 characters', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final longType = 'entity_type_' + 'x' * 88; // total 100 chars
      expect(longType.length, equals(100));

      await db.into(db.syncCursor).insert(SyncCursorCompanion.insert(
        entityType: longType,
        lastPulledAt: now,
      ));

      final cursor = await db.select(db.syncCursor).getSingle();
      expect(cursor.entityType, equals(longType));
    });

    test('multiple entity types can coexist', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      const types = ['products', 'clients', 'invoices', 'receipts', 'expenses'];

      for (final type in types) {
        await db.into(db.syncCursor).insert(SyncCursorCompanion.insert(
          entityType: type,
          lastPulledAt: now,
        ));
      }

      final results = await db.select(db.syncCursor).get();
      expect(results.length, equals(types.length));
    });
  });

  // ── SyncOutbox table definition ────────────────────────────────────────────

  group('SyncOutbox table definition', () {
    late AppDatabase db;
    late String deviceId;
    late int now;

    setUp(() async {
      db = _openInMemory();
      deviceId = 'aaaabbbb-cccc-dddd-eeee-000000000000';
      now = DateTime.now().millisecondsSinceEpoch;

      // SyncOutbox.deviceId is a FK → devices.id
      await db.into(db.devices).insert(DevicesCompanion.insert(
        id: deviceId,
        deviceName: 'TestDevice',
        platform: 'android',
        createdAt: now,
        lastActiveAt: now,
      ));
    });

    tearDown(() async {
      await db.close();
    });

    test('id is an auto-incrementing integer primary key', () async {
      for (var i = 0; i < 3; i++) {
        await db.into(db.syncOutbox).insert(SyncOutboxCompanion.insert(
          entityType: 'products',
          entityId: 'aaaabbbb-cccc-dddd-eeee-00000000000$i',
          operation: 'CREATE',
          payload: '{}',
          rowVersion: 1,
          deviceId: deviceId,
          createdAt: now,
        ));
      }

      final results = await db.select(db.syncOutbox).get();
      expect(results.map((r) => r.id).toList(), equals([1, 2, 3]));
    });

    test('retryCount defaults to 0', () async {
      await db.into(db.syncOutbox).insert(SyncOutboxCompanion.insert(
        entityType: 'clients',
        entityId: 'aaaabbbb-cccc-dddd-eeee-000000000001',
        operation: 'UPDATE',
        payload: '{}',
        rowVersion: 2,
        deviceId: deviceId,
        createdAt: now,
      ));

      final record = await db.select(db.syncOutbox).getSingle();
      expect(record.retryCount, equals(0));
    });

    test('status defaults to "pending"', () async {
      await db.into(db.syncOutbox).insert(SyncOutboxCompanion.insert(
        entityType: 'expenses',
        entityId: 'aaaabbbb-cccc-dddd-eeee-000000000002',
        operation: 'CREATE',
        payload: '{"amount":50000}',
        rowVersion: 1,
        deviceId: deviceId,
        createdAt: now,
      ));

      final record = await db.select(db.syncOutbox).getSingle();
      expect(record.status, equals('pending'));
    });

    test('entityId stores exactly 36-character UUID string', () async {
      const entityId = 'bbbbcccc-dddd-eeee-ffff-aaaaaaaaaaaa';
      expect(entityId.length, equals(36));

      await db.into(db.syncOutbox).insert(SyncOutboxCompanion.insert(
        entityType: 'invoices',
        entityId: entityId,
        operation: 'CREATE',
        payload: '{}',
        rowVersion: 1,
        deviceId: deviceId,
        createdAt: now,
      ));

      final record = await db.select(db.syncOutbox).getSingle();
      expect(record.entityId, equals(entityId));
    });

    test('payload stores JSON string of arbitrary length', () async {
      // Simulate a realistic invoice payload
      const payload = '''{"id":"aaa","clientId":"bbb","lines":['''
          '''{"productId":"ccc","qty":2,"price":100000},'''
          '''{"productId":"ddd","qty":1,"price":50000}],'''
          '''"discount":5000,"total":245000}''';

      await db.into(db.syncOutbox).insert(SyncOutboxCompanion.insert(
        entityType: 'invoices',
        entityId: 'ccccdddd-eeee-ffff-aaaa-bbbbbbbbbbbb',
        operation: 'CREATE',
        payload: payload,
        rowVersion: 1,
        deviceId: deviceId,
        createdAt: now,
      ));

      final record = await db.select(db.syncOutbox).getSingle();
      expect(record.payload, equals(payload));
    });

    test('rowVersion stores large integer values', () async {
      const largeVersion = 9999999;

      await db.into(db.syncOutbox).insert(SyncOutboxCompanion.insert(
        entityType: 'receipts',
        entityId: 'ddddeeee-ffff-aaaa-bbbb-cccccccccccc',
        operation: 'UPDATE',
        payload: '{}',
        rowVersion: largeVersion,
        deviceId: deviceId,
        createdAt: now,
      ));

      final record = await db.select(db.syncOutbox).getSingle();
      expect(record.rowVersion, equals(largeVersion));
    });

    test('supports all expected status values', () async {
      final statuses = ['pending', 'in_progress', 'completed', 'failed'];

      for (var i = 0; i < statuses.length; i++) {
        await db.into(db.syncOutbox).insert(SyncOutboxCompanion.insert(
          entityType: 'products',
          entityId: 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee0$i',
          operation: 'CREATE',
          payload: '{}',
          rowVersion: 1,
          deviceId: deviceId,
          createdAt: now,
          status: Value(statuses[i]),
        ));
      }

      final results = await db.select(db.syncOutbox).get();
      final storedStatuses = results.map((r) => r.status).toSet();
      expect(storedStatuses, containsAll(statuses));
    });

    test('supports all expected operation values', () async {
      final operations = ['CREATE', 'UPDATE', 'VOID'];

      for (var i = 0; i < operations.length; i++) {
        await db.into(db.syncOutbox).insert(SyncOutboxCompanion.insert(
          entityType: 'clients',
          entityId: 'ffffffff-ffff-ffff-ffff-fffffffffff$i',
          operation: operations[i],
          payload: '{}',
          rowVersion: i + 1,
          deviceId: deviceId,
          createdAt: now,
        ));
      }

      final results = await db.select(db.syncOutbox).get();
      final storedOps = results.map((r) => r.operation).toSet();
      expect(storedOps, containsAll(operations));
    });
  });
}