/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: unnecessary_null_comparison

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;
import 'sales_invoice.dart' as _i2;
import 'product.dart' as _i3;
import 'package:motaz_app_server/src/generated/protocol.dart' as _i4;

abstract class SalesInvoiceLine
    implements _i1.TableRow<_i1.UuidValue?>, _i1.ProtocolSerialization {
  SalesInvoiceLine._({
    this.id,
    required this.invoiceId,
    this.invoice,
    required this.productId,
    this.product,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.productionDate,
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
    DateTime? productionDate,
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
      productionDate: jsonSerialization['productionDate'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['productionDate'],
            ),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = SalesInvoiceLineTable();

  static const db = SalesInvoiceLineRepository._();

  @override
  _i1.UuidValue? id;

  _i1.UuidValue invoiceId;

  _i2.SalesInvoice? invoice;

  _i1.UuidValue productId;

  _i3.Product? product;

  int quantity;

  int unitPrice;

  int lineTotal;

  DateTime? productionDate;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _i1.Table<_i1.UuidValue?> get table => t;

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
    DateTime? productionDate,
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
      if (productionDate != null) 'productionDate': productionDate?.toJson(),
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SalesInvoiceLine',
      if (id != null) 'id': id?.toJson(),
      'invoiceId': invoiceId.toJson(),
      if (invoice != null) 'invoice': invoice?.toJsonForProtocol(),
      'productId': productId.toJson(),
      if (product != null) 'product': product?.toJsonForProtocol(),
      'quantity': quantity,
      'unitPrice': unitPrice,
      'lineTotal': lineTotal,
      if (productionDate != null) 'productionDate': productionDate?.toJson(),
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  static SalesInvoiceLineInclude include({
    _i2.SalesInvoiceInclude? invoice,
    _i3.ProductInclude? product,
  }) {
    return SalesInvoiceLineInclude._(
      invoice: invoice,
      product: product,
    );
  }

  static SalesInvoiceLineIncludeList includeList({
    _i1.WhereExpressionBuilder<SalesInvoiceLineTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SalesInvoiceLineTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SalesInvoiceLineTable>? orderByList,
    SalesInvoiceLineInclude? include,
  }) {
    return SalesInvoiceLineIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SalesInvoiceLine.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(SalesInvoiceLine.t),
      include: include,
    );
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
    DateTime? productionDate,
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
         productionDate: productionDate,
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
    Object? productionDate = _Undefined,
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
      productionDate: productionDate is DateTime?
          ? productionDate
          : this.productionDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class SalesInvoiceLineUpdateTable
    extends _i1.UpdateTable<SalesInvoiceLineTable> {
  SalesInvoiceLineUpdateTable(super.table);

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> invoiceId(
    _i1.UuidValue value,
  ) => _i1.ColumnValue(
    table.invoiceId,
    value,
  );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> productId(
    _i1.UuidValue value,
  ) => _i1.ColumnValue(
    table.productId,
    value,
  );

  _i1.ColumnValue<int, int> quantity(int value) => _i1.ColumnValue(
    table.quantity,
    value,
  );

  _i1.ColumnValue<int, int> unitPrice(int value) => _i1.ColumnValue(
    table.unitPrice,
    value,
  );

  _i1.ColumnValue<int, int> lineTotal(int value) => _i1.ColumnValue(
    table.lineTotal,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> productionDate(DateTime? value) =>
      _i1.ColumnValue(
        table.productionDate,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _i1.ColumnValue(
        table.updatedAt,
        value,
      );
}

class SalesInvoiceLineTable extends _i1.Table<_i1.UuidValue?> {
  SalesInvoiceLineTable({super.tableRelation})
    : super(tableName: 'sales_invoice_line') {
    updateTable = SalesInvoiceLineUpdateTable(this);
    invoiceId = _i1.ColumnUuid(
      'invoiceId',
      this,
    );
    productId = _i1.ColumnUuid(
      'productId',
      this,
    );
    quantity = _i1.ColumnInt(
      'quantity',
      this,
    );
    unitPrice = _i1.ColumnInt(
      'unitPrice',
      this,
    );
    lineTotal = _i1.ColumnInt(
      'lineTotal',
      this,
    );
    productionDate = _i1.ColumnDateTime(
      'productionDate',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
    updatedAt = _i1.ColumnDateTime(
      'updatedAt',
      this,
    );
  }

  late final SalesInvoiceLineUpdateTable updateTable;

  late final _i1.ColumnUuid invoiceId;

  _i2.SalesInvoiceTable? _invoice;

  late final _i1.ColumnUuid productId;

  _i3.ProductTable? _product;

  late final _i1.ColumnInt quantity;

  late final _i1.ColumnInt unitPrice;

  late final _i1.ColumnInt lineTotal;

  late final _i1.ColumnDateTime productionDate;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  _i2.SalesInvoiceTable get invoice {
    if (_invoice != null) return _invoice!;
    _invoice = _i1.createRelationTable(
      relationFieldName: 'invoice',
      field: SalesInvoiceLine.t.invoiceId,
      foreignField: _i2.SalesInvoice.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i2.SalesInvoiceTable(tableRelation: foreignTableRelation),
    );
    return _invoice!;
  }

  _i3.ProductTable get product {
    if (_product != null) return _product!;
    _product = _i1.createRelationTable(
      relationFieldName: 'product',
      field: SalesInvoiceLine.t.productId,
      foreignField: _i3.Product.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i3.ProductTable(tableRelation: foreignTableRelation),
    );
    return _product!;
  }

  @override
  List<_i1.Column> get columns => [
    id,
    invoiceId,
    productId,
    quantity,
    unitPrice,
    lineTotal,
    productionDate,
    createdAt,
    updatedAt,
  ];

  @override
  _i1.Table? getRelationTable(String relationField) {
    if (relationField == 'invoice') {
      return invoice;
    }
    if (relationField == 'product') {
      return product;
    }
    return null;
  }
}

class SalesInvoiceLineInclude extends _i1.IncludeObject {
  SalesInvoiceLineInclude._({
    _i2.SalesInvoiceInclude? invoice,
    _i3.ProductInclude? product,
  }) {
    _invoice = invoice;
    _product = product;
  }

  _i2.SalesInvoiceInclude? _invoice;

  _i3.ProductInclude? _product;

  @override
  Map<String, _i1.Include?> get includes => {
    'invoice': _invoice,
    'product': _product,
  };

  @override
  _i1.Table<_i1.UuidValue?> get table => SalesInvoiceLine.t;
}

class SalesInvoiceLineIncludeList extends _i1.IncludeList {
  SalesInvoiceLineIncludeList._({
    _i1.WhereExpressionBuilder<SalesInvoiceLineTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(SalesInvoiceLine.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue?> get table => SalesInvoiceLine.t;
}

class SalesInvoiceLineRepository {
  const SalesInvoiceLineRepository._();

  final attachRow = const SalesInvoiceLineAttachRowRepository._();

  /// Returns a list of [SalesInvoiceLine]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<SalesInvoiceLine>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<SalesInvoiceLineTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SalesInvoiceLineTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SalesInvoiceLineTable>? orderByList,
    _i1.Transaction? transaction,
    SalesInvoiceLineInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<SalesInvoiceLine>(
      where: where?.call(SalesInvoiceLine.t),
      orderBy: orderBy?.call(SalesInvoiceLine.t),
      orderByList: orderByList?.call(SalesInvoiceLine.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [SalesInvoiceLine] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<SalesInvoiceLine?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<SalesInvoiceLineTable>? where,
    int? offset,
    _i1.OrderByBuilder<SalesInvoiceLineTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SalesInvoiceLineTable>? orderByList,
    _i1.Transaction? transaction,
    SalesInvoiceLineInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<SalesInvoiceLine>(
      where: where?.call(SalesInvoiceLine.t),
      orderBy: orderBy?.call(SalesInvoiceLine.t),
      orderByList: orderByList?.call(SalesInvoiceLine.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [SalesInvoiceLine] by its [id] or null if no such row exists.
  Future<SalesInvoiceLine?> findById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    SalesInvoiceLineInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<SalesInvoiceLine>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [SalesInvoiceLine]s in the list and returns the inserted rows.
  ///
  /// The returned [SalesInvoiceLine]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<SalesInvoiceLine>> insert(
    _i1.DatabaseSession session,
    List<SalesInvoiceLine> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<SalesInvoiceLine>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [SalesInvoiceLine] and returns the inserted row.
  ///
  /// The returned [SalesInvoiceLine] will have its `id` field set.
  Future<SalesInvoiceLine> insertRow(
    _i1.DatabaseSession session,
    SalesInvoiceLine row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<SalesInvoiceLine>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [SalesInvoiceLine]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<SalesInvoiceLine>> update(
    _i1.DatabaseSession session,
    List<SalesInvoiceLine> rows, {
    _i1.ColumnSelections<SalesInvoiceLineTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<SalesInvoiceLine>(
      rows,
      columns: columns?.call(SalesInvoiceLine.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SalesInvoiceLine]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<SalesInvoiceLine> updateRow(
    _i1.DatabaseSession session,
    SalesInvoiceLine row, {
    _i1.ColumnSelections<SalesInvoiceLineTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<SalesInvoiceLine>(
      row,
      columns: columns?.call(SalesInvoiceLine.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SalesInvoiceLine] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<SalesInvoiceLine?> updateById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<SalesInvoiceLineUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<SalesInvoiceLine>(
      id,
      columnValues: columnValues(SalesInvoiceLine.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [SalesInvoiceLine]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<SalesInvoiceLine>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<SalesInvoiceLineUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<SalesInvoiceLineTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SalesInvoiceLineTable>? orderBy,
    _i1.OrderByListBuilder<SalesInvoiceLineTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<SalesInvoiceLine>(
      columnValues: columnValues(SalesInvoiceLine.t.updateTable),
      where: where(SalesInvoiceLine.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SalesInvoiceLine.t),
      orderByList: orderByList?.call(SalesInvoiceLine.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [SalesInvoiceLine]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<SalesInvoiceLine>> delete(
    _i1.DatabaseSession session,
    List<SalesInvoiceLine> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<SalesInvoiceLine>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [SalesInvoiceLine].
  Future<SalesInvoiceLine> deleteRow(
    _i1.DatabaseSession session,
    SalesInvoiceLine row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<SalesInvoiceLine>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<SalesInvoiceLine>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<SalesInvoiceLineTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<SalesInvoiceLine>(
      where: where(SalesInvoiceLine.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<SalesInvoiceLineTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<SalesInvoiceLine>(
      where: where?.call(SalesInvoiceLine.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [SalesInvoiceLine] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<SalesInvoiceLineTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<SalesInvoiceLine>(
      where: where(SalesInvoiceLine.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class SalesInvoiceLineAttachRowRepository {
  const SalesInvoiceLineAttachRowRepository._();

  /// Creates a relation between the given [SalesInvoiceLine] and [SalesInvoice]
  /// by setting the [SalesInvoiceLine]'s foreign key `invoiceId` to refer to the [SalesInvoice].
  Future<void> invoice(
    _i1.DatabaseSession session,
    SalesInvoiceLine salesInvoiceLine,
    _i2.SalesInvoice invoice, {
    _i1.Transaction? transaction,
  }) async {
    if (salesInvoiceLine.id == null) {
      throw ArgumentError.notNull('salesInvoiceLine.id');
    }
    if (invoice.id == null) {
      throw ArgumentError.notNull('invoice.id');
    }

    var $salesInvoiceLine = salesInvoiceLine.copyWith(invoiceId: invoice.id);
    await session.db.updateRow<SalesInvoiceLine>(
      $salesInvoiceLine,
      columns: [SalesInvoiceLine.t.invoiceId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [SalesInvoiceLine] and [Product]
  /// by setting the [SalesInvoiceLine]'s foreign key `productId` to refer to the [Product].
  Future<void> product(
    _i1.DatabaseSession session,
    SalesInvoiceLine salesInvoiceLine,
    _i3.Product product, {
    _i1.Transaction? transaction,
  }) async {
    if (salesInvoiceLine.id == null) {
      throw ArgumentError.notNull('salesInvoiceLine.id');
    }
    if (product.id == null) {
      throw ArgumentError.notNull('product.id');
    }

    var $salesInvoiceLine = salesInvoiceLine.copyWith(productId: product.id);
    await session.db.updateRow<SalesInvoiceLine>(
      $salesInvoiceLine,
      columns: [SalesInvoiceLine.t.productId],
      transaction: transaction,
    );
  }
}
