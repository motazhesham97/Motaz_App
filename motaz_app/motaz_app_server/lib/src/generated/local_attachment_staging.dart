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

abstract class LocalAttachmentStaging
    implements _i1.TableRow<_i1.UuidValue?>, _i1.ProtocolSerialization {
  LocalAttachmentStaging._({
    this.id,
    required this.parentEntityType,
    required this.parentEntityId,
    required this.localFilePath,
    required this.fileType,
    this.fileSize,
    String? uploadStatus,
    required this.createdAt,
    required this.updatedAt,
  }) : uploadStatus = uploadStatus ?? 'PENDING';

  factory LocalAttachmentStaging({
    _i1.UuidValue? id,
    required _i2.ParentEntityType parentEntityType,
    required _i1.UuidValue parentEntityId,
    required String localFilePath,
    required String fileType,
    int? fileSize,
    String? uploadStatus,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _LocalAttachmentStagingImpl;

  factory LocalAttachmentStaging.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return LocalAttachmentStaging(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      parentEntityType: _i2.ParentEntityType.fromJson(
        (jsonSerialization['parentEntityType'] as String),
      ),
      parentEntityId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['parentEntityId'],
      ),
      localFilePath: jsonSerialization['localFilePath'] as String,
      fileType: jsonSerialization['fileType'] as String,
      fileSize: jsonSerialization['fileSize'] as int?,
      uploadStatus: jsonSerialization['uploadStatus'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = LocalAttachmentStagingTable();

  static const db = LocalAttachmentStagingRepository._();

  @override
  _i1.UuidValue? id;

  _i2.ParentEntityType parentEntityType;

  _i1.UuidValue parentEntityId;

  String localFilePath;

  String fileType;

  int? fileSize;

  String uploadStatus;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _i1.Table<_i1.UuidValue?> get table => t;

  /// Returns a shallow copy of this [LocalAttachmentStaging]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  LocalAttachmentStaging copyWith({
    _i1.UuidValue? id,
    _i2.ParentEntityType? parentEntityType,
    _i1.UuidValue? parentEntityId,
    String? localFilePath,
    String? fileType,
    int? fileSize,
    String? uploadStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LocalAttachmentStaging',
      if (id != null) 'id': id?.toJson(),
      'parentEntityType': parentEntityType.toJson(),
      'parentEntityId': parentEntityId.toJson(),
      'localFilePath': localFilePath,
      'fileType': fileType,
      if (fileSize != null) 'fileSize': fileSize,
      'uploadStatus': uploadStatus,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LocalAttachmentStaging',
      if (id != null) 'id': id?.toJson(),
      'parentEntityType': parentEntityType.toJson(),
      'parentEntityId': parentEntityId.toJson(),
      'localFilePath': localFilePath,
      'fileType': fileType,
      if (fileSize != null) 'fileSize': fileSize,
      'uploadStatus': uploadStatus,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  static LocalAttachmentStagingInclude include() {
    return LocalAttachmentStagingInclude._();
  }

  static LocalAttachmentStagingIncludeList includeList({
    _i1.WhereExpressionBuilder<LocalAttachmentStagingTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<LocalAttachmentStagingTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<LocalAttachmentStagingTable>? orderByList,
    LocalAttachmentStagingInclude? include,
  }) {
    return LocalAttachmentStagingIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(LocalAttachmentStaging.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(LocalAttachmentStaging.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LocalAttachmentStagingImpl extends LocalAttachmentStaging {
  _LocalAttachmentStagingImpl({
    _i1.UuidValue? id,
    required _i2.ParentEntityType parentEntityType,
    required _i1.UuidValue parentEntityId,
    required String localFilePath,
    required String fileType,
    int? fileSize,
    String? uploadStatus,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         parentEntityType: parentEntityType,
         parentEntityId: parentEntityId,
         localFilePath: localFilePath,
         fileType: fileType,
         fileSize: fileSize,
         uploadStatus: uploadStatus,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [LocalAttachmentStaging]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  LocalAttachmentStaging copyWith({
    Object? id = _Undefined,
    _i2.ParentEntityType? parentEntityType,
    _i1.UuidValue? parentEntityId,
    String? localFilePath,
    String? fileType,
    Object? fileSize = _Undefined,
    String? uploadStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LocalAttachmentStaging(
      id: id is _i1.UuidValue? ? id : this.id,
      parentEntityType: parentEntityType ?? this.parentEntityType,
      parentEntityId: parentEntityId ?? this.parentEntityId,
      localFilePath: localFilePath ?? this.localFilePath,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize is int? ? fileSize : this.fileSize,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class LocalAttachmentStagingUpdateTable
    extends _i1.UpdateTable<LocalAttachmentStagingTable> {
  LocalAttachmentStagingUpdateTable(super.table);

  _i1.ColumnValue<_i2.ParentEntityType, _i2.ParentEntityType> parentEntityType(
    _i2.ParentEntityType value,
  ) => _i1.ColumnValue(
    table.parentEntityType,
    value,
  );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> parentEntityId(
    _i1.UuidValue value,
  ) => _i1.ColumnValue(
    table.parentEntityId,
    value,
  );

  _i1.ColumnValue<String, String> localFilePath(String value) =>
      _i1.ColumnValue(
        table.localFilePath,
        value,
      );

  _i1.ColumnValue<String, String> fileType(String value) => _i1.ColumnValue(
    table.fileType,
    value,
  );

  _i1.ColumnValue<int, int> fileSize(int? value) => _i1.ColumnValue(
    table.fileSize,
    value,
  );

  _i1.ColumnValue<String, String> uploadStatus(String value) => _i1.ColumnValue(
    table.uploadStatus,
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

class LocalAttachmentStagingTable extends _i1.Table<_i1.UuidValue?> {
  LocalAttachmentStagingTable({super.tableRelation})
    : super(tableName: 'local_attachment_staging') {
    updateTable = LocalAttachmentStagingUpdateTable(this);
    parentEntityType = _i1.ColumnEnum(
      'parentEntityType',
      this,
      _i1.EnumSerialization.byName,
    );
    parentEntityId = _i1.ColumnUuid(
      'parentEntityId',
      this,
    );
    localFilePath = _i1.ColumnString(
      'localFilePath',
      this,
    );
    fileType = _i1.ColumnString(
      'fileType',
      this,
    );
    fileSize = _i1.ColumnInt(
      'fileSize',
      this,
    );
    uploadStatus = _i1.ColumnString(
      'uploadStatus',
      this,
      hasDefault: true,
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

  late final LocalAttachmentStagingUpdateTable updateTable;

  late final _i1.ColumnEnum<_i2.ParentEntityType> parentEntityType;

  late final _i1.ColumnUuid parentEntityId;

  late final _i1.ColumnString localFilePath;

  late final _i1.ColumnString fileType;

  late final _i1.ColumnInt fileSize;

  late final _i1.ColumnString uploadStatus;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    parentEntityType,
    parentEntityId,
    localFilePath,
    fileType,
    fileSize,
    uploadStatus,
    createdAt,
    updatedAt,
  ];
}

class LocalAttachmentStagingInclude extends _i1.IncludeObject {
  LocalAttachmentStagingInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<_i1.UuidValue?> get table => LocalAttachmentStaging.t;
}

class LocalAttachmentStagingIncludeList extends _i1.IncludeList {
  LocalAttachmentStagingIncludeList._({
    _i1.WhereExpressionBuilder<LocalAttachmentStagingTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(LocalAttachmentStaging.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue?> get table => LocalAttachmentStaging.t;
}

class LocalAttachmentStagingRepository {
  const LocalAttachmentStagingRepository._();

  /// Returns a list of [LocalAttachmentStaging]s matching the given query parameters.
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
  Future<List<LocalAttachmentStaging>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<LocalAttachmentStagingTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<LocalAttachmentStagingTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<LocalAttachmentStagingTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<LocalAttachmentStaging>(
      where: where?.call(LocalAttachmentStaging.t),
      orderBy: orderBy?.call(LocalAttachmentStaging.t),
      orderByList: orderByList?.call(LocalAttachmentStaging.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [LocalAttachmentStaging] matching the given query parameters.
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
  Future<LocalAttachmentStaging?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<LocalAttachmentStagingTable>? where,
    int? offset,
    _i1.OrderByBuilder<LocalAttachmentStagingTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<LocalAttachmentStagingTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<LocalAttachmentStaging>(
      where: where?.call(LocalAttachmentStaging.t),
      orderBy: orderBy?.call(LocalAttachmentStaging.t),
      orderByList: orderByList?.call(LocalAttachmentStaging.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [LocalAttachmentStaging] by its [id] or null if no such row exists.
  Future<LocalAttachmentStaging?> findById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<LocalAttachmentStaging>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [LocalAttachmentStaging]s in the list and returns the inserted rows.
  ///
  /// The returned [LocalAttachmentStaging]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<LocalAttachmentStaging>> insert(
    _i1.DatabaseSession session,
    List<LocalAttachmentStaging> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<LocalAttachmentStaging>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [LocalAttachmentStaging] and returns the inserted row.
  ///
  /// The returned [LocalAttachmentStaging] will have its `id` field set.
  Future<LocalAttachmentStaging> insertRow(
    _i1.DatabaseSession session,
    LocalAttachmentStaging row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<LocalAttachmentStaging>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [LocalAttachmentStaging]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<LocalAttachmentStaging>> update(
    _i1.DatabaseSession session,
    List<LocalAttachmentStaging> rows, {
    _i1.ColumnSelections<LocalAttachmentStagingTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<LocalAttachmentStaging>(
      rows,
      columns: columns?.call(LocalAttachmentStaging.t),
      transaction: transaction,
    );
  }

  /// Updates a single [LocalAttachmentStaging]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<LocalAttachmentStaging> updateRow(
    _i1.DatabaseSession session,
    LocalAttachmentStaging row, {
    _i1.ColumnSelections<LocalAttachmentStagingTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<LocalAttachmentStaging>(
      row,
      columns: columns?.call(LocalAttachmentStaging.t),
      transaction: transaction,
    );
  }

  /// Updates a single [LocalAttachmentStaging] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<LocalAttachmentStaging?> updateById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<LocalAttachmentStagingUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<LocalAttachmentStaging>(
      id,
      columnValues: columnValues(LocalAttachmentStaging.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [LocalAttachmentStaging]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<LocalAttachmentStaging>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<LocalAttachmentStagingUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<LocalAttachmentStagingTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<LocalAttachmentStagingTable>? orderBy,
    _i1.OrderByListBuilder<LocalAttachmentStagingTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<LocalAttachmentStaging>(
      columnValues: columnValues(LocalAttachmentStaging.t.updateTable),
      where: where(LocalAttachmentStaging.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(LocalAttachmentStaging.t),
      orderByList: orderByList?.call(LocalAttachmentStaging.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [LocalAttachmentStaging]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<LocalAttachmentStaging>> delete(
    _i1.DatabaseSession session,
    List<LocalAttachmentStaging> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<LocalAttachmentStaging>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [LocalAttachmentStaging].
  Future<LocalAttachmentStaging> deleteRow(
    _i1.DatabaseSession session,
    LocalAttachmentStaging row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<LocalAttachmentStaging>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<LocalAttachmentStaging>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<LocalAttachmentStagingTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<LocalAttachmentStaging>(
      where: where(LocalAttachmentStaging.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<LocalAttachmentStagingTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<LocalAttachmentStaging>(
      where: where?.call(LocalAttachmentStaging.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [LocalAttachmentStaging] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<LocalAttachmentStagingTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<LocalAttachmentStaging>(
      where: where(LocalAttachmentStaging.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
