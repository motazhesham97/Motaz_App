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
import 'sales_invoice.dart' as _i4;
import 'device.dart' as _i5;
import 'package:motaz_app_client/src/protocol/protocol.dart' as _i6;

abstract class SalesReturn implements _i1.SerializableModel {
  SalesReturn._({
    this.id,
    this.localRef,
    this.officialNo,
    required this.invoiceId,
    this.invoice,
    required this.returnDate,
    required this.totalReturnedAmount,
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

  factory SalesReturn({
    _i1.UuidValue? id,
    String? localRef,
    String? officialNo,
    required _i1.UuidValue invoiceId,
    _i4.SalesInvoice? invoice,
    required DateTime returnDate,
    required int totalReturnedAmount,
    String? note,
    _i2.RecordStatus? status,
    String? voidReason,
    required DateTime createdAt,
    required DateTime updatedAt,
    required _i1.UuidValue deviceId,
    _i5.Device? device,
    int? rowVersion,
    _i3.SyncStatus? syncStatus,
  }) = _SalesReturnImpl;

  factory SalesReturn.fromJson(Map<String, dynamic> jsonSerialization) {
    return SalesReturn(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      localRef: jsonSerialization['localRef'] as String?,
      officialNo: jsonSerialization['officialNo'] as String?,
      invoiceId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['invoiceId'],
      ),
      invoice: jsonSerialization['invoice'] == null
          ? null
          : _i6.Protocol().deserialize<_i4.SalesInvoice>(
              jsonSerialization['invoice'],
            ),
      returnDate: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['returnDate'],
      ),
      totalReturnedAmount: jsonSerialization['totalReturnedAmount'] as int,
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

  String? localRef;

  String? officialNo;

  _i1.UuidValue invoiceId;

  _i4.SalesInvoice? invoice;

  DateTime returnDate;

  int totalReturnedAmount;

  String? note;

  _i2.RecordStatus status;

  String? voidReason;

  DateTime createdAt;

  DateTime updatedAt;

  _i1.UuidValue deviceId;

  _i5.Device? device;

  int rowVersion;

  _i3.SyncStatus syncStatus;

  /// Returns a shallow copy of this [SalesReturn]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SalesReturn copyWith({
    _i1.UuidValue? id,
    String? localRef,
    String? officialNo,
    _i1.UuidValue? invoiceId,
    _i4.SalesInvoice? invoice,
    DateTime? returnDate,
    int? totalReturnedAmount,
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
      '__className__': 'SalesReturn',
      if (id != null) 'id': id?.toJson(),
      if (localRef != null) 'localRef': localRef,
      if (officialNo != null) 'officialNo': officialNo,
      'invoiceId': invoiceId.toJson(),
      if (invoice != null) 'invoice': invoice?.toJson(),
      'returnDate': returnDate.toJson(),
      'totalReturnedAmount': totalReturnedAmount,
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

class _SalesReturnImpl extends SalesReturn {
  _SalesReturnImpl({
    _i1.UuidValue? id,
    String? localRef,
    String? officialNo,
    required _i1.UuidValue invoiceId,
    _i4.SalesInvoice? invoice,
    required DateTime returnDate,
    required int totalReturnedAmount,
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
         invoiceId: invoiceId,
         invoice: invoice,
         returnDate: returnDate,
         totalReturnedAmount: totalReturnedAmount,
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

  /// Returns a shallow copy of this [SalesReturn]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SalesReturn copyWith({
    Object? id = _Undefined,
    Object? localRef = _Undefined,
    Object? officialNo = _Undefined,
    _i1.UuidValue? invoiceId,
    Object? invoice = _Undefined,
    DateTime? returnDate,
    int? totalReturnedAmount,
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
    return SalesReturn(
      id: id is _i1.UuidValue? ? id : this.id,
      localRef: localRef is String? ? localRef : this.localRef,
      officialNo: officialNo is String? ? officialNo : this.officialNo,
      invoiceId: invoiceId ?? this.invoiceId,
      invoice: invoice is _i4.SalesInvoice?
          ? invoice
          : this.invoice?.copyWith(),
      returnDate: returnDate ?? this.returnDate,
      totalReturnedAmount: totalReturnedAmount ?? this.totalReturnedAmount,
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
