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
import 'package:motaz_app_client/src/protocol/protocol.dart' as _i2;

abstract class PullResponse implements _i1.SerializableModel {
  PullResponse._({
    required this.entityType,
    required this.rows,
    required this.hasMore,
    required this.latestRowVersion,
  });

  factory PullResponse({
    required String entityType,
    required List<String> rows,
    required bool hasMore,
    required int latestRowVersion,
  }) = _PullResponseImpl;

  factory PullResponse.fromJson(Map<String, dynamic> jsonSerialization) {
    return PullResponse(
      entityType: jsonSerialization['entityType'] as String,
      rows: _i2.Protocol().deserialize<List<String>>(jsonSerialization['rows']),
      hasMore: _i1.BoolJsonExtension.fromJson(jsonSerialization['hasMore']),
      latestRowVersion: jsonSerialization['latestRowVersion'] as int,
    );
  }

  String entityType;

  List<String> rows;

  bool hasMore;

  int latestRowVersion;

  /// Returns a shallow copy of this [PullResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PullResponse copyWith({
    String? entityType,
    List<String>? rows,
    bool? hasMore,
    int? latestRowVersion,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PullResponse',
      'entityType': entityType,
      'rows': rows.toJson(),
      'hasMore': hasMore,
      'latestRowVersion': latestRowVersion,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _PullResponseImpl extends PullResponse {
  _PullResponseImpl({
    required String entityType,
    required List<String> rows,
    required bool hasMore,
    required int latestRowVersion,
  }) : super._(
         entityType: entityType,
         rows: rows,
         hasMore: hasMore,
         latestRowVersion: latestRowVersion,
       );

  /// Returns a shallow copy of this [PullResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PullResponse copyWith({
    String? entityType,
    List<String>? rows,
    bool? hasMore,
    int? latestRowVersion,
  }) {
    return PullResponse(
      entityType: entityType ?? this.entityType,
      rows: rows ?? this.rows.map((e0) => e0).toList(),
      hasMore: hasMore ?? this.hasMore,
      latestRowVersion: latestRowVersion ?? this.latestRowVersion,
    );
  }
}
