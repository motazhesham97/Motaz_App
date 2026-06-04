import 'package:serverpod/serverpod.dart';

import '../generated/device.dart';
import '../generated/device_registration_request.dart';
import '../generated/device_registration_response.dart';
import '../generated/enums/device_platform.dart';

class DeviceEndpoint extends Endpoint {
  Future<DeviceRegistrationResponse> registerDevice(
    Session session,
    DeviceRegistrationRequest request,
  ) async {
    if (!session.isUserSignedIn) {
      return DeviceRegistrationResponse(
        success: false,
        errorMessage: 'Authentication required',
      );
    }

    final now = DateTime.now().toUtc();
    final uuid = UuidValue.fromString(request.deviceId);
    final existing = await Device.db.findById(session, uuid);

    if (existing != null) {
      final updated = existing.copyWith(
        lastActiveAt: now,
        deviceName: request.deviceName,
      );
      await Device.db.updateRow(session, updated);
      return DeviceRegistrationResponse(success: true);
    }

    final device = Device(
      id: uuid,
      deviceName: request.deviceName,
      platform: DevicePlatform.values.firstWhere(
        (e) => e.name == request.platform,
        orElse: () => DevicePlatform.ANDROID,
      ),
      deviceCode: request.deviceCode,
      createdAt: now,
      lastActiveAt: now,
    );

    await Device.db.insertRow(session, device);
    return DeviceRegistrationResponse(success: true);
  }
}
