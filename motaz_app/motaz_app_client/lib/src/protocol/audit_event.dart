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
import 'enums/parent_entity_type.dart' as _i2;
import 'enums/audit_operation.dart' as _i3;
import 'device.dart' as _i4;
import 'package:motaz_app_client/src/protocol/protocol.dart' as _i5;

abstract class AuditEvent implements _i1.SerializableModel {
  AuditEvent._({
    this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.diffData,
    required this.deviceId,
    this.device,
    required this.createdAt,
  });

  factory AuditEvent({
    _i1.UuidValue? id,
    required _i2.ParentEntityType entityType,
    required _i1.UuidValue entityId,
    required _i3.AuditOperation operation,
    required String diffData,
    required _i1.UuidValue deviceId,
    _i4.Device? device,
    required DateTime createdAt,
  }) = _AuditEventImpl;

  factory AuditEvent.fromJson(Map<String, dynamic> jsonSerialization) {
    return AuditEvent(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      entityType: _i2.ParentEntityType.fromJson(
        (jsonSerialization['entityType'] as String),
      ),
      entityId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['entityId'],
      ),
      operation: _i3.AuditOperation.fromJson(
        (jsonSerialization['operation'] as String),
      ),
      diffData: jsonSerialization['diffData'] as String,
      deviceId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['deviceId'],
      ),
      device: jsonSerialization['device'] == null
          ? null
          : _i5.Protocol().deserialize<_i4.Device>(jsonSerialization['device']),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _i1.UuidValue? id;

  _i2.ParentEntityType entityType;

  _i1.UuidValue entityId;

  _i3.AuditOperation operation;

  String diffData;

  _i1.UuidValue deviceId;

  _i4.Device? device;

  DateTime createdAt;

  /// Returns a shallow copy of this [AuditEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AuditEvent copyWith({
    _i1.UuidValue? id,
    _i2.ParentEntityType? entityType,
    _i1.UuidValue? entityId,
    _i3.AuditOperation? operation,
    String? diffData,
    _i1.UuidValue? deviceId,
    _i4.Device? device,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AuditEvent',
      if (id != null) 'id': id?.toJson(),
      'entityType': entityType.toJson(),
      'entityId': entityId.toJson(),
      'operation': operation.toJson(),
      'diffData': diffData,
      'deviceId': deviceId.toJson(),
      if (device != null) 'device': device?.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AuditEventImpl extends AuditEvent {
  _AuditEventImpl({
    _i1.UuidValue? id,
    required _i2.ParentEntityType entityType,
    required _i1.UuidValue entityId,
    required _i3.AuditOperation operation,
    required String diffData,
    required _i1.UuidValue deviceId,
    _i4.Device? device,
    required DateTime createdAt,
  }) : super._(
         id: id,
         entityType: entityType,
         entityId: entityId,
         operation: operation,
         diffData: diffData,
         deviceId: deviceId,
         device: device,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [AuditEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AuditEvent copyWith({
    Object? id = _Undefined,
    _i2.ParentEntityType? entityType,
    _i1.UuidValue? entityId,
    _i3.AuditOperation? operation,
    String? diffData,
    _i1.UuidValue? deviceId,
    Object? device = _Undefined,
    DateTime? createdAt,
  }) {
    return AuditEvent(
      id: id is _i1.UuidValue? ? id : this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      diffData: diffData ?? this.diffData,
      deviceId: deviceId ?? this.deviceId,
      device: device is _i4.Device? ? device : this.device?.copyWith(),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
