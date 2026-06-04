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
import 'enums/sync_status.dart' as _i2;
import 'free_sample.dart' as _i3;
import 'product.dart' as _i4;
import 'device.dart' as _i5;
import 'package:motaz_app_client/src/protocol/protocol.dart' as _i6;

abstract class FreeSampleLine implements _i1.SerializableModel {
  FreeSampleLine._({
    this.id,
    required this.sampleId,
    this.sample,
    required this.productId,
    this.product,
    required this.quantity,
    required this.createdAt,
    required this.updatedAt,
    required this.deviceId,
    this.device,
    int? rowVersion,
    _i2.SyncStatus? syncStatus,
  }) : rowVersion = rowVersion ?? 1,
       syncStatus = syncStatus ?? _i2.SyncStatus.PENDING;

  factory FreeSampleLine({
    _i1.UuidValue? id,
    required _i1.UuidValue sampleId,
    _i3.FreeSample? sample,
    required _i1.UuidValue productId,
    _i4.Product? product,
    required int quantity,
    required DateTime createdAt,
    required DateTime updatedAt,
    required _i1.UuidValue deviceId,
    _i5.Device? device,
    int? rowVersion,
    _i2.SyncStatus? syncStatus,
  }) = _FreeSampleLineImpl;

  factory FreeSampleLine.fromJson(Map<String, dynamic> jsonSerialization) {
    return FreeSampleLine(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      sampleId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['sampleId'],
      ),
      sample: jsonSerialization['sample'] == null
          ? null
          : _i6.Protocol().deserialize<_i3.FreeSample>(
              jsonSerialization['sample'],
            ),
      productId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['productId'],
      ),
      product: jsonSerialization['product'] == null
          ? null
          : _i6.Protocol().deserialize<_i4.Product>(
              jsonSerialization['product'],
            ),
      quantity: jsonSerialization['quantity'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
      deviceId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['deviceId'],
      ),
      device: jsonSerialization['device'] == null
          ? null
          : _i6.Protocol().deserialize<_i5.Device>(jsonSerialization['device']),
      rowVersion: jsonSerialization['rowVersion'] as int?,
      syncStatus: jsonSerialization['syncStatus'] == null
          ? null
          : _i2.SyncStatus.fromJson(
              (jsonSerialization['syncStatus'] as String),
            ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _i1.UuidValue? id;

  _i1.UuidValue sampleId;

  _i3.FreeSample? sample;

  _i1.UuidValue productId;

  _i4.Product? product;

  int quantity;

  DateTime createdAt;

  DateTime updatedAt;

  _i1.UuidValue deviceId;

  _i5.Device? device;

  int rowVersion;

  _i2.SyncStatus syncStatus;

  /// Returns a shallow copy of this [FreeSampleLine]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  FreeSampleLine copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? sampleId,
    _i3.FreeSample? sample,
    _i1.UuidValue? productId,
    _i4.Product? product,
    int? quantity,
    DateTime? createdAt,
    DateTime? updatedAt,
    _i1.UuidValue? deviceId,
    _i5.Device? device,
    int? rowVersion,
    _i2.SyncStatus? syncStatus,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FreeSampleLine',
      if (id != null) 'id': id?.toJson(),
      'sampleId': sampleId.toJson(),
      if (sample != null) 'sample': sample?.toJson(),
      'productId': productId.toJson(),
      if (product != null) 'product': product?.toJson(),
      'quantity': quantity,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      'deviceId': deviceId.toJson(),
      if (device != null) 'device': device?.toJson(),
      'rowVersion': rowVersion,
      'syncStatus': syncStatus.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _FreeSampleLineImpl extends FreeSampleLine {
  _FreeSampleLineImpl({
    _i1.UuidValue? id,
    required _i1.UuidValue sampleId,
    _i3.FreeSample? sample,
    required _i1.UuidValue productId,
    _i4.Product? product,
    required int quantity,
    required DateTime createdAt,
    required DateTime updatedAt,
    required _i1.UuidValue deviceId,
    _i5.Device? device,
    int? rowVersion,
    _i2.SyncStatus? syncStatus,
  }) : super._(
         id: id,
         sampleId: sampleId,
         sample: sample,
         productId: productId,
         product: product,
         quantity: quantity,
         createdAt: createdAt,
         updatedAt: updatedAt,
         deviceId: deviceId,
         device: device,
         rowVersion: rowVersion,
         syncStatus: syncStatus,
       );

  /// Returns a shallow copy of this [FreeSampleLine]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  FreeSampleLine copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? sampleId,
    Object? sample = _Undefined,
    _i1.UuidValue? productId,
    Object? product = _Undefined,
    int? quantity,
    DateTime? createdAt,
    DateTime? updatedAt,
    _i1.UuidValue? deviceId,
    Object? device = _Undefined,
    int? rowVersion,
    _i2.SyncStatus? syncStatus,
  }) {
    return FreeSampleLine(
      id: id is _i1.UuidValue? ? id : this.id,
      sampleId: sampleId ?? this.sampleId,
      sample: sample is _i3.FreeSample? ? sample : this.sample?.copyWith(),
      productId: productId ?? this.productId,
      product: product is _i4.Product? ? product : this.product?.copyWith(),
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      device: device is _i5.Device? ? device : this.device?.copyWith(),
      rowVersion: rowVersion ?? this.rowVersion,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
