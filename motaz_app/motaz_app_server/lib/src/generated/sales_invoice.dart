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
import 'client_record.dart' as _i4;
import 'device.dart' as _i5;
import 'package:motaz_app_server/src/generated/protocol.dart' as _i6;

abstract class SalesInvoice
    implements _i1.TableRow<_i1.UuidValue?>, _i1.ProtocolSerialization {
  SalesInvoice._({
    this.id,
    required this.localRef,
    this.officialNo,
    required this.clientId,
    this.client,
    required this.invoiceDate,
    int? discount,
    required this.total,
    this.note,
    _i2.RecordStatus? status,
    this.voidReason,
    required this.createdAt,
    required this.updatedAt,
    required this.deviceId,
    this.device,
    int? rowVersion,
    _i3.SyncStatus? syncStatus,
  }) : discount = discount ?? 0,
       status = status ?? _i2.RecordStatus.ACTIVE,
       rowVersion = rowVersion ?? 1,
       syncStatus = syncStatus ?? _i3.SyncStatus.PENDING;

  factory SalesInvoice({
    _i1.UuidValue? id,
    required String localRef,
    String? officialNo,
    required _i1.UuidValue clientId,
    _i4.ClientRecord? client,
    required DateTime invoiceDate,
    int? discount,
    required int total,
    String? note,
    _i2.RecordStatus? status,
    String? voidReason,
    required DateTime createdAt,
    required DateTime updatedAt,
    required _i1.UuidValue deviceId,
    _i5.Device? device,
    int? rowVersion,
    _i3.SyncStatus? syncStatus,
  }) = _SalesInvoiceImpl;

  factory SalesInvoice.fromJson(Map<String, dynamic> jsonSerialization) {
    return SalesInvoice(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      localRef: jsonSerialization['localRef'] as String,
      officialNo: jsonSerialization['officialNo'] as String?,
      clientId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['clientId'],
      ),
      client: jsonSerialization['client'] == null
          ? null
          : _i6.Protocol().deserialize<_i4.ClientRecord>(
              jsonSerialization['client'],
            ),
      invoiceDate: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['invoiceDate'],
      ),
      discount: jsonSerialization['discount'] as int?,
      total: jsonSerialization['total'] as int,
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

  static final t = SalesInvoiceTable();

  static const db = SalesInvoiceRepository._();

  @override
  _i1.UuidValue? id;

  String localRef;

  String? officialNo;

  _i1.UuidValue clientId;

  _i4.ClientRecord? client;

  DateTime invoiceDate;

  int discount;

  int total;

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

  /// Returns a shallow copy of this [SalesInvoice]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SalesInvoice copyWith({
    _i1.UuidValue? id,
    String? localRef,
    String? officialNo,
    _i1.UuidValue? clientId,
    _i4.ClientRecord? client,
    DateTime? invoiceDate,
    int? discount,
    int? total,
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
      '__className__': 'SalesInvoice',
      if (id != null) 'id': id?.toJson(),
      'localRef': localRef,
      if (officialNo != null) 'officialNo': officialNo,
      'clientId': clientId.toJson(),
      if (client != null) 'client': client?.toJson(),
      'invoiceDate': invoiceDate.toJson(),
      'discount': discount,
      'total': total,
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
      '__className__': 'SalesInvoice',
      if (id != null) 'id': id?.toJson(),
      'localRef': localRef,
      if (officialNo != null) 'officialNo': officialNo,
      'clientId': clientId.toJson(),
      if (client != null) 'client': client?.toJsonForProtocol(),
      'invoiceDate': invoiceDate.toJson(),
      'discount': discount,
      'total': total,
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

  static SalesInvoiceInclude include({
    _i4.ClientRecordInclude? client,
    _i5.DeviceInclude? device,
  }) {
    return SalesInvoiceInclude._(
      client: client,
      device: device,
    );
  }

  static SalesInvoiceIncludeList includeList({
    _i1.WhereExpressionBuilder<SalesInvoiceTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SalesInvoiceTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SalesInvoiceTable>? orderByList,
    SalesInvoiceInclude? include,
  }) {
    return SalesInvoiceIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SalesInvoice.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(SalesInvoice.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SalesInvoiceImpl extends SalesInvoice {
  _SalesInvoiceImpl({
    _i1.UuidValue? id,
    required String localRef,
    String? officialNo,
    required _i1.UuidValue clientId,
    _i4.ClientRecord? client,
    required DateTime invoiceDate,
    int? discount,
    required int total,
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
         clientId: clientId,
         client: client,
         invoiceDate: invoiceDate,
         discount: discount,
         total: total,
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

  /// Returns a shallow copy of this [SalesInvoice]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SalesInvoice copyWith({
    Object? id = _Undefined,
    String? localRef,
    Object? officialNo = _Undefined,
    _i1.UuidValue? clientId,
    Object? client = _Undefined,
    DateTime? invoiceDate,
    int? discount,
    int? total,
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
    return SalesInvoice(
      id: id is _i1.UuidValue? ? id : this.id,
      localRef: localRef ?? this.localRef,
      officialNo: officialNo is String? ? officialNo : this.officialNo,
      clientId: clientId ?? this.clientId,
      client: client is _i4.ClientRecord? ? client : this.client?.copyWith(),
      invoiceDate: invoiceDate ?? this.invoiceDate,
      discount: discount ?? this.discount,
      total: total ?? this.total,
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

class SalesInvoiceUpdateTable extends _i1.UpdateTable<SalesInvoiceTable> {
  SalesInvoiceUpdateTable(super.table);

  _i1.ColumnValue<String, String> localRef(String value) => _i1.ColumnValue(
    table.localRef,
    value,
  );

  _i1.ColumnValue<String, String> officialNo(String? value) => _i1.ColumnValue(
    table.officialNo,
    value,
  );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> clientId(_i1.UuidValue value) =>
      _i1.ColumnValue(
        table.clientId,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> invoiceDate(DateTime value) =>
      _i1.ColumnValue(
        table.invoiceDate,
        value,
      );

  _i1.ColumnValue<int, int> discount(int value) => _i1.ColumnValue(
    table.discount,
    value,
  );

  _i1.ColumnValue<int, int> total(int value) => _i1.ColumnValue(
    table.total,
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

class SalesInvoiceTable extends _i1.Table<_i1.UuidValue?> {
  SalesInvoiceTable({super.tableRelation}) : super(tableName: 'sales_invoice') {
    updateTable = SalesInvoiceUpdateTable(this);
    localRef = _i1.ColumnString(
      'localRef',
      this,
    );
    officialNo = _i1.ColumnString(
      'officialNo',
      this,
    );
    clientId = _i1.ColumnUuid(
      'clientId',
      this,
    );
    invoiceDate = _i1.ColumnDateTime(
      'invoiceDate',
      this,
    );
    discount = _i1.ColumnInt(
      'discount',
      this,
      hasDefault: true,
    );
    total = _i1.ColumnInt(
      'total',
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

  late final SalesInvoiceUpdateTable updateTable;

  late final _i1.ColumnString localRef;

  late final _i1.ColumnString officialNo;

  late final _i1.ColumnUuid clientId;

  _i4.ClientRecordTable? _client;

  late final _i1.ColumnDateTime invoiceDate;

  late final _i1.ColumnInt discount;

  late final _i1.ColumnInt total;

  late final _i1.ColumnString note;

  late final _i1.ColumnEnum<_i2.RecordStatus> status;

  late final _i1.ColumnString voidReason;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  late final _i1.ColumnUuid deviceId;

  _i5.DeviceTable? _device;

  late final _i1.ColumnInt rowVersion;

  late final _i1.ColumnEnum<_i3.SyncStatus> syncStatus;

  _i4.ClientRecordTable get client {
    if (_client != null) return _client!;
    _client = _i1.createRelationTable(
      relationFieldName: 'client',
      field: SalesInvoice.t.clientId,
      foreignField: _i4.ClientRecord.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i4.ClientRecordTable(tableRelation: foreignTableRelation),
    );
    return _client!;
  }

  _i5.DeviceTable get device {
    if (_device != null) return _device!;
    _device = _i1.createRelationTable(
      relationFieldName: 'device',
      field: SalesInvoice.t.deviceId,
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
    clientId,
    invoiceDate,
    discount,
    total,
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
    if (relationField == 'client') {
      return client;
    }
    if (relationField == 'device') {
      return device;
    }
    return null;
  }
}

class SalesInvoiceInclude extends _i1.IncludeObject {
  SalesInvoiceInclude._({
    _i4.ClientRecordInclude? client,
    _i5.DeviceInclude? device,
  }) {
    _client = client;
    _device = device;
  }

  _i4.ClientRecordInclude? _client;

  _i5.DeviceInclude? _device;

  @override
  Map<String, _i1.Include?> get includes => {
    'client': _client,
    'device': _device,
  };

  @override
  _i1.Table<_i1.UuidValue?> get table => SalesInvoice.t;
}

class SalesInvoiceIncludeList extends _i1.IncludeList {
  SalesInvoiceIncludeList._({
    _i1.WhereExpressionBuilder<SalesInvoiceTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(SalesInvoice.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue?> get table => SalesInvoice.t;
}

class SalesInvoiceRepository {
  const SalesInvoiceRepository._();

  final attachRow = const SalesInvoiceAttachRowRepository._();

  /// Returns a list of [SalesInvoice]s matching the given query parameters.
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
  Future<List<SalesInvoice>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<SalesInvoiceTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SalesInvoiceTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SalesInvoiceTable>? orderByList,
    _i1.Transaction? transaction,
    SalesInvoiceInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<SalesInvoice>(
      where: where?.call(SalesInvoice.t),
      orderBy: orderBy?.call(SalesInvoice.t),
      orderByList: orderByList?.call(SalesInvoice.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [SalesInvoice] matching the given query parameters.
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
  Future<SalesInvoice?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<SalesInvoiceTable>? where,
    int? offset,
    _i1.OrderByBuilder<SalesInvoiceTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SalesInvoiceTable>? orderByList,
    _i1.Transaction? transaction,
    SalesInvoiceInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<SalesInvoice>(
      where: where?.call(SalesInvoice.t),
      orderBy: orderBy?.call(SalesInvoice.t),
      orderByList: orderByList?.call(SalesInvoice.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [SalesInvoice] by its [id] or null if no such row exists.
  Future<SalesInvoice?> findById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    SalesInvoiceInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<SalesInvoice>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [SalesInvoice]s in the list and returns the inserted rows.
  ///
  /// The returned [SalesInvoice]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<SalesInvoice>> insert(
    _i1.DatabaseSession session,
    List<SalesInvoice> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<SalesInvoice>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [SalesInvoice] and returns the inserted row.
  ///
  /// The returned [SalesInvoice] will have its `id` field set.
  Future<SalesInvoice> insertRow(
    _i1.DatabaseSession session,
    SalesInvoice row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<SalesInvoice>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [SalesInvoice]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<SalesInvoice>> update(
    _i1.DatabaseSession session,
    List<SalesInvoice> rows, {
    _i1.ColumnSelections<SalesInvoiceTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<SalesInvoice>(
      rows,
      columns: columns?.call(SalesInvoice.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SalesInvoice]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<SalesInvoice> updateRow(
    _i1.DatabaseSession session,
    SalesInvoice row, {
    _i1.ColumnSelections<SalesInvoiceTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<SalesInvoice>(
      row,
      columns: columns?.call(SalesInvoice.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SalesInvoice] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<SalesInvoice?> updateById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<SalesInvoiceUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<SalesInvoice>(
      id,
      columnValues: columnValues(SalesInvoice.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [SalesInvoice]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<SalesInvoice>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<SalesInvoiceUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<SalesInvoiceTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SalesInvoiceTable>? orderBy,
    _i1.OrderByListBuilder<SalesInvoiceTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<SalesInvoice>(
      columnValues: columnValues(SalesInvoice.t.updateTable),
      where: where(SalesInvoice.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SalesInvoice.t),
      orderByList: orderByList?.call(SalesInvoice.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [SalesInvoice]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<SalesInvoice>> delete(
    _i1.DatabaseSession session,
    List<SalesInvoice> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<SalesInvoice>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [SalesInvoice].
  Future<SalesInvoice> deleteRow(
    _i1.DatabaseSession session,
    SalesInvoice row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<SalesInvoice>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<SalesInvoice>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<SalesInvoiceTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<SalesInvoice>(
      where: where(SalesInvoice.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<SalesInvoiceTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<SalesInvoice>(
      where: where?.call(SalesInvoice.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [SalesInvoice] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<SalesInvoiceTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<SalesInvoice>(
      where: where(SalesInvoice.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class SalesInvoiceAttachRowRepository {
  const SalesInvoiceAttachRowRepository._();

  /// Creates a relation between the given [SalesInvoice] and [ClientRecord]
  /// by setting the [SalesInvoice]'s foreign key `clientId` to refer to the [ClientRecord].
  Future<void> client(
    _i1.DatabaseSession session,
    SalesInvoice salesInvoice,
    _i4.ClientRecord client, {
    _i1.Transaction? transaction,
  }) async {
    if (salesInvoice.id == null) {
      throw ArgumentError.notNull('salesInvoice.id');
    }
    if (client.id == null) {
      throw ArgumentError.notNull('client.id');
    }

    var $salesInvoice = salesInvoice.copyWith(clientId: client.id);
    await session.db.updateRow<SalesInvoice>(
      $salesInvoice,
      columns: [SalesInvoice.t.clientId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [SalesInvoice] and [Device]
  /// by setting the [SalesInvoice]'s foreign key `deviceId` to refer to the [Device].
  Future<void> device(
    _i1.DatabaseSession session,
    SalesInvoice salesInvoice,
    _i5.Device device, {
    _i1.Transaction? transaction,
  }) async {
    if (salesInvoice.id == null) {
      throw ArgumentError.notNull('salesInvoice.id');
    }
    if (device.id == null) {
      throw ArgumentError.notNull('device.id');
    }

    var $salesInvoice = salesInvoice.copyWith(deviceId: device.id);
    await session.db.updateRow<SalesInvoice>(
      $salesInvoice,
      columns: [SalesInvoice.t.deviceId],
      transaction: transaction,
    );
  }
}
