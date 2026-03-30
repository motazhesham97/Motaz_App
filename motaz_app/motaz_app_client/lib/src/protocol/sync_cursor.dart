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

abstract class SyncCursor implements _i1.SerializableModel {
  SyncCursor._({
    this.id,
    required this.entityType,
    this.lastPulledAt,
    int? lastRowVersion,
    required this.updatedAt,
  }) : lastRowVersion = lastRowVersion ?? 0;

  factory SyncCursor({
    _i1.UuidValue? id,
    required _i2.ParentEntityType entityType,
    DateTime? lastPulledAt,
    int? lastRowVersion,
    required DateTime updatedAt,
  }) = _SyncCursorImpl;

  factory SyncCursor.fromJson(Map<String, dynamic> jsonSerialization) {
    return SyncCursor(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      entityType: _i2.ParentEntityType.fromJson(
        (jsonSerialization['entityType'] as String),
      ),
      lastPulledAt: jsonSerialization['lastPulledAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastPulledAt'],
            ),
      lastRowVersion: jsonSerialization['lastRowVersion'] as int?,
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _i1.UuidValue? id;

  _i2.ParentEntityType entityType;

  DateTime? lastPulledAt;

  int lastRowVersion;

  DateTime updatedAt;

  /// Returns a shallow copy of this [SyncCursor]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SyncCursor copyWith({
    _i1.UuidValue? id,
    _i2.ParentEntityType? entityType,
    DateTime? lastPulledAt,
    int? lastRowVersion,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SyncCursor',
      if (id != null) 'id': id?.toJson(),
      'entityType': entityType.toJson(),
      if (lastPulledAt != null) 'lastPulledAt': lastPulledAt?.toJson(),
      'lastRowVersion': lastRowVersion,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SyncCursorImpl extends SyncCursor {
  _SyncCursorImpl({
    _i1.UuidValue? id,
    required _i2.ParentEntityType entityType,
    DateTime? lastPulledAt,
    int? lastRowVersion,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         entityType: entityType,
         lastPulledAt: lastPulledAt,
         lastRowVersion: lastRowVersion,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [SyncCursor]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SyncCursor copyWith({
    Object? id = _Undefined,
    _i2.ParentEntityType? entityType,
    Object? lastPulledAt = _Undefined,
    int? lastRowVersion,
    DateTime? updatedAt,
  }) {
    return SyncCursor(
      id: id is _i1.UuidValue? ? id : this.id,
      entityType: entityType ?? this.entityType,
      lastPulledAt: lastPulledAt is DateTime?
          ? lastPulledAt
          : this.lastPulledAt,
      lastRowVersion: lastRowVersion ?? this.lastRowVersion,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
