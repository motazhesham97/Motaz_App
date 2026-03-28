import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'device_service.dart';
import 'database_provider.dart';

final deviceServiceProvider = Provider<DeviceService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DeviceService(db);
});

final deviceProvider = FutureProvider<Device>((ref) async {
  final deviceService = ref.watch(deviceServiceProvider);
  return await deviceService.getOrCreateDevice();
});

final deviceIdProvider = FutureProvider<String?>((ref) async {
  final device = await ref.watch(deviceProvider.future);
  return device.id;
});
