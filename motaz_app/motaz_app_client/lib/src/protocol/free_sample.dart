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
import 'beneficiary.dart' as _i4;
import 'device.dart' as _i5;
import 'package:motaz_app_client/src/protocol/protocol.dart' as _i6;

abstract class FreeSample implements _i1.SerializableModel {
  FreeSample._({
    this.id,
    required this.localRef,
    this.officialNo,
    required this.beneficiaryId,
    this.beneficiary,
    required this.sampleDate,
    this.note,
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

  factory FreeSample({
    _i1.UuidValue? id,
    required String localRef,
    String? officialNo,
    required _i1.UuidValue beneficiaryId,
    _i4.Beneficiary? beneficiary,
    required DateTime sampleDate,
    String? note,
    _i2.RecordStatus? status,
    String? voidReason,
    required DateTime createdAt,
    required DateTime updatedAt,
    required _i1.UuidValue deviceId,
    _i5.Device? device,
    int? rowVersion,
    _i3.SyncStatus? syncStatus,
  }) = _FreeSampleImpl;

  factory FreeSample.fromJson(Map<String, dynamic> jsonSerialization) {
    return FreeSample(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      localRef: jsonSerialization['localRef'] as String,
      officialNo: jsonSerialization['officialNo'] as String?,
      beneficiaryId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['beneficiaryId'],
      ),
      beneficiary: jsonSerialization['beneficiary'] == null
          ? null
          : _i6.Protocol().deserialize<_i4.Beneficiary>(
              jsonSerialization['beneficiary'],
            ),
      sampleDate: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['sampleDate'],
      ),
      note: jsonSerialization['note'] as String?,
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
          : _i6.Protocol().deserialize<_i5.Device>(jsonSerialization['device']),
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

  String localRef;

  String? officialNo;

  _i1.UuidValue beneficiaryId;

  _i4.Beneficiary? beneficiary;

  DateTime sampleDate;

  String? note;

  _i2.RecordStatus status;

  String? voidReason;

  DateTime createdAt;

  DateTime updatedAt;

  _i1.UuidValue deviceId;

  _i5.Device? device;

  int rowVersion;

  _i3.SyncStatus syncStatus;

  /// Returns a shallow copy of this [FreeSample]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  FreeSample copyWith({
    _i1.UuidValue? id,
    String? localRef,
    String? officialNo,
    _i1.UuidValue? beneficiaryId,
    _i4.Beneficiary? beneficiary,
    DateTime? sampleDate,
    String? note,
    _i2.RecordStatus? status,
    String? voidReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    _i1.UuidValue? deviceId,
    _i5.Device? device,
    int? rowVersion,
    _i3.SyncStatus? syncStatus,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FreeSample',
      if (id != null) 'id': id?.toJson(),
      'localRef': localRef,
      if (officialNo != null) 'officialNo': officialNo,
      'beneficiaryId': beneficiaryId.toJson(),
      if (beneficiary != null) 'beneficiary': beneficiary?.toJson(),
      'sampleDate': sampleDate.toJson(),
      if (note != null) 'note': note,
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

class _FreeSampleImpl extends FreeSample {
  _FreeSampleImpl({
    _i1.UuidValue? id,
    required String localRef,
    String? officialNo,
    required _i1.UuidValue beneficiaryId,
    _i4.Beneficiary? beneficiary,
    required DateTime sampleDate,
    String? note,
    _i2.RecordStatus? status,
    String? voidReason,
    required DateTime createdAt,
    required DateTime updatedAt,
    required _i1.UuidValue deviceId,
    _i5.Device? device,
    int? rowVersion,
    _i3.SyncStatus? syncStatus,
  }) : super._(
         id: id,
         localRef: localRef,
         officialNo: officialNo,
         beneficiaryId: beneficiaryId,
         beneficiary: beneficiary,
         sampleDate: sampleDate,
         note: note,
         status: status,
         voidReason: voidReason,
         createdAt: createdAt,
         updatedAt: updatedAt,
         deviceId: deviceId,
         device: device,
         rowVersion: rowVersion,
         syncStatus: syncStatus,
       );

  /// Returns a shallow copy of this [FreeSample]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  FreeSample copyWith({
    Object? id = _Undefined,
    String? localRef,
    Object? officialNo = _Undefined,
    _i1.UuidValue? beneficiaryId,
    Object? beneficiary = _Undefined,
    DateTime? sampleDate,
    Object? note = _Undefined,
    _i2.RecordStatus? status,
    Object? voidReason = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
    _i1.UuidValue? deviceId,
    Object? device = _Undefined,
    int? rowVersion,
    _i3.SyncStatus? syncStatus,
  }) {
    return FreeSample(
      id: id is _i1.UuidValue? ? id : this.id,
      localRef: localRef ?? this.localRef,
      officialNo: officialNo is String? ? officialNo : this.officialNo,
      beneficiaryId: beneficiaryId ?? this.beneficiaryId,
      beneficiary: beneficiary is _i4.Beneficiary?
          ? beneficiary
          : this.beneficiary?.copyWith(),
      sampleDate: sampleDate ?? this.sampleDate,
      note: note is String? ? note : this.note,
      status: status ?? this.status,
      voidReason: voidReason is String? ? voidReason : this.voidReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      device: device is _i5.Device? ? device : this.device?.copyWith(),
      rowVersion: rowVersion ?? this.rowVersion,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
