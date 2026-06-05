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
import 'enums/sync_status.dart' as _i2;
import 'enums/parent_entity_type.dart' as _i3;
import 'device.dart' as _i4;
import 'package:motaz_app_server/src/generated/protocol.dart' as _i5;

abstract class AttachmentMetadata
    implements _i1.TableRow<_i1.UuidValue?>, _i1.ProtocolSerialization {
  AttachmentMetadata._({
    this.id,
    required this.parentEntityType,
    required this.parentEntityId,
    required this.storageReference,
    this.secureUrl,
    required this.fileType,
    this.fileSize,
    required this.createdAt,
    required this.updatedAt,
    required this.deviceId,
    this.device,
    int? rowVersion,
    _i2.SyncStatus? syncStatus,
  }) : rowVersion = rowVersion ?? 1,
       syncStatus = syncStatus ?? _i2.SyncStatus.PENDING;

  factory AttachmentMetadata({
    _i1.UuidValue? id,
    required _i3.ParentEntityType parentEntityType,
    required _i1.UuidValue parentEntityId,
    required String storageReference,
    String? secureUrl,
    required String fileType,
    int? fileSize,
    required DateTime createdAt,
    required DateTime updatedAt,
    required _i1.UuidValue deviceId,
    _i4.Device? device,
    int? rowVersion,
    _i2.SyncStatus? syncStatus,
  }) = _AttachmentMetadataImpl;

  factory AttachmentMetadata.fromJson(Map<String, dynamic> jsonSerialization) {
    return AttachmentMetadata(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      parentEntityType: _i3.ParentEntityType.fromJson(
        (jsonSerialization['parentEntityType'] as String),
      ),
      parentEntityId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['parentEntityId'],
      ),
      storageReference: jsonSerialization['storageReference'] as String,
      secureUrl: jsonSerialization['secureUrl'] as String?,
      fileType: jsonSerialization['fileType'] as String,
      fileSize: jsonSerialization['fileSize'] as int?,
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
          : _i2.SyncStatus.fromJson(
              (jsonSerialization['syncStatus'] as String),
            ),
    );
  }

  static final t = AttachmentMetadataTable();

  static const db = AttachmentMetadataRepository._();

  @override
  _i1.UuidValue? id;

  _i3.ParentEntityType parentEntityType;

  _i1.UuidValue parentEntityId;

  String storageReference;

  String? secureUrl;

  String fileType;

  int? fileSize;

  DateTime createdAt;

  DateTime updatedAt;

  _i1.UuidValue deviceId;

  _i4.Device? device;

  int rowVersion;

  _i2.SyncStatus syncStatus;

  @override
  _i1.Table<_i1.UuidValue?> get table => t;

  /// Returns a shallow copy of this [AttachmentMetadata]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AttachmentMetadata copyWith({
    _i1.UuidValue? id,
    _i3.ParentEntityType? parentEntityType,
    _i1.UuidValue? parentEntityId,
    String? storageReference,
    String? secureUrl,
    String? fileType,
    int? fileSize,
    DateTime? createdAt,
    DateTime? updatedAt,
    _i1.UuidValue? deviceId,
    _i4.Device? device,
    int? rowVersion,
    _i2.SyncStatus? syncStatus,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AttachmentMetadata',
      if (id != null) 'id': id?.toJson(),
      'parentEntityType': parentEntityType.toJson(),
      'parentEntityId': parentEntityId.toJson(),
      'storageReference': storageReference,
      if (secureUrl != null) 'secureUrl': secureUrl,
      'fileType': fileType,
      if (fileSize != null) 'fileSize': fileSize,
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
      '__className__': 'AttachmentMetadata',
      if (id != null) 'id': id?.toJson(),
      'parentEntityType': parentEntityType.toJson(),
      'parentEntityId': parentEntityId.toJson(),
      'storageReference': storageReference,
      if (secureUrl != null) 'secureUrl': secureUrl,
      'fileType': fileType,
      if (fileSize != null) 'fileSize': fileSize,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      'deviceId': deviceId.toJson(),
      if (device != null) 'device': device?.toJsonForProtocol(),
      'rowVersion': rowVersion,
      'syncStatus': syncStatus.toJson(),
    };
  }

  static AttachmentMetadataInclude include({_i4.DeviceInclude? device}) {
    return AttachmentMetadataInclude._(device: device);
  }

  static AttachmentMetadataIncludeList includeList({
    _i1.WhereExpressionBuilder<AttachmentMetadataTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AttachmentMetadataTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AttachmentMetadataTable>? orderByList,
    AttachmentMetadataInclude? include,
  }) {
    return AttachmentMetadataIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AttachmentMetadata.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(AttachmentMetadata.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AttachmentMetadataImpl extends AttachmentMetadata {
  _AttachmentMetadataImpl({
    _i1.UuidValue? id,
    required _i3.ParentEntityType parentEntityType,
    required _i1.UuidValue parentEntityId,
    required String storageReference,
    String? secureUrl,
    required String fileType,
    int? fileSize,
    required DateTime createdAt,
    required DateTime updatedAt,
    required _i1.UuidValue deviceId,
    _i4.Device? device,
    int? rowVersion,
    _i2.SyncStatus? syncStatus,
  }) : super._(
         id: id,
         parentEntityType: parentEntityType,
         parentEntityId: parentEntityId,
         storageReference: storageReference,
         secureUrl: secureUrl,
         fileType: fileType,
         fileSize: fileSize,
         createdAt: createdAt,
         updatedAt: updatedAt,
         deviceId: deviceId,
         device: device,
         rowVersion: rowVersion,
         syncStatus: syncStatus,
       );

  /// Returns a shallow copy of this [AttachmentMetadata]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AttachmentMetadata copyWith({
    Object? id = _Undefined,
    _i3.ParentEntityType? parentEntityType,
    _i1.UuidValue? parentEntityId,
    String? storageReference,
    Object? secureUrl = _Undefined,
    String? fileType,
    Object? fileSize = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
    _i1.UuidValue? deviceId,
    Object? device = _Undefined,
    int? rowVersion,
    _i2.SyncStatus? syncStatus,
  }) {
    return AttachmentMetadata(
      id: id is _i1.UuidValue? ? id : this.id,
      parentEntityType: parentEntityType ?? this.parentEntityType,
      parentEntityId: parentEntityId ?? this.parentEntityId,
      storageReference: storageReference ?? this.storageReference,
      secureUrl: secureUrl is String? ? secureUrl : this.secureUrl,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize is int? ? fileSize : this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      device: device is _i4.Device? ? device : this.device?.copyWith(),
      rowVersion: rowVersion ?? this.rowVersion,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}

class AttachmentMetadataUpdateTable
    extends _i1.UpdateTable<AttachmentMetadataTable> {
  AttachmentMetadataUpdateTable(super.table);

  _i1.ColumnValue<_i3.ParentEntityType, _i3.ParentEntityType> parentEntityType(
    _i3.ParentEntityType value,
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

  _i1.ColumnValue<String, String> storageReference(String value) =>
      _i1.ColumnValue(
        table.storageReference,
        value,
      );

  _i1.ColumnValue<String, String> secureUrl(String? value) => _i1.ColumnValue(
    table.secureUrl,
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

  _i1.ColumnValue<_i2.SyncStatus, _i2.SyncStatus> syncStatus(
    _i2.SyncStatus value,
  ) => _i1.ColumnValue(
    table.syncStatus,
    value,
  );
}

class AttachmentMetadataTable extends _i1.Table<_i1.UuidValue?> {
  AttachmentMetadataTable({super.tableRelation})
    : super(tableName: 'attachment_metadata') {
    updateTable = AttachmentMetadataUpdateTable(this);
    parentEntityType = _i1.ColumnEnum(
      'parentEntityType',
      this,
      _i1.EnumSerialization.byName,
    );
    parentEntityId = _i1.ColumnUuid(
      'parentEntityId',
      this,
    );
    storageReference = _i1.ColumnString(
      'storageReference',
      this,
    );
    secureUrl = _i1.ColumnString(
      'secureUrl',
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

  late final AttachmentMetadataUpdateTable updateTable;

  late final _i1.ColumnEnum<_i3.ParentEntityType> parentEntityType;

  late final _i1.ColumnUuid parentEntityId;

  late final _i1.ColumnString storageReference;

  late final _i1.ColumnString secureUrl;

  late final _i1.ColumnString fileType;

  late final _i1.ColumnInt fileSize;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  late final _i1.ColumnUuid deviceId;

  _i4.DeviceTable? _device;

  late final _i1.ColumnInt rowVersion;

  late final _i1.ColumnEnum<_i2.SyncStatus> syncStatus;

  _i4.DeviceTable get device {
    if (_device != null) return _device!;
    _device = _i1.createRelationTable(
      relationFieldName: 'device',
      field: AttachmentMetadata.t.deviceId,
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
    parentEntityType,
    parentEntityId,
    storageReference,
    secureUrl,
    fileType,
    fileSize,
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

class AttachmentMetadataInclude extends _i1.IncludeObject {
  AttachmentMetadataInclude._({_i4.DeviceInclude? device}) {
    _device = device;
  }

  _i4.DeviceInclude? _device;

  @override
  Map<String, _i1.Include?> get includes => {'device': _device};

  @override
  _i1.Table<_i1.UuidValue?> get table => AttachmentMetadata.t;
}

class AttachmentMetadataIncludeList extends _i1.IncludeList {
  AttachmentMetadataIncludeList._({
    _i1.WhereExpressionBuilder<AttachmentMetadataTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(AttachmentMetadata.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue?> get table => AttachmentMetadata.t;
}

class AttachmentMetadataRepository {
  const AttachmentMetadataRepository._();

  final attachRow = const AttachmentMetadataAttachRowRepository._();

  /// Returns a list of [AttachmentMetadata]s matching the given query parameters.
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
  Future<List<AttachmentMetadata>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<AttachmentMetadataTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AttachmentMetadataTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AttachmentMetadataTable>? orderByList,
    _i1.Transaction? transaction,
    AttachmentMetadataInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<AttachmentMetadata>(
      where: where?.call(AttachmentMetadata.t),
      orderBy: orderBy?.call(AttachmentMetadata.t),
      orderByList: orderByList?.call(AttachmentMetadata.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [AttachmentMetadata] matching the given query parameters.
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
  Future<AttachmentMetadata?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<AttachmentMetadataTable>? where,
    int? offset,
    _i1.OrderByBuilder<AttachmentMetadataTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AttachmentMetadataTable>? orderByList,
    _i1.Transaction? transaction,
    AttachmentMetadataInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<AttachmentMetadata>(
      where: where?.call(AttachmentMetadata.t),
      orderBy: orderBy?.call(AttachmentMetadata.t),
      orderByList: orderByList?.call(AttachmentMetadata.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [AttachmentMetadata] by its [id] or null if no such row exists.
  Future<AttachmentMetadata?> findById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    AttachmentMetadataInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<AttachmentMetadata>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [AttachmentMetadata]s in the list and returns the inserted rows.
  ///
  /// The returned [AttachmentMetadata]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<AttachmentMetadata>> insert(
    _i1.DatabaseSession session,
    List<AttachmentMetadata> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<AttachmentMetadata>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [AttachmentMetadata] and returns the inserted row.
  ///
  /// The returned [AttachmentMetadata] will have its `id` field set.
  Future<AttachmentMetadata> insertRow(
    _i1.DatabaseSession session,
    AttachmentMetadata row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<AttachmentMetadata>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [AttachmentMetadata]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<AttachmentMetadata>> update(
    _i1.DatabaseSession session,
    List<AttachmentMetadata> rows, {
    _i1.ColumnSelections<AttachmentMetadataTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<AttachmentMetadata>(
      rows,
      columns: columns?.call(AttachmentMetadata.t),
      transaction: transaction,
    );
  }

  /// Updates a single [AttachmentMetadata]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<AttachmentMetadata> updateRow(
    _i1.DatabaseSession session,
    AttachmentMetadata row, {
    _i1.ColumnSelections<AttachmentMetadataTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<AttachmentMetadata>(
      row,
      columns: columns?.call(AttachmentMetadata.t),
      transaction: transaction,
    );
  }

  /// Updates a single [AttachmentMetadata] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<AttachmentMetadata?> updateById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<AttachmentMetadataUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<AttachmentMetadata>(
      id,
      columnValues: columnValues(AttachmentMetadata.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [AttachmentMetadata]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<AttachmentMetadata>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<AttachmentMetadataUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<AttachmentMetadataTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AttachmentMetadataTable>? orderBy,
    _i1.OrderByListBuilder<AttachmentMetadataTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<AttachmentMetadata>(
      columnValues: columnValues(AttachmentMetadata.t.updateTable),
      where: where(AttachmentMetadata.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AttachmentMetadata.t),
      orderByList: orderByList?.call(AttachmentMetadata.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [AttachmentMetadata]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<AttachmentMetadata>> delete(
    _i1.DatabaseSession session,
    List<AttachmentMetadata> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<AttachmentMetadata>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [AttachmentMetadata].
  Future<AttachmentMetadata> deleteRow(
    _i1.DatabaseSession session,
    AttachmentMetadata row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<AttachmentMetadata>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<AttachmentMetadata>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<AttachmentMetadataTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<AttachmentMetadata>(
      where: where(AttachmentMetadata.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<AttachmentMetadataTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<AttachmentMetadata>(
      where: where?.call(AttachmentMetadata.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [AttachmentMetadata] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<AttachmentMetadataTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<AttachmentMetadata>(
      where: where(AttachmentMetadata.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class AttachmentMetadataAttachRowRepository {
  const AttachmentMetadataAttachRowRepository._();

  /// Creates a relation between the given [AttachmentMetadata] and [Device]
  /// by setting the [AttachmentMetadata]'s foreign key `deviceId` to refer to the [Device].
  Future<void> device(
    _i1.DatabaseSession session,
    AttachmentMetadata attachmentMetadata,
    _i4.Device device, {
    _i1.Transaction? transaction,
  }) async {
    if (attachmentMetadata.id == null) {
      throw ArgumentError.notNull('attachmentMetadata.id');
    }
    if (device.id == null) {
      throw ArgumentError.notNull('device.id');
    }

    var $attachmentMetadata = attachmentMetadata.copyWith(deviceId: device.id);
    await session.db.updateRow<AttachmentMetadata>(
      $attachmentMetadata,
      columns: [AttachmentMetadata.t.deviceId],
      transaction: transaction,
    );
  }
}
