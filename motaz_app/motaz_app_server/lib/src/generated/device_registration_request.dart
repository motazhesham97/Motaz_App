/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;

abstract class DeviceRegistrationRequest
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  DeviceRegistrationRequest._({
    required this.deviceId,
    required this.deviceCode,
    required this.platform,
    required this.deviceName,
  });

  factory DeviceRegistrationRequest({
    required String deviceId,
    required String deviceCode,
    required String platform,
    required String deviceName,
  }) = _DeviceRegistrationRequestImpl;

  factory DeviceRegistrationRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return DeviceRegistrationRequest(
      deviceId: jsonSerialization['deviceId'] as String,
      deviceCode: jsonSerialization['deviceCode'] as String,
      platform: jsonSerialization['platform'] as String,
      deviceName: jsonSerialization['deviceName'] as String,
    );
  }

  String deviceId;

  String deviceCode;

  String platform;

  String deviceName;

  /// Returns a shallow copy of this [DeviceRegistrationRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DeviceRegistrationRequest copyWith({
    String? deviceId,
    String? deviceCode,
    String? platform,
    String? deviceName,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DeviceRegistrationRequest',
      'deviceId': deviceId,
      'deviceCode': deviceCode,
      'platform': platform,
      'deviceName': deviceName,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DeviceRegistrationRequest',
      'deviceId': deviceId,
      'deviceCode': deviceCode,
      'platform': platform,
      'deviceName': deviceName,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _DeviceRegistrationRequestImpl extends DeviceRegistrationRequest {
  _DeviceRegistrationRequestImpl({
    required String deviceId,
    required String deviceCode,
    required String platform,
    required String deviceName,
  }) : super._(
         deviceId: deviceId,
         deviceCode: deviceCode,
         platform: platform,
         deviceName: deviceName,
       );

  /// Returns a shallow copy of this [DeviceRegistrationRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DeviceRegistrationRequest copyWith({
    String? deviceId,
    String? deviceCode,
    String? platform,
    String? deviceName,
  }) {
    return DeviceRegistrationRequest(
      deviceId: deviceId ?? this.deviceId,
      deviceCode: deviceCode ?? this.deviceCode,
      platform: platform ?? this.platform,
      deviceName: deviceName ?? this.deviceName,
    );
  }
}
