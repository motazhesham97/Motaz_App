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
import 'sales_return.dart' as _i2;
import 'sales_invoice_line.dart' as _i3;
import 'package:motaz_app_client/src/protocol/protocol.dart' as _i4;

abstract class SalesReturnLine implements _i1.SerializableModel {
  SalesReturnLine._({
    this.id,
    required this.returnId,
    this.salesReturn,
    required this.invoiceLineId,
    this.invoiceLine,
    required this.returnedQuantity,
    required this.returnedAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SalesReturnLine({
    _i1.UuidValue? id,
    required _i1.UuidValue returnId,
    _i2.SalesReturn? salesReturn,
    required _i1.UuidValue invoiceLineId,
    _i3.SalesInvoiceLine? invoiceLine,
    required int returnedQuantity,
    required int returnedAmount,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _SalesReturnLineImpl;

  factory SalesReturnLine.fromJson(Map<String, dynamic> jsonSerialization) {
    return SalesReturnLine(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      returnId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['returnId'],
      ),
      salesReturn: jsonSerialization['salesReturn'] == null
          ? null
          : _i4.Protocol().deserialize<_i2.SalesReturn>(
              jsonSerialization['salesReturn'],
            ),
      invoiceLineId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['invoiceLineId'],
      ),
      invoiceLine: jsonSerialization['invoiceLine'] == null
          ? null
          : _i4.Protocol().deserialize<_i3.SalesInvoiceLine>(
              jsonSerialization['invoiceLine'],
            ),
      returnedQuantity: jsonSerialization['returnedQuantity'] as int,
      returnedAmount: jsonSerialization['returnedAmount'] as int,
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

  _i1.UuidValue returnId;

  _i2.SalesReturn? salesReturn;

  _i1.UuidValue invoiceLineId;

  _i3.SalesInvoiceLine? invoiceLine;

  int returnedQuantity;

  int returnedAmount;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [SalesReturnLine]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SalesReturnLine copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? returnId,
    _i2.SalesReturn? salesReturn,
    _i1.UuidValue? invoiceLineId,
    _i3.SalesInvoiceLine? invoiceLine,
    int? returnedQuantity,
    int? returnedAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SalesReturnLine',
      if (id != null) 'id': id?.toJson(),
      'returnId': returnId.toJson(),
      if (salesReturn != null) 'salesReturn': salesReturn?.toJson(),
      'invoiceLineId': invoiceLineId.toJson(),
      if (invoiceLine != null) 'invoiceLine': invoiceLine?.toJson(),
      'returnedQuantity': returnedQuantity,
      'returnedAmount': returnedAmount,
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

class _SalesReturnLineImpl extends SalesReturnLine {
  _SalesReturnLineImpl({
    _i1.UuidValue? id,
    required _i1.UuidValue returnId,
    _i2.SalesReturn? salesReturn,
    required _i1.UuidValue invoiceLineId,
    _i3.SalesInvoiceLine? invoiceLine,
    required int returnedQuantity,
    required int returnedAmount,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         returnId: returnId,
         salesReturn: salesReturn,
         invoiceLineId: invoiceLineId,
         invoiceLine: invoiceLine,
         returnedQuantity: returnedQuantity,
         returnedAmount: returnedAmount,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [SalesReturnLine]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SalesReturnLine copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? returnId,
    Object? salesReturn = _Undefined,
    _i1.UuidValue? invoiceLineId,
    Object? invoiceLine = _Undefined,
    int? returnedQuantity,
    int? returnedAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SalesReturnLine(
      id: id is _i1.UuidValue? ? id : this.id,
      returnId: returnId ?? this.returnId,
      salesReturn: salesReturn is _i2.SalesReturn?
          ? salesReturn
          : this.salesReturn?.copyWith(),
      invoiceLineId: invoiceLineId ?? this.invoiceLineId,
      invoiceLine: invoiceLine is _i3.SalesInvoiceLine?
          ? invoiceLine
          : this.invoiceLine?.copyWith(),
      returnedQuantity: returnedQuantity ?? this.returnedQuantity,
      returnedAmount: returnedAmount ?? this.returnedAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
