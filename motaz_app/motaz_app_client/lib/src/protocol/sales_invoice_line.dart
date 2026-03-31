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
import 'sales_invoice.dart' as _i2;
import 'product.dart' as _i3;
import 'package:motaz_app_client/src/protocol/protocol.dart' as _i4;

abstract class SalesInvoiceLine implements _i1.SerializableModel {
  SalesInvoiceLine._({
    this.id,
    required this.invoiceId,
    this.invoice,
    required this.productId,
    this.product,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SalesInvoiceLine({
    _i1.UuidValue? id,
    required _i1.UuidValue invoiceId,
    _i2.SalesInvoice? invoice,
    required _i1.UuidValue productId,
    _i3.Product? product,
    required int quantity,
    required int unitPrice,
    required int lineTotal,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _SalesInvoiceLineImpl;

  factory SalesInvoiceLine.fromJson(Map<String, dynamic> jsonSerialization) {
    return SalesInvoiceLine(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      invoiceId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['invoiceId'],
      ),
      invoice: jsonSerialization['invoice'] == null
          ? null
          : _i4.Protocol().deserialize<_i2.SalesInvoice>(
              jsonSerialization['invoice'],
            ),
      productId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['productId'],
      ),
      product: jsonSerialization['product'] == null
          ? null
          : _i4.Protocol().deserialize<_i3.Product>(
              jsonSerialization['product'],
            ),
      quantity: jsonSerialization['quantity'] as int,
      unitPrice: jsonSerialization['unitPrice'] as int,
      lineTotal: jsonSerialization['lineTotal'] as int,
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

  _i1.UuidValue invoiceId;

  _i2.SalesInvoice? invoice;

  _i1.UuidValue productId;

  _i3.Product? product;

  int quantity;

  int unitPrice;

  int lineTotal;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [SalesInvoiceLine]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SalesInvoiceLine copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? invoiceId,
    _i2.SalesInvoice? invoice,
    _i1.UuidValue? productId,
    _i3.Product? product,
    int? quantity,
    int? unitPrice,
    int? lineTotal,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SalesInvoiceLine',
      if (id != null) 'id': id?.toJson(),
      'invoiceId': invoiceId.toJson(),
      if (invoice != null) 'invoice': invoice?.toJson(),
      'productId': productId.toJson(),
      if (product != null) 'product': product?.toJson(),
      'quantity': quantity,
      'unitPrice': unitPrice,
      'lineTotal': lineTotal,
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

class _SalesInvoiceLineImpl extends SalesInvoiceLine {
  _SalesInvoiceLineImpl({
    _i1.UuidValue? id,
    required _i1.UuidValue invoiceId,
    _i2.SalesInvoice? invoice,
    required _i1.UuidValue productId,
    _i3.Product? product,
    required int quantity,
    required int unitPrice,
    required int lineTotal,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         invoiceId: invoiceId,
         invoice: invoice,
         productId: productId,
         product: product,
         quantity: quantity,
         unitPrice: unitPrice,
         lineTotal: lineTotal,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [SalesInvoiceLine]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SalesInvoiceLine copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? invoiceId,
    Object? invoice = _Undefined,
    _i1.UuidValue? productId,
    Object? product = _Undefined,
    int? quantity,
    int? unitPrice,
    int? lineTotal,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SalesInvoiceLine(
      id: id is _i1.UuidValue? ? id : this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      invoice: invoice is _i2.SalesInvoice?
          ? invoice
          : this.invoice?.copyWith(),
      productId: productId ?? this.productId,
      product: product is _i3.Product? ? product : this.product?.copyWith(),
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      lineTotal: lineTotal ?? this.lineTotal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
