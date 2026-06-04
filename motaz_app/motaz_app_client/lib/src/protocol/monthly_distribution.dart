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
import 'enums/record_status.dart' as _i2;
import 'enums/sync_status.dart' as _i3;
import 'device.dart' as _i4;
import 'package:motaz_app_client/src/protocol/protocol.dart' as _i5;

abstract class MonthlyDistribution implements _i1.SerializableModel {
  MonthlyDistribution._({
    this.id,
    required this.year,
    required this.month,
    required this.netProfit,
    required this.ownerShare,
    required this.partnerShare,
    required this.marginShare,
    _i2.RecordStatus? status,
    this.voidReason,
    required this.createdAt,
    required this.updatedAt,
    required this.deviceId,
    this.device,
    int? rowVersion,
    _i3.SyncStatus? syncStatus,
  }) : status = status ?? _i2.RecordStatus.ACTIVE,
       rowVersion = rowVersion ?? 1,
       syncStatus = syncStatus ?? _i3.SyncStatus.PENDING;

  factory MonthlyDistribution({
    _i1.UuidValue? id,
    required int year,
    required int month,
    required int netProfit,
    required int ownerShare,
    required int partnerShare,
    required int marginShare,
    _i2.RecordStatus? status,
    String? voidReason,
    required DateTime createdAt,
    required DateTime updatedAt,
    required _i1.UuidValue deviceId,
    _i4.Device? device,
    int? rowVersion,
    _i3.SyncStatus? syncStatus,
  }) = _MonthlyDistributionImpl;

  factory MonthlyDistribution.fromJson(Map<String, dynamic> jsonSerialization) {
    return MonthlyDistribution(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      year: jsonSerialization['year'] as int,
      month: jsonSerialization['month'] as int,
      netProfit: jsonSerialization['netProfit'] as int,
      ownerShare: jsonSerialization['ownerShare'] as int,
      partnerShare: jsonSerialization['partnerShare'] as int,
      marginShare: jsonSerialization['marginShare'] as int,
      status: jsonSerialization['status'] == null
          ? null
          : _i2.RecordStatus.fromJson((jsonSerialization['status'] as String)),
      voidReason: jsonSerialization['voidReason'] as String?,
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
          : _i5.Protocol().deserialize<_i4.Device>(jsonSerialization['device']),
      rowVersion: jsonSerialization['rowVersion'] as int?,
      syncStatus: jsonSerialization['syncStatus'] == null
          ? null
          : _i3.SyncStatus.fromJson(
              (jsonSerialization['syncStatus'] as String),
            ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _i1.UuidValue? id;

  int year;

  int month;

  int netProfit;

  int ownerShare;

  int partnerShare;

  int marginShare;

  _i2.RecordStatus status;

  String? voidReason;

  DateTime createdAt;

  DateTime updatedAt;

  _i1.UuidValue deviceId;

  _i4.Device? device;

  int rowVersion;

  _i3.SyncStatus syncStatus;

  /// Returns a shallow copy of this [MonthlyDistribution]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  MonthlyDistribution copyWith({
    _i1.UuidValue? id,
    int? year,
    int? month,
    int? netProfit,
    int? ownerShare,
    int? partnerShare,
    int? marginShare,
    _i2.RecordStatus? status,
    String? voidReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    _i1.UuidValue? deviceId,
    _i4.Device? device,
    int? rowVersion,
    _i3.SyncStatus? syncStatus,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MonthlyDistribution',
      if (id != null) 'id': id?.toJson(),
      'year': year,
      'month': month,
      'netProfit': netProfit,
      'ownerShare': ownerShare,
      'partnerShare': partnerShare,
      'marginShare': marginShare,
      'status': status.toJson(),
      if (voidReason != null) 'voidReason': voidReason,
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

class _MonthlyDistributionImpl extends MonthlyDistribution {
  _MonthlyDistributionImpl({
    _i1.UuidValue? id,
    required int year,
    required int month,
    required int netProfit,
    required int ownerShare,
    required int partnerShare,
    required int marginShare,
    _i2.RecordStatus? status,
    String? voidReason,
    required DateTime createdAt,
    required DateTime updatedAt,
    required _i1.UuidValue deviceId,
    _i4.Device? device,
    int? rowVersion,
    _i3.SyncStatus? syncStatus,
  }) : super._(
         id: id,
         year: year,
         month: month,
         netProfit: netProfit,
         ownerShare: ownerShare,
         partnerShare: partnerShare,
         marginShare: marginShare,
         status: status,
         voidReason: voidReason,
         createdAt: createdAt,
         updatedAt: updatedAt,
         deviceId: deviceId,
         device: device,
         rowVersion: rowVersion,
         syncStatus: syncStatus,
       );

  /// Returns a shallow copy of this [MonthlyDistribution]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  MonthlyDistribution copyWith({
    Object? id = _Undefined,
    int? year,
    int? month,
    int? netProfit,
    int? ownerShare,
    int? partnerShare,
    int? marginShare,
    _i2.RecordStatus? status,
    Object? voidReason = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
    _i1.UuidValue? deviceId,
    Object? device = _Undefined,
    int? rowVersion,
    _i3.SyncStatus? syncStatus,
  }) {
    return MonthlyDistribution(
      id: id is _i1.UuidValue? ? id : this.id,
      year: year ?? this.year,
      month: month ?? this.month,
      netProfit: netProfit ?? this.netProfit,
      ownerShare: ownerShare ?? this.ownerShare,
      partnerShare: partnerShare ?? this.partnerShare,
      marginShare: marginShare ?? this.marginShare,
      status: status ?? this.status,
      voidReason: voidReason is String? ? voidReason : this.voidReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      device: device is _i4.Device? ? device : this.device?.copyWith(),
      rowVersion: rowVersion ?? this.rowVersion,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
