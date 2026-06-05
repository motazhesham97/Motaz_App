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

abstract class AttachmentUploadRequest
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  AttachmentUploadRequest._({
    required this.parentEntityType,
    required this.parentEntityId,
    required this.fileType,
    required this.fileSize,
  });

  factory AttachmentUploadRequest({
    required String parentEntityType,
    required String parentEntityId,
    required String fileType,
    required int fileSize,
  }) = _AttachmentUploadRequestImpl;

  factory AttachmentUploadRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return AttachmentUploadRequest(
      parentEntityType: jsonSerialization['parentEntityType'] as String,
      parentEntityId: jsonSerialization['parentEntityId'] as String,
      fileType: jsonSerialization['fileType'] as String,
      fileSize: jsonSerialization['fileSize'] as int,
    );
  }

  String parentEntityType;

  String parentEntityId;

  String fileType;

  int fileSize;

  /// Returns a shallow copy of this [AttachmentUploadRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AttachmentUploadRequest copyWith({
    String? parentEntityType,
    String? parentEntityId,
    String? fileType,
    int? fileSize,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AttachmentUploadRequest',
      'parentEntityType': parentEntityType,
      'parentEntityId': parentEntityId,
      'fileType': fileType,
      'fileSize': fileSize,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AttachmentUploadRequest',
      'parentEntityType': parentEntityType,
      'parentEntityId': parentEntityId,
      'fileType': fileType,
      'fileSize': fileSize,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _AttachmentUploadRequestImpl extends AttachmentUploadRequest {
  _AttachmentUploadRequestImpl({
    required String parentEntityType,
    required String parentEntityId,
    required String fileType,
    required int fileSize,
  }) : super._(
         parentEntityType: parentEntityType,
         parentEntityId: parentEntityId,
         fileType: fileType,
         fileSize: fileSize,
       );

  /// Returns a shallow copy of this [AttachmentUploadRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AttachmentUploadRequest copyWith({
    String? parentEntityType,
    String? parentEntityId,
    String? fileType,
    int? fileSize,
  }) {
    return AttachmentUploadRequest(
      parentEntityType: parentEntityType ?? this.parentEntityType,
      parentEntityId: parentEntityId ?? this.parentEntityId,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
    );
  }
}
