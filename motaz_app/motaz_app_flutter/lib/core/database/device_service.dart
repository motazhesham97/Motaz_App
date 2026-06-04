import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../logging/app_logger.dart';
import 'app_database.dart';
import 'database_provider.dart';
import 'enums/device_platform.dart';

class DeviceService {
  DeviceService(this._db);

  final AppDatabase _db;
  final Uuid _uuid = const Uuid();
  static const _currentDeviceIdKey = 'motaz_current_device_id';

  Future<Device> ensureCurrentDevice() async {
    final deviceName = await _currentDeviceName();
    final existing = await _findCurrentDevice(deviceName);
    if (existing != null) {
      final now = DateTime.now();
      await (_db.update(
        _db.devices,
      )..where((tbl) => tbl.id.equals(existing.id))).write(
        DevicesCompanion(
          deviceName: Value(deviceName),
          lastActiveAt: Value(now),
        ),
      );
      await _rememberCurrentDevice(existing.id);
      return (await (_db.select(
        _db.devices,
      )..where((tbl) => tbl.id.equals(existing.id))).getSingle());
    }

    final id = _uuid.v4();
    final now = DateTime.now();
    final code = await _uniqueDeviceCodeFor(id);
    final platform = _currentPlatform;

    await _db
        .into(_db.devices)
        .insert(
          DevicesCompanion(
            id: Value(id),
            deviceName: Value(deviceName),
            platform: Value(platform),
            deviceCode: Value(code),
            createdAt: Value(now),
            lastActiveAt: Value(now),
          ),
        );
    await _rememberCurrentDevice(id);
    AppLogger.database.info('Created local device identity $id');
    return (await (_db.select(
      _db.devices,
    )..where((tbl) => tbl.id.equals(id))).getSingle());
  }

  Future<Device?> currentDevice() async {
    return _findCurrentDevice(await _currentDeviceName());
  }

  DevicePlatform get _currentPlatform {
    return Platform.isWindows ? DevicePlatform.WINDOWS : DevicePlatform.ANDROID;
  }

  Future<Device?> _findCurrentDevice(String deviceName) async {
    final platform = _currentPlatform;
    final prefs = await SharedPreferences.getInstance();
    final storedId = prefs.getString(_currentDeviceIdKey);

    if (storedId != null && storedId.isNotEmpty) {
      final stored =
          await (_db.select(_db.devices)
                ..where(
                  (tbl) =>
                      tbl.id.equals(storedId) &
                      tbl.platform.equals(platform.index),
                )
                ..limit(1))
              .getSingleOrNull();
      if (stored != null) return stored;
    }

    final byHost =
        await (_db.select(_db.devices)
              ..where(
                (tbl) =>
                    tbl.platform.equals(platform.index) &
                    tbl.deviceName.equals(deviceName),
              )
              ..limit(1))
            .getSingleOrNull();
    if (byHost != null) {
      await _rememberCurrentDevice(byHost.id);
      return byHost;
    }

    final byPlatform =
        await (_db.select(_db.devices)
              ..where(
                (tbl) =>
                    tbl.platform.equals(platform.index) &
                    tbl.deviceName.like('Synced device %').not(),
              )
              ..limit(1))
            .getSingleOrNull();
    if (byPlatform != null) {
      await _rememberCurrentDevice(byPlatform.id);
      return byPlatform;
    }

    return null;
  }

  Future<void> _rememberCurrentDevice(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentDeviceIdKey, id);
  }

  Future<String> _currentDeviceName() async {
    if (Platform.isWindows) {
      final computerName = Platform.environment['COMPUTERNAME']?.trim();
      if (computerName != null && computerName.isNotEmpty) {
        return computerName;
      }
    }

    if (Platform.isAndroid) {
      try {
        final info = await DeviceInfoPlugin().androidInfo;
        final manufacturer = info.manufacturer.trim();
        final model = info.model.trim();
        if (model.isNotEmpty) {
          if (manufacturer.isNotEmpty &&
              !model.toLowerCase().contains(manufacturer.toLowerCase())) {
            return '$manufacturer $model';
          }
          return model;
        }
      } catch (error) {
        AppLogger.database.warning(
          'Could not read Android device info: $error',
        );
      }
    }

    final hostName = Platform.localHostname.trim();
    if (hostName.isNotEmpty && hostName.toLowerCase() != 'localhost') {
      return hostName;
    }
    return Platform.isAndroid ? 'Android device' : 'Unknown device';
  }

  Future<String> _uniqueDeviceCodeFor(String deviceId) async {
    final compact = deviceId.replaceAll('-', '').toUpperCase();
    final candidates = <String>[];
    for (var i = 0; i + 4 <= compact.length; i += 4) {
      candidates.add(compact.substring(i, i + 4));
    }
    for (var i = 1; i <= 9999; i++) {
      candidates.add(i.toString().padLeft(4, '0'));
    }

    for (final candidate in candidates) {
      final existing =
          await (_db.select(_db.devices)
                ..where((tbl) => tbl.deviceCode.equals(candidate))
                ..limit(1))
              .getSingleOrNull();
      if (existing == null || existing.id == deviceId) {
        return candidate;
      }
    }
    return compact.substring(0, 4);
  }
}

final deviceServiceProvider = Provider<DeviceService>((ref) {
  return DeviceService(ref.watch(appDatabaseProvider));
});
