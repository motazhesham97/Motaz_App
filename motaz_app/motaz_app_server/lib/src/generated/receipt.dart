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
import 'enums/receipt_type.dart' as _i4;
import 'client_record.dart' as _i5;
import 'sales_invoice.dart' as _i6;
import 'device.dart' as _i7;
import 'package:motaz_app_server/src/generated/protocol.dart' as _i8;

abstract class Receipt
    implements _i1.TableRow<_i1.UuidValue?>, _i1.ProtocolSerialization {
  Receipt._({
    this.id,
    this.localRef,
    this.officialNo,
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
    String? localRef,
    String? officialNo,
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
      localRef: jsonSerialization['localRef'] as String?,
      officialNo: jsonSerialization['officialNo'] as String?,
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

  static final t = ReceiptTable();

  static const db = ReceiptRepository._();

  @override
  _i1.UuidValue? id;

  String? localRef;

  String? officialNo;

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

  @override
  _i1.Table<_i1.UuidValue?> get table => t;

  /// Returns a shallow copy of this [Receipt]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Receipt copyWith({
    _i1.UuidValue? id,
    String? localRef,
    String? officialNo,
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
      if (localRef != null) 'localRef': localRef,
      if (officialNo != null) 'officialNo': officialNo,
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
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Receipt',
      if (id != null) 'id': id?.toJson(),
      if (localRef != null) 'localRef': localRef,
      if (officialNo != null) 'officialNo': officialNo,
      'receiptType': receiptType.toJson(),
      'clientId': clientId.toJson(),
      if (client != null) 'client': client?.toJsonForProtocol(),
      if (invoiceId != null) 'invoiceId': invoiceId?.toJson(),
      if (invoice != null) 'invoice': invoice?.toJsonForProtocol(),
      'amount': amount,
      'receiptDate': receiptDate.toJson(),
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

  static ReceiptInclude include({
    _i5.ClientRecordInclude? client,
    _i6.SalesInvoiceInclude? invoice,
    _i7.DeviceInclude? device,
  }) {
    return ReceiptInclude._(
      client: client,
      invoice: invoice,
      device: device,
    );
  }

  static ReceiptIncludeList includeList({
    _i1.WhereExpressionBuilder<ReceiptTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ReceiptTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ReceiptTable>? orderByList,
    ReceiptInclude? include,
  }) {
    return ReceiptIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Receipt.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Receipt.t),
      include: include,
    );
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
    String? localRef,
    String? officialNo,
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
         localRef: localRef,
         officialNo: officialNo,
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
    Object? localRef = _Undefined,
    Object? officialNo = _Undefined,
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
      localRef: localRef is String? ? localRef : this.localRef,
      officialNo: officialNo is String? ? officialNo : this.officialNo,
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

class ReceiptUpdateTable extends _i1.UpdateTable<ReceiptTable> {
  ReceiptUpdateTable(super.table);

  _i1.ColumnValue<String, String> localRef(String? value) => _i1.ColumnValue(
    table.localRef,
    value,
  );

  _i1.ColumnValue<String, String> officialNo(String? value) => _i1.ColumnValue(
    table.officialNo,
    value,
  );

  _i1.ColumnValue<_i4.ReceiptType, _i4.ReceiptType> receiptType(
    _i4.ReceiptType value,
  ) => _i1.ColumnValue(
    table.receiptType,
    value,
  );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> clientId(_i1.UuidValue value) =>
      _i1.ColumnValue(
        table.clientId,
        value,
      );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> invoiceId(
    _i1.UuidValue? value,
  ) => _i1.ColumnValue(
    table.invoiceId,
    value,
  );

  _i1.ColumnValue<int, int> amount(int value) => _i1.ColumnValue(
    table.amount,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> receiptDate(DateTime value) =>
      _i1.ColumnValue(
        table.receiptDate,
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

class ReceiptTable extends _i1.Table<_i1.UuidValue?> {
  ReceiptTable({super.tableRelation}) : super(tableName: 'receipt') {
    updateTable = ReceiptUpdateTable(this);
    localRef = _i1.ColumnString(
      'localRef',
      this,
    );
    officialNo = _i1.ColumnString(
      'officialNo',
      this,
    );
    receiptType = _i1.ColumnEnum(
      'receiptType',
      this,
      _i1.EnumSerialization.byName,
    );
    clientId = _i1.ColumnUuid(
      'clientId',
      this,
    );
    invoiceId = _i1.ColumnUuid(
      'invoiceId',
      this,
    );
    amount = _i1.ColumnInt(
      'amount',
      this,
    );
    receiptDate = _i1.ColumnDateTime(
      'receiptDate',
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

  late final ReceiptUpdateTable updateTable;

  late final _i1.ColumnString localRef;

  late final _i1.ColumnString officialNo;

  late final _i1.ColumnEnum<_i4.ReceiptType> receiptType;

  late final _i1.ColumnUuid clientId;

  _i5.ClientRecordTable? _client;

  late final _i1.ColumnUuid invoiceId;

  _i6.SalesInvoiceTable? _invoice;

  late final _i1.ColumnInt amount;

  late final _i1.ColumnDateTime receiptDate;

  late final _i1.ColumnString note;

  late final _i1.ColumnEnum<_i2.RecordStatus> status;

  late final _i1.ColumnString voidReason;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  late final _i1.ColumnUuid deviceId;

  _i7.DeviceTable? _device;

  late final _i1.ColumnInt rowVersion;

  late final _i1.ColumnEnum<_i3.SyncStatus> syncStatus;

  _i5.ClientRecordTable get client {
    if (_client != null) return _client!;
    _client = _i1.createRelationTable(
      relationFieldName: 'client',
      field: Receipt.t.clientId,
      foreignField: _i5.ClientRecord.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i5.ClientRecordTable(tableRelation: foreignTableRelation),
    );
    return _client!;
  }

  _i6.SalesInvoiceTable get invoice {
    if (_invoice != null) return _invoice!;
    _invoice = _i1.createRelationTable(
      relationFieldName: 'invoice',
      field: Receipt.t.invoiceId,
      foreignField: _i6.SalesInvoice.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i6.SalesInvoiceTable(tableRelation: foreignTableRelation),
    );
    return _invoice!;
  }

  _i7.DeviceTable get device {
    if (_device != null) return _device!;
    _device = _i1.createRelationTable(
      relationFieldName: 'device',
      field: Receipt.t.deviceId,
      foreignField: _i7.Device.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i7.DeviceTable(tableRelation: foreignTableRelation),
    );
    return _device!;
  }

  @override
  List<_i1.Column> get columns => [
    id,
    localRef,
    officialNo,
    receiptType,
    clientId,
    invoiceId,
    amount,
    receiptDate,
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
    if (relationField == 'invoice') {
      return invoice;
    }
    if (relationField == 'device') {
      return device;
    }
    return null;
  }
}

class ReceiptInclude extends _i1.IncludeObject {
  ReceiptInclude._({
    _i5.ClientRecordInclude? client,
    _i6.SalesInvoiceInclude? invoice,
    _i7.DeviceInclude? device,
  }) {
    _client = client;
    _invoice = invoice;
    _device = device;
  }

  _i5.ClientRecordInclude? _client;

  _i6.SalesInvoiceInclude? _invoice;

  _i7.DeviceInclude? _device;

  @override
  Map<String, _i1.Include?> get includes => {
    'client': _client,
    'invoice': _invoice,
    'device': _device,
  };

  @override
  _i1.Table<_i1.UuidValue?> get table => Receipt.t;
}

class ReceiptIncludeList extends _i1.IncludeList {
  ReceiptIncludeList._({
    _i1.WhereExpressionBuilder<ReceiptTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Receipt.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue?> get table => Receipt.t;
}

class ReceiptRepository {
  const ReceiptRepository._();

  final attachRow = const ReceiptAttachRowRepository._();

  final detachRow = const ReceiptDetachRowRepository._();

  /// Returns a list of [Receipt]s matching the given query parameters.
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
  Future<List<Receipt>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ReceiptTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ReceiptTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ReceiptTable>? orderByList,
    _i1.Transaction? transaction,
    ReceiptInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Receipt>(
      where: where?.call(Receipt.t),
      orderBy: orderBy?.call(Receipt.t),
      orderByList: orderByList?.call(Receipt.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Receipt] matching the given query parameters.
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
  Future<Receipt?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ReceiptTable>? where,
    int? offset,
    _i1.OrderByBuilder<ReceiptTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ReceiptTable>? orderByList,
    _i1.Transaction? transaction,
    ReceiptInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Receipt>(
      where: where?.call(Receipt.t),
      orderBy: orderBy?.call(Receipt.t),
      orderByList: orderByList?.call(Receipt.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Receipt] by its [id] or null if no such row exists.
  Future<Receipt?> findById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    ReceiptInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Receipt>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Receipt]s in the list and returns the inserted rows.
  ///
  /// The returned [Receipt]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<Receipt>> insert(
    _i1.DatabaseSession session,
    List<Receipt> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<Receipt>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [Receipt] and returns the inserted row.
  ///
  /// The returned [Receipt] will have its `id` field set.
  Future<Receipt> insertRow(
    _i1.DatabaseSession session,
    Receipt row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Receipt>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Receipt]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Receipt>> update(
    _i1.DatabaseSession session,
    List<Receipt> rows, {
    _i1.ColumnSelections<ReceiptTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Receipt>(
      rows,
      columns: columns?.call(Receipt.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Receipt]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Receipt> updateRow(
    _i1.DatabaseSession session,
    Receipt row, {
    _i1.ColumnSelections<ReceiptTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Receipt>(
      row,
      columns: columns?.call(Receipt.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Receipt] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Receipt?> updateById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<ReceiptUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Receipt>(
      id,
      columnValues: columnValues(Receipt.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Receipt]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Receipt>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<ReceiptUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<ReceiptTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ReceiptTable>? orderBy,
    _i1.OrderByListBuilder<ReceiptTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Receipt>(
      columnValues: columnValues(Receipt.t.updateTable),
      where: where(Receipt.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Receipt.t),
      orderByList: orderByList?.call(Receipt.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Receipt]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Receipt>> delete(
    _i1.DatabaseSession session,
    List<Receipt> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Receipt>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Receipt].
  Future<Receipt> deleteRow(
    _i1.DatabaseSession session,
    Receipt row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Receipt>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Receipt>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ReceiptTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Receipt>(
      where: where(Receipt.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ReceiptTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Receipt>(
      where: where?.call(Receipt.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Receipt] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ReceiptTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Receipt>(
      where: where(Receipt.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class ReceiptAttachRowRepository {
  const ReceiptAttachRowRepository._();

  /// Creates a relation between the given [Receipt] and [ClientRecord]
  /// by setting the [Receipt]'s foreign key `clientId` to refer to the [ClientRecord].
  Future<void> client(
    _i1.DatabaseSession session,
    Receipt receipt,
    _i5.ClientRecord client, {
    _i1.Transaction? transaction,
  }) async {
    if (receipt.id == null) {
      throw ArgumentError.notNull('receipt.id');
    }
    if (client.id == null) {
      throw ArgumentError.notNull('client.id');
    }

    var $receipt = receipt.copyWith(clientId: client.id);
    await session.db.updateRow<Receipt>(
      $receipt,
      columns: [Receipt.t.clientId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [Receipt] and [SalesInvoice]
  /// by setting the [Receipt]'s foreign key `invoiceId` to refer to the [SalesInvoice].
  Future<void> invoice(
    _i1.DatabaseSession session,
    Receipt receipt,
    _i6.SalesInvoice invoice, {
    _i1.Transaction? transaction,
  }) async {
    if (receipt.id == null) {
      throw ArgumentError.notNull('receipt.id');
    }
    if (invoice.id == null) {
      throw ArgumentError.notNull('invoice.id');
    }

    var $receipt = receipt.copyWith(invoiceId: invoice.id);
    await session.db.updateRow<Receipt>(
      $receipt,
      columns: [Receipt.t.invoiceId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [Receipt] and [Device]
  /// by setting the [Receipt]'s foreign key `deviceId` to refer to the [Device].
  Future<void> device(
    _i1.DatabaseSession session,
    Receipt receipt,
    _i7.Device device, {
    _i1.Transaction? transaction,
  }) async {
    if (receipt.id == null) {
      throw ArgumentError.notNull('receipt.id');
    }
    if (device.id == null) {
      throw ArgumentError.notNull('device.id');
    }

    var $receipt = receipt.copyWith(deviceId: device.id);
    await session.db.updateRow<Receipt>(
      $receipt,
      columns: [Receipt.t.deviceId],
      transaction: transaction,
    );
  }
}

class ReceiptDetachRowRepository {
  const ReceiptDetachRowRepository._();

  /// Detaches the relation between this [Receipt] and the [SalesInvoice] set in `invoice`
  /// by setting the [Receipt]'s foreign key `invoiceId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> invoice(
    _i1.DatabaseSession session,
    Receipt receipt, {
    _i1.Transaction? transaction,
  }) async {
    if (receipt.id == null) {
      throw ArgumentError.notNull('receipt.id');
    }

    var $receipt = receipt.copyWith(invoiceId: null);
    await session.db.updateRow<Receipt>(
      $receipt,
      columns: [Receipt.t.invoiceId],
      transaction: transaction,
    );
  }
}
