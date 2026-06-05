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
import 'beneficiary.dart' as _i4;
import 'device.dart' as _i5;
import 'package:motaz_app_server/src/generated/protocol.dart' as _i6;

abstract class FreeSample
    implements _i1.TableRow<_i1.UuidValue?>, _i1.ProtocolSerialization {
  FreeSample._({
    this.id,
    required this.localRef,
    this.officialNo,
    required this.beneficiaryId,
    this.beneficiary,
    required this.sampleDate,
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

  factory FreeSample({
    _i1.UuidValue? id,
    required String localRef,
    String? officialNo,
    required _i1.UuidValue beneficiaryId,
    _i4.Beneficiary? beneficiary,
    required DateTime sampleDate,
    String? note,
    _i2.RecordStatus? status,
    String? voidReason,
    required DateTime createdAt,
    required DateTime updatedAt,
    required _i1.UuidValue deviceId,
    _i5.Device? device,
    int? rowVersion,
    _i3.SyncStatus? syncStatus,
  }) = _FreeSampleImpl;

  factory FreeSample.fromJson(Map<String, dynamic> jsonSerialization) {
    return FreeSample(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      localRef: jsonSerialization['localRef'] as String,
      officialNo: jsonSerialization['officialNo'] as String?,
      beneficiaryId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['beneficiaryId'],
      ),
      beneficiary: jsonSerialization['beneficiary'] == null
          ? null
          : _i6.Protocol().deserialize<_i4.Beneficiary>(
              jsonSerialization['beneficiary'],
            ),
      sampleDate: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['sampleDate'],
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
          : _i6.Protocol().deserialize<_i5.Device>(jsonSerialization['device']),
      rowVersion: jsonSerialization['rowVersion'] as int?,
      syncStatus: jsonSerialization['syncStatus'] == null
          ? null
          : _i3.SyncStatus.fromJson(
              (jsonSerialization['syncStatus'] as String),
            ),
    );
  }

  static final t = FreeSampleTable();

  static const db = FreeSampleRepository._();

  @override
  _i1.UuidValue? id;

  String localRef;

  String? officialNo;

  _i1.UuidValue beneficiaryId;

  _i4.Beneficiary? beneficiary;

  DateTime sampleDate;

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

  /// Returns a shallow copy of this [FreeSample]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  FreeSample copyWith({
    _i1.UuidValue? id,
    String? localRef,
    String? officialNo,
    _i1.UuidValue? beneficiaryId,
    _i4.Beneficiary? beneficiary,
    DateTime? sampleDate,
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
      '__className__': 'FreeSample',
      if (id != null) 'id': id?.toJson(),
      'localRef': localRef,
      if (officialNo != null) 'officialNo': officialNo,
      'beneficiaryId': beneficiaryId.toJson(),
      if (beneficiary != null) 'beneficiary': beneficiary?.toJson(),
      'sampleDate': sampleDate.toJson(),
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
      '__className__': 'FreeSample',
      if (id != null) 'id': id?.toJson(),
      'localRef': localRef,
      if (officialNo != null) 'officialNo': officialNo,
      'beneficiaryId': beneficiaryId.toJson(),
      if (beneficiary != null) 'beneficiary': beneficiary?.toJsonForProtocol(),
      'sampleDate': sampleDate.toJson(),
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

  static FreeSampleInclude include({
    _i4.BeneficiaryInclude? beneficiary,
    _i5.DeviceInclude? device,
  }) {
    return FreeSampleInclude._(
      beneficiary: beneficiary,
      device: device,
    );
  }

  static FreeSampleIncludeList includeList({
    _i1.WhereExpressionBuilder<FreeSampleTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<FreeSampleTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<FreeSampleTable>? orderByList,
    FreeSampleInclude? include,
  }) {
    return FreeSampleIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(FreeSample.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(FreeSample.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _FreeSampleImpl extends FreeSample {
  _FreeSampleImpl({
    _i1.UuidValue? id,
    required String localRef,
    String? officialNo,
    required _i1.UuidValue beneficiaryId,
    _i4.Beneficiary? beneficiary,
    required DateTime sampleDate,
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
         beneficiaryId: beneficiaryId,
         beneficiary: beneficiary,
         sampleDate: sampleDate,
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

  /// Returns a shallow copy of this [FreeSample]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  FreeSample copyWith({
    Object? id = _Undefined,
    String? localRef,
    Object? officialNo = _Undefined,
    _i1.UuidValue? beneficiaryId,
    Object? beneficiary = _Undefined,
    DateTime? sampleDate,
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
    return FreeSample(
      id: id is _i1.UuidValue? ? id : this.id,
      localRef: localRef ?? this.localRef,
      officialNo: officialNo is String? ? officialNo : this.officialNo,
      beneficiaryId: beneficiaryId ?? this.beneficiaryId,
      beneficiary: beneficiary is _i4.Beneficiary?
          ? beneficiary
          : this.beneficiary?.copyWith(),
      sampleDate: sampleDate ?? this.sampleDate,
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

class FreeSampleUpdateTable extends _i1.UpdateTable<FreeSampleTable> {
  FreeSampleUpdateTable(super.table);

  _i1.ColumnValue<String, String> localRef(String value) => _i1.ColumnValue(
    table.localRef,
    value,
  );

  _i1.ColumnValue<String, String> officialNo(String? value) => _i1.ColumnValue(
    table.officialNo,
    value,
  );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> beneficiaryId(
    _i1.UuidValue value,
  ) => _i1.ColumnValue(
    table.beneficiaryId,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> sampleDate(DateTime value) =>
      _i1.ColumnValue(
        table.sampleDate,
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

class FreeSampleTable extends _i1.Table<_i1.UuidValue?> {
  FreeSampleTable({super.tableRelation}) : super(tableName: 'free_sample') {
    updateTable = FreeSampleUpdateTable(this);
    localRef = _i1.ColumnString(
      'localRef',
      this,
    );
    officialNo = _i1.ColumnString(
      'officialNo',
      this,
    );
    beneficiaryId = _i1.ColumnUuid(
      'beneficiaryId',
      this,
    );
    sampleDate = _i1.ColumnDateTime(
      'sampleDate',
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

  late final FreeSampleUpdateTable updateTable;

  late final _i1.ColumnString localRef;

  late final _i1.ColumnString officialNo;

  late final _i1.ColumnUuid beneficiaryId;

  _i4.BeneficiaryTable? _beneficiary;

  late final _i1.ColumnDateTime sampleDate;

  late final _i1.ColumnString note;

  late final _i1.ColumnEnum<_i2.RecordStatus> status;

  late final _i1.ColumnString voidReason;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  late final _i1.ColumnUuid deviceId;

  _i5.DeviceTable? _device;

  late final _i1.ColumnInt rowVersion;

  late final _i1.ColumnEnum<_i3.SyncStatus> syncStatus;

  _i4.BeneficiaryTable get beneficiary {
    if (_beneficiary != null) return _beneficiary!;
    _beneficiary = _i1.createRelationTable(
      relationFieldName: 'beneficiary',
      field: FreeSample.t.beneficiaryId,
      foreignField: _i4.Beneficiary.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i4.BeneficiaryTable(tableRelation: foreignTableRelation),
    );
    return _beneficiary!;
  }

  _i5.DeviceTable get device {
    if (_device != null) return _device!;
    _device = _i1.createRelationTable(
      relationFieldName: 'device',
      field: FreeSample.t.deviceId,
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
    beneficiaryId,
    sampleDate,
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
    if (relationField == 'beneficiary') {
      return beneficiary;
    }
    if (relationField == 'device') {
      return device;
    }
    return null;
  }
}

class FreeSampleInclude extends _i1.IncludeObject {
  FreeSampleInclude._({
    _i4.BeneficiaryInclude? beneficiary,
    _i5.DeviceInclude? device,
  }) {
    _beneficiary = beneficiary;
    _device = device;
  }

  _i4.BeneficiaryInclude? _beneficiary;

  _i5.DeviceInclude? _device;

  @override
  Map<String, _i1.Include?> get includes => {
    'beneficiary': _beneficiary,
    'device': _device,
  };

  @override
  _i1.Table<_i1.UuidValue?> get table => FreeSample.t;
}

class FreeSampleIncludeList extends _i1.IncludeList {
  FreeSampleIncludeList._({
    _i1.WhereExpressionBuilder<FreeSampleTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(FreeSample.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue?> get table => FreeSample.t;
}

class FreeSampleRepository {
  const FreeSampleRepository._();

  final attachRow = const FreeSampleAttachRowRepository._();

  /// Returns a list of [FreeSample]s matching the given query parameters.
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
  Future<List<FreeSample>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<FreeSampleTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<FreeSampleTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<FreeSampleTable>? orderByList,
    _i1.Transaction? transaction,
    FreeSampleInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<FreeSample>(
      where: where?.call(FreeSample.t),
      orderBy: orderBy?.call(FreeSample.t),
      orderByList: orderByList?.call(FreeSample.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [FreeSample] matching the given query parameters.
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
  Future<FreeSample?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<FreeSampleTable>? where,
    int? offset,
    _i1.OrderByBuilder<FreeSampleTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<FreeSampleTable>? orderByList,
    _i1.Transaction? transaction,
    FreeSampleInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<FreeSample>(
      where: where?.call(FreeSample.t),
      orderBy: orderBy?.call(FreeSample.t),
      orderByList: orderByList?.call(FreeSample.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [FreeSample] by its [id] or null if no such row exists.
  Future<FreeSample?> findById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    FreeSampleInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<FreeSample>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [FreeSample]s in the list and returns the inserted rows.
  ///
  /// The returned [FreeSample]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<FreeSample>> insert(
    _i1.DatabaseSession session,
    List<FreeSample> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<FreeSample>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [FreeSample] and returns the inserted row.
  ///
  /// The returned [FreeSample] will have its `id` field set.
  Future<FreeSample> insertRow(
    _i1.DatabaseSession session,
    FreeSample row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<FreeSample>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [FreeSample]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<FreeSample>> update(
    _i1.DatabaseSession session,
    List<FreeSample> rows, {
    _i1.ColumnSelections<FreeSampleTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<FreeSample>(
      rows,
      columns: columns?.call(FreeSample.t),
      transaction: transaction,
    );
  }

  /// Updates a single [FreeSample]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<FreeSample> updateRow(
    _i1.DatabaseSession session,
    FreeSample row, {
    _i1.ColumnSelections<FreeSampleTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<FreeSample>(
      row,
      columns: columns?.call(FreeSample.t),
      transaction: transaction,
    );
  }

  /// Updates a single [FreeSample] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<FreeSample?> updateById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<FreeSampleUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<FreeSample>(
      id,
      columnValues: columnValues(FreeSample.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [FreeSample]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<FreeSample>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<FreeSampleUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<FreeSampleTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<FreeSampleTable>? orderBy,
    _i1.OrderByListBuilder<FreeSampleTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<FreeSample>(
      columnValues: columnValues(FreeSample.t.updateTable),
      where: where(FreeSample.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(FreeSample.t),
      orderByList: orderByList?.call(FreeSample.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [FreeSample]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<FreeSample>> delete(
    _i1.DatabaseSession session,
    List<FreeSample> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<FreeSample>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [FreeSample].
  Future<FreeSample> deleteRow(
    _i1.DatabaseSession session,
    FreeSample row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<FreeSample>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<FreeSample>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<FreeSampleTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<FreeSample>(
      where: where(FreeSample.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<FreeSampleTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<FreeSample>(
      where: where?.call(FreeSample.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [FreeSample] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<FreeSampleTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<FreeSample>(
      where: where(FreeSample.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class FreeSampleAttachRowRepository {
  const FreeSampleAttachRowRepository._();

  /// Creates a relation between the given [FreeSample] and [Beneficiary]
  /// by setting the [FreeSample]'s foreign key `beneficiaryId` to refer to the [Beneficiary].
  Future<void> beneficiary(
    _i1.DatabaseSession session,
    FreeSample freeSample,
    _i4.Beneficiary beneficiary, {
    _i1.Transaction? transaction,
  }) async {
    if (freeSample.id == null) {
      throw ArgumentError.notNull('freeSample.id');
    }
    if (beneficiary.id == null) {
      throw ArgumentError.notNull('beneficiary.id');
    }

    var $freeSample = freeSample.copyWith(beneficiaryId: beneficiary.id);
    await session.db.updateRow<FreeSample>(
      $freeSample,
      columns: [FreeSample.t.beneficiaryId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [FreeSample] and [Device]
  /// by setting the [FreeSample]'s foreign key `deviceId` to refer to the [Device].
  Future<void> device(
    _i1.DatabaseSession session,
    FreeSample freeSample,
    _i5.Device device, {
    _i1.Transaction? transaction,
  }) async {
    if (freeSample.id == null) {
      throw ArgumentError.notNull('freeSample.id');
    }
    if (device.id == null) {
      throw ArgumentError.notNull('device.id');
    }

    var $freeSample = freeSample.copyWith(deviceId: device.id);
    await session.db.updateRow<FreeSample>(
      $freeSample,
      columns: [FreeSample.t.deviceId],
      transaction: transaction,
    );
  }
}
