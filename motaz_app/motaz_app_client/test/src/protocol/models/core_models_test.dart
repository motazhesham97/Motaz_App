import 'package:test/test.dart';
import 'package:serverpod_client/serverpod_client.dart';
import 'package:motaz_app_client/src/protocol/device.dart';
import 'package:motaz_app_client/src/protocol/client_record.dart';
import 'package:motaz_app_client/src/protocol/product.dart';
import 'package:motaz_app_client/src/protocol/enums/device_platform.dart';
import 'package:motaz_app_client/src/protocol/enums/sync_status.dart';

// Helper to create a UUID from string
UuidValue _uuid(String s) => UuidValue.withoutValidation(s);

// Standard UUIDs for tests
const _deviceId1 = '00000000-0000-0000-0000-000000000001';
const _deviceId2 = '00000000-0000-0000-0000-000000000002';
const _entityId1 = '00000000-0000-0000-0000-000000000010';

final _now = DateTime.utc(2024, 6, 15, 12, 0, 0);
final _later = DateTime.utc(2024, 6, 15, 13, 0, 0);

void main() {
  group('Device', () {
    Device _makeDevice({
      String? id,
      String deviceName = 'Test Device',
      DevicePlatform platform = DevicePlatform.ANDROID,
      String deviceCode = 'DEV001',
      int? nextInvoiceSequence,
      DateTime? createdAt,
      DateTime? lastActiveAt,
    }) {
      return Device(
        id: id != null ? _uuid(id) : null,
        deviceName: deviceName,
        platform: platform,
        deviceCode: deviceCode,
        nextInvoiceSequence: nextInvoiceSequence,
        createdAt: createdAt ?? _now,
        lastActiveAt: lastActiveAt ?? _now,
      );
    }

    group('construction', () {
      test('creates device with required fields', () {
        final device = _makeDevice(deviceName: 'My Phone', deviceCode: 'ABC1');
        expect(device.deviceName, 'My Phone');
        expect(device.deviceCode, 'ABC1');
        expect(device.platform, DevicePlatform.ANDROID);
        expect(device.id, isNull);
        expect(device.syncOutboxItems, isNull);
      });

      test('nextInvoiceSequence defaults to 1', () {
        final device = _makeDevice();
        expect(device.nextInvoiceSequence, 1);
      });

      test('nextInvoiceSequence can be set explicitly', () {
        final device = _makeDevice(nextInvoiceSequence: 42);
        expect(device.nextInvoiceSequence, 42);
      });

      test('id can be set', () {
        final device = _makeDevice(id: _deviceId1);
        expect(device.id, _uuid(_deviceId1));
      });

      test('platform WINDOWS is supported', () {
        final device = _makeDevice(platform: DevicePlatform.WINDOWS);
        expect(device.platform, DevicePlatform.WINDOWS);
      });
    });

    group('toJson', () {
      test('includes __className__ key', () {
        final json = _makeDevice().toJson();
        expect(json['__className__'], 'Device');
      });

      test('omits id when null', () {
        final json = _makeDevice().toJson();
        expect(json.containsKey('id'), isFalse);
      });

      test('includes id when set', () {
        final json = _makeDevice(id: _deviceId1).toJson();
        expect(json.containsKey('id'), isTrue);
      });

      test('includes required fields', () {
        final json = _makeDevice(deviceName: 'Phone', deviceCode: 'X1').toJson();
        expect(json['deviceName'], 'Phone');
        expect(json['deviceCode'], 'X1');
        expect(json['nextInvoiceSequence'], 1);
        expect(json.containsKey('createdAt'), isTrue);
        expect(json.containsKey('lastActiveAt'), isTrue);
        expect(json.containsKey('platform'), isTrue);
      });

      test('omits syncOutboxItems when null', () {
        final json = _makeDevice().toJson();
        expect(json.containsKey('syncOutboxItems'), isFalse);
      });
    });

    group('fromJson', () {
      test('round-trip: toJson then fromJson preserves values', () {
        final original = _makeDevice(
          id: _deviceId1,
          deviceName: 'Round Trip',
          deviceCode: 'RT1',
          platform: DevicePlatform.WINDOWS,
          nextInvoiceSequence: 5,
        );
        final json = original.toJson();
        final restored = Device.fromJson(json);
        expect(restored.deviceName, original.deviceName);
        expect(restored.deviceCode, original.deviceCode);
        expect(restored.platform, original.platform);
        expect(restored.nextInvoiceSequence, original.nextInvoiceSequence);
        expect(restored.id, original.id);
      });

      test('parses minimal JSON without id', () {
        final device = Device.fromJson({
          'deviceName': 'Minimal',
          'platform': 'ANDROID',
          'deviceCode': 'MIN1',
          'nextInvoiceSequence': 1,
          'createdAt': _now.toIso8601String(),
          'lastActiveAt': _now.toIso8601String(),
        });
        expect(device.id, isNull);
        expect(device.deviceName, 'Minimal');
        expect(device.platform, DevicePlatform.ANDROID);
      });

      test('parses nextInvoiceSequence from JSON', () {
        final device = Device.fromJson({
          'deviceName': 'Dev',
          'platform': 'WINDOWS',
          'deviceCode': 'W1',
          'nextInvoiceSequence': 10,
          'createdAt': _now.toIso8601String(),
          'lastActiveAt': _now.toIso8601String(),
        });
        expect(device.nextInvoiceSequence, 10);
        expect(device.platform, DevicePlatform.WINDOWS);
      });

      test('syncOutboxItems is null when absent from JSON', () {
        final device = Device.fromJson({
          'deviceName': 'Dev',
          'platform': 'ANDROID',
          'deviceCode': 'D1',
          'nextInvoiceSequence': 1,
          'createdAt': _now.toIso8601String(),
          'lastActiveAt': _now.toIso8601String(),
        });
        expect(device.syncOutboxItems, isNull);
      });
    });

    group('copyWith', () {
      test('copies device with changed deviceName', () {
        final original = _makeDevice(deviceName: 'Original');
        final copy = original.copyWith(deviceName: 'Updated');
        expect(copy.deviceName, 'Updated');
        expect(copy.deviceCode, original.deviceCode);
        expect(copy.platform, original.platform);
      });

      test('copies device with changed platform', () {
        final original = _makeDevice(platform: DevicePlatform.ANDROID);
        final copy = original.copyWith(platform: DevicePlatform.WINDOWS);
        expect(copy.platform, DevicePlatform.WINDOWS);
      });

      test('copies device with changed nextInvoiceSequence', () {
        final original = _makeDevice();
        final copy = original.copyWith(nextInvoiceSequence: 99);
        expect(copy.nextInvoiceSequence, 99);
        expect(copy.deviceName, original.deviceName);
      });

      test('original is not mutated by copyWith', () {
        final original = _makeDevice(deviceName: 'Unchanged');
        original.copyWith(deviceName: 'Changed');
        expect(original.deviceName, 'Unchanged');
      });

      test('can set id via copyWith', () {
        final original = _makeDevice();
        final copy = original.copyWith(id: _uuid(_deviceId2));
        expect(copy.id, _uuid(_deviceId2));
      });

      test('preserves all fields when no arguments given', () {
        final original = _makeDevice(
          id: _deviceId1,
          deviceName: 'Preserved',
          platform: DevicePlatform.WINDOWS,
          deviceCode: 'PRS',
          nextInvoiceSequence: 7,
        );
        final copy = original.copyWith();
        expect(copy.deviceName, original.deviceName);
        expect(copy.deviceCode, original.deviceCode);
        expect(copy.platform, original.platform);
        expect(copy.nextInvoiceSequence, original.nextInvoiceSequence);
      });
    });
  });

  group('ClientRecord', () {
    ClientRecord _makeClientRecord({
      String? id,
      String displayName = 'Test Client',
      String? phone,
      String? note,
      String? clientCode,
      bool? isActive,
      int? rowVersion,
      SyncStatus? syncStatus,
      String deviceId = _deviceId1,
    }) {
      return ClientRecord(
        id: id != null ? _uuid(id) : null,
        displayName: displayName,
        phone: phone,
        note: note,
        clientCode: clientCode,
        isActive: isActive,
        createdAt: _now,
        updatedAt: _later,
        deviceId: _uuid(deviceId),
        rowVersion: rowVersion,
        syncStatus: syncStatus,
      );
    }

    group('construction', () {
      test('creates client record with required fields', () {
        final client = _makeClientRecord(displayName: 'John Doe');
        expect(client.displayName, 'John Doe');
        expect(client.id, isNull);
        expect(client.phone, isNull);
        expect(client.note, isNull);
        expect(client.clientCode, isNull);
        expect(client.device, isNull);
      });

      test('isActive defaults to true', () {
        final client = _makeClientRecord();
        expect(client.isActive, isTrue);
      });

      test('rowVersion defaults to 1', () {
        final client = _makeClientRecord();
        expect(client.rowVersion, 1);
      });

      test('syncStatus defaults to PENDING', () {
        final client = _makeClientRecord();
        expect(client.syncStatus, SyncStatus.PENDING);
      });

      test('optional fields can be set', () {
        final client = _makeClientRecord(
          phone: '+1234567890',
          note: 'VIP client',
          clientCode: 'CLI001',
        );
        expect(client.phone, '+1234567890');
        expect(client.note, 'VIP client');
        expect(client.clientCode, 'CLI001');
      });

      test('isActive can be set to false', () {
        final client = _makeClientRecord(isActive: false);
        expect(client.isActive, isFalse);
      });
    });

    group('toJson', () {
      test('includes __className__ = ClientRecord', () {
        final json = _makeClientRecord().toJson();
        expect(json['__className__'], 'ClientRecord');
      });

      test('omits optional null fields', () {
        final json = _makeClientRecord().toJson();
        expect(json.containsKey('id'), isFalse);
        expect(json.containsKey('phone'), isFalse);
        expect(json.containsKey('note'), isFalse);
        expect(json.containsKey('clientCode'), isFalse);
        expect(json.containsKey('device'), isFalse);
      });

      test('includes optional fields when set', () {
        final json = _makeClientRecord(
          phone: '555',
          note: 'note',
          clientCode: 'C1',
        ).toJson();
        expect(json['phone'], '555');
        expect(json['note'], 'note');
        expect(json['clientCode'], 'C1');
      });

      test('includes isActive, rowVersion, syncStatus', () {
        final json = _makeClientRecord().toJson();
        expect(json['isActive'], isTrue);
        expect(json['rowVersion'], 1);
        expect(json['syncStatus'], 'PENDING');
      });
    });

    group('fromJson', () {
      test('round-trip preserves all fields', () {
        final original = _makeClientRecord(
          id: _entityId1,
          displayName: 'Alice',
          phone: '999',
          note: 'note here',
          clientCode: 'A1',
          isActive: false,
          rowVersion: 3,
          syncStatus: SyncStatus.SYNCED,
        );
        final json = original.toJson();
        final restored = ClientRecord.fromJson(json);
        expect(restored.displayName, 'Alice');
        expect(restored.phone, '999');
        expect(restored.note, 'note here');
        expect(restored.clientCode, 'A1');
        expect(restored.isActive, isFalse);
        expect(restored.rowVersion, 3);
        expect(restored.syncStatus, SyncStatus.SYNCED);
        expect(restored.id, original.id);
      });

      test('uses default isActive=true when not in JSON', () {
        final client = ClientRecord.fromJson({
          'displayName': 'Bob',
          'createdAt': _now.toIso8601String(),
          'updatedAt': _later.toIso8601String(),
          'deviceId': _deviceId1,
          'rowVersion': 1,
          'syncStatus': 'PENDING',
        });
        expect(client.isActive, isTrue);
      });

      test('uses default syncStatus=PENDING when absent', () {
        final client = ClientRecord.fromJson({
          'displayName': 'Bob',
          'isActive': true,
          'createdAt': _now.toIso8601String(),
          'updatedAt': _later.toIso8601String(),
          'deviceId': _deviceId1,
          'rowVersion': 1,
        });
        expect(client.syncStatus, SyncStatus.PENDING);
      });
    });

    group('copyWith', () {
      test('updates displayName', () {
        final original = _makeClientRecord(displayName: 'Old Name');
        final copy = original.copyWith(displayName: 'New Name');
        expect(copy.displayName, 'New Name');
      });

      test('updates syncStatus', () {
        final original = _makeClientRecord();
        final copy = original.copyWith(syncStatus: SyncStatus.SYNCED);
        expect(copy.syncStatus, SyncStatus.SYNCED);
        expect(copy.displayName, original.displayName);
      });

      test('updates isActive', () {
        final original = _makeClientRecord(isActive: true);
        final copy = original.copyWith(isActive: false);
        expect(copy.isActive, isFalse);
      });

      test('preserves unchanged fields', () {
        final original = _makeClientRecord(
          displayName: 'Preserved',
          phone: '123',
          rowVersion: 5,
        );
        final copy = original.copyWith(note: 'added note');
        expect(copy.displayName, 'Preserved');
        expect(copy.phone, '123');
        expect(copy.rowVersion, 5);
        expect(copy.note, 'added note');
      });

      test('can set phone to null explicitly', () {
        final original = _makeClientRecord(phone: '123');
        final copy = original.copyWith(phone: null);
        expect(copy.phone, isNull);
      });
    });
  });

  group('Product', () {
    Product _makeProduct({
      String? id,
      String name = 'Test Product',
      String? description,
      int defaultSalePrice = 1000,
      bool? isActive,
      int? rowVersion,
      SyncStatus? syncStatus,
      String deviceId = _deviceId1,
    }) {
      return Product(
        id: id != null ? _uuid(id) : null,
        name: name,
        description: description,
        defaultSalePrice: defaultSalePrice,
        isActive: isActive,
        createdAt: _now,
        updatedAt: _later,
        deviceId: _uuid(deviceId),
        rowVersion: rowVersion,
        syncStatus: syncStatus,
      );
    }

    group('construction', () {
      test('creates product with required fields', () {
        final product = _makeProduct(name: 'Widget', defaultSalePrice: 500);
        expect(product.name, 'Widget');
        expect(product.defaultSalePrice, 500);
        expect(product.description, isNull);
        expect(product.id, isNull);
      });

      test('isActive defaults to true', () {
        expect(_makeProduct().isActive, isTrue);
      });

      test('rowVersion defaults to 1', () {
        expect(_makeProduct().rowVersion, 1);
      });

      test('syncStatus defaults to PENDING', () {
        expect(_makeProduct().syncStatus, SyncStatus.PENDING);
      });

      test('optional description can be set', () {
        final product = _makeProduct(description: 'A widget');
        expect(product.description, 'A widget');
      });
    });

    group('toJson', () {
      test('includes __className__ = Product', () {
        final json = _makeProduct().toJson();
        expect(json['__className__'], 'Product');
      });

      test('omits id when null', () {
        final json = _makeProduct().toJson();
        expect(json.containsKey('id'), isFalse);
      });

      test('omits description when null', () {
        final json = _makeProduct().toJson();
        expect(json.containsKey('description'), isFalse);
      });

      test('includes description when set', () {
        final json = _makeProduct(description: 'desc').toJson();
        expect(json['description'], 'desc');
      });

      test('includes isActive, rowVersion, syncStatus', () {
        final json = _makeProduct().toJson();
        expect(json['isActive'], isTrue);
        expect(json['rowVersion'], 1);
        expect(json['syncStatus'], 'PENDING');
        expect(json['name'], 'Test Product');
        expect(json['defaultSalePrice'], 1000);
      });

      test('omits device when null', () {
        final json = _makeProduct().toJson();
        expect(json.containsKey('device'), isFalse);
      });
    });

    group('fromJson', () {
      test('round-trip preserves all fields', () {
        final original = _makeProduct(
          id: _entityId1,
          name: 'Gadget',
          description: 'A gadget',
          defaultSalePrice: 2500,
          isActive: false,
          rowVersion: 2,
          syncStatus: SyncStatus.CONFLICT,
        );
        final json = original.toJson();
        final restored = Product.fromJson(json);
        expect(restored.name, 'Gadget');
        expect(restored.description, 'A gadget');
        expect(restored.defaultSalePrice, 2500);
        expect(restored.isActive, isFalse);
        expect(restored.rowVersion, 2);
        expect(restored.syncStatus, SyncStatus.CONFLICT);
        expect(restored.id, original.id);
      });

      test('description is null when absent from JSON', () {
        final product = Product.fromJson({
          'name': 'Simple',
          'defaultSalePrice': 100,
          'isActive': true,
          'createdAt': _now.toIso8601String(),
          'updatedAt': _later.toIso8601String(),
          'deviceId': _deviceId1,
          'rowVersion': 1,
          'syncStatus': 'PENDING',
        });
        expect(product.description, isNull);
      });
    });

    group('copyWith', () {
      test('updates name', () {
        final original = _makeProduct(name: 'Old');
        final copy = original.copyWith(name: 'New');
        expect(copy.name, 'New');
      });

      test('updates defaultSalePrice', () {
        final original = _makeProduct(defaultSalePrice: 100);
        final copy = original.copyWith(defaultSalePrice: 200);
        expect(copy.defaultSalePrice, 200);
        expect(copy.name, original.name);
      });

      test('can set description to null', () {
        final original = _makeProduct(description: 'old desc');
        final copy = original.copyWith(description: null);
        expect(copy.description, isNull);
      });

      test('can update isActive and syncStatus together', () {
        final original = _makeProduct();
        final copy = original.copyWith(
          isActive: false,
          syncStatus: SyncStatus.FAILED,
        );
        expect(copy.isActive, isFalse);
        expect(copy.syncStatus, SyncStatus.FAILED);
        expect(copy.name, original.name);
      });

      test('preserves all fields when no arguments given', () {
        final original = _makeProduct(
          name: 'Stable',
          defaultSalePrice: 999,
          rowVersion: 4,
        );
        final copy = original.copyWith();
        expect(copy.name, original.name);
        expect(copy.defaultSalePrice, original.defaultSalePrice);
        expect(copy.rowVersion, original.rowVersion);
      });
    });
  });
}