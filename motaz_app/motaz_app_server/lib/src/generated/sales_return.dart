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
import 'enums/record_status.dart' as _i2;
import 'enums/sync_status.dart' as _i3;
import 'sales_invoice.dart' as _i4;
import 'device.dart' as _i5;
import 'package:motaz_app_server/src/generated/protocol.dart' as _i6;

abstract class SalesReturn
    implements _i1.TableRow<_i1.UuidValue?>, _i1.ProtocolSerialization {
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

  static final t = SalesReturnTable();

  static const db = SalesReturnRepository._();

  @override
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

  @override
  _i1.Table<_i1.UuidValue?> get table => t;

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
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SalesReturn',
      if (id != null) 'id': id?.toJson(),
      if (localRef != null) 'localRef': localRef,
      if (officialNo != null) 'officialNo': officialNo,
      'invoiceId': invoiceId.toJson(),
      if (invoice != null) 'invoice': invoice?.toJsonForProtocol(),
      'returnDate': returnDate.toJson(),
      'totalReturnedAmount': totalReturnedAmount,
      if (note != null) 'note': note,
      'status': status.toJson(),
      if (voidReason != null) 'voidReason': voidReason,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      'deviceId': deviceId.toJson(),
      if (device != null) 'device': device?.toJsonForProtocol(),
      'rowVersion': rowVersion,
      'syncStatus': syncStatus.toJson(),
    };
  }

  static SalesReturnInclude include({
    _i4.SalesInvoiceInclude? invoice,
    _i5.DeviceInclude? device,
  }) {
    return SalesReturnInclude._(
      invoice: invoice,
      device: device,
    );
  }

  static SalesReturnIncludeList includeList({
    _i1.WhereExpressionBuilder<SalesReturnTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SalesReturnTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SalesReturnTable>? orderByList,
    SalesReturnInclude? include,
  }) {
    return SalesReturnIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SalesReturn.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(SalesReturn.t),
      include: include,
    );
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

class SalesReturnUpdateTable extends _i1.UpdateTable<SalesReturnTable> {
  SalesReturnUpdateTable(super.table);

  _i1.ColumnValue<String, String> localRef(String? value) => _i1.ColumnValue(
    table.localRef,
    value,
  );

