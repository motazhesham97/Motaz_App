import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'device_service.dart';

final currentDeviceProvider = FutureProvider((ref) async {
  return ref.watch(deviceServiceProvider).currentDevice();
});
