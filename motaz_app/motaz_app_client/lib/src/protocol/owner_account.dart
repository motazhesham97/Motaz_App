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

abstract class OwnerAccount implements _i1.SerializableModel {
  OwnerAccount._({
    this.id,
    int? singletonKey,
    required this.authUserId,
    required this.createdAt,
  }) : singletonKey = singletonKey ?? 1;

  factory OwnerAccount({
    _i1.UuidValue? id,
    int? singletonKey,
    required _i1.UuidValue authUserId,
    required DateTime createdAt,
  }) = _OwnerAccountImpl;

  factory OwnerAccount.fromJson(Map<String, dynamic> jsonSerialization) {
    return OwnerAccount(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      singletonKey: jsonSerialization['singletonKey'] as int?,
      authUserId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['authUserId'],
      ),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _i1.UuidValue? id;

  int singletonKey;

  _i1.UuidValue authUserId;

  DateTime createdAt;

  /// Returns a shallow copy of this [OwnerAccount]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  OwnerAccount copyWith({
    _i1.UuidValue? id,
    int? singletonKey,
    _i1.UuidValue? authUserId,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'OwnerAccount',
      if (id != null) 'id': id?.toJson(),
      'singletonKey': singletonKey,
      'authUserId': authUserId.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _OwnerAccountImpl extends OwnerAccount {
  _OwnerAccountImpl({
    _i1.UuidValue? id,
    int? singletonKey,
    required _i1.UuidValue authUserId,
    required DateTime createdAt,
  }) : super._(
         id: id,
         singletonKey: singletonKey,
         authUserId: authUserId,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [OwnerAccount]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  OwnerAccount copyWith({
    Object? id = _Undefined,
    int? singletonKey,
    _i1.UuidValue? authUserId,
    DateTime? createdAt,
  }) {
    return OwnerAccount(
      id: id is _i1.UuidValue? ? id : this.id,
      singletonKey: singletonKey ?? this.singletonKey,
      authUserId: authUserId ?? this.authUserId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
