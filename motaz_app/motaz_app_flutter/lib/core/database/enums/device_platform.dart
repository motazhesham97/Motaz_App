// ignore_for_file: constant_identifier_names

import 'package:drift/drift.dart';

enum DevicePlatform {
  ANDROID,
  WINDOWS,
}

class DevicePlatformConverter extends TypeConverter<DevicePlatform, int> {
  const DevicePlatformConverter();

  @override
  DevicePlatform fromSql(int fromDb) {
    if (fromDb >= 0 && fromDb < DevicePlatform.values.length) {
      return DevicePlatform.values[fromDb];
    }
    assert(false, 'Unknown DevicePlatform database value: $fromDb');
    return DevicePlatform.ANDROID;
  }

  @override
  int toSql(DevicePlatform value) {
    return value.index;
  }
}
