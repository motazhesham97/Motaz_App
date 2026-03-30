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
import 'enums/sync_status.dart' as _i2;
import 'device.dart' as _i3;
import 'package:motaz_app_client/src/protocol/protocol.dart' as _i4;

abstract class ClientRecord implements _i1.SerializableModel {
  ClientRecord._({
    this.id,
    required this.displayName,
    this.phone,
    this.note,
    this.clientCode,
    bool? isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.deviceId,
    this.device,
    int? rowVersion,
    _i2.SyncStatus? syncStatus,
  }) : isActive = isActive ?? true,
       rowVersion = rowVersion ?? 1,
       syncStatus = syncStatus ?? _i2.SyncStatus.PENDING;

  factory ClientRecord({
    _i1.UuidValue? id,
    required String displayName,
    String? phone,
    String? note,
    String? clientCode,
    bool? isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
    required _i1.UuidValue deviceId,
    _i3.Device? device,
    int? rowVersion,
    _i2.SyncStatus? syncStatus,
  }) = _ClientRecordImpl;

  factory ClientRecord.fromJson(Map<String, dynamic> jsonSerialization) {
    return ClientRecord(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      displayName: jsonSerialization['displayName'] as String,
      phone: jsonSerialization['phone'] as String?,
      note: jsonSerialization['note'] as String?,
      clientCode: jsonSerialization['clientCode'] as String?,
      isActive: jsonSerialization['isActive'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['isActive']),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
      deviceId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['deviceId'],
      ),
      device: jsonSerialization['device'] == null
          ? null
          : _i4.Protocol().deserialize<_i3.Device>(jsonSerialization['device']),
      rowVersion: jsonSerialization['rowVersion'] as int?,
      syncStatus: jsonSerialization['syncStatus'] == null
          ? null
          : _i2.SyncStatus.fromJson(
              (jsonSerialization['syncStatus'] as String),
            ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _i1.UuidValue? id;

  String displayName;

  String? phone;

  String? note;

  String? clientCode;

  bool isActive;

  DateTime createdAt;

  DateTime updatedAt;

  _i1.UuidValue deviceId;

  _i3.Device? device;

  int rowVersion;

  _i2.SyncStatus syncStatus;

  /// Returns a shallow copy of this [ClientRecord]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ClientRecord copyWith({
    _i1.UuidValue? id,
    String? displayName,
    String? phone,
    String? note,
    String? clientCode,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    _i1.UuidValue? deviceId,
    _i3.Device? device,
    int? rowVersion,
    _i2.SyncStatus? syncStatus,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ClientRecord',
      if (id != null) 'id': id?.toJson(),
      'displayName': displayName,
      if (phone != null) 'phone': phone,
      if (note != null) 'note': note,
      if (clientCode != null) 'clientCode': clientCode,
      'isActive': isActive,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      'deviceId': deviceId.toJson(),
      if (device != null) 'device': device?.toJson(),
      'rowVersion': rowVersion,
      'syncStatus': syncStatus.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ClientRecordImpl extends ClientRecord {
  _ClientRecordImpl({
    _i1.UuidValue? id,
    required String displayName,
    String? phone,
    String? note,
    String? clientCode,
    bool? isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
    required _i1.UuidValue deviceId,
    _i3.Device? device,
    int? rowVersion,
    _i2.SyncStatus? syncStatus,
  }) : super._(
         id: id,
         displayName: displayName,
         phone: phone,
         note: note,
         clientCode: clientCode,
         isActive: isActive,
         createdAt: createdAt,
         updatedAt: updatedAt,
         deviceId: deviceId,
         device: device,
         rowVersion: rowVersion,
         syncStatus: syncStatus,
       );

  /// Returns a shallow copy of this [ClientRecord]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ClientRecord copyWith({
    Object? id = _Undefined,
    String? displayName,
    Object? phone = _Undefined,
    Object? note = _Undefined,
    Object? clientCode = _Undefined,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    _i1.UuidValue? deviceId,
    Object? device = _Undefined,
    int? rowVersion,
    _i2.SyncStatus? syncStatus,
  }) {
    return ClientRecord(
      id: id is _i1.UuidValue? ? id : this.id,
      displayName: displayName ?? this.displayName,
      phone: phone is String? ? phone : this.phone,
      note: note is String? ? note : this.note,
      clientCode: clientCode is String? ? clientCode : this.clientCode,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      device: device is _i3.Device? ? device : this.device?.copyWith(),
      rowVersion: rowVersion ?? this.rowVersion,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
