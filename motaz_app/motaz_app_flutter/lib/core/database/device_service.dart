import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../logging/app_logger.dart';
import 'app_database.dart';
import 'database_provider.dart';
import 'enums/device_platform.dart';

class DeviceService {
  DeviceService(this._db);

  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  Future<Device> ensureCurrentDevice() async {
    final existing = await _db.select(_db.devices).getSingleOrNull();
    if (existing != null) {
      await (_db.update(_db.devices)..where((tbl) => tbl.id.equals(existing.id)))
          .write(DevicesCompanion(lastActiveAt: Value(DateTime.now())));
      return (await (_db.select(_db.devices)..where((tbl) => tbl.id.equals(existing.id))).getSingle());
    }

    final id = _uuid.v4();
    final now = DateTime.now();
    final code = id.replaceAll('-', '').substring(0, 4).toUpperCase();
    final platform = Platform.isWindows
        ? DevicePlatform.WINDOWS
        : DevicePlatform.ANDROID;

    await _db.into(_db.devices).insert(
      DevicesCompanion(
        id: Value(id),
        deviceName: Value(Platform.localHostname),
        platform: Value(platform),
        deviceCode: Value(code),
        createdAt: Value(now),
        lastActiveAt: Value(now),
      ),
    );
    AppLogger.database.info('Created local device identity $id');
    return (await (_db.select(_db.devices)..where((tbl) => tbl.id.equals(id))).getSingle());
  }

  Future<Device?> currentDevice() {
    return _db.select(_db.devices).getSingleOrNull();
  }
}

final deviceServiceProvider = Provider<DeviceService>((ref) {
  return DeviceService(ref.watch(appDatabaseProvider));
});
