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

abstract class AttachmentUploadApproval implements _i1.SerializableModel {
  AttachmentUploadApproval._({
    required this.approved,
    this.uploadUrl,
    this.uploadPreset,
    this.rejectionReason,
  });

  factory AttachmentUploadApproval({
    required bool approved,
    String? uploadUrl,
    String? uploadPreset,
    String? rejectionReason,
  }) = _AttachmentUploadApprovalImpl;

  factory AttachmentUploadApproval.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return AttachmentUploadApproval(
      approved: _i1.BoolJsonExtension.fromJson(jsonSerialization['approved']),
      uploadUrl: jsonSerialization['uploadUrl'] as String?,
      uploadPreset: jsonSerialization['uploadPreset'] as String?,
      rejectionReason: jsonSerialization['rejectionReason'] as String?,
    );
  }

  bool approved;

  String? uploadUrl;

  String? uploadPreset;

  String? rejectionReason;

  /// Returns a shallow copy of this [AttachmentUploadApproval]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AttachmentUploadApproval copyWith({
    bool? approved,
    String? uploadUrl,
    String? uploadPreset,
    String? rejectionReason,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AttachmentUploadApproval',
      'approved': approved,
      if (uploadUrl != null) 'uploadUrl': uploadUrl,
      if (uploadPreset != null) 'uploadPreset': uploadPreset,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AttachmentUploadApprovalImpl extends AttachmentUploadApproval {
  _AttachmentUploadApprovalImpl({
    required bool approved,
    String? uploadUrl,
    String? uploadPreset,
    String? rejectionReason,
  }) : super._(
         approved: approved,
         uploadUrl: uploadUrl,
         uploadPreset: uploadPreset,
         rejectionReason: rejectionReason,
       );

  /// Returns a shallow copy of this [AttachmentUploadApproval]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AttachmentUploadApproval copyWith({
    bool? approved,
    Object? uploadUrl = _Undefined,
    Object? uploadPreset = _Undefined,
    Object? rejectionReason = _Undefined,
  }) {
    return AttachmentUploadApproval(
      approved: approved ?? this.approved,
      uploadUrl: uploadUrl is String? ? uploadUrl : this.uploadUrl,
      uploadPreset: uploadPreset is String? ? uploadPreset : this.uploadPreset,
      rejectionReason: rejectionReason is String?
          ? rejectionReason
          : this.rejectionReason,
    );
  }
}
