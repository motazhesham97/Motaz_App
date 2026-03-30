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
import 'enums/conflict_status.dart' as _i2;
import 'enums/parent_entity_type.dart' as _i3;
import 'device.dart' as _i4;
import 'package:motaz_app_client/src/protocol/protocol.dart' as _i5;

abstract class ConflictLog implements _i1.SerializableModel {
  ConflictLog._({
    this.id,
    required this.entityType,
    required this.entityId,
    required this.localPayload,
    required this.remotePayload,
    required this.conflictType,
    _i2.ConflictStatus? resolutionStatus,
    this.resolvedAt,
    this.resolutionData,
    required this.createdAt,
    required this.deviceId,
    this.device,
  }) : resolutionStatus = resolutionStatus ?? _i2.ConflictStatus.PENDING;

  factory ConflictLog({
    _i1.UuidValue? id,
    required _i3.ParentEntityType entityType,
    required _i1.UuidValue entityId,
    required String localPayload,
    required String remotePayload,
    required String conflictType,
    _i2.ConflictStatus? resolutionStatus,
    DateTime? resolvedAt,
    String? resolutionData,
    required DateTime createdAt,
    required _i1.UuidValue deviceId,
    _i4.Device? device,
  }) = _ConflictLogImpl;

  factory ConflictLog.fromJson(Map<String, dynamic> jsonSerialization) {
    return ConflictLog(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      entityType: _i3.ParentEntityType.fromJson(
        (jsonSerialization['entityType'] as String),
      ),
      entityId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['entityId'],
      ),
      localPayload: jsonSerialization['localPayload'] as String,
      remotePayload: jsonSerialization['remotePayload'] as String,
      conflictType: jsonSerialization['conflictType'] as String,
      resolutionStatus: jsonSerialization['resolutionStatus'] == null
          ? null
          : _i2.ConflictStatus.fromJson(
              (jsonSerialization['resolutionStatus'] as String),
            ),
      resolvedAt: jsonSerialization['resolvedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['resolvedAt']),
      resolutionData: jsonSerialization['resolutionData'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      deviceId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['deviceId'],
      ),
      device: jsonSerialization['device'] == null
          ? null
          : _i5.Protocol().deserialize<_i4.Device>(jsonSerialization['device']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _i1.UuidValue? id;

  _i3.ParentEntityType entityType;

  _i1.UuidValue entityId;

  String localPayload;

  String remotePayload;

  String conflictType;

  _i2.ConflictStatus resolutionStatus;

  DateTime? resolvedAt;

  String? resolutionData;

  DateTime createdAt;

  _i1.UuidValue deviceId;

  _i4.Device? device;

  /// Returns a shallow copy of this [ConflictLog]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ConflictLog copyWith({
    _i1.UuidValue? id,
    _i3.ParentEntityType? entityType,
    _i1.UuidValue? entityId,
    String? localPayload,
    String? remotePayload,
    String? conflictType,
    _i2.ConflictStatus? resolutionStatus,
    DateTime? resolvedAt,
    String? resolutionData,
    DateTime? createdAt,
    _i1.UuidValue? deviceId,
    _i4.Device? device,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConflictLog',
      if (id != null) 'id': id?.toJson(),
      'entityType': entityType.toJson(),
      'entityId': entityId.toJson(),
      'localPayload': localPayload,
      'remotePayload': remotePayload,
      'conflictType': conflictType,
      'resolutionStatus': resolutionStatus.toJson(),
      if (resolvedAt != null) 'resolvedAt': resolvedAt?.toJson(),
      if (resolutionData != null) 'resolutionData': resolutionData,
      'createdAt': createdAt.toJson(),
      'deviceId': deviceId.toJson(),
      if (device != null) 'device': device?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ConflictLogImpl extends ConflictLog {
  _ConflictLogImpl({
    _i1.UuidValue? id,
    required _i3.ParentEntityType entityType,
    required _i1.UuidValue entityId,
    required String localPayload,
    required String remotePayload,
    required String conflictType,
    _i2.ConflictStatus? resolutionStatus,
    DateTime? resolvedAt,
    String? resolutionData,
    required DateTime createdAt,
    required _i1.UuidValue deviceId,
    _i4.Device? device,
  }) : super._(
         id: id,
         entityType: entityType,
         entityId: entityId,
         localPayload: localPayload,
         remotePayload: remotePayload,
         conflictType: conflictType,
         resolutionStatus: resolutionStatus,
         resolvedAt: resolvedAt,
         resolutionData: resolutionData,
         createdAt: createdAt,
         deviceId: deviceId,
         device: device,
       );

  /// Returns a shallow copy of this [ConflictLog]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ConflictLog copyWith({
    Object? id = _Undefined,
    _i3.ParentEntityType? entityType,
    _i1.UuidValue? entityId,
    String? localPayload,
    String? remotePayload,
    String? conflictType,
    _i2.ConflictStatus? resolutionStatus,
    Object? resolvedAt = _Undefined,
    Object? resolutionData = _Undefined,
    DateTime? createdAt,
    _i1.UuidValue? deviceId,
    Object? device = _Undefined,
  }) {
    return ConflictLog(
      id: id is _i1.UuidValue? ? id : this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      localPayload: localPayload ?? this.localPayload,
      remotePayload: remotePayload ?? this.remotePayload,
      conflictType: conflictType ?? this.conflictType,
      resolutionStatus: resolutionStatus ?? this.resolutionStatus,
      resolvedAt: resolvedAt is DateTime? ? resolvedAt : this.resolvedAt,
      resolutionData: resolutionData is String?
          ? resolutionData
          : this.resolutionData,
      createdAt: createdAt ?? this.createdAt,
      deviceId: deviceId ?? this.deviceId,
      device: device is _i4.Device? ? device : this.device?.copyWith(),
    );
  }
}
