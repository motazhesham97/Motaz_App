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

abstract class AttachmentConfirmRequest implements _i1.SerializableModel {
  AttachmentConfirmRequest._({
    required this.parentEntityType,
    required this.parentEntityId,
    required this.publicId,
    required this.secureUrl,
    required this.fileType,
    required this.fileSize,
    required this.deviceId,
  });

  factory AttachmentConfirmRequest({
    required String parentEntityType,
    required String parentEntityId,
    required String publicId,
    required String secureUrl,
    required String fileType,
    required int fileSize,
    required String deviceId,
  }) = _AttachmentConfirmRequestImpl;

  factory AttachmentConfirmRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return AttachmentConfirmRequest(
      parentEntityType: jsonSerialization['parentEntityType'] as String,
      parentEntityId: jsonSerialization['parentEntityId'] as String,
      publicId: jsonSerialization['publicId'] as String,
      secureUrl: jsonSerialization['secureUrl'] as String,
      fileType: jsonSerialization['fileType'] as String,
      fileSize: jsonSerialization['fileSize'] as int,
      deviceId: jsonSerialization['deviceId'] as String,
    );
  }

  String parentEntityType;

  String parentEntityId;

  String publicId;

  String secureUrl;

  String fileType;

  int fileSize;

  String deviceId;

  /// Returns a shallow copy of this [AttachmentConfirmRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AttachmentConfirmRequest copyWith({
    String? parentEntityType,
    String? parentEntityId,
    String? publicId,
    String? secureUrl,
    String? fileType,
    int? fileSize,
    String? deviceId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AttachmentConfirmRequest',
      'parentEntityType': parentEntityType,
      'parentEntityId': parentEntityId,
      'publicId': publicId,
      'secureUrl': secureUrl,
      'fileType': fileType,
      'fileSize': fileSize,
      'deviceId': deviceId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _AttachmentConfirmRequestImpl extends AttachmentConfirmRequest {
  _AttachmentConfirmRequestImpl({
    required String parentEntityType,
    required String parentEntityId,
    required String publicId,
    required String secureUrl,
    required String fileType,
    required int fileSize,
    required String deviceId,
  }) : super._(
         parentEntityType: parentEntityType,
         parentEntityId: parentEntityId,
         publicId: publicId,
         secureUrl: secureUrl,
         fileType: fileType,
         fileSize: fileSize,
         deviceId: deviceId,
       );

  /// Returns a shallow copy of this [AttachmentConfirmRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AttachmentConfirmRequest copyWith({
    String? parentEntityType,
    String? parentEntityId,
    String? publicId,
    String? secureUrl,
    String? fileType,
    int? fileSize,
    String? deviceId,
  }) {
    return AttachmentConfirmRequest(
      parentEntityType: parentEntityType ?? this.parentEntityType,
      parentEntityId: parentEntityId ?? this.parentEntityId,
      publicId: publicId ?? this.publicId,
      secureUrl: secureUrl ?? this.secureUrl,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      deviceId: deviceId ?? this.deviceId,
    );
  }
}
