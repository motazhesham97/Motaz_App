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

abstract class ConflictPayload implements _i1.SerializableModel {
  ConflictPayload._({
    required this.entityType,
    required this.entityId,
    required this.localPayload,
    required this.remotePayload,
    required this.conflictType,
  });

  factory ConflictPayload({
    required String entityType,
    required String entityId,
    required String localPayload,
    required String remotePayload,
    required String conflictType,
  }) = _ConflictPayloadImpl;

  factory ConflictPayload.fromJson(Map<String, dynamic> jsonSerialization) {
    return ConflictPayload(
      entityType: jsonSerialization['entityType'] as String,
      entityId: jsonSerialization['entityId'] as String,
      localPayload: jsonSerialization['localPayload'] as String,
      remotePayload: jsonSerialization['remotePayload'] as String,
      conflictType: jsonSerialization['conflictType'] as String,
    );
  }

  String entityType;

  String entityId;

  String localPayload;

  String remotePayload;

  String conflictType;

  /// Returns a shallow copy of this [ConflictPayload]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ConflictPayload copyWith({
    String? entityType,
    String? entityId,
    String? localPayload,
    String? remotePayload,
    String? conflictType,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConflictPayload',
      'entityType': entityType,
      'entityId': entityId,
      'localPayload': localPayload,
      'remotePayload': remotePayload,
      'conflictType': conflictType,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _ConflictPayloadImpl extends ConflictPayload {
  _ConflictPayloadImpl({
    required String entityType,
    required String entityId,
    required String localPayload,
    required String remotePayload,
    required String conflictType,
  }) : super._(
         entityType: entityType,
         entityId: entityId,
         localPayload: localPayload,
         remotePayload: remotePayload,
         conflictType: conflictType,
       );

  /// Returns a shallow copy of this [ConflictPayload]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ConflictPayload copyWith({
    String? entityType,
    String? entityId,
    String? localPayload,
    String? remotePayload,
    String? conflictType,
  }) {
    return ConflictPayload(
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      localPayload: localPayload ?? this.localPayload,
      remotePayload: remotePayload ?? this.remotePayload,
      conflictType: conflictType ?? this.conflictType,
    );
  }
}
