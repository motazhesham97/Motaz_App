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
import 'enums/parent_entity_type.dart' as _i3;
import 'device.dart' as _i4;
import 'package:motaz_app_client/src/protocol/protocol.dart' as _i5;

abstract class AttachmentMetadata implements _i1.SerializableModel {
  AttachmentMetadata._({
    this.id,
    required this.parentEntityType,
    required this.parentEntityId,
    required this.storageReference,
    this.secureUrl,
    required this.fileType,
    this.fileSize,
    required this.createdAt,
    required this.updatedAt,
    required this.deviceId,
    this.device,
    int? rowVersion,
    _i2.SyncStatus? syncStatus,
  }) : rowVersion = rowVersion ?? 1,
       syncStatus = syncStatus ?? _i2.SyncStatus.PENDING;

  factory AttachmentMetadata({
    _i1.UuidValue? id,
    required _i3.ParentEntityType parentEntityType,
    required _i1.UuidValue parentEntityId,
    required String storageReference,
    String? secureUrl,
    required String fileType,
    int? fileSize,
    required DateTime createdAt,
    required DateTime updatedAt,
    required _i1.UuidValue deviceId,
    _i4.Device? device,
    int? rowVersion,
    _i2.SyncStatus? syncStatus,
  }) = _AttachmentMetadataImpl;

  factory AttachmentMetadata.fromJson(Map<String, dynamic> jsonSerialization) {
    return AttachmentMetadata(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      parentEntityType: _i3.ParentEntityType.fromJson(
        (jsonSerialization['parentEntityType'] as String),
      ),
      parentEntityId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['parentEntityId'],
      ),
      storageReference: jsonSerialization['storageReference'] as String,
      secureUrl: jsonSerialization['secureUrl'] as String?,
      fileType: jsonSerialization['fileType'] as String,
      fileSize: jsonSerialization['fileSize'] as int?,
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
          : _i5.Protocol().deserialize<_i4.Device>(jsonSerialization['device']),
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

  _i3.ParentEntityType parentEntityType;

  _i1.UuidValue parentEntityId;

  String storageReference;

  String? secureUrl;

  String fileType;

  int? fileSize;

  DateTime createdAt;

  DateTime updatedAt;

  _i1.UuidValue deviceId;

  _i4.Device? device;

  int rowVersion;

  _i2.SyncStatus syncStatus;

  /// Returns a shallow copy of this [AttachmentMetadata]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AttachmentMetadata copyWith({
    _i1.UuidValue? id,
    _i3.ParentEntityType? parentEntityType,
    _i1.UuidValue? parentEntityId,
    String? storageReference,
    String? secureUrl,
    String? fileType,
    int? fileSize,
    DateTime? createdAt,
    DateTime? updatedAt,
    _i1.UuidValue? deviceId,
    _i4.Device? device,
    int? rowVersion,
    _i2.SyncStatus? syncStatus,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AttachmentMetadata',
      if (id != null) 'id': id?.toJson(),
      'parentEntityType': parentEntityType.toJson(),
      'parentEntityId': parentEntityId.toJson(),
      'storageReference': storageReference,
      if (secureUrl != null) 'secureUrl': secureUrl,
      'fileType': fileType,
      if (fileSize != null) 'fileSize': fileSize,
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

class _AttachmentMetadataImpl extends AttachmentMetadata {
  _AttachmentMetadataImpl({
    _i1.UuidValue? id,
    required _i3.ParentEntityType parentEntityType,
    required _i1.UuidValue parentEntityId,
    required String storageReference,
    String? secureUrl,
    required String fileType,
    int? fileSize,
    required DateTime createdAt,
    required DateTime updatedAt,
    required _i1.UuidValue deviceId,
    _i4.Device? device,
    int? rowVersion,
    _i2.SyncStatus? syncStatus,
  }) : super._(
         id: id,
         parentEntityType: parentEntityType,
         parentEntityId: parentEntityId,
         storageReference: storageReference,
         secureUrl: secureUrl,
         fileType: fileType,
         fileSize: fileSize,
         createdAt: createdAt,
         updatedAt: updatedAt,
         deviceId: deviceId,
         device: device,
         rowVersion: rowVersion,
         syncStatus: syncStatus,
       );

  /// Returns a shallow copy of this [AttachmentMetadata]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AttachmentMetadata copyWith({
    Object? id = _Undefined,
    _i3.ParentEntityType? parentEntityType,
    _i1.UuidValue? parentEntityId,
    String? storageReference,
    Object? secureUrl = _Undefined,
    String? fileType,
    Object? fileSize = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
    _i1.UuidValue? deviceId,
    Object? device = _Undefined,
    int? rowVersion,
    _i2.SyncStatus? syncStatus,
  }) {
    return AttachmentMetadata(
      id: id is _i1.UuidValue? ? id : this.id,
      parentEntityType: parentEntityType ?? this.parentEntityType,
      parentEntityId: parentEntityId ?? this.parentEntityId,
      storageReference: storageReference ?? this.storageReference,
      secureUrl: secureUrl is String? ? secureUrl : this.secureUrl,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize is int? ? fileSize : this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      device: device is _i4.Device? ? device : this.device?.copyWith(),
      rowVersion: rowVersion ?? this.rowVersion,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
