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
import 'package:serverpod_client/serverpod_client.dart' as _i1;

abstract class PushRequest implements _i1.SerializableModel {
  PushRequest._({
    required this.outboxId,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.rowVersion,
    required this.deviceId,
  });

  factory PushRequest({
    required String outboxId,
    required String entityType,
    required String entityId,
    required String operation,
    required String payload,
    required int rowVersion,
    required String deviceId,
  }) = _PushRequestImpl;

  factory PushRequest.fromJson(Map<String, dynamic> jsonSerialization) {
    return PushRequest(
      outboxId: jsonSerialization['outboxId'] as String,
      entityType: jsonSerialization['entityType'] as String,
      entityId: jsonSerialization['entityId'] as String,
      operation: jsonSerialization['operation'] as String,
      payload: jsonSerialization['payload'] as String,
      rowVersion: jsonSerialization['rowVersion'] as int,
      deviceId: jsonSerialization['deviceId'] as String,
    );
  }

  String outboxId;

  String entityType;

  String entityId;

  String operation;

  String payload;

  int rowVersion;

  String deviceId;

  /// Returns a shallow copy of this [PushRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PushRequest copyWith({
    String? outboxId,
    String? entityType,
    String? entityId,
    String? operation,
    String? payload,
    int? rowVersion,
    String? deviceId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PushRequest',
      'outboxId': outboxId,
      'entityType': entityType,
      'entityId': entityId,
      'operation': operation,
      'payload': payload,
      'rowVersion': rowVersion,
      'deviceId': deviceId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _PushRequestImpl extends PushRequest {
  _PushRequestImpl({
    required String outboxId,
    required String entityType,
    required String entityId,
    required String operation,
    required String payload,
    required int rowVersion,
    required String deviceId,
  }) : super._(
         outboxId: outboxId,
         entityType: entityType,
         entityId: entityId,
         operation: operation,
         payload: payload,
         rowVersion: rowVersion,
         deviceId: deviceId,
       );

  /// Returns a shallow copy of this [PushRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PushRequest copyWith({
    String? outboxId,
    String? entityType,
    String? entityId,
    String? operation,
    String? payload,
    int? rowVersion,
    String? deviceId,
  }) {
    return PushRequest(
      outboxId: outboxId ?? this.outboxId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      rowVersion: rowVersion ?? this.rowVersion,
      deviceId: deviceId ?? this.deviceId,
    );
  }
}
