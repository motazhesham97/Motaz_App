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

abstract class LocalAttachmentStaging implements _i1.SerializableModel {
  LocalAttachmentStaging._({
    this.id,
    required this.parentEntityType,
    required this.parentEntityId,
    required this.localFilePath,
    required this.fileType,
    this.fileSize,
    String? uploadStatus,
    required this.createdAt,
    required this.updatedAt,
  }) : uploadStatus = uploadStatus ?? 'PENDING';

  factory LocalAttachmentStaging({
    _i1.UuidValue? id,
    required _i2.ParentEntityType parentEntityType,
    required _i1.UuidValue parentEntityId,
    required String localFilePath,
    required String fileType,
    int? fileSize,
    String? uploadStatus,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _LocalAttachmentStagingImpl;

  factory LocalAttachmentStaging.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return LocalAttachmentStaging(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      parentEntityType: _i2.ParentEntityType.fromJson(
        (jsonSerialization['parentEntityType'] as String),
      ),
      parentEntityId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['parentEntityId'],
      ),
      localFilePath: jsonSerialization['localFilePath'] as String,
      fileType: jsonSerialization['fileType'] as String,
      fileSize: jsonSerialization['fileSize'] as int?,
      uploadStatus: jsonSerialization['uploadStatus'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _i1.UuidValue? id;

  _i2.ParentEntityType parentEntityType;

  _i1.UuidValue parentEntityId;

  String localFilePath;

  String fileType;

  int? fileSize;

  String uploadStatus;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [LocalAttachmentStaging]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  LocalAttachmentStaging copyWith({
    _i1.UuidValue? id,
    _i2.ParentEntityType? parentEntityType,
    _i1.UuidValue? parentEntityId,
    String? localFilePath,
    String? fileType,
    int? fileSize,
    String? uploadStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LocalAttachmentStaging',
      if (id != null) 'id': id?.toJson(),
      'parentEntityType': parentEntityType.toJson(),
      'parentEntityId': parentEntityId.toJson(),
      'localFilePath': localFilePath,
      'fileType': fileType,
      if (fileSize != null) 'fileSize': fileSize,
      'uploadStatus': uploadStatus,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LocalAttachmentStagingImpl extends LocalAttachmentStaging {
  _LocalAttachmentStagingImpl({
    _i1.UuidValue? id,
    required _i2.ParentEntityType parentEntityType,
    required _i1.UuidValue parentEntityId,
    required String localFilePath,
    required String fileType,
    int? fileSize,
    String? uploadStatus,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         parentEntityType: parentEntityType,
         parentEntityId: parentEntityId,
         localFilePath: localFilePath,
         fileType: fileType,
         fileSize: fileSize,
         uploadStatus: uploadStatus,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [LocalAttachmentStaging]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  LocalAttachmentStaging copyWith({
    Object? id = _Undefined,
    _i2.ParentEntityType? parentEntityType,
    _i1.UuidValue? parentEntityId,
    String? localFilePath,
    String? fileType,
    Object? fileSize = _Undefined,
    String? uploadStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LocalAttachmentStaging(
      id: id is _i1.UuidValue? ? id : this.id,
      parentEntityType: parentEntityType ?? this.parentEntityType,
      parentEntityId: parentEntityId ?? this.parentEntityId,
      localFilePath: localFilePath ?? this.localFilePath,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize is int? ? fileSize : this.fileSize,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
