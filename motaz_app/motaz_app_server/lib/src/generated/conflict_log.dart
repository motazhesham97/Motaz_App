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
import 'enums/conflict_status.dart' as _i2;
import 'enums/parent_entity_type.dart' as _i3;
import 'device.dart' as _i4;
import 'package:motaz_app_server/src/generated/protocol.dart' as _i5;

abstract class ConflictLog
    implements _i1.TableRow<_i1.UuidValue?>, _i1.ProtocolSerialization {
  ConflictLog._({
    this.id,
    required this.entityType,
    required this.entityId,
    required this.localPayload,
    required this.remotePayload,
    required this.conflictType,
    _i2.ConflictStatus? resolutionStatus,
    this.resolvedAt,
    this.resolutionData,
    required this.createdAt,
    required this.deviceId,
    this.device,
  }) : resolutionStatus = resolutionStatus ?? _i2.ConflictStatus.PENDING;

  factory ConflictLog({
    _i1.UuidValue? id,
    required _i3.ParentEntityType entityType,
    required _i1.UuidValue entityId,
    required String localPayload,
    required String remotePayload,
    required String conflictType,
    _i2.ConflictStatus? resolutionStatus,
    DateTime? resolvedAt,
    String? resolutionData,
    required DateTime createdAt,
    required _i1.UuidValue deviceId,
    _i4.Device? device,
  }) = _ConflictLogImpl;

  factory ConflictLog.fromJson(Map<String, dynamic> jsonSerialization) {
    return ConflictLog(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      entityType: _i3.ParentEntityType.fromJson(
        (jsonSerialization['entityType'] as String),
      ),
      entityId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['entityId'],
      ),
      localPayload: jsonSerialization['localPayload'] as String,
      remotePayload: jsonSerialization['remotePayload'] as String,
      conflictType: jsonSerialization['conflictType'] as String,
      resolutionStatus: jsonSerialization['resolutionStatus'] == null
          ? null
          : _i2.ConflictStatus.fromJson(
              (jsonSerialization['resolutionStatus'] as String),
            ),
      resolvedAt: jsonSerialization['resolvedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['resolvedAt']),
      resolutionData: jsonSerialization['resolutionData'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      deviceId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['deviceId'],
      ),
      device: jsonSerialization['device'] == null
          ? null
          : _i5.Protocol().deserialize<_i4.Device>(jsonSerialization['device']),
    );
  }

  static final t = ConflictLogTable();

  static const db = ConflictLogRepository._();

  @override
  _i1.UuidValue? id;

  _i3.ParentEntityType entityType;

  _i1.UuidValue entityId;

  String localPayload;

  String remotePayload;

  String conflictType;

  _i2.ConflictStatus resolutionStatus;

  DateTime? resolvedAt;

  String? resolutionData;

  DateTime createdAt;

  _i1.UuidValue deviceId;

  _i4.Device? device;

  @override
  _i1.Table<_i1.UuidValue?> get table => t;

  /// Returns a shallow copy of this [ConflictLog]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ConflictLog copyWith({
    _i1.UuidValue? id,
    _i3.ParentEntityType? entityType,
    _i1.UuidValue? entityId,
    String? localPayload,
    String? remotePayload,
    String? conflictType,
    _i2.ConflictStatus? resolutionStatus,
    DateTime? resolvedAt,
    String? resolutionData,
    DateTime? createdAt,
    _i1.UuidValue? deviceId,
    _i4.Device? device,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConflictLog',
      if (id != null) 'id': id?.toJson(),
      'entityType': entityType.toJson(),
      'entityId': entityId.toJson(),
      'localPayload': localPayload,
      'remotePayload': remotePayload,
      'conflictType': conflictType,
      'resolutionStatus': resolutionStatus.toJson(),
      if (resolvedAt != null) 'resolvedAt': resolvedAt?.toJson(),
      if (resolutionData != null) 'resolutionData': resolutionData,
      'createdAt': createdAt.toJson(),
      'deviceId': deviceId.toJson(),
      if (device != null) 'device': device?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ConflictLog',
      if (id != null) 'id': id?.toJson(),
      'entityType': entityType.toJson(),
      'entityId': entityId.toJson(),
      'localPayload': localPayload,
      'remotePayload': remotePayload,
      'conflictType': conflictType,
      'resolutionStatus': resolutionStatus.toJson(),
      if (resolvedAt != null) 'resolvedAt': resolvedAt?.toJson(),
      if (resolutionData != null) 'resolutionData': resolutionData,
      'createdAt': createdAt.toJson(),
      'deviceId': deviceId.toJson(),
      if (device != null) 'device': device?.toJsonForProtocol(),
    };
  }

  static ConflictLogInclude include({_i4.DeviceInclude? device}) {
    return ConflictLogInclude._(device: device);
  }

  static ConflictLogIncludeList includeList({
    _i1.WhereExpressionBuilder<ConflictLogTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ConflictLogTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ConflictLogTable>? orderByList,
    ConflictLogInclude? include,
  }) {
    return ConflictLogIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ConflictLog.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(ConflictLog.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ConflictLogImpl extends ConflictLog {
  _ConflictLogImpl({
    _i1.UuidValue? id,
    required _i3.ParentEntityType entityType,
    required _i1.UuidValue entityId,
    required String localPayload,
    required String remotePayload,
    required String conflictType,
    _i2.ConflictStatus? resolutionStatus,
    DateTime? resolvedAt,
    String? resolutionData,
    required DateTime createdAt,
    required _i1.UuidValue deviceId,
    _i4.Device? device,
  }) : super._(
         id: id,
         entityType: entityType,
         entityId: entityId,
         localPayload: localPayload,
         remotePayload: remotePayload,
         conflictType: conflictType,
         resolutionStatus: resolutionStatus,
         resolvedAt: resolvedAt,
         resolutionData: resolutionData,
         createdAt: createdAt,
         deviceId: deviceId,
         device: device,
       );

  /// Returns a shallow copy of this [ConflictLog]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ConflictLog copyWith({
    Object? id = _Undefined,
    _i3.ParentEntityType? entityType,
    _i1.UuidValue? entityId,
    String? localPayload,
    String? remotePayload,
    String? conflictType,
    _i2.ConflictStatus? resolutionStatus,
    Object? resolvedAt = _Undefined,
    Object? resolutionData = _Undefined,
    DateTime? createdAt,
    _i1.UuidValue? deviceId,
    Object? device = _Undefined,
  }) {
    return ConflictLog(
      id: id is _i1.UuidValue? ? id : this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      localPayload: localPayload ?? this.localPayload,
      remotePayload: remotePayload ?? this.remotePayload,
      conflictType: conflictType ?? this.conflictType,
      resolutionStatus: resolutionStatus ?? this.resolutionStatus,
      resolvedAt: resolvedAt is DateTime? ? resolvedAt : this.resolvedAt,
      resolutionData: resolutionData is String?
          ? resolutionData
          : this.resolutionData,
      createdAt: createdAt ?? this.createdAt,
      deviceId: deviceId ?? this.deviceId,
      device: device is _i4.Device? ? device : this.device?.copyWith(),
    );
  }
}

