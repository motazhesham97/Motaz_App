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
    return DevicePlatform.values[fromDb];
  }

  @override
  int toSql(DevicePlatform value) {
    return value.index;
  }
}
