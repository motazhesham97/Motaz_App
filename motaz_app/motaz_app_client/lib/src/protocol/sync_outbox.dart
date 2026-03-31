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
import 'enums/sync_outbox_status.dart' as _i2;
import 'enums/parent_entity_type.dart' as _i3;
import 'enums/audit_operation.dart' as _i4;
import 'device.dart' as _i5;
import 'package:motaz_app_client/src/protocol/protocol.dart' as _i6;

abstract class SyncOutbox implements _i1.SerializableModel {
  SyncOutbox._({
    this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.rowVersion,
    required this.deviceId,
    this.device,
    int? retryCount,
    _i2.SyncOutboxStatus? status,
    required this.createdAt,
  }) : retryCount = retryCount ?? 0,
       status = status ?? _i2.SyncOutboxStatus.PENDING;

  factory SyncOutbox({
    _i1.UuidValue? id,
    required _i3.ParentEntityType entityType,
    required _i1.UuidValue entityId,
    required _i4.AuditOperation operation,
    required String payload,
    required int rowVersion,
    required _i1.UuidValue deviceId,
    _i5.Device? device,
    int? retryCount,
    _i2.SyncOutboxStatus? status,
    required DateTime createdAt,
  }) = _SyncOutboxImpl;

  factory SyncOutbox.fromJson(Map<String, dynamic> jsonSerialization) {
    return SyncOutbox(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      entityType: _i3.ParentEntityType.fromJson(
        (jsonSerialization['entityType'] as String),
      ),
      entityId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['entityId'],
      ),
      operation: _i4.AuditOperation.fromJson(
        (jsonSerialization['operation'] as String),
      ),
      payload: jsonSerialization['payload'] as String,
      rowVersion: jsonSerialization['rowVersion'] as int,
      deviceId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['deviceId'],
      ),
      device: jsonSerialization['device'] == null
          ? null
          : _i6.Protocol().deserialize<_i5.Device>(jsonSerialization['device']),
      retryCount: jsonSerialization['retryCount'] as int?,
      status: jsonSerialization['status'] == null
          ? null
          : _i2.SyncOutboxStatus.fromJson(
              (jsonSerialization['status'] as String),
            ),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _i1.UuidValue? id;

  _i3.ParentEntityType entityType;

  _i1.UuidValue entityId;

  _i4.AuditOperation operation;

  String payload;

  int rowVersion;

  _i1.UuidValue deviceId;

  _i5.Device? device;

  int retryCount;

  _i2.SyncOutboxStatus status;

  DateTime createdAt;

  /// Returns a shallow copy of this [SyncOutbox]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SyncOutbox copyWith({
    _i1.UuidValue? id,
    _i3.ParentEntityType? entityType,
    _i1.UuidValue? entityId,
    _i4.AuditOperation? operation,
    String? payload,
    int? rowVersion,
    _i1.UuidValue? deviceId,
    _i5.Device? device,
    int? retryCount,
    _i2.SyncOutboxStatus? status,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SyncOutbox',
      if (id != null) 'id': id?.toJson(),
      'entityType': entityType.toJson(),
      'entityId': entityId.toJson(),
      'operation': operation.toJson(),
      'payload': payload,
      'rowVersion': rowVersion,
      'deviceId': deviceId.toJson(),
      if (device != null) 'device': device?.toJson(),
      'retryCount': retryCount,
      'status': status.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SyncOutboxImpl extends SyncOutbox {
  _SyncOutboxImpl({
    _i1.UuidValue? id,
    required _i3.ParentEntityType entityType,
    required _i1.UuidValue entityId,
    required _i4.AuditOperation operation,
    required String payload,
    required int rowVersion,
    required _i1.UuidValue deviceId,
    _i5.Device? device,
    int? retryCount,
    _i2.SyncOutboxStatus? status,
    required DateTime createdAt,
  }) : super._(
         id: id,
         entityType: entityType,
         entityId: entityId,
         operation: operation,
         payload: payload,
         rowVersion: rowVersion,
         deviceId: deviceId,
         device: device,
         retryCount: retryCount,
         status: status,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [SyncOutbox]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SyncOutbox copyWith({
    Object? id = _Undefined,
    _i3.ParentEntityType? entityType,
    _i1.UuidValue? entityId,
    _i4.AuditOperation? operation,
    String? payload,
    int? rowVersion,
    _i1.UuidValue? deviceId,
    Object? device = _Undefined,
    int? retryCount,
    _i2.SyncOutboxStatus? status,
    DateTime? createdAt,
  }) {
    return SyncOutbox(
      id: id is _i1.UuidValue? ? id : this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      rowVersion: rowVersion ?? this.rowVersion,
      deviceId: deviceId ?? this.deviceId,
      device: device is _i5.Device? ? device : this.device?.copyWith(),
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
