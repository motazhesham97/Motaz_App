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
import 'sales_return.dart' as _i2;
import 'sales_invoice_line.dart' as _i3;
import 'package:motaz_app_server/src/generated/protocol.dart' as _i4;

abstract class SalesReturnLine
    implements _i1.TableRow<_i1.UuidValue?>, _i1.ProtocolSerialization {
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

  static final t = SalesReturnLineTable();

  static const db = SalesReturnLineRepository._();

  @override
  _i1.UuidValue? id;

  _i1.UuidValue returnId;

  _i2.SalesReturn? salesReturn;

  _i1.UuidValue invoiceLineId;

  _i3.SalesInvoiceLine? invoiceLine;

  int returnedQuantity;

  int returnedAmount;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _i1.Table<_i1.UuidValue?> get table => t;

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
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SalesReturnLine',
      if (id != null) 'id': id?.toJson(),
      'returnId': returnId.toJson(),
      if (salesReturn != null) 'salesReturn': salesReturn?.toJsonForProtocol(),
      'invoiceLineId': invoiceLineId.toJson(),
      if (invoiceLine != null) 'invoiceLine': invoiceLine?.toJsonForProtocol(),
      'returnedQuantity': returnedQuantity,
      'returnedAmount': returnedAmount,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  static SalesReturnLineInclude include({
    _i2.SalesReturnInclude? salesReturn,
    _i3.SalesInvoiceLineInclude? invoiceLine,
  }) {
    return SalesReturnLineInclude._(
      salesReturn: salesReturn,
      invoiceLine: invoiceLine,
    );
  }

  static SalesReturnLineIncludeList includeList({
    _i1.WhereExpressionBuilder<SalesReturnLineTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SalesReturnLineTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SalesReturnLineTable>? orderByList,
    SalesReturnLineInclude? include,
  }) {
    return SalesReturnLineIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SalesReturnLine.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(SalesReturnLine.t),
      include: include,
    );
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

class SalesReturnLineUpdateTable extends _i1.UpdateTable<SalesReturnLineTable> {
  SalesReturnLineUpdateTable(super.table);

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> returnId(_i1.UuidValue value) =>
      _i1.ColumnValue(
        table.returnId,
        value,
      );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> invoiceLineId(
    _i1.UuidValue value,
  ) => _i1.ColumnValue(
    table.invoiceLineId,
    value,
  );

  _i1.ColumnValue<int, int> returnedQuantity(int value) => _i1.ColumnValue(
    table.returnedQuantity,
    value,
  );

  _i1.ColumnValue<int, int> returnedAmount(int value) => _i1.ColumnValue(
    table.returnedAmount,
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

class SalesReturnLineTable extends _i1.Table<_i1.UuidValue?> {
  SalesReturnLineTable({super.tableRelation})
    : super(tableName: 'sales_return_line') {
    updateTable = SalesReturnLineUpdateTable(this);
    returnId = _i1.ColumnUuid(
      'returnId',
      this,
    );
    invoiceLineId = _i1.ColumnUuid(
      'invoiceLineId',
      this,
    );
    returnedQuantity = _i1.ColumnInt(
      'returnedQuantity',
      this,
    );
    returnedAmount = _i1.ColumnInt(
      'returnedAmount',
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

  late final SalesReturnLineUpdateTable updateTable;

  late final _i1.ColumnUuid returnId;

  _i2.SalesReturnTable? _salesReturn;

  late final _i1.ColumnUuid invoiceLineId;

  _i3.SalesInvoiceLineTable? _invoiceLine;

  late final _i1.ColumnInt returnedQuantity;

  late final _i1.ColumnInt returnedAmount;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  _i2.SalesReturnTable get salesReturn {
    if (_salesReturn != null) return _salesReturn!;
    _salesReturn = _i1.createRelationTable(
      relationFieldName: 'salesReturn',
      field: SalesReturnLine.t.returnId,
      foreignField: _i2.SalesReturn.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i2.SalesReturnTable(tableRelation: foreignTableRelation),
    );
    return _salesReturn!;
  }

  _i3.SalesInvoiceLineTable get invoiceLine {
    if (_invoiceLine != null) return _invoiceLine!;
    _invoiceLine = _i1.createRelationTable(
      relationFieldName: 'invoiceLine',
      field: SalesReturnLine.t.invoiceLineId,
      foreignField: _i3.SalesInvoiceLine.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i3.SalesInvoiceLineTable(tableRelation: foreignTableRelation),
    );
    return _invoiceLine!;
  }

  @override
  List<_i1.Column> get columns => [
    id,
    returnId,
    invoiceLineId,
    returnedQuantity,
    returnedAmount,
    createdAt,
    updatedAt,
  ];

  @override
  _i1.Table? getRelationTable(String relationField) {
    if (relationField == 'salesReturn') {
      return salesReturn;
    }
    if (relationField == 'invoiceLine') {
      return invoiceLine;
    }
    return null;
  }
}

class SalesReturnLineInclude extends _i1.IncludeObject {
  SalesReturnLineInclude._({
    _i2.SalesReturnInclude? salesReturn,
    _i3.SalesInvoiceLineInclude? invoiceLine,
  }) {
    _salesReturn = salesReturn;
    _invoiceLine = invoiceLine;
  }

  _i2.SalesReturnInclude? _salesReturn;

  _i3.SalesInvoiceLineInclude? _invoiceLine;

  @override
  Map<String, _i1.Include?> get includes => {
    'salesReturn': _salesReturn,
    'invoiceLine': _invoiceLine,
  };

  @override
  _i1.Table<_i1.UuidValue?> get table => SalesReturnLine.t;
}

class SalesReturnLineIncludeList extends _i1.IncludeList {
  SalesReturnLineIncludeList._({
    _i1.WhereExpressionBuilder<SalesReturnLineTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(SalesReturnLine.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue?> get table => SalesReturnLine.t;
}

class SalesReturnLineRepository {
  const SalesReturnLineRepository._();

  final attachRow = const SalesReturnLineAttachRowRepository._();

  /// Returns a list of [SalesReturnLine]s matching the given query parameters.
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
  Future<List<SalesReturnLine>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<SalesReturnLineTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SalesReturnLineTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SalesReturnLineTable>? orderByList,
    _i1.Transaction? transaction,
    SalesReturnLineInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<SalesReturnLine>(
      where: where?.call(SalesReturnLine.t),
      orderBy: orderBy?.call(SalesReturnLine.t),
      orderByList: orderByList?.call(SalesReturnLine.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [SalesReturnLine] matching the given query parameters.
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
  Future<SalesReturnLine?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<SalesReturnLineTable>? where,
    int? offset,
    _i1.OrderByBuilder<SalesReturnLineTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SalesReturnLineTable>? orderByList,
    _i1.Transaction? transaction,
    SalesReturnLineInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<SalesReturnLine>(
      where: where?.call(SalesReturnLine.t),
      orderBy: orderBy?.call(SalesReturnLine.t),
      orderByList: orderByList?.call(SalesReturnLine.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [SalesReturnLine] by its [id] or null if no such row exists.
  Future<SalesReturnLine?> findById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    SalesReturnLineInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<SalesReturnLine>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [SalesReturnLine]s in the list and returns the inserted rows.
  ///
  /// The returned [SalesReturnLine]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<SalesReturnLine>> insert(
    _i1.DatabaseSession session,
    List<SalesReturnLine> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<SalesReturnLine>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [SalesReturnLine] and returns the inserted row.
  ///
  /// The returned [SalesReturnLine] will have its `id` field set.
  Future<SalesReturnLine> insertRow(
    _i1.DatabaseSession session,
    SalesReturnLine row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<SalesReturnLine>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [SalesReturnLine]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<SalesReturnLine>> update(
    _i1.DatabaseSession session,
    List<SalesReturnLine> rows, {
    _i1.ColumnSelections<SalesReturnLineTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<SalesReturnLine>(
      rows,
      columns: columns?.call(SalesReturnLine.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SalesReturnLine]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<SalesReturnLine> updateRow(
    _i1.DatabaseSession session,
    SalesReturnLine row, {
    _i1.ColumnSelections<SalesReturnLineTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<SalesReturnLine>(
      row,
      columns: columns?.call(SalesReturnLine.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SalesReturnLine] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<SalesReturnLine?> updateById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<SalesReturnLineUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<SalesReturnLine>(
      id,
      columnValues: columnValues(SalesReturnLine.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [SalesReturnLine]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<SalesReturnLine>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<SalesReturnLineUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<SalesReturnLineTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SalesReturnLineTable>? orderBy,
    _i1.OrderByListBuilder<SalesReturnLineTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<SalesReturnLine>(
      columnValues: columnValues(SalesReturnLine.t.updateTable),
      where: where(SalesReturnLine.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SalesReturnLine.t),
      orderByList: orderByList?.call(SalesReturnLine.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [SalesReturnLine]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<SalesReturnLine>> delete(
    _i1.DatabaseSession session,
    List<SalesReturnLine> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<SalesReturnLine>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [SalesReturnLine].
  Future<SalesReturnLine> deleteRow(
    _i1.DatabaseSession session,
    SalesReturnLine row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<SalesReturnLine>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<SalesReturnLine>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<SalesReturnLineTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<SalesReturnLine>(
      where: where(SalesReturnLine.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<SalesReturnLineTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<SalesReturnLine>(
      where: where?.call(SalesReturnLine.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [SalesReturnLine] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<SalesReturnLineTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<SalesReturnLine>(
      where: where(SalesReturnLine.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class SalesReturnLineAttachRowRepository {
  const SalesReturnLineAttachRowRepository._();

  /// Creates a relation between the given [SalesReturnLine] and [SalesReturn]
  /// by setting the [SalesReturnLine]'s foreign key `returnId` to refer to the [SalesReturn].
  Future<void> salesReturn(
    _i1.DatabaseSession session,
    SalesReturnLine salesReturnLine,
    _i2.SalesReturn salesReturn, {
    _i1.Transaction? transaction,
  }) async {
    if (salesReturnLine.id == null) {
      throw ArgumentError.notNull('salesReturnLine.id');
    }
    if (salesReturn.id == null) {
      throw ArgumentError.notNull('salesReturn.id');
    }

    var $salesReturnLine = salesReturnLine.copyWith(returnId: salesReturn.id);
    await session.db.updateRow<SalesReturnLine>(
      $salesReturnLine,
      columns: [SalesReturnLine.t.returnId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [SalesReturnLine] and [SalesInvoiceLine]
  /// by setting the [SalesReturnLine]'s foreign key `invoiceLineId` to refer to the [SalesInvoiceLine].
  Future<void> invoiceLine(
    _i1.DatabaseSession session,
    SalesReturnLine salesReturnLine,
    _i3.SalesInvoiceLine invoiceLine, {
    _i1.Transaction? transaction,
  }) async {
    if (salesReturnLine.id == null) {
      throw ArgumentError.notNull('salesReturnLine.id');
    }
    if (invoiceLine.id == null) {
      throw ArgumentError.notNull('invoiceLine.id');
    }

    var $salesReturnLine = salesReturnLine.copyWith(
      invoiceLineId: invoiceLine.id,
    );
    await session.db.updateRow<SalesReturnLine>(
      $salesReturnLine,
      columns: [SalesReturnLine.t.invoiceLineId],
      transaction: transaction,
    );
  }
}
