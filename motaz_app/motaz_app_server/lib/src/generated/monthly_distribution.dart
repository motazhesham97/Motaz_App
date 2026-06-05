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
import 'device.dart' as _i4;
import 'package:motaz_app_server/src/generated/protocol.dart' as _i5;

abstract class MonthlyDistribution
    implements _i1.TableRow<_i1.UuidValue?>, _i1.ProtocolSerialization {
  MonthlyDistribution._({
    this.id,
    required this.year,
    required this.month,
    required this.netProfit,
    required this.ownerShare,
    required this.partnerShare,
    required this.marginShare,
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

  factory MonthlyDistribution({
    _i1.UuidValue? id,
    required int year,
    required int month,
    required int netProfit,
    required int ownerShare,
    required int partnerShare,
    required int marginShare,
    _i2.RecordStatus? status,
    String? voidReason,
    required DateTime createdAt,
    required DateTime updatedAt,
    required _i1.UuidValue deviceId,
    _i4.Device? device,
    int? rowVersion,
    _i3.SyncStatus? syncStatus,
  }) = _MonthlyDistributionImpl;

  factory MonthlyDistribution.fromJson(Map<String, dynamic> jsonSerialization) {
    return MonthlyDistribution(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      year: jsonSerialization['year'] as int,
      month: jsonSerialization['month'] as int,
      netProfit: jsonSerialization['netProfit'] as int,
      ownerShare: jsonSerialization['ownerShare'] as int,
      partnerShare: jsonSerialization['partnerShare'] as int,
      marginShare: jsonSerialization['marginShare'] as int,
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
          : _i5.Protocol().deserialize<_i4.Device>(jsonSerialization['device']),
      rowVersion: jsonSerialization['rowVersion'] as int?,
      syncStatus: jsonSerialization['syncStatus'] == null
          ? null
          : _i3.SyncStatus.fromJson(
              (jsonSerialization['syncStatus'] as String),
            ),
    );
  }

  static final t = MonthlyDistributionTable();

  static const db = MonthlyDistributionRepository._();

  @override
  _i1.UuidValue? id;

  int year;

  int month;

  int netProfit;

  int ownerShare;

  int partnerShare;

  int marginShare;

  _i2.RecordStatus status;

  String? voidReason;

  DateTime createdAt;

  DateTime updatedAt;

  _i1.UuidValue deviceId;

  _i4.Device? device;

  int rowVersion;

  _i3.SyncStatus syncStatus;

  @override
  _i1.Table<_i1.UuidValue?> get table => t;

  /// Returns a shallow copy of this [MonthlyDistribution]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  MonthlyDistribution copyWith({
    _i1.UuidValue? id,
    int? year,
    int? month,
    int? netProfit,
    int? ownerShare,
    int? partnerShare,
    int? marginShare,
    _i2.RecordStatus? status,
    String? voidReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    _i1.UuidValue? deviceId,
    _i4.Device? device,
    int? rowVersion,
    _i3.SyncStatus? syncStatus,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MonthlyDistribution',
      if (id != null) 'id': id?.toJson(),
      'year': year,
      'month': month,
      'netProfit': netProfit,
      'ownerShare': ownerShare,
      'partnerShare': partnerShare,
      'marginShare': marginShare,
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
      '__className__': 'MonthlyDistribution',
      if (id != null) 'id': id?.toJson(),
      'year': year,
      'month': month,
      'netProfit': netProfit,
      'ownerShare': ownerShare,
      'partnerShare': partnerShare,
      'marginShare': marginShare,
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

  static MonthlyDistributionInclude include({_i4.DeviceInclude? device}) {
    return MonthlyDistributionInclude._(device: device);
  }

  static MonthlyDistributionIncludeList includeList({
    _i1.WhereExpressionBuilder<MonthlyDistributionTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<MonthlyDistributionTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<MonthlyDistributionTable>? orderByList,
    MonthlyDistributionInclude? include,
  }) {
    return MonthlyDistributionIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(MonthlyDistribution.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(MonthlyDistribution.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MonthlyDistributionImpl extends MonthlyDistribution {
  _MonthlyDistributionImpl({
    _i1.UuidValue? id,
    required int year,
    required int month,
    required int netProfit,
    required int ownerShare,
    required int partnerShare,
    required int marginShare,
    _i2.RecordStatus? status,
    String? voidReason,
    required DateTime createdAt,
    required DateTime updatedAt,
    required _i1.UuidValue deviceId,
    _i4.Device? device,
    int? rowVersion,
    _i3.SyncStatus? syncStatus,
  }) : super._(
         id: id,
         year: year,
         month: month,
         netProfit: netProfit,
         ownerShare: ownerShare,
         partnerShare: partnerShare,
         marginShare: marginShare,
         status: status,
         voidReason: voidReason,
         createdAt: createdAt,
         updatedAt: updatedAt,
         deviceId: deviceId,
         device: device,
         rowVersion: rowVersion,
         syncStatus: syncStatus,
       );

  /// Returns a shallow copy of this [MonthlyDistribution]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  MonthlyDistribution copyWith({
    Object? id = _Undefined,
    int? year,
    int? month,
    int? netProfit,
    int? ownerShare,
    int? partnerShare,
    int? marginShare,
    _i2.RecordStatus? status,
    Object? voidReason = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
    _i1.UuidValue? deviceId,
    Object? device = _Undefined,
    int? rowVersion,
    _i3.SyncStatus? syncStatus,
  }) {
    return MonthlyDistribution(
      id: id is _i1.UuidValue? ? id : this.id,
      year: year ?? this.year,
      month: month ?? this.month,
      netProfit: netProfit ?? this.netProfit,
      ownerShare: ownerShare ?? this.ownerShare,
      partnerShare: partnerShare ?? this.partnerShare,
      marginShare: marginShare ?? this.marginShare,
      status: status ?? this.status,
      voidReason: voidReason is String? ? voidReason : this.voidReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      device: device is _i4.Device? ? device : this.device?.copyWith(),
      rowVersion: rowVersion ?? this.rowVersion,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}

class MonthlyDistributionUpdateTable
    extends _i1.UpdateTable<MonthlyDistributionTable> {
  MonthlyDistributionUpdateTable(super.table);

  _i1.ColumnValue<int, int> year(int value) => _i1.ColumnValue(
    table.year,
    value,
  );

  _i1.ColumnValue<int, int> month(int value) => _i1.ColumnValue(
    table.month,
    value,
  );

  _i1.ColumnValue<int, int> netProfit(int value) => _i1.ColumnValue(
    table.netProfit,
    value,
  );

  _i1.ColumnValue<int, int> ownerShare(int value) => _i1.ColumnValue(
    table.ownerShare,
    value,
  );

  _i1.ColumnValue<int, int> partnerShare(int value) => _i1.ColumnValue(
    table.partnerShare,
    value,
  );

  _i1.ColumnValue<int, int> marginShare(int value) => _i1.ColumnValue(
    table.marginShare,
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

class MonthlyDistributionTable extends _i1.Table<_i1.UuidValue?> {
  MonthlyDistributionTable({super.tableRelation})
    : super(tableName: 'monthly_distribution') {
    updateTable = MonthlyDistributionUpdateTable(this);
    year = _i1.ColumnInt(
      'year',
      this,
    );
    month = _i1.ColumnInt(
      'month',
      this,
    );
    netProfit = _i1.ColumnInt(
      'netProfit',
      this,
    );
    ownerShare = _i1.ColumnInt(
      'ownerShare',
      this,
    );
    partnerShare = _i1.ColumnInt(
      'partnerShare',
      this,
    );
    marginShare = _i1.ColumnInt(
      'marginShare',
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

  late final MonthlyDistributionUpdateTable updateTable;

  late final _i1.ColumnInt year;

  late final _i1.ColumnInt month;

  late final _i1.ColumnInt netProfit;

  late final _i1.ColumnInt ownerShare;

  late final _i1.ColumnInt partnerShare;

  late final _i1.ColumnInt marginShare;

  late final _i1.ColumnEnum<_i2.RecordStatus> status;

  late final _i1.ColumnString voidReason;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  late final _i1.ColumnUuid deviceId;

  _i4.DeviceTable? _device;

  late final _i1.ColumnInt rowVersion;

  late final _i1.ColumnEnum<_i3.SyncStatus> syncStatus;

  _i4.DeviceTable get device {
    if (_device != null) return _device!;
    _device = _i1.createRelationTable(
      relationFieldName: 'device',
      field: MonthlyDistribution.t.deviceId,
      foreignField: _i4.Device.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i4.DeviceTable(tableRelation: foreignTableRelation),
    );
    return _device!;
  }

  @override
  List<_i1.Column> get columns => [
    id,
    year,
    month,
    netProfit,
    ownerShare,
    partnerShare,
    marginShare,
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
    if (relationField == 'device') {
      return device;
    }
    return null;
  }
}

class MonthlyDistributionInclude extends _i1.IncludeObject {
  MonthlyDistributionInclude._({_i4.DeviceInclude? device}) {
    _device = device;
  }

  _i4.DeviceInclude? _device;

  @override
  Map<String, _i1.Include?> get includes => {'device': _device};

  @override
  _i1.Table<_i1.UuidValue?> get table => MonthlyDistribution.t;
}

class MonthlyDistributionIncludeList extends _i1.IncludeList {
  MonthlyDistributionIncludeList._({
    _i1.WhereExpressionBuilder<MonthlyDistributionTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(MonthlyDistribution.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue?> get table => MonthlyDistribution.t;
}

class MonthlyDistributionRepository {
  const MonthlyDistributionRepository._();

  final attachRow = const MonthlyDistributionAttachRowRepository._();

  /// Returns a list of [MonthlyDistribution]s matching the given query parameters.
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
  Future<List<MonthlyDistribution>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<MonthlyDistributionTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<MonthlyDistributionTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<MonthlyDistributionTable>? orderByList,
    _i1.Transaction? transaction,
    MonthlyDistributionInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<MonthlyDistribution>(
      where: where?.call(MonthlyDistribution.t),
      orderBy: orderBy?.call(MonthlyDistribution.t),
      orderByList: orderByList?.call(MonthlyDistribution.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [MonthlyDistribution] matching the given query parameters.
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
  Future<MonthlyDistribution?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<MonthlyDistributionTable>? where,
    int? offset,
    _i1.OrderByBuilder<MonthlyDistributionTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<MonthlyDistributionTable>? orderByList,
    _i1.Transaction? transaction,
    MonthlyDistributionInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<MonthlyDistribution>(
      where: where?.call(MonthlyDistribution.t),
      orderBy: orderBy?.call(MonthlyDistribution.t),
      orderByList: orderByList?.call(MonthlyDistribution.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [MonthlyDistribution] by its [id] or null if no such row exists.
  Future<MonthlyDistribution?> findById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    MonthlyDistributionInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<MonthlyDistribution>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [MonthlyDistribution]s in the list and returns the inserted rows.
  ///
  /// The returned [MonthlyDistribution]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<MonthlyDistribution>> insert(
    _i1.DatabaseSession session,
    List<MonthlyDistribution> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<MonthlyDistribution>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [MonthlyDistribution] and returns the inserted row.
  ///
  /// The returned [MonthlyDistribution] will have its `id` field set.
  Future<MonthlyDistribution> insertRow(
    _i1.DatabaseSession session,
    MonthlyDistribution row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<MonthlyDistribution>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [MonthlyDistribution]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<MonthlyDistribution>> update(
    _i1.DatabaseSession session,
    List<MonthlyDistribution> rows, {
    _i1.ColumnSelections<MonthlyDistributionTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<MonthlyDistribution>(
      rows,
      columns: columns?.call(MonthlyDistribution.t),
      transaction: transaction,
    );
  }

  /// Updates a single [MonthlyDistribution]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<MonthlyDistribution> updateRow(
    _i1.DatabaseSession session,
    MonthlyDistribution row, {
    _i1.ColumnSelections<MonthlyDistributionTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<MonthlyDistribution>(
      row,
      columns: columns?.call(MonthlyDistribution.t),
      transaction: transaction,
    );
  }

  /// Updates a single [MonthlyDistribution] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<MonthlyDistribution?> updateById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<MonthlyDistributionUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<MonthlyDistribution>(
      id,
      columnValues: columnValues(MonthlyDistribution.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [MonthlyDistribution]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<MonthlyDistribution>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<MonthlyDistributionUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<MonthlyDistributionTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<MonthlyDistributionTable>? orderBy,
    _i1.OrderByListBuilder<MonthlyDistributionTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<MonthlyDistribution>(
      columnValues: columnValues(MonthlyDistribution.t.updateTable),
      where: where(MonthlyDistribution.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(MonthlyDistribution.t),
      orderByList: orderByList?.call(MonthlyDistribution.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [MonthlyDistribution]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<MonthlyDistribution>> delete(
    _i1.DatabaseSession session,
    List<MonthlyDistribution> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<MonthlyDistribution>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [MonthlyDistribution].
  Future<MonthlyDistribution> deleteRow(
    _i1.DatabaseSession session,
    MonthlyDistribution row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<MonthlyDistribution>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<MonthlyDistribution>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<MonthlyDistributionTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<MonthlyDistribution>(
      where: where(MonthlyDistribution.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<MonthlyDistributionTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<MonthlyDistribution>(
      where: where?.call(MonthlyDistribution.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [MonthlyDistribution] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<MonthlyDistributionTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<MonthlyDistribution>(
      where: where(MonthlyDistribution.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class MonthlyDistributionAttachRowRepository {
  const MonthlyDistributionAttachRowRepository._();

  /// Creates a relation between the given [MonthlyDistribution] and [Device]
  /// by setting the [MonthlyDistribution]'s foreign key `deviceId` to refer to the [Device].
  Future<void> device(
    _i1.DatabaseSession session,
    MonthlyDistribution monthlyDistribution,
    _i4.Device device, {
    _i1.Transaction? transaction,
  }) async {
    if (monthlyDistribution.id == null) {
      throw ArgumentError.notNull('monthlyDistribution.id');
    }
    if (device.id == null) {
      throw ArgumentError.notNull('device.id');
    }

    var $monthlyDistribution = monthlyDistribution.copyWith(
      deviceId: device.id,
    );
    await session.db.updateRow<MonthlyDistribution>(
      $monthlyDistribution,
      columns: [MonthlyDistribution.t.deviceId],
      transaction: transaction,
    );
  }
}