  _i1.ColumnValue<String, String> officialNo(String? value) => _i1.ColumnValue(
    table.officialNo,
    value,
  );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> invoiceId(
    _i1.UuidValue value,
  ) => _i1.ColumnValue(
    table.invoiceId,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> returnDate(DateTime value) =>
      _i1.ColumnValue(
        table.returnDate,
        value,
      );

  _i1.ColumnValue<int, int> totalReturnedAmount(int value) => _i1.ColumnValue(
    table.totalReturnedAmount,
    value,
  );

  _i1.ColumnValue<String, String> note(String? value) => _i1.ColumnValue(
    table.note,
    value,
  );

  _i1.ColumnValue<_i2.RecordStatus, _i2.RecordStatus> status(
    _i2.RecordStatus value,
  ) => _i1.ColumnValue(
    table.status,
    value,
  );

  _i1.ColumnValue<String, String> voidReason(String? value) => _i1.ColumnValue(
    table.voidReason,
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

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> deviceId(_i1.UuidValue value) =>
      _i1.ColumnValue(
        table.deviceId,
        value,
      );

  _i1.ColumnValue<int, int> rowVersion(int value) => _i1.ColumnValue(
    table.rowVersion,
    value,
  );

  _i1.ColumnValue<_i3.SyncStatus, _i3.SyncStatus> syncStatus(
    _i3.SyncStatus value,
  ) => _i1.ColumnValue(
    table.syncStatus,
    value,
  );
}

class SalesReturnTable extends _i1.Table<_i1.UuidValue?> {
  SalesReturnTable({super.tableRelation}) : super(tableName: 'sales_return') {
    updateTable = SalesReturnUpdateTable(this);
    localRef = _i1.ColumnString(
      'localRef',
      this,
    );
    officialNo = _i1.ColumnString(
      'officialNo',
      this,
    );
    invoiceId = _i1.ColumnUuid(
      'invoiceId',
      this,
    );
    returnDate = _i1.ColumnDateTime(
      'returnDate',
      this,
    );
    totalReturnedAmount = _i1.ColumnInt(
      'totalReturnedAmount',
      this,
    );
    note = _i1.ColumnString(
      'note',
      this,
    );
    status = _i1.ColumnEnum(
      'status',
      this,
      _i1.EnumSerialization.byName,
      hasDefault: true,
    );
    voidReason = _i1.ColumnString(
      'voidReason',
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
    deviceId = _i1.ColumnUuid(
      'deviceId',
      this,
    );
    rowVersion = _i1.ColumnInt(
      'rowVersion',
      this,
      hasDefault: true,
    );
    syncStatus = _i1.ColumnEnum(
      'syncStatus',
      this,
      _i1.EnumSerialization.byName,
      hasDefault: true,
    );
  }

  late final SalesReturnUpdateTable updateTable;

  late final _i1.ColumnString localRef;

  late final _i1.ColumnString officialNo;

  late final _i1.ColumnUuid invoiceId;

  _i4.SalesInvoiceTable? _invoice;

  late final _i1.ColumnDateTime returnDate;

  late final _i1.ColumnInt totalReturnedAmount;

  late final _i1.ColumnString note;

  late final _i1.ColumnEnum<_i2.RecordStatus> status;

  late final _i1.ColumnString voidReason;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  late final _i1.ColumnUuid deviceId;

  _i5.DeviceTable? _device;

  late final _i1.ColumnInt rowVersion;

  late final _i1.ColumnEnum<_i3.SyncStatus> syncStatus;

  _i4.SalesInvoiceTable get invoice {
    if (_invoice != null) return _invoice!;
    _invoice = _i1.createRelationTable(
      relationFieldName: 'invoice',
      field: SalesReturn.t.invoiceId,
      foreignField: _i4.SalesInvoice.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i4.SalesInvoiceTable(tableRelation: foreignTableRelation),
    );
    return _invoice!;
  }

  _i5.DeviceTable get device {
    if (_device != null) return _device!;
    _device = _i1.createRelationTable(
      relationFieldName: 'device',
      field: SalesReturn.t.deviceId,
      foreignField: _i5.Device.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i5.DeviceTable(tableRelation: foreignTableRelation),
    );
    return _device!;
  }

  @override
  List<_i1.Column> get columns => [
    id,
    localRef,
    officialNo,
    invoiceId,
    returnDate,
    totalReturnedAmount,
    note,
    status,
    voidReason,
    createdAt,
    updatedAt,
    deviceId,
    rowVersion,
    syncStatus,
  ];

  @override
  _i1.Table? getRelationTable(String relationField) {
    if (relationField == 'invoice') {
      return invoice;
    }
    if (relationField == 'device') {
      return device;
    }
    return null;
  }
}

class SalesReturnInclude extends _i1.IncludeObject {
  SalesReturnInclude._({
    _i4.SalesInvoiceInclude? invoice,
    _i5.DeviceInclude? device,
  }) {
    _invoice = invoice;
    _device = device;
  }

  _i4.SalesInvoiceInclude? _invoice;

  _i5.DeviceInclude? _device;

  @override
  Map<String, _i1.Include?> get includes => {
    'invoice': _invoice,
    'device': _device,
  };

  @override
  _i1.Table<_i1.UuidValue?> get table => SalesReturn.t;
}

class SalesReturnIncludeList extends _i1.IncludeList {
  SalesReturnIncludeList._({
    _i1.WhereExpressionBuilder<SalesReturnTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(SalesReturn.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue?> get table => SalesReturn.t;
}

class SalesReturnRepository {
  const SalesReturnRepository._();

  final attachRow = const SalesReturnAttachRowRepository._();

  /// Returns a list of [SalesReturn]s matching the given query parameters.
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
  Future<List<SalesReturn>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<SalesReturnTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SalesReturnTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SalesReturnTable>? orderByList,
    _i1.Transaction? transaction,
    SalesReturnInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<SalesReturn>(
      where: where?.call(SalesReturn.t),
      orderBy: orderBy?.call(SalesReturn.t),
      orderByList: orderByList?.call(SalesReturn.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [SalesReturn] matching the given query parameters.
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
  Future<SalesReturn?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<SalesReturnTable>? where,
    int? offset,
    _i1.OrderByBuilder<SalesReturnTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SalesReturnTable>? orderByList,
    _i1.Transaction? transaction,
    SalesReturnInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<SalesReturn>(
      where: where?.call(SalesReturn.t),
      orderBy: orderBy?.call(SalesReturn.t),
      orderByList: orderByList?.call(SalesReturn.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [SalesReturn] by its [id] or null if no such row exists.
  Future<SalesReturn?> findById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    SalesReturnInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<SalesReturn>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [SalesReturn]s in the list and returns the inserted rows.
  ///
  /// The returned [SalesReturn]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<SalesReturn>> insert(
    _i1.DatabaseSession session,
    List<SalesReturn> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<SalesReturn>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [SalesReturn] and returns the inserted row.
  ///
  /// The returned [SalesReturn] will have its `id` field set.
  Future<SalesReturn> insertRow(
    _i1.DatabaseSession session,
    SalesReturn row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<SalesReturn>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [SalesReturn]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<SalesReturn>> update(
    _i1.DatabaseSession session,
    List<SalesReturn> rows, {
    _i1.ColumnSelections<SalesReturnTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<SalesReturn>(
      rows,
      columns: columns?.call(SalesReturn.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SalesReturn]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<SalesReturn> updateRow(
    _i1.DatabaseSession session,
    SalesReturn row, {
    _i1.ColumnSelections<SalesReturnTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<SalesReturn>(
      row,
      columns: columns?.call(SalesReturn.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SalesReturn] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<SalesReturn?> updateById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<SalesReturnUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<SalesReturn>(
      id,
      columnValues: columnValues(SalesReturn.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [SalesReturn]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<SalesReturn>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<SalesReturnUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<SalesReturnTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SalesReturnTable>? orderBy,
    _i1.OrderByListBuilder<SalesReturnTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<SalesReturn>(
      columnValues: columnValues(SalesReturn.t.updateTable),
      where: where(SalesReturn.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SalesReturn.t),
      orderByList: orderByList?.call(SalesReturn.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [SalesReturn]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<SalesReturn>> delete(
    _i1.DatabaseSession session,
    List<SalesReturn> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<SalesReturn>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [SalesReturn].
  Future<SalesReturn> deleteRow(
    _i1.DatabaseSession session,
    SalesReturn row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<SalesReturn>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<SalesReturn>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<SalesReturnTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<SalesReturn>(
      where: where(SalesReturn.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<SalesReturnTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<SalesReturn>(
      where: where?.call(SalesReturn.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [SalesReturn] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<SalesReturnTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<SalesReturn>(
      where: where(SalesReturn.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class SalesReturnAttachRowRepository {
  const SalesReturnAttachRowRepository._();

  /// Creates a relation between the given [SalesReturn] and [SalesInvoice]
  /// by setting the [SalesReturn]'s foreign key `invoiceId` to refer to the [SalesInvoice].
  Future<void> invoice(
    _i1.DatabaseSession session,
    SalesReturn salesReturn,
    _i4.SalesInvoice invoice, {
    _i1.Transaction? transaction,
  }) async {
    if (salesReturn.id == null) {
      throw ArgumentError.notNull('salesReturn.id');
    }
    if (invoice.id == null) {
      throw ArgumentError.notNull('invoice.id');
    }

    var $salesReturn = salesReturn.copyWith(invoiceId: invoice.id);
    await session.db.updateRow<SalesReturn>(
      $salesReturn,
      columns: [SalesReturn.t.invoiceId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [SalesReturn] and [Device]
  /// by setting the [SalesReturn]'s foreign key `deviceId` to refer to the [Device].
  Future<void> device(
    _i1.DatabaseSession session,
    SalesReturn salesReturn,
    _i5.Device device, {
    _i1.Transaction? transaction,
  }) async {
    if (salesReturn.id == null) {
      throw ArgumentError.notNull('salesReturn.id');
    }
    if (device.id == null) {
      throw ArgumentError.notNull('device.id');
    }

    var $salesReturn = salesReturn.copyWith(deviceId: device.id);
    await session.db.updateRow<SalesReturn>(
      $salesReturn,
      columns: [SalesReturn.t.deviceId],
      transaction: transaction,
    );
  }
}