class ConflictLogUpdateTable extends _i1.UpdateTable<ConflictLogTable> {
  ConflictLogUpdateTable(super.table);

  _i1.ColumnValue<_i3.ParentEntityType, _i3.ParentEntityType> entityType(
    _i3.ParentEntityType value,
  ) => _i1.ColumnValue(
    table.entityType,
    value,
  );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> entityId(_i1.UuidValue value) =>
      _i1.ColumnValue(
        table.entityId,
        value,
      );

  _i1.ColumnValue<String, String> localPayload(String value) => _i1.ColumnValue(
    table.localPayload,
    value,
  );

  _i1.ColumnValue<String, String> remotePayload(String value) =>
      _i1.ColumnValue(
        table.remotePayload,
        value,
      );

  _i1.ColumnValue<String, String> conflictType(String value) => _i1.ColumnValue(
    table.conflictType,
    value,
  );

  _i1.ColumnValue<_i2.ConflictStatus, _i2.ConflictStatus> resolutionStatus(
    _i2.ConflictStatus value,
  ) => _i1.ColumnValue(
    table.resolutionStatus,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> resolvedAt(DateTime? value) =>
      _i1.ColumnValue(
        table.resolvedAt,
        value,
      );

  _i1.ColumnValue<String, String> resolutionData(String? value) =>
      _i1.ColumnValue(
        table.resolutionData,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> deviceId(_i1.UuidValue value) =>
      _i1.ColumnValue(
        table.deviceId,
        value,
      );
}

class ConflictLogTable extends _i1.Table<_i1.UuidValue?> {
  ConflictLogTable({super.tableRelation}) : super(tableName: 'conflict_log') {
    updateTable = ConflictLogUpdateTable(this);
    entityType = _i1.ColumnEnum(
      'entityType',
      this,
      _i1.EnumSerialization.byName,
    );
    entityId = _i1.ColumnUuid(
      'entityId',
      this,
    );
    localPayload = _i1.ColumnString(
      'localPayload',
      this,
    );
    remotePayload = _i1.ColumnString(
      'remotePayload',
      this,
    );
    conflictType = _i1.ColumnString(
      'conflictType',
      this,
    );
    resolutionStatus = _i1.ColumnEnum(
      'resolutionStatus',
      this,
      _i1.EnumSerialization.byName,
      hasDefault: true,
    );
    resolvedAt = _i1.ColumnDateTime(
      'resolvedAt',
      this,
    );
    resolutionData = _i1.ColumnString(
      'resolutionData',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
    deviceId = _i1.ColumnUuid(
      'deviceId',
      this,
    );
  }

  late final ConflictLogUpdateTable updateTable;

  late final _i1.ColumnEnum<_i3.ParentEntityType> entityType;

  late final _i1.ColumnUuid entityId;

  late final _i1.ColumnString localPayload;

  late final _i1.ColumnString remotePayload;

  late final _i1.ColumnString conflictType;

  late final _i1.ColumnEnum<_i2.ConflictStatus> resolutionStatus;

  late final _i1.ColumnDateTime resolvedAt;

  late final _i1.ColumnString resolutionData;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnUuid deviceId;

  _i4.DeviceTable? _device;

  _i4.DeviceTable get device {
    if (_device != null) return _device!;
    _device = _i1.createRelationTable(
      relationFieldName: 'device',
      field: ConflictLog.t.deviceId,
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
    entityType,
    entityId,
    localPayload,
    remotePayload,
    conflictType,
    resolutionStatus,
    resolvedAt,
    resolutionData,
    createdAt,
    deviceId,
  ];

  @override
  _i1.Table? getRelationTable(String relationField) {
    if (relationField == 'device') {
      return device;
    }
    return null;
  }
}

class ConflictLogInclude extends _i1.IncludeObject {
  ConflictLogInclude._({_i4.DeviceInclude? device}) {
    _device = device;
  }

  _i4.DeviceInclude? _device;

  @override
  Map<String, _i1.Include?> get includes => {'device': _device};

  @override
  _i1.Table<_i1.UuidValue?> get table => ConflictLog.t;
}

class ConflictLogIncludeList extends _i1.IncludeList {
  ConflictLogIncludeList._({
    _i1.WhereExpressionBuilder<ConflictLogTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ConflictLog.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue?> get table => ConflictLog.t;
}

class ConflictLogRepository {
  const ConflictLogRepository._();

  final attachRow = const ConflictLogAttachRowRepository._();

  /// Returns a list of [ConflictLog]s matching the given query parameters.
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
  Future<List<ConflictLog>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ConflictLogTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ConflictLogTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ConflictLogTable>? orderByList,
    _i1.Transaction? transaction,
    ConflictLogInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ConflictLog>(
      where: where?.call(ConflictLog.t),
      orderBy: orderBy?.call(ConflictLog.t),
      orderByList: orderByList?.call(ConflictLog.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ConflictLog] matching the given query parameters.
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
  Future<ConflictLog?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ConflictLogTable>? where,
    int? offset,
    _i1.OrderByBuilder<ConflictLogTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ConflictLogTable>? orderByList,
    _i1.Transaction? transaction,
    ConflictLogInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ConflictLog>(
      where: where?.call(ConflictLog.t),
      orderBy: orderBy?.call(ConflictLog.t),
      orderByList: orderByList?.call(ConflictLog.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ConflictLog] by its [id] or null if no such row exists.
  Future<ConflictLog?> findById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    ConflictLogInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ConflictLog>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ConflictLog]s in the list and returns the inserted rows.
  ///
  /// The returned [ConflictLog]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<ConflictLog>> insert(
    _i1.DatabaseSession session,
    List<ConflictLog> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<ConflictLog>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [ConflictLog] and returns the inserted row.
  ///
  /// The returned [ConflictLog] will have its `id` field set.
  Future<ConflictLog> insertRow(
    _i1.DatabaseSession session,
    ConflictLog row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<ConflictLog>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [ConflictLog]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<ConflictLog>> update(
    _i1.DatabaseSession session,
    List<ConflictLog> rows, {
    _i1.ColumnSelections<ConflictLogTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<ConflictLog>(
      rows,
      columns: columns?.call(ConflictLog.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ConflictLog]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ConflictLog> updateRow(
    _i1.DatabaseSession session,
    ConflictLog row, {
    _i1.ColumnSelections<ConflictLogTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<ConflictLog>(
      row,
      columns: columns?.call(ConflictLog.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ConflictLog] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ConflictLog?> updateById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<ConflictLogUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<ConflictLog>(
      id,
      columnValues: columnValues(ConflictLog.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ConflictLog]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<ConflictLog>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<ConflictLogUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<ConflictLogTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ConflictLogTable>? orderBy,
    _i1.OrderByListBuilder<ConflictLogTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<ConflictLog>(
      columnValues: columnValues(ConflictLog.t.updateTable),
      where: where(ConflictLog.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ConflictLog.t),
      orderByList: orderByList?.call(ConflictLog.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [ConflictLog]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<ConflictLog>> delete(
    _i1.DatabaseSession session,
    List<ConflictLog> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<ConflictLog>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [ConflictLog].
  Future<ConflictLog> deleteRow(
    _i1.DatabaseSession session,
    ConflictLog row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ConflictLog>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<ConflictLog>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ConflictLogTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<ConflictLog>(
      where: where(ConflictLog.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ConflictLogTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<ConflictLog>(
      where: where?.call(ConflictLog.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ConflictLog] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ConflictLogTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ConflictLog>(
      where: where(ConflictLog.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class ConflictLogAttachRowRepository {
  const ConflictLogAttachRowRepository._();

  /// Creates a relation between the given [ConflictLog] and [Device]
  /// by setting the [ConflictLog]'s foreign key `deviceId` to refer to the [Device].
  Future<void> device(
    _i1.DatabaseSession session,
    ConflictLog conflictLog,
    _i4.Device device, {
    _i1.Transaction? transaction,
  }) async {
    if (conflictLog.id == null) {
      throw ArgumentError.notNull('conflictLog.id');
    }
    if (device.id == null) {
      throw ArgumentError.notNull('device.id');
    }

    var $conflictLog = conflictLog.copyWith(deviceId: device.id);
    await session.db.updateRow<ConflictLog>(
      $conflictLog,
      columns: [ConflictLog.t.deviceId],
      transaction: transaction,
    );
  }
}
