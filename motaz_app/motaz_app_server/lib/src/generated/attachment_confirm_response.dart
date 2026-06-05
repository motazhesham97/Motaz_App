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

abstract class AttachmentConfirmResponse
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  AttachmentConfirmResponse._({
    required this.success,
    this.attachmentMetadataId,
    this.errorMessage,
  });

  factory AttachmentConfirmResponse({
    required bool success,
    String? attachmentMetadataId,
    String? errorMessage,
  }) = _AttachmentConfirmResponseImpl;

  factory AttachmentConfirmResponse.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return AttachmentConfirmResponse(
      success: _i1.BoolJsonExtension.fromJson(jsonSerialization['success']),
      attachmentMetadataId:
          jsonSerialization['attachmentMetadataId'] as String?,
      errorMessage: jsonSerialization['errorMessage'] as String?,
    );
  }

  bool success;

  String? attachmentMetadataId;

  String? errorMessage;

  /// Returns a shallow copy of this [AttachmentConfirmResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AttachmentConfirmResponse copyWith({
    bool? success,
    String? attachmentMetadataId,
    String? errorMessage,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AttachmentConfirmResponse',
      'success': success,
      if (attachmentMetadataId != null)
        'attachmentMetadataId': attachmentMetadataId,
      if (errorMessage != null) 'errorMessage': errorMessage,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AttachmentConfirmResponse',
      'success': success,
      if (attachmentMetadataId != null)
        'attachmentMetadataId': attachmentMetadataId,
      if (errorMessage != null) 'errorMessage': errorMessage,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AttachmentConfirmResponseImpl extends AttachmentConfirmResponse {
  _AttachmentConfirmResponseImpl({
    required bool success,
    String? attachmentMetadataId,
    String? errorMessage,
  }) : super._(
         success: success,
         attachmentMetadataId: attachmentMetadataId,
         errorMessage: errorMessage,
       );

  /// Returns a shallow copy of this [AttachmentConfirmResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AttachmentConfirmResponse copyWith({
    bool? success,
    Object? attachmentMetadataId = _Undefined,
    Object? errorMessage = _Undefined,
  }) {
    return AttachmentConfirmResponse(
      success: success ?? this.success,
      attachmentMetadataId: attachmentMetadataId is String?
          ? attachmentMetadataId
          : this.attachmentMetadataId,
      errorMessage: errorMessage is String? ? errorMessage : this.errorMessage,
    );
  }
}
