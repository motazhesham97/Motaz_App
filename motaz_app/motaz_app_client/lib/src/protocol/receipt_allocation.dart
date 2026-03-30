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
import 'receipt.dart' as _i2;
import 'sales_invoice.dart' as _i3;
import 'package:motaz_app_client/src/protocol/protocol.dart' as _i4;

abstract class ReceiptAllocation implements _i1.SerializableModel {
  ReceiptAllocation._({
    this.id,
    required this.receiptId,
    this.receipt,
    required this.invoiceId,
    this.invoice,
    required this.allocatedAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReceiptAllocation({
    _i1.UuidValue? id,
    required _i1.UuidValue receiptId,
    _i2.Receipt? receipt,
    required _i1.UuidValue invoiceId,
    _i3.SalesInvoice? invoice,
    required int allocatedAmount,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ReceiptAllocationImpl;

  factory ReceiptAllocation.fromJson(Map<String, dynamic> jsonSerialization) {
    return ReceiptAllocation(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      receiptId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['receiptId'],
      ),
      receipt: jsonSerialization['receipt'] == null
          ? null
          : _i4.Protocol().deserialize<_i2.Receipt>(
              jsonSerialization['receipt'],
            ),
      invoiceId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['invoiceId'],
      ),
      invoice: jsonSerialization['invoice'] == null
          ? null
          : _i4.Protocol().deserialize<_i3.SalesInvoice>(
              jsonSerialization['invoice'],
            ),
      allocatedAmount: jsonSerialization['allocatedAmount'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _i1.UuidValue? id;

  _i1.UuidValue receiptId;

  _i2.Receipt? receipt;

  _i1.UuidValue invoiceId;

  _i3.SalesInvoice? invoice;

  int allocatedAmount;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [ReceiptAllocation]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ReceiptAllocation copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? receiptId,
    _i2.Receipt? receipt,
    _i1.UuidValue? invoiceId,
    _i3.SalesInvoice? invoice,
    int? allocatedAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ReceiptAllocation',
      if (id != null) 'id': id?.toJson(),
      'receiptId': receiptId.toJson(),
      if (receipt != null) 'receipt': receipt?.toJson(),
      'invoiceId': invoiceId.toJson(),
      if (invoice != null) 'invoice': invoice?.toJson(),
      'allocatedAmount': allocatedAmount,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ReceiptAllocationImpl extends ReceiptAllocation {
  _ReceiptAllocationImpl({
    _i1.UuidValue? id,
    required _i1.UuidValue receiptId,
    _i2.Receipt? receipt,
    required _i1.UuidValue invoiceId,
    _i3.SalesInvoice? invoice,
    required int allocatedAmount,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         receiptId: receiptId,
         receipt: receipt,
         invoiceId: invoiceId,
         invoice: invoice,
         allocatedAmount: allocatedAmount,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [ReceiptAllocation]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ReceiptAllocation copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? receiptId,
    Object? receipt = _Undefined,
    _i1.UuidValue? invoiceId,
    Object? invoice = _Undefined,
    int? allocatedAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReceiptAllocation(
      id: id is _i1.UuidValue? ? id : this.id,
      receiptId: receiptId ?? this.receiptId,
      receipt: receipt is _i2.Receipt? ? receipt : this.receipt?.copyWith(),
      invoiceId: invoiceId ?? this.invoiceId,
      invoice: invoice is _i3.SalesInvoice?
          ? invoice
          : this.invoice?.copyWith(),
      allocatedAmount: allocatedAmount ?? this.allocatedAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
