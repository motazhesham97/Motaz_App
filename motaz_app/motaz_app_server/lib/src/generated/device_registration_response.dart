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

abstract class DeviceRegistrationResponse
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  DeviceRegistrationResponse._({
    required this.success,
    this.errorMessage,
  });

  factory DeviceRegistrationResponse({
    required bool success,
    String? errorMessage,
  }) = _DeviceRegistrationResponseImpl;

  factory DeviceRegistrationResponse.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return DeviceRegistrationResponse(
      success: _i1.BoolJsonExtension.fromJson(jsonSerialization['success']),
      errorMessage: jsonSerialization['errorMessage'] as String?,
    );
  }

  bool success;

  String? errorMessage;

  /// Returns a shallow copy of this [DeviceRegistrationResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DeviceRegistrationResponse copyWith({
    bool? success,
    String? errorMessage,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DeviceRegistrationResponse',
      'success': success,
      if (errorMessage != null) 'errorMessage': errorMessage,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DeviceRegistrationResponse',
      'success': success,
      if (errorMessage != null) 'errorMessage': errorMessage,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DeviceRegistrationResponseImpl extends DeviceRegistrationResponse {
  _DeviceRegistrationResponseImpl({
    required bool success,
    String? errorMessage,
  }) : super._(
         success: success,
         errorMessage: errorMessage,
       );

  /// Returns a shallow copy of this [DeviceRegistrationResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DeviceRegistrationResponse copyWith({
    bool? success,
    Object? errorMessage = _Undefined,
  }) {
    return DeviceRegistrationResponse(
      success: success ?? this.success,
      errorMessage: errorMessage is String? ? errorMessage : this.errorMessage,
    );
  }
}
