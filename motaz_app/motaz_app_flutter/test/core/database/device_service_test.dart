// ignore_for_file: lines_longer_than_80_chars
// NOTE: This test requires the Drift-generated file app_database.g.dart.
// Run `flutter pub run build_runner build` before executing these tests.

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/core/database/app_database.dart';
import 'package:motaz_app_flutter/core/database/device_service.dart';
import 'package:uuid/uuid.dart';

/// Creates an in-memory AppDatabase backed by a temp file for isolation.
AppDatabase _buildInMemoryDatabase() {
  final file = File('/tmp/motaz_test_device_${DateTime.now().microsecondsSinceEpoch}.sqlite');
  return AppDatabase(NativeDatabase(file));
}

void main() {
  group('DeviceService', () {
    late AppDatabase db;
    late DeviceService service;

    setUp(() async {
      db = _buildInMemoryDatabase();
      service = DeviceService(db);
    });

    tearDown(() async {
      await db.close();
    });

    group('getOrCreateDevice()', () {
      test('creates a device when none exists', () async {
        final device = await service.getOrCreateDevice();
        expect(device, isNotNull);
        expect(device.id, isNotEmpty);
      });

      test('created device has a UUID-format id (36 chars)', () async {
        final device = await service.getOrCreateDevice();
        expect(device.id.length, equals(36));
        // UUID v4 format: 8-4-4-4-12
        final uuidPattern = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          caseSensitive: false,
        );
        expect(uuidPattern.hasMatch(device.id), isTrue);
      });

      test('device platform is set to a non-empty string', () async {
        final device = await service.getOrCreateDevice();
        expect(device.platform, isNotEmpty);
      });

      test('device deviceName is set to a non-empty string', () async {
        final device = await service.getOrCreateDevice();
        expect(device.deviceName, isNotEmpty);
      });

      test('device createdAt is set to a recent epoch millisecond', () async {
        final before = DateTime.now().millisecondsSinceEpoch;
        final device = await service.getOrCreateDevice();
        final after = DateTime.now().millisecondsSinceEpoch;
        expect(device.createdAt, greaterThanOrEqualTo(before - 1000));
        expect(device.createdAt, lessThanOrEqualTo(after + 1000));
      });

      test('device lastActiveAt is set on creation', () async {
        final before = DateTime.now().millisecondsSinceEpoch;
        final device = await service.getOrCreateDevice();
        expect(device.lastActiveAt, greaterThanOrEqualTo(before - 1000));
      });

      test('returns same device id on second call', () async {
        final first = await service.getOrCreateDevice();
        final second = await service.getOrCreateDevice();
        expect(second.id, equals(first.id));
      });

      test('updates lastActiveAt on second call', () async {
        final first = await service.getOrCreateDevice();
        await Future<void>.delayed(const Duration(milliseconds: 10));
        final second = await service.getOrCreateDevice();
        expect(second.lastActiveAt, greaterThanOrEqualTo(first.lastActiveAt));
      });

      test('only one device exists after multiple getOrCreate calls', () async {
        await service.getOrCreateDevice();
        await service.getOrCreateDevice();
        await service.getOrCreateDevice();
        final devices = await db.select(db.devices).get();
        expect(devices.length, equals(1));
      });
    });

    group('getDeviceId()', () {
      test('returns null when no device exists', () async {
        final id = await service.getDeviceId();
        expect(id, isNull);
      });

      test('returns the device id after creation', () async {
        final device = await service.getOrCreateDevice();
        final id = await service.getDeviceId();
        expect(id, equals(device.id));
      });
    });

    group('getDevice()', () {
      test('returns null when no device exists', () async {
        final device = await service.getDevice();
        expect(device, isNull);
      });

      test('returns the device after creation', () async {
        final created = await service.getOrCreateDevice();
        final fetched = await service.getDevice();
        expect(fetched, isNotNull);
        expect(fetched!.id, equals(created.id));
      });
    });

    group('updateDeviceName()', () {
      test('updates device name after creation', () async {
        await service.getOrCreateDevice();
        await service.updateDeviceName('My Custom Device');
        final device = await service.getDevice();
        expect(device?.deviceName, equals('My Custom Device'));
      });

      test('does nothing when no device exists', () async {
        // Should not throw
        await expectLater(
          service.updateDeviceName('name'),
          completes,
        );
      });

      test('updated name is persisted across service calls', () async {
        await service.getOrCreateDevice();
        await service.updateDeviceName('New Name');
        // Create a new service pointing to same DB to verify persistence
        final service2 = DeviceService(db);
        final device = await service2.getDevice();
        expect(device?.deviceName, equals('New Name'));
      });
    });

    group('DeviceService with custom UUID', () {
      test('uses provided UUID instance for device id generation', () async {
        const fixedId = '12345678-1234-4234-a234-123456789012';
        final mockUuid = _FixedUuid(fixedId);
        final serviceWithUuid = DeviceService(db, mockUuid);
        final device = await serviceWithUuid.getOrCreateDevice();
        expect(device.id, equals(fixedId));
      });
    });
  });

  group('DatabaseCorruptedException', () {
    test('is an Exception', () {
      final e = DatabaseCorruptedException('test message');
      expect(e, isA<Exception>());
    });

    test('stores the message', () {
      final e = DatabaseCorruptedException('فشل في فتح قاعدة البيانات');
      expect(e.message, equals('فشل في فتح قاعدة البيانات'));
    });

    test('can be thrown and caught', () {
      expect(
        () => throw DatabaseCorruptedException('corrupt'),
        throwsA(isA<DatabaseCorruptedException>()),
      );
    });
  });
}

/// Minimal fake UUID that always returns a fixed value for testing.
/// Uses [noSuchMethod] to satisfy the full [Uuid] interface at runtime.
class _FixedUuid implements Uuid {
  const _FixedUuid(this._fixedV4);

  final String _fixedV4;

  // Override v4() since that is what DeviceService calls.
  @override
  // ignore: override_on_non_overriding_member
  String v4({Map<String, dynamic>? options, List<int>? buffer, int? offset}) =>
      _fixedV4;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}