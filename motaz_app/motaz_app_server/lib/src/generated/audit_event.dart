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
import 'enums/parent_entity_type.dart' as _i2;
import 'enums/audit_operation.dart' as _i3;
import 'device.dart' as _i4;
import 'package:motaz_app_server/src/generated/protocol.dart' as _i5;

abstract class AuditEvent
    implements _i1.TableRow<_i1.UuidValue?>, _i1.ProtocolSerialization {
  AuditEvent._({
    this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.diffData,
    required this.deviceId,
    this.device,
    required this.createdAt,
  });

  factory AuditEvent({
    _i1.UuidValue? id,
    required _i2.ParentEntityType entityType,
    required _i1.UuidValue entityId,
    required _i3.AuditOperation operation,
    required String diffData,
    required _i1.UuidValue deviceId,
    _i4.Device? device,
    required DateTime createdAt,
  }) = _AuditEventImpl;

  factory AuditEvent.fromJson(Map<String, dynamic> jsonSerialization) {
    return AuditEvent(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      entityType: _i2.ParentEntityType.fromJson(
        (jsonSerialization['entityType'] as String),
      ),
      entityId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['entityId'],
      ),
      operation: _i3.AuditOperation.fromJson(
        (jsonSerialization['operation'] as String),
      ),
      diffData: jsonSerialization['diffData'] as String,
      deviceId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['deviceId'],
      ),
      device: jsonSerialization['device'] == null
          ? null
          : _i5.Protocol().deserialize<_i4.Device>(jsonSerialization['device']),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = AuditEventTable();

  static const db = AuditEventRepository._();

  @override
  _i1.UuidValue? id;

  _i2.ParentEntityType entityType;

  _i1.UuidValue entityId;

  _i3.AuditOperation operation;

  String diffData;

  _i1.UuidValue deviceId;

  _i4.Device? device;

  DateTime createdAt;

  @override
  _i1.Table<_i1.UuidValue?> get table => t;

  /// Returns a shallow copy of this [AuditEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AuditEvent copyWith({
    _i1.UuidValue? id,
    _i2.ParentEntityType? entityType,
    _i1.UuidValue? entityId,
    _i3.AuditOperation? operation,
    String? diffData,
    _i1.UuidValue? deviceId,
    _i4.Device? device,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AuditEvent',
      if (id != null) 'id': id?.toJson(),
      'entityType': entityType.toJson(),
      'entityId': entityId.toJson(),
      'operation': operation.toJson(),
      'diffData': diffData,
      'deviceId': deviceId.toJson(),
      if (device != null) 'device': device?.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AuditEvent',
      if (id != null) 'id': id?.toJson(),
      'entityType': entityType.toJson(),
      'entityId': entityId.toJson(),
      'operation': operation.toJson(),
      'diffData': diffData,
      'deviceId': deviceId.toJson(),
      if (device != null) 'device': device?.toJsonForProtocol(),
      'createdAt': createdAt.toJson(),
    };
  }

  static AuditEventInclude include({_i4.DeviceInclude? device}) {
    return AuditEventInclude._(device: device);
  }

  static AuditEventIncludeList includeList({
    _i1.WhereExpressionBuilder<AuditEventTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AuditEventTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AuditEventTable>? orderByList,
    AuditEventInclude? include,
  }) {
    return AuditEventIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AuditEvent.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(AuditEvent.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AuditEventImpl extends AuditEvent {
  _AuditEventImpl({
    _i1.UuidValue? id,
    required _i2.ParentEntityType entityType,
    required _i1.UuidValue entityId,
    required _i3.AuditOperation operation,
    required String diffData,
    required _i1.UuidValue deviceId,
    _i4.Device? device,
    required DateTime createdAt,
  }) : super._(
         id: id,
         entityType: entityType,
         entityId: entityId,
         operation: operation,
         diffData: diffData,
         deviceId: deviceId,
         device: device,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [AuditEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AuditEvent copyWith({
    Object? id = _Undefined,
    _i2.ParentEntityType? entityType,
    _i1.UuidValue? entityId,
    _i3.AuditOperation? operation,
    String? diffData,
    _i1.UuidValue? deviceId,
    Object? device = _Undefined,
    DateTime? createdAt,
  }) {
    return AuditEvent(
      id: id is _i1.UuidValue? ? id : this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      diffData: diffData ?? this.diffData,
      deviceId: deviceId ?? this.deviceId,
      device: device is _i4.Device? ? device : this.device?.copyWith(),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class AuditEventUpdateTable extends _i1.UpdateTable<AuditEventTable> {
  AuditEventUpdateTable(super.table);

  _i1.ColumnValue<_i2.ParentEntityType, _i2.ParentEntityType> entityType(
    _i2.ParentEntityType value,
  ) => _i1.ColumnValue(
    table.entityType,
    value,
  );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> entityId(_i1.UuidValue value) =>
      _i1.ColumnValue(
        table.entityId,
        value,
      );

  _i1.ColumnValue<_i3.AuditOperation, _i3.AuditOperation> operation(
    _i3.AuditOperation value,
  ) => _i1.ColumnValue(
    table.operation,
    value,
  );

  _i1.ColumnValue<String, String> diffData(String value) => _i1.ColumnValue(
    table.diffData,
    value,
  );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> deviceId(_i1.UuidValue value) =>
      _i1.ColumnValue(
        table.deviceId,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );
}

class AuditEventTable extends _i1.Table<_i1.UuidValue?> {
  AuditEventTable({super.tableRelation}) : super(tableName: 'audit_event') {
    updateTable = AuditEventUpdateTable(this);
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
    diffData = _i1.ColumnString(
      'diffData',
      this,
    );
    deviceId = _i1.ColumnUuid(
      'deviceId',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final AuditEventUpdateTable updateTable;

  late final _i1.ColumnEnum<_i2.ParentEntityType> entityType;

  late final _i1.ColumnUuid entityId;

  late final _i1.ColumnEnum<_i3.AuditOperation> operation;

  late final _i1.ColumnString diffData;

  late final _i1.ColumnUuid deviceId;

  _i4.DeviceTable? _device;

  late final _i1.ColumnDateTime createdAt;

  _i4.DeviceTable get device {
    if (_device != null) return _device!;
    _device = _i1.createRelationTable(
      relationFieldName: 'device',
      field: AuditEvent.t.deviceId,
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
    operation,
    diffData,
    deviceId,
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

class AuditEventInclude extends _i1.IncludeObject {
  AuditEventInclude._({_i4.DeviceInclude? device}) {
    _device = device;
  }

  _i4.DeviceInclude? _device;

  @override
  Map<String, _i1.Include?> get includes => {'device': _device};

  @override
  _i1.Table<_i1.UuidValue?> get table => AuditEvent.t;
}

class AuditEventIncludeList extends _i1.IncludeList {
  AuditEventIncludeList._({
    _i1.WhereExpressionBuilder<AuditEventTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(AuditEvent.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue?> get table => AuditEvent.t;
}

class AuditEventRepository {
  const AuditEventRepository._();

  final attachRow = const AuditEventAttachRowRepository._();

  /// Returns a list of [AuditEvent]s matching the given query parameters.
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
  Future<List<AuditEvent>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<AuditEventTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AuditEventTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AuditEventTable>? orderByList,
    _i1.Transaction? transaction,
    AuditEventInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<AuditEvent>(
      where: where?.call(AuditEvent.t),
      orderBy: orderBy?.call(AuditEvent.t),
      orderByList: orderByList?.call(AuditEvent.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [AuditEvent] matching the given query parameters.
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
  Future<AuditEvent?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<AuditEventTable>? where,
    int? offset,
    _i1.OrderByBuilder<AuditEventTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AuditEventTable>? orderByList,
    _i1.Transaction? transaction,
    AuditEventInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<AuditEvent>(
      where: where?.call(AuditEvent.t),
      orderBy: orderBy?.call(AuditEvent.t),
      orderByList: orderByList?.call(AuditEvent.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [AuditEvent] by its [id] or null if no such row exists.
  Future<AuditEvent?> findById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    AuditEventInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<AuditEvent>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [AuditEvent]s in the list and returns the inserted rows.
  ///
  /// The returned [AuditEvent]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<AuditEvent>> insert(
    _i1.DatabaseSession session,
    List<AuditEvent> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<AuditEvent>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [AuditEvent] and returns the inserted row.
  ///
  /// The returned [AuditEvent] will have its `id` field set.
  Future<AuditEvent> insertRow(
    _i1.DatabaseSession session,
    AuditEvent row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<AuditEvent>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [AuditEvent]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<AuditEvent>> update(
    _i1.DatabaseSession session,
    List<AuditEvent> rows, {
    _i1.ColumnSelections<AuditEventTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<AuditEvent>(
      rows,
      columns: columns?.call(AuditEvent.t),
      transaction: transaction,
    );
  }

  /// Updates a single [AuditEvent]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<AuditEvent> updateRow(
    _i1.DatabaseSession session,
    AuditEvent row, {
    _i1.ColumnSelections<AuditEventTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<AuditEvent>(
      row,
      columns: columns?.call(AuditEvent.t),
      transaction: transaction,
    );
  }

  /// Updates a single [AuditEvent] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<AuditEvent?> updateById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<AuditEventUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<AuditEvent>(
      id,
      columnValues: columnValues(AuditEvent.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [AuditEvent]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<AuditEvent>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<AuditEventUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<AuditEventTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AuditEventTable>? orderBy,
    _i1.OrderByListBuilder<AuditEventTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<AuditEvent>(
      columnValues: columnValues(AuditEvent.t.updateTable),
      where: where(AuditEvent.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AuditEvent.t),
      orderByList: orderByList?.call(AuditEvent.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [AuditEvent]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<AuditEvent>> delete(
    _i1.DatabaseSession session,
    List<AuditEvent> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<AuditEvent>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [AuditEvent].
  Future<AuditEvent> deleteRow(
    _i1.DatabaseSession session,
    AuditEvent row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<AuditEvent>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<AuditEvent>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<AuditEventTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<AuditEvent>(
      where: where(AuditEvent.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<AuditEventTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<AuditEvent>(
      where: where?.call(AuditEvent.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [AuditEvent] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<AuditEventTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<AuditEvent>(
      where: where(AuditEvent.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class AuditEventAttachRowRepository {
  const AuditEventAttachRowRepository._();

  /// Creates a relation between the given [AuditEvent] and [Device]
  /// by setting the [AuditEvent]'s foreign key `deviceId` to refer to the [Device].
  Future<void> device(
    _i1.DatabaseSession session,
    AuditEvent auditEvent,
    _i4.Device device, {
    _i1.Transaction? transaction,
  }) async {
    if (auditEvent.id == null) {
      throw ArgumentError.notNull('auditEvent.id');
    }
    if (device.id == null) {
      throw ArgumentError.notNull('device.id');
    }

    var $auditEvent = auditEvent.copyWith(deviceId: device.id);
    await session.db.updateRow<AuditEvent>(
      $auditEvent,
      columns: [AuditEvent.t.deviceId],
      transaction: transaction,
    );
  }
}
