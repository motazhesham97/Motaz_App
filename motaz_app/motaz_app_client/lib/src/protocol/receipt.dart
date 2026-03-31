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
import 'enums/receipt_type.dart' as _i4;
import 'client_record.dart' as _i5;
import 'sales_invoice.dart' as _i6;
import 'device.dart' as _i7;
import 'package:motaz_app_client/src/protocol/protocol.dart' as _i8;

abstract class Receipt implements _i1.SerializableModel {
  Receipt._({
    this.id,
    required this.receiptType,
    required this.clientId,
    this.client,
    this.invoiceId,
    this.invoice,
    required this.amount,
    required this.receiptDate,
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

  factory Receipt({
    _i1.UuidValue? id,
    required _i4.ReceiptType receiptType,
    required _i1.UuidValue clientId,
    _i5.ClientRecord? client,
    _i1.UuidValue? invoiceId,
    _i6.SalesInvoice? invoice,
    required int amount,
    required DateTime receiptDate,
    String? note,
    _i2.RecordStatus? status,
    String? voidReason,
    required DateTime createdAt,
    required DateTime updatedAt,
    required _i1.UuidValue deviceId,
    _i7.Device? device,
    int? rowVersion,
    _i3.SyncStatus? syncStatus,
  }) = _ReceiptImpl;

  factory Receipt.fromJson(Map<String, dynamic> jsonSerialization) {
    return Receipt(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      receiptType: _i4.ReceiptType.fromJson(
        (jsonSerialization['receiptType'] as String),
      ),
      clientId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['clientId'],
      ),
      client: jsonSerialization['client'] == null
          ? null
          : _i8.Protocol().deserialize<_i5.ClientRecord>(
              jsonSerialization['client'],
            ),
      invoiceId: jsonSerialization['invoiceId'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['invoiceId']),
      invoice: jsonSerialization['invoice'] == null
          ? null
          : _i8.Protocol().deserialize<_i6.SalesInvoice>(
              jsonSerialization['invoice'],
            ),
      amount: jsonSerialization['amount'] as int,
      receiptDate: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['receiptDate'],
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
          : _i8.Protocol().deserialize<_i7.Device>(jsonSerialization['device']),
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

  _i4.ReceiptType receiptType;

  _i1.UuidValue clientId;

  _i5.ClientRecord? client;

  _i1.UuidValue? invoiceId;

  _i6.SalesInvoice? invoice;

  int amount;

  DateTime receiptDate;

  String? note;

  _i2.RecordStatus status;

  String? voidReason;

  DateTime createdAt;

  DateTime updatedAt;

  _i1.UuidValue deviceId;

  _i7.Device? device;

  int rowVersion;

  _i3.SyncStatus syncStatus;

  /// Returns a shallow copy of this [Receipt]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Receipt copyWith({
    _i1.UuidValue? id,
    _i4.ReceiptType? receiptType,
    _i1.UuidValue? clientId,
    _i5.ClientRecord? client,
    _i1.UuidValue? invoiceId,
    _i6.SalesInvoice? invoice,
    int? amount,
    DateTime? receiptDate,
    String? note,
    _i2.RecordStatus? status,
    String? voidReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    _i1.UuidValue? deviceId,
    _i7.Device? device,
    int? rowVersion,
    _i3.SyncStatus? syncStatus,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Receipt',
      if (id != null) 'id': id?.toJson(),
      'receiptType': receiptType.toJson(),
      'clientId': clientId.toJson(),
      if (client != null) 'client': client?.toJson(),
      if (invoiceId != null) 'invoiceId': invoiceId?.toJson(),
      if (invoice != null) 'invoice': invoice?.toJson(),
      'amount': amount,
      'receiptDate': receiptDate.toJson(),
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

class _ReceiptImpl extends Receipt {
  _ReceiptImpl({
    _i1.UuidValue? id,
    required _i4.ReceiptType receiptType,
    required _i1.UuidValue clientId,
    _i5.ClientRecord? client,
    _i1.UuidValue? invoiceId,
    _i6.SalesInvoice? invoice,
    required int amount,
    required DateTime receiptDate,
    String? note,
    _i2.RecordStatus? status,
    String? voidReason,
    required DateTime createdAt,
    required DateTime updatedAt,
    required _i1.UuidValue deviceId,
    _i7.Device? device,
    int? rowVersion,
    _i3.SyncStatus? syncStatus,
  }) : super._(
         id: id,
         receiptType: receiptType,
         clientId: clientId,
         client: client,
         invoiceId: invoiceId,
         invoice: invoice,
         amount: amount,
         receiptDate: receiptDate,
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

  /// Returns a shallow copy of this [Receipt]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Receipt copyWith({
    Object? id = _Undefined,
    _i4.ReceiptType? receiptType,
    _i1.UuidValue? clientId,
    Object? client = _Undefined,
    Object? invoiceId = _Undefined,
    Object? invoice = _Undefined,
    int? amount,
    DateTime? receiptDate,
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
    return Receipt(
      id: id is _i1.UuidValue? ? id : this.id,
      receiptType: receiptType ?? this.receiptType,
      clientId: clientId ?? this.clientId,
      client: client is _i5.ClientRecord? ? client : this.client?.copyWith(),
      invoiceId: invoiceId is _i1.UuidValue? ? invoiceId : this.invoiceId,
      invoice: invoice is _i6.SalesInvoice?
          ? invoice
          : this.invoice?.copyWith(),
      amount: amount ?? this.amount,
      receiptDate: receiptDate ?? this.receiptDate,
      note: note is String? ? note : this.note,
      status: status ?? this.status,
      voidReason: voidReason is String? ? voidReason : this.voidReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      device: device is _i7.Device? ? device : this.device?.copyWith(),
      rowVersion: rowVersion ?? this.rowVersion,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
