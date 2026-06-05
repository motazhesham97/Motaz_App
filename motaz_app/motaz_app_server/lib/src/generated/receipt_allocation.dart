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
import 'receipt.dart' as _i2;
import 'sales_invoice.dart' as _i3;
import 'package:motaz_app_server/src/generated/protocol.dart' as _i4;

abstract class ReceiptAllocation
    implements _i1.TableRow<_i1.UuidValue?>, _i1.ProtocolSerialization {
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

  static final t = ReceiptAllocationTable();

  static const db = ReceiptAllocationRepository._();

  @override
  _i1.UuidValue? id;

  _i1.UuidValue receiptId;

  _i2.Receipt? receipt;

  _i1.UuidValue invoiceId;

  _i3.SalesInvoice? invoice;

  int allocatedAmount;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _i1.Table<_i1.UuidValue?> get table => t;

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
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ReceiptAllocation',
      if (id != null) 'id': id?.toJson(),
      'receiptId': receiptId.toJson(),
      if (receipt != null) 'receipt': receipt?.toJsonForProtocol(),
      'invoiceId': invoiceId.toJson(),
      if (invoice != null) 'invoice': invoice?.toJsonForProtocol(),
      'allocatedAmount': allocatedAmount,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  static ReceiptAllocationInclude include({
    _i2.ReceiptInclude? receipt,
    _i3.SalesInvoiceInclude? invoice,
  }) {
    return ReceiptAllocationInclude._(
      receipt: receipt,
      invoice: invoice,
    );
  }

  static ReceiptAllocationIncludeList includeList({
    _i1.WhereExpressionBuilder<ReceiptAllocationTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ReceiptAllocationTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ReceiptAllocationTable>? orderByList,
    ReceiptAllocationInclude? include,
  }) {
    return ReceiptAllocationIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ReceiptAllocation.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(ReceiptAllocation.t),
      include: include,
    );
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

class ReceiptAllocationUpdateTable
    extends _i1.UpdateTable<ReceiptAllocationTable> {
  ReceiptAllocationUpdateTable(super.table);

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> receiptId(
    _i1.UuidValue value,
  ) => _i1.ColumnValue(
    table.receiptId,
    value,
  );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> invoiceId(
    _i1.UuidValue value,
  ) => _i1.ColumnValue(
    table.invoiceId,
    value,
  );

  _i1.ColumnValue<int, int> allocatedAmount(int value) => _i1.ColumnValue(
    table.allocatedAmount,
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

class ReceiptAllocationTable extends _i1.Table<_i1.UuidValue?> {
  ReceiptAllocationTable({super.tableRelation})
    : super(tableName: 'receipt_allocation') {
    updateTable = ReceiptAllocationUpdateTable(this);
    receiptId = _i1.ColumnUuid(
      'receiptId',
      this,
    );
    invoiceId = _i1.ColumnUuid(
      'invoiceId',
      this,
    );
    allocatedAmount = _i1.ColumnInt(
      'allocatedAmount',
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

  late final ReceiptAllocationUpdateTable updateTable;

  late final _i1.ColumnUuid receiptId;

  _i2.ReceiptTable? _receipt;

  late final _i1.ColumnUuid invoiceId;

  _i3.SalesInvoiceTable? _invoice;

  late final _i1.ColumnInt allocatedAmount;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  _i2.ReceiptTable get receipt {
    if (_receipt != null) return _receipt!;
    _receipt = _i1.createRelationTable(
      relationFieldName: 'receipt',
      field: ReceiptAllocation.t.receiptId,
      foreignField: _i2.Receipt.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i2.ReceiptTable(tableRelation: foreignTableRelation),
    );
    return _receipt!;
  }

  _i3.SalesInvoiceTable get invoice {
    if (_invoice != null) return _invoice!;
    _invoice = _i1.createRelationTable(
      relationFieldName: 'invoice',
      field: ReceiptAllocation.t.invoiceId,
      foreignField: _i3.SalesInvoice.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i3.SalesInvoiceTable(tableRelation: foreignTableRelation),
    );
    return _invoice!;
  }

  @override
  List<_i1.Column> get columns => [
    id,
    receiptId,
    invoiceId,
    allocatedAmount,
    createdAt,
    updatedAt,
  ];

  @override
  _i1.Table? getRelationTable(String relationField) {
    if (relationField == 'receipt') {
      return receipt;
    }
    if (relationField == 'invoice') {
      return invoice;
    }
    return null;
  }
}

class ReceiptAllocationInclude extends _i1.IncludeObject {
  ReceiptAllocationInclude._({
    _i2.ReceiptInclude? receipt,
    _i3.SalesInvoiceInclude? invoice,
  }) {
    _receipt = receipt;
    _invoice = invoice;
  }

  _i2.ReceiptInclude? _receipt;

  _i3.SalesInvoiceInclude? _invoice;

  @override
  Map<String, _i1.Include?> get includes => {
    'receipt': _receipt,
    'invoice': _invoice,
  };

  @override
  _i1.Table<_i1.UuidValue?> get table => ReceiptAllocation.t;
}

class ReceiptAllocationIncludeList extends _i1.IncludeList {
  ReceiptAllocationIncludeList._({
    _i1.WhereExpressionBuilder<ReceiptAllocationTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ReceiptAllocation.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue?> get table => ReceiptAllocation.t;
}

class ReceiptAllocationRepository {
  const ReceiptAllocationRepository._();

  final attachRow = const ReceiptAllocationAttachRowRepository._();

  /// Returns a list of [ReceiptAllocation]s matching the given query parameters.
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
  Future<List<ReceiptAllocation>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ReceiptAllocationTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ReceiptAllocationTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ReceiptAllocationTable>? orderByList,
    _i1.Transaction? transaction,
    ReceiptAllocationInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ReceiptAllocation>(
      where: where?.call(ReceiptAllocation.t),
      orderBy: orderBy?.call(ReceiptAllocation.t),
      orderByList: orderByList?.call(ReceiptAllocation.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ReceiptAllocation] matching the given query parameters.
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
  Future<ReceiptAllocation?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ReceiptAllocationTable>? where,
    int? offset,
    _i1.OrderByBuilder<ReceiptAllocationTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ReceiptAllocationTable>? orderByList,
    _i1.Transaction? transaction,
    ReceiptAllocationInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ReceiptAllocation>(
      where: where?.call(ReceiptAllocation.t),
      orderBy: orderBy?.call(ReceiptAllocation.t),
      orderByList: orderByList?.call(ReceiptAllocation.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ReceiptAllocation] by its [id] or null if no such row exists.
  Future<ReceiptAllocation?> findById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    ReceiptAllocationInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ReceiptAllocation>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ReceiptAllocation]s in the list and returns the inserted rows.
  ///
  /// The returned [ReceiptAllocation]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<ReceiptAllocation>> insert(
    _i1.DatabaseSession session,
    List<ReceiptAllocation> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<ReceiptAllocation>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [ReceiptAllocation] and returns the inserted row.
  ///
  /// The returned [ReceiptAllocation] will have its `id` field set.
  Future<ReceiptAllocation> insertRow(
    _i1.DatabaseSession session,
    ReceiptAllocation row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<ReceiptAllocation>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [ReceiptAllocation]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<ReceiptAllocation>> update(
    _i1.DatabaseSession session,
    List<ReceiptAllocation> rows, {
    _i1.ColumnSelections<ReceiptAllocationTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<ReceiptAllocation>(
      rows,
      columns: columns?.call(ReceiptAllocation.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ReceiptAllocation]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ReceiptAllocation> updateRow(
    _i1.DatabaseSession session,
    ReceiptAllocation row, {
    _i1.ColumnSelections<ReceiptAllocationTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<ReceiptAllocation>(
      row,
      columns: columns?.call(ReceiptAllocation.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ReceiptAllocation] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ReceiptAllocation?> updateById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<ReceiptAllocationUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<ReceiptAllocation>(
      id,
      columnValues: columnValues(ReceiptAllocation.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ReceiptAllocation]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<ReceiptAllocation>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<ReceiptAllocationUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<ReceiptAllocationTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ReceiptAllocationTable>? orderBy,
    _i1.OrderByListBuilder<ReceiptAllocationTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<ReceiptAllocation>(
      columnValues: columnValues(ReceiptAllocation.t.updateTable),
      where: where(ReceiptAllocation.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ReceiptAllocation.t),
      orderByList: orderByList?.call(ReceiptAllocation.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [ReceiptAllocation]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<ReceiptAllocation>> delete(
    _i1.DatabaseSession session,
    List<ReceiptAllocation> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<ReceiptAllocation>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [ReceiptAllocation].
  Future<ReceiptAllocation> deleteRow(
    _i1.DatabaseSession session,
    ReceiptAllocation row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ReceiptAllocation>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<ReceiptAllocation>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ReceiptAllocationTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<ReceiptAllocation>(
      where: where(ReceiptAllocation.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ReceiptAllocationTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<ReceiptAllocation>(
      where: where?.call(ReceiptAllocation.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ReceiptAllocation] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ReceiptAllocationTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ReceiptAllocation>(
      where: where(ReceiptAllocation.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class ReceiptAllocationAttachRowRepository {
  const ReceiptAllocationAttachRowRepository._();

  /// Creates a relation between the given [ReceiptAllocation] and [Receipt]
  /// by setting the [ReceiptAllocation]'s foreign key `receiptId` to refer to the [Receipt].
  Future<void> receipt(
    _i1.DatabaseSession session,
    ReceiptAllocation receiptAllocation,
    _i2.Receipt receipt, {
    _i1.Transaction? transaction,
  }) async {
    if (receiptAllocation.id == null) {
      throw ArgumentError.notNull('receiptAllocation.id');
    }
    if (receipt.id == null) {
      throw ArgumentError.notNull('receipt.id');
    }

    var $receiptAllocation = receiptAllocation.copyWith(receiptId: receipt.id);
    await session.db.updateRow<ReceiptAllocation>(
      $receiptAllocation,
      columns: [ReceiptAllocation.t.receiptId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [ReceiptAllocation] and [SalesInvoice]
  /// by setting the [ReceiptAllocation]'s foreign key `invoiceId` to refer to the [SalesInvoice].
  Future<void> invoice(
    _i1.DatabaseSession session,
    ReceiptAllocation receiptAllocation,
    _i3.SalesInvoice invoice, {
    _i1.Transaction? transaction,
  }) async {
    if (receiptAllocation.id == null) {
      throw ArgumentError.notNull('receiptAllocation.id');
    }
    if (invoice.id == null) {
      throw ArgumentError.notNull('invoice.id');
    }

    var $receiptAllocation = receiptAllocation.copyWith(invoiceId: invoice.id);
    await session.db.updateRow<ReceiptAllocation>(
      $receiptAllocation,
      columns: [ReceiptAllocation.t.invoiceId],
      transaction: transaction,
    );
  }
}
