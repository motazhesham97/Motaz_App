import 'dart:io';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'app_database.dart';
import '../logging/app_logger.dart';

class DeviceService {
  final AppDatabase _db;
  final Uuid _uuid;

  DeviceService(this._db, [Uuid? uuid]) : _uuid = uuid ?? const Uuid();

  Future<Device> getOrCreateDevice() async {
    final existing = await _getExistingDevice();
    if (existing != null) {
      await _updateLastActive(existing.id);
      AppLog.db('Reused existing device identity ${existing.id}');
      return existing;
    }

    return await _createNewDevice();
  }

  Future<Device?> _getExistingDevice() async {
    final devices = await _db.select(_db.devices).get();
    if (devices.isEmpty) return null;
    return devices.first;
  }

  Future<void> _updateLastActive(String deviceId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.devices)..where((t) => t.id.equals(deviceId))).write(
      DevicesCompanion(lastActiveAt: Value(now)),
    );
    AppLog.db('Updated device last_active_at for $deviceId');
  }

  Future<Device> _createNewDevice() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final platform = Platform.isAndroid ? 'android' : 'windows';
    final deviceName = await _getDeviceName(platform);
    final id = _uuid.v4();

    await _db
        .into(_db.devices)
        .insert(
          DevicesCompanion.insert(
            id: id,
            deviceName: deviceName,
            platform: platform,
            createdAt: now,
            lastActiveAt: now,
          ),
        );

    AppLog.db('Created new device identity $id for platform $platform');

    return await _db.select(_db.devices).getSingle();
  }

  Future<String> _getDeviceName(String platform) async {
    try {
      if (platform == 'android') {
        final model =
            Platform.environment['PRODUCT'] ??
            Platform.environment['MODEL'] ??
            'Android';
        return 'Android - $model';
      } else if (platform == 'windows') {
        final hostname =
            Platform.environment['COMPUTERNAME'] ?? Platform.localHostname;
        final user = Platform.environment['USERNAME'] ?? '';
        return user.isNotEmpty
            ? 'Windows - $hostname ($user)'
            : 'Windows - $hostname';
      }
      return 'Unknown Device';
    } catch (_) {
      return 'Unknown Device';
    }
  }

  Future<String?> getDeviceId() async {
    final device = await _getExistingDevice();
    return device?.id;
  }

  Future<Device?> getDevice() async {
    return await _getExistingDevice();
  }

  Future<void> updateDeviceName(String newName) async {
    final device = await _getExistingDevice();
    if (device != null) {
      await (_db.update(_db.devices)..where((t) => t.id.equals(device.id)))
          .write(DevicesCompanion(deviceName: Value(newName)));
    }
  }
}
