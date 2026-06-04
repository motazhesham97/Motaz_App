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

abstract class Beneficiary implements _i1.SerializableModel {
  Beneficiary._({
    this.id,
    required this.displayName,
    this.phone,
    this.sourceClientId,
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

  factory Beneficiary({
    _i1.UuidValue? id,
    required String displayName,
    String? phone,
    _i1.UuidValue? sourceClientId,
    bool? isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
    required _i1.UuidValue deviceId,
    _i3.Device? device,
    int? rowVersion,
    _i2.SyncStatus? syncStatus,
  }) = _BeneficiaryImpl;

  factory Beneficiary.fromJson(Map<String, dynamic> jsonSerialization) {
    return Beneficiary(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      displayName: jsonSerialization['displayName'] as String,
      phone: jsonSerialization['phone'] as String?,
      sourceClientId: jsonSerialization['sourceClientId'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(
              jsonSerialization['sourceClientId'],
            ),
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

  _i1.UuidValue? sourceClientId;

  bool isActive;

  DateTime createdAt;

  DateTime updatedAt;

  _i1.UuidValue deviceId;

  _i3.Device? device;

  int rowVersion;

  _i2.SyncStatus syncStatus;

  /// Returns a shallow copy of this [Beneficiary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Beneficiary copyWith({
    _i1.UuidValue? id,
    String? displayName,
    String? phone,
    _i1.UuidValue? sourceClientId,
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
      '__className__': 'Beneficiary',
      if (id != null) 'id': id?.toJson(),
      'displayName': displayName,
      if (phone != null) 'phone': phone,
      if (sourceClientId != null) 'sourceClientId': sourceClientId?.toJson(),
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

class _BeneficiaryImpl extends Beneficiary {
  _BeneficiaryImpl({
    _i1.UuidValue? id,
    required String displayName,
    String? phone,
    _i1.UuidValue? sourceClientId,
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
         sourceClientId: sourceClientId,
         isActive: isActive,
         createdAt: createdAt,
         updatedAt: updatedAt,
         deviceId: deviceId,
         device: device,
         rowVersion: rowVersion,
         syncStatus: syncStatus,
       );

  /// Returns a shallow copy of this [Beneficiary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Beneficiary copyWith({
    Object? id = _Undefined,
    String? displayName,
    Object? phone = _Undefined,
    Object? sourceClientId = _Undefined,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    _i1.UuidValue? deviceId,
    Object? device = _Undefined,
    int? rowVersion,
    _i2.SyncStatus? syncStatus,
  }) {
    return Beneficiary(
      id: id is _i1.UuidValue? ? id : this.id,
      displayName: displayName ?? this.displayName,
      phone: phone is String? ? phone : this.phone,
      sourceClientId: sourceClientId is _i1.UuidValue?
          ? sourceClientId
          : this.sourceClientId,
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
