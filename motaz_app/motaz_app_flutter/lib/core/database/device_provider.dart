import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database_provider.dart';
import 'device_service.dart';

final currentDeviceProvider = StreamProvider((ref) async* {
  final db = ref.watch(appDatabaseProvider);
  final device = await ref.watch(deviceServiceProvider).ensureCurrentDevice();
  final query = db.select(db.devices)
    ..where((tbl) => tbl.id.equals(device.id))
    ..limit(1);
  yield* query.watchSingleOrNull();
});
