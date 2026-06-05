/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;
import 'enums/parent_entity_type.dart' as _i2;

abstract class SyncCursor
    implements _i1.TableRow<_i1.UuidValue?>, _i1.ProtocolSerialization {
  SyncCursor._({
    this.id,
    required this.entityType,
    this.lastPulledAt,
    int? lastRowVersion,
    required this.updatedAt,
  }) : lastRowVersion = lastRowVersion ?? 0;

  factory SyncCursor({
    _i1.UuidValue? id,
    required _i2.ParentEntityType entityType,
    DateTime? lastPulledAt,
    int? lastRowVersion,
    required DateTime updatedAt,
  }) = _SyncCursorImpl;

  factory SyncCursor.fromJson(Map<String, dynamic> jsonSerialization) {
    return SyncCursor(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      entityType: _i2.ParentEntityType.fromJson(
        (jsonSerialization['entityType'] as String),
      ),
      lastPulledAt: jsonSerialization['lastPulledAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastPulledAt'],
            ),
      lastRowVersion: jsonSerialization['lastRowVersion'] as int?,
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = SyncCursorTable();

  static const db = SyncCursorRepository._();

  @override
  _i1.UuidValue? id;

  _i2.ParentEntityType entityType;

  DateTime? lastPulledAt;

  int lastRowVersion;

  DateTime updatedAt;

  @override
  _i1.Table<_i1.UuidValue?> get table => t;

  /// Returns a shallow copy of this [SyncCursor]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SyncCursor copyWith({
    _i1.UuidValue? id,
    _i2.ParentEntityType? entityType,
    DateTime? lastPulledAt,
    int? lastRowVersion,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SyncCursor',
      if (id != null) 'id': id?.toJson(),
      'entityType': entityType.toJson(),
      if (lastPulledAt != null) 'lastPulledAt': lastPulledAt?.toJson(),
      'lastRowVersion': lastRowVersion,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SyncCursor',
      if (id != null) 'id': id?.toJson(),
      'entityType': entityType.toJson(),
      if (lastPulledAt != null) 'lastPulledAt': lastPulledAt?.toJson(),
      'lastRowVersion': lastRowVersion,
      'updatedAt': updatedAt.toJson(),
    };
  }

  static SyncCursorInclude include() {
    return SyncCursorInclude._();
  }

  static SyncCursorIncludeList includeList({
    _i1.WhereExpressionBuilder<SyncCursorTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SyncCursorTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SyncCursorTable>? orderByList,
    SyncCursorInclude? include,
  }) {
    return SyncCursorIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SyncCursor.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(SyncCursor.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SyncCursorImpl extends SyncCursor {
  _SyncCursorImpl({
    _i1.UuidValue? id,
    required _i2.ParentEntityType entityType,
    DateTime? lastPulledAt,
    int? lastRowVersion,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         entityType: entityType,
         lastPulledAt: lastPulledAt,
         lastRowVersion: lastRowVersion,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [SyncCursor]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SyncCursor copyWith({
    Object? id = _Undefined,
    _i2.ParentEntityType? entityType,
    Object? lastPulledAt = _Undefined,
    int? lastRowVersion,
    DateTime? updatedAt,
  }) {
    return SyncCursor(
      id: id is _i1.UuidValue? ? id : this.id,
      entityType: entityType ?? this.entityType,
      lastPulledAt: lastPulledAt is DateTime?
          ? lastPulledAt
          : this.lastPulledAt,
      lastRowVersion: lastRowVersion ?? this.lastRowVersion,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class SyncCursorUpdateTable extends _i1.UpdateTable<SyncCursorTable> {
  SyncCursorUpdateTable(super.table);

  _i1.ColumnValue<_i2.ParentEntityType, _i2.ParentEntityType> entityType(
    _i2.ParentEntityType value,
  ) => _i1.ColumnValue(
    table.entityType,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> lastPulledAt(DateTime? value) =>
      _i1.ColumnValue(
        table.lastPulledAt,
        value,
      );

  _i1.ColumnValue<int, int> lastRowVersion(int value) => _i1.ColumnValue(
    table.lastRowVersion,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _i1.ColumnValue(
        table.updatedAt,
        value,
      );
}

class SyncCursorTable extends _i1.Table<_i1.UuidValue?> {
  SyncCursorTable({super.tableRelation}) : super(tableName: 'sync_cursor') {
    updateTable = SyncCursorUpdateTable(this);
    entityType = _i1.ColumnEnum(
      'entityType',
      this,
      _i1.EnumSerialization.byName,
    );
    lastPulledAt = _i1.ColumnDateTime(
      'lastPulledAt',
      this,
    );
    lastRowVersion = _i1.ColumnInt(
      'lastRowVersion',
      this,
      hasDefault: true,
    );
    updatedAt = _i1.ColumnDateTime(
      'updatedAt',
      this,
    );
  }

  late final SyncCursorUpdateTable updateTable;

  late final _i1.ColumnEnum<_i2.ParentEntityType> entityType;

  late final _i1.ColumnDateTime lastPulledAt;

  late final _i1.ColumnInt lastRowVersion;

  late final _i1.ColumnDateTime updatedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    entityType,
    lastPulledAt,
    lastRowVersion,
    updatedAt,
  ];
}

class SyncCursorInclude extends _i1.IncludeObject {
  SyncCursorInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<_i1.UuidValue?> get table => SyncCursor.t;
}

class SyncCursorIncludeList extends _i1.IncludeList {
  SyncCursorIncludeList._({
    _i1.WhereExpressionBuilder<SyncCursorTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(SyncCursor.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue?> get table => SyncCursor.t;
}

class SyncCursorRepository {
  const SyncCursorRepository._();

  /// Returns a list of [SyncCursor]s matching the given query parameters.
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
  Future<List<SyncCursor>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<SyncCursorTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SyncCursorTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SyncCursorTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<SyncCursor>(
      where: where?.call(SyncCursor.t),
      orderBy: orderBy?.call(SyncCursor.t),
      orderByList: orderByList?.call(SyncCursor.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [SyncCursor] matching the given query parameters.
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
  Future<SyncCursor?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<SyncCursorTable>? where,
    int? offset,
    _i1.OrderByBuilder<SyncCursorTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SyncCursorTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<SyncCursor>(
      where: where?.call(SyncCursor.t),
      orderBy: orderBy?.call(SyncCursor.t),
      orderByList: orderByList?.call(SyncCursor.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [SyncCursor] by its [id] or null if no such row exists.
  Future<SyncCursor?> findById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<SyncCursor>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [SyncCursor]s in the list and returns the inserted rows.
  ///
  /// The returned [SyncCursor]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<SyncCursor>> insert(
    _i1.DatabaseSession session,
    List<SyncCursor> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<SyncCursor>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [SyncCursor] and returns the inserted row.
  ///
  /// The returned [SyncCursor] will have its `id` field set.
  Future<SyncCursor> insertRow(
    _i1.DatabaseSession session,
    SyncCursor row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<SyncCursor>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [SyncCursor]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<SyncCursor>> update(
    _i1.DatabaseSession session,
    List<SyncCursor> rows, {
    _i1.ColumnSelections<SyncCursorTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<SyncCursor>(
      rows,
      columns: columns?.call(SyncCursor.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SyncCursor]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<SyncCursor> updateRow(
    _i1.DatabaseSession session,
    SyncCursor row, {
    _i1.ColumnSelections<SyncCursorTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<SyncCursor>(
      row,
      columns: columns?.call(SyncCursor.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SyncCursor] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<SyncCursor?> updateById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<SyncCursorUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<SyncCursor>(
      id,
      columnValues: columnValues(SyncCursor.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [SyncCursor]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<SyncCursor>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<SyncCursorUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<SyncCursorTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SyncCursorTable>? orderBy,
    _i1.OrderByListBuilder<SyncCursorTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<SyncCursor>(
      columnValues: columnValues(SyncCursor.t.updateTable),
      where: where(SyncCursor.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SyncCursor.t),
      orderByList: orderByList?.call(SyncCursor.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [SyncCursor]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<SyncCursor>> delete(
    _i1.DatabaseSession session,
    List<SyncCursor> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<SyncCursor>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [SyncCursor].
  Future<SyncCursor> deleteRow(
    _i1.DatabaseSession session,
    SyncCursor row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<SyncCursor>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<SyncCursor>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<SyncCursorTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<SyncCursor>(
      where: where(SyncCursor.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<SyncCursorTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<SyncCursor>(
      where: where?.call(SyncCursor.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [SyncCursor] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<SyncCursorTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<SyncCursor>(
      where: where(SyncCursor.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
