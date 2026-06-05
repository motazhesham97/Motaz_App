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
import 'enums/sync_outbox_status.dart' as _i2;
import 'enums/parent_entity_type.dart' as _i3;
import 'enums/audit_operation.dart' as _i4;
import 'device.dart' as _i5;
import 'package:motaz_app_server/src/generated/protocol.dart' as _i6;

abstract class SyncOutbox
    implements _i1.TableRow<_i1.UuidValue?>, _i1.ProtocolSerialization {
  SyncOutbox._({
    this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.rowVersion,
    required this.deviceId,
    this.device,
    int? retryCount,
    _i2.SyncOutboxStatus? status,
    required this.createdAt,
  }) : retryCount = retryCount ?? 0,
       status = status ?? _i2.SyncOutboxStatus.PENDING;

  factory SyncOutbox({
    _i1.UuidValue? id,
    required _i3.ParentEntityType entityType,
    required _i1.UuidValue entityId,
    required _i4.AuditOperation operation,
    required String payload,
    required int rowVersion,
    required _i1.UuidValue deviceId,
    _i5.Device? device,
    int? retryCount,
    _i2.SyncOutboxStatus? status,
    required DateTime createdAt,
  }) = _SyncOutboxImpl;

  factory SyncOutbox.fromJson(Map<String, dynamic> jsonSerialization) {
    return SyncOutbox(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      entityType: _i3.ParentEntityType.fromJson(
        (jsonSerialization['entityType'] as String),
      ),
      entityId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['entityId'],
      ),
      operation: _i4.AuditOperation.fromJson(
        (jsonSerialization['operation'] as String),
      ),
      payload: jsonSerialization['payload'] as String,
      rowVersion: jsonSerialization['rowVersion'] as int,
      deviceId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['deviceId'],
      ),
      device: jsonSerialization['device'] == null
          ? null
          : _i6.Protocol().deserialize<_i5.Device>(jsonSerialization['device']),
      retryCount: jsonSerialization['retryCount'] as int?,
      status: jsonSerialization['status'] == null
          ? null
          : _i2.SyncOutboxStatus.fromJson(
              (jsonSerialization['status'] as String),
            ),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = SyncOutboxTable();

  static const db = SyncOutboxRepository._();

  @override
  _i1.UuidValue? id;

  _i3.ParentEntityType entityType;

  _i1.UuidValue entityId;

  _i4.AuditOperation operation;

  String payload;

  int rowVersion;

  _i1.UuidValue deviceId;

  _i5.Device? device;

  int retryCount;

  _i2.SyncOutboxStatus status;

  DateTime createdAt;

  @override
  _i1.Table<_i1.UuidValue?> get table => t;

  /// Returns a shallow copy of this [SyncOutbox]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SyncOutbox copyWith({
    _i1.UuidValue? id,
    _i3.ParentEntityType? entityType,
    _i1.UuidValue? entityId,
    _i4.AuditOperation? operation,
    String? payload,
    int? rowVersion,
    _i1.UuidValue? deviceId,
    _i5.Device? device,
    int? retryCount,
    _i2.SyncOutboxStatus? status,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SyncOutbox',
      if (id != null) 'id': id?.toJson(),
      'entityType': entityType.toJson(),
      'entityId': entityId.toJson(),
      'operation': operation.toJson(),
      'payload': payload,
      'rowVersion': rowVersion,
      'deviceId': deviceId.toJson(),
      if (device != null) 'device': device?.toJson(),
      'retryCount': retryCount,
      'status': status.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SyncOutbox',
      if (id != null) 'id': id?.toJson(),
      'entityType': entityType.toJson(),
      'entityId': entityId.toJson(),
      'operation': operation.toJson(),
      'payload': payload,
      'rowVersion': rowVersion,
      'deviceId': deviceId.toJson(),
      if (device != null) 'device': device?.toJsonForProtocol(),
      'retryCount': retryCount,
      'status': status.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  static SyncOutboxInclude include({_i5.DeviceInclude? device}) {
    return SyncOutboxInclude._(device: device);
  }

  static SyncOutboxIncludeList includeList({
    _i1.WhereExpressionBuilder<SyncOutboxTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SyncOutboxTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SyncOutboxTable>? orderByList,
    SyncOutboxInclude? include,
  }) {
    return SyncOutboxIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SyncOutbox.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(SyncOutbox.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SyncOutboxImpl extends SyncOutbox {
  _SyncOutboxImpl({
    _i1.UuidValue? id,
    required _i3.ParentEntityType entityType,
    required _i1.UuidValue entityId,
    required _i4.AuditOperation operation,
    required String payload,
    required int rowVersion,
    required _i1.UuidValue deviceId,
    _i5.Device? device,
    int? retryCount,
    _i2.SyncOutboxStatus? status,
    required DateTime createdAt,
  }) : super._(
         id: id,
         entityType: entityType,
         entityId: entityId,
         operation: operation,
         payload: payload,
         rowVersion: rowVersion,
         deviceId: deviceId,
         device: device,
         retryCount: retryCount,
         status: status,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [SyncOutbox]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SyncOutbox copyWith({
    Object? id = _Undefined,
    _i3.ParentEntityType? entityType,
    _i1.UuidValue? entityId,
    _i4.AuditOperation? operation,
    String? payload,
    int? rowVersion,
    _i1.UuidValue? deviceId,
    Object? device = _Undefined,
    int? retryCount,
    _i2.SyncOutboxStatus? status,
    DateTime? createdAt,
  }) {
    return SyncOutbox(
      id: id is _i1.UuidValue? ? id : this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      rowVersion: rowVersion ?? this.rowVersion,
      deviceId: deviceId ?? this.deviceId,
      device: device is _i5.Device? ? device : this.device?.copyWith(),
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class SyncOutboxUpdateTable extends _i1.UpdateTable<SyncOutboxTable> {
  SyncOutboxUpdateTable(super.table);

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

  _i1.ColumnValue<_i4.AuditOperation, _i4.AuditOperation> operation(
    _i4.AuditOperation value,
  ) => _i1.ColumnValue(
    table.operation,
    value,
  );

  _i1.ColumnValue<String, String> payload(String value) => _i1.ColumnValue(
    table.payload,
    value,
  );

  _i1.ColumnValue<int, int> rowVersion(int value) => _i1.ColumnValue(
    table.rowVersion,
    value,
  );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> deviceId(_i1.UuidValue value) =>
      _i1.ColumnValue(
        table.deviceId,
        value,
      );

  _i1.ColumnValue<int, int> retryCount(int value) => _i1.ColumnValue(
    table.retryCount,
    value,
  );

  _i1.ColumnValue<_i2.SyncOutboxStatus, _i2.SyncOutboxStatus> status(
    _i2.SyncOutboxStatus value,
  ) => _i1.ColumnValue(
    table.status,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );
}

class SyncOutboxTable extends _i1.Table<_i1.UuidValue?> {
  SyncOutboxTable({super.tableRelation}) : super(tableName: 'sync_outbox') {
    updateTable = SyncOutboxUpdateTable(this);
    entityType = _i1.ColumnEnum(
      'entityType',
      this,
      _i1.EnumSerialization.byName,
    );
    entityId = _i1.ColumnUuid(
      'entityId',
      this,
    );
    operation = _i1.ColumnEnum(
      'operation',
      this,
      _i1.EnumSerialization.byName,
    );
    payload = _i1.ColumnString(
      'payload',
      this,
    );
    rowVersion = _i1.ColumnInt(
      'rowVersion',
      this,
    );
    deviceId = _i1.ColumnUuid(
      'deviceId',
      this,
    );
    retryCount = _i1.ColumnInt(
      'retryCount',
      this,
      hasDefault: true,
    );
    status = _i1.ColumnEnum(
      'status',
      this,
      _i1.EnumSerialization.byName,
      hasDefault: true,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final SyncOutboxUpdateTable updateTable;

  late final _i1.ColumnEnum<_i3.ParentEntityType> entityType;

  late final _i1.ColumnUuid entityId;

  late final _i1.ColumnEnum<_i4.AuditOperation> operation;

  late final _i1.ColumnString payload;

  late final _i1.ColumnInt rowVersion;

  late final _i1.ColumnUuid deviceId;

  _i5.DeviceTable? _device;

  late final _i1.ColumnInt retryCount;

  late final _i1.ColumnEnum<_i2.SyncOutboxStatus> status;

  late final _i1.ColumnDateTime createdAt;

  _i5.DeviceTable get device {
    if (_device != null) return _device!;
    _device = _i1.createRelationTable(
      relationFieldName: 'device',
      field: SyncOutbox.t.deviceId,
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
    entityType,
    entityId,
    operation,
    payload,
    rowVersion,
    deviceId,
    retryCount,
    status,
    createdAt,
  ];

  @override
  _i1.Table? getRelationTable(String relationField) {
    if (relationField == 'device') {
      return device;
    }
    return null;
  }
}

class SyncOutboxInclude extends _i1.IncludeObject {
  SyncOutboxInclude._({_i5.DeviceInclude? device}) {
    _device = device;
  }

  _i5.DeviceInclude? _device;

  @override
  Map<String, _i1.Include?> get includes => {'device': _device};

  @override
  _i1.Table<_i1.UuidValue?> get table => SyncOutbox.t;
}

class SyncOutboxIncludeList extends _i1.IncludeList {
  SyncOutboxIncludeList._({
    _i1.WhereExpressionBuilder<SyncOutboxTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(SyncOutbox.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue?> get table => SyncOutbox.t;
}

class SyncOutboxRepository {
  const SyncOutboxRepository._();

  final attachRow = const SyncOutboxAttachRowRepository._();

  /// Returns a list of [SyncOutbox]s matching the given query parameters.
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
  Future<List<SyncOutbox>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<SyncOutboxTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SyncOutboxTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SyncOutboxTable>? orderByList,
    _i1.Transaction? transaction,
    SyncOutboxInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<SyncOutbox>(
      where: where?.call(SyncOutbox.t),
      orderBy: orderBy?.call(SyncOutbox.t),
      orderByList: orderByList?.call(SyncOutbox.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [SyncOutbox] matching the given query parameters.
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
  Future<SyncOutbox?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<SyncOutboxTable>? where,
    int? offset,
    _i1.OrderByBuilder<SyncOutboxTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SyncOutboxTable>? orderByList,
    _i1.Transaction? transaction,
    SyncOutboxInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<SyncOutbox>(
      where: where?.call(SyncOutbox.t),
      orderBy: orderBy?.call(SyncOutbox.t),
      orderByList: orderByList?.call(SyncOutbox.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [SyncOutbox] by its [id] or null if no such row exists.
  Future<SyncOutbox?> findById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    SyncOutboxInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<SyncOutbox>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [SyncOutbox]s in the list and returns the inserted rows.
  ///
  /// The returned [SyncOutbox]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<SyncOutbox>> insert(
    _i1.DatabaseSession session,
    List<SyncOutbox> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<SyncOutbox>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [SyncOutbox] and returns the inserted row.
  ///
  /// The returned [SyncOutbox] will have its `id` field set.
  Future<SyncOutbox> insertRow(
    _i1.DatabaseSession session,
    SyncOutbox row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<SyncOutbox>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [SyncOutbox]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<SyncOutbox>> update(
    _i1.DatabaseSession session,
    List<SyncOutbox> rows, {
    _i1.ColumnSelections<SyncOutboxTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<SyncOutbox>(
      rows,
      columns: columns?.call(SyncOutbox.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SyncOutbox]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<SyncOutbox> updateRow(
    _i1.DatabaseSession session,
    SyncOutbox row, {
    _i1.ColumnSelections<SyncOutboxTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<SyncOutbox>(
      row,
      columns: columns?.call(SyncOutbox.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SyncOutbox] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<SyncOutbox?> updateById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<SyncOutboxUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<SyncOutbox>(
      id,
      columnValues: columnValues(SyncOutbox.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [SyncOutbox]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<SyncOutbox>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<SyncOutboxUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<SyncOutboxTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SyncOutboxTable>? orderBy,
    _i1.OrderByListBuilder<SyncOutboxTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<SyncOutbox>(
      columnValues: columnValues(SyncOutbox.t.updateTable),
      where: where(SyncOutbox.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SyncOutbox.t),
      orderByList: orderByList?.call(SyncOutbox.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [SyncOutbox]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<SyncOutbox>> delete(
    _i1.DatabaseSession session,
    List<SyncOutbox> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<SyncOutbox>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [SyncOutbox].
  Future<SyncOutbox> deleteRow(
    _i1.DatabaseSession session,
    SyncOutbox row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<SyncOutbox>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<SyncOutbox>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<SyncOutboxTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<SyncOutbox>(
      where: where(SyncOutbox.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<SyncOutboxTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<SyncOutbox>(
      where: where?.call(SyncOutbox.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [SyncOutbox] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<SyncOutboxTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<SyncOutbox>(
      where: where(SyncOutbox.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class SyncOutboxAttachRowRepository {
  const SyncOutboxAttachRowRepository._();

  /// Creates a relation between the given [SyncOutbox] and [Device]
  /// by setting the [SyncOutbox]'s foreign key `deviceId` to refer to the [Device].
  Future<void> device(
    _i1.DatabaseSession session,
    SyncOutbox syncOutbox,
    _i5.Device device, {
    _i1.Transaction? transaction,
  }) async {
    if (syncOutbox.id == null) {
      throw ArgumentError.notNull('syncOutbox.id');
    }
    if (device.id == null) {
      throw ArgumentError.notNull('device.id');
    }

    var $syncOutbox = syncOutbox.copyWith(deviceId: device.id);
    await session.db.updateRow<SyncOutbox>(
      $syncOutbox,
      columns: [SyncOutbox.t.deviceId],
      transaction: transaction,
    );
  }
}
