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

abstract class PushResponse implements _i1.SerializableModel {
  PushResponse._({
    required this.success,
    this.newRowVersion,
    this.conflictId,
    this.errorCode,
    this.errorMessage,
  });

  factory PushResponse({
    required bool success,
    int? newRowVersion,
    String? conflictId,
    String? errorCode,
    String? errorMessage,
  }) = _PushResponseImpl;

  factory PushResponse.fromJson(Map<String, dynamic> jsonSerialization) {
    return PushResponse(
      success: _i1.BoolJsonExtension.fromJson(jsonSerialization['success']),
      newRowVersion: jsonSerialization['newRowVersion'] as int?,
      conflictId: jsonSerialization['conflictId'] as String?,
      errorCode: jsonSerialization['errorCode'] as String?,
      errorMessage: jsonSerialization['errorMessage'] as String?,
    );
  }

  bool success;

  int? newRowVersion;

  String? conflictId;

  String? errorCode;

  String? errorMessage;

  /// Returns a shallow copy of this [PushResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PushResponse copyWith({
    bool? success,
    int? newRowVersion,
    String? conflictId,
    String? errorCode,
    String? errorMessage,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PushResponse',
      'success': success,
      if (newRowVersion != null) 'newRowVersion': newRowVersion,
      if (conflictId != null) 'conflictId': conflictId,
      if (errorCode != null) 'errorCode': errorCode,
      if (errorMessage != null) 'errorMessage': errorMessage,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PushResponseImpl extends PushResponse {
  _PushResponseImpl({
    required bool success,
    int? newRowVersion,
    String? conflictId,
    String? errorCode,
    String? errorMessage,
  }) : super._(
         success: success,
         newRowVersion: newRowVersion,
         conflictId: conflictId,
         errorCode: errorCode,
         errorMessage: errorMessage,
       );

  /// Returns a shallow copy of this [PushResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PushResponse copyWith({
    bool? success,
    Object? newRowVersion = _Undefined,
    Object? conflictId = _Undefined,
    Object? errorCode = _Undefined,
    Object? errorMessage = _Undefined,
  }) {
    return PushResponse(
      success: success ?? this.success,
      newRowVersion: newRowVersion is int? ? newRowVersion : this.newRowVersion,
      conflictId: conflictId is String? ? conflictId : this.conflictId,
      errorCode: errorCode is String? ? errorCode : this.errorCode,
      errorMessage: errorMessage is String? ? errorMessage : this.errorMessage,
    );
  }
}
