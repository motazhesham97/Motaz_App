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

abstract class PullRequest implements _i1.SerializableModel {
  PullRequest._({
    required this.entityType,
    required this.sinceRowVersion,
    required this.deviceId,
    required this.limit,
  });

  factory PullRequest({
    required String entityType,
    required int sinceRowVersion,
    required String deviceId,
    required int limit,
  }) = _PullRequestImpl;

  factory PullRequest.fromJson(Map<String, dynamic> jsonSerialization) {
    return PullRequest(
      entityType: jsonSerialization['entityType'] as String,
      sinceRowVersion: jsonSerialization['sinceRowVersion'] as int,
      deviceId: jsonSerialization['deviceId'] as String,
      limit: jsonSerialization['limit'] as int,
    );
  }

  String entityType;

  int sinceRowVersion;

  String deviceId;

  int limit;

  /// Returns a shallow copy of this [PullRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PullRequest copyWith({
    String? entityType,
    int? sinceRowVersion,
    String? deviceId,
    int? limit,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PullRequest',
      'entityType': entityType,
      'sinceRowVersion': sinceRowVersion,
      'deviceId': deviceId,
      'limit': limit,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _PullRequestImpl extends PullRequest {
  _PullRequestImpl({
    required String entityType,
    required int sinceRowVersion,
    required String deviceId,
    required int limit,
  }) : super._(
         entityType: entityType,
         sinceRowVersion: sinceRowVersion,
         deviceId: deviceId,
         limit: limit,
       );

  /// Returns a shallow copy of this [PullRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PullRequest copyWith({
    String? entityType,
    int? sinceRowVersion,
    String? deviceId,
    int? limit,
  }) {
    return PullRequest(
      entityType: entityType ?? this.entityType,
      sinceRowVersion: sinceRowVersion ?? this.sinceRowVersion,
      deviceId: deviceId ?? this.deviceId,
      limit: limit ?? this.limit,
    );
  }
}
