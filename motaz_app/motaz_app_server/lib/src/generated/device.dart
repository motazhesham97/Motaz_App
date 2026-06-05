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
import 'enums/device_platform.dart' as _i2;
import 'sync_outbox.dart' as _i3;
import 'package:motaz_app_server/src/generated/protocol.dart' as _i4;

abstract class Device
    implements _i1.TableRow<_i1.UuidValue?>, _i1.ProtocolSerialization {
  Device._({
    this.id,
    required this.deviceName,
    required this.platform,
    required this.deviceCode,
    int? nextInvoiceSequence,
    int? nextReceiptSequence,
    int? nextReturnSequence,
    int? nextSampleSequence,
    required this.createdAt,
    required this.lastActiveAt,
    this.syncOutboxItems,
  }) : nextInvoiceSequence = nextInvoiceSequence ?? 1,
       nextReceiptSequence = nextReceiptSequence ?? 1,
       nextReturnSequence = nextReturnSequence ?? 1,
       nextSampleSequence = nextSampleSequence ?? 1;

  factory Device({
    _i1.UuidValue? id,
    required String deviceName,
    required _i2.DevicePlatform platform,
    required String deviceCode,
    int? nextInvoiceSequence,
    int? nextReceiptSequence,
    int? nextReturnSequence,
    int? nextSampleSequence,
    required DateTime createdAt,
    required DateTime lastActiveAt,
    List<_i3.SyncOutbox>? syncOutboxItems,
  }) = _DeviceImpl;

  factory Device.fromJson(Map<String, dynamic> jsonSerialization) {
    return Device(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      deviceName: jsonSerialization['deviceName'] as String,
      platform: _i2.DevicePlatform.fromJson(
        (jsonSerialization['platform'] as String),
      ),
      deviceCode: jsonSerialization['deviceCode'] as String,
      nextInvoiceSequence: jsonSerialization['nextInvoiceSequence'] as int?,
      nextReceiptSequence: jsonSerialization['nextReceiptSequence'] as int?,
      nextReturnSequence: jsonSerialization['nextReturnSequence'] as int?,
      nextSampleSequence: jsonSerialization['nextSampleSequence'] as int?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      lastActiveAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastActiveAt'],
      ),
      syncOutboxItems: jsonSerialization['syncOutboxItems'] == null
          ? null
          : _i4.Protocol().deserialize<List<_i3.SyncOutbox>>(
              jsonSerialization['syncOutboxItems'],
            ),
    );
  }

  static final t = DeviceTable();

  static const db = DeviceRepository._();

  @override
  _i1.UuidValue? id;

  String deviceName;

  _i2.DevicePlatform platform;

  String deviceCode;

  int nextInvoiceSequence;

  int nextReceiptSequence;

  int nextReturnSequence;

  int nextSampleSequence;

  DateTime createdAt;

  DateTime lastActiveAt;

  List<_i3.SyncOutbox>? syncOutboxItems;

  @override
  _i1.Table<_i1.UuidValue?> get table => t;

  /// Returns a shallow copy of this [Device]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Device copyWith({
    _i1.UuidValue? id,
    String? deviceName,
    _i2.DevicePlatform? platform,
    String? deviceCode,
    int? nextInvoiceSequence,
    int? nextReceiptSequence,
    int? nextReturnSequence,
    int? nextSampleSequence,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    List<_i3.SyncOutbox>? syncOutboxItems,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Device',
      if (id != null) 'id': id?.toJson(),
      'deviceName': deviceName,
      'platform': platform.toJson(),
      'deviceCode': deviceCode,
      'nextInvoiceSequence': nextInvoiceSequence,
      'nextReceiptSequence': nextReceiptSequence,
      'nextReturnSequence': nextReturnSequence,
      'nextSampleSequence': nextSampleSequence,
      'createdAt': createdAt.toJson(),
      'lastActiveAt': lastActiveAt.toJson(),
      if (syncOutboxItems != null)
        'syncOutboxItems': syncOutboxItems?.toJson(
          valueToJson: (v) => v.toJson(),
        ),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Device',
      if (id != null) 'id': id?.toJson(),
      'deviceName': deviceName,
      'platform': platform.toJson(),
      'deviceCode': deviceCode,
      'nextInvoiceSequence': nextInvoiceSequence,
      'nextReceiptSequence': nextReceiptSequence,
      'nextReturnSequence': nextReturnSequence,
      'nextSampleSequence': nextSampleSequence,
      'createdAt': createdAt.toJson(),
      'lastActiveAt': lastActiveAt.toJson(),
      if (syncOutboxItems != null)
        'syncOutboxItems': syncOutboxItems?.toJson(
          valueToJson: (v) => v.toJsonForProtocol(),
        ),
    };
  }

  static DeviceInclude include({_i3.SyncOutboxIncludeList? syncOutboxItems}) {
    return DeviceInclude._(syncOutboxItems: syncOutboxItems);
  }

  static DeviceIncludeList includeList({
    _i1.WhereExpressionBuilder<DeviceTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<DeviceTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<DeviceTable>? orderByList,
    DeviceInclude? include,
  }) {
    return DeviceIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Device.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Device.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DeviceImpl extends Device {
  _DeviceImpl({
    _i1.UuidValue? id,
    required String deviceName,
    required _i2.DevicePlatform platform,
    required String deviceCode,
    int? nextInvoiceSequence,
    int? nextReceiptSequence,
    int? nextReturnSequence,
    int? nextSampleSequence,
    required DateTime createdAt,
    required DateTime lastActiveAt,
    List<_i3.SyncOutbox>? syncOutboxItems,
  }) : super._(
         id: id,
         deviceName: deviceName,
         platform: platform,
         deviceCode: deviceCode,
         nextInvoiceSequence: nextInvoiceSequence,
         nextReceiptSequence: nextReceiptSequence,
         nextReturnSequence: nextReturnSequence,
         nextSampleSequence: nextSampleSequence,
         createdAt: createdAt,
         lastActiveAt: lastActiveAt,
         syncOutboxItems: syncOutboxItems,
       );

  /// Returns a shallow copy of this [Device]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Device copyWith({
    Object? id = _Undefined,
    String? deviceName,
    _i2.DevicePlatform? platform,
    String? deviceCode,
    int? nextInvoiceSequence,
    int? nextReceiptSequence,
    int? nextReturnSequence,
    int? nextSampleSequence,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    Object? syncOutboxItems = _Undefined,
  }) {
    return Device(
      id: id is _i1.UuidValue? ? id : this.id,
      deviceName: deviceName ?? this.deviceName,
      platform: platform ?? this.platform,
      deviceCode: deviceCode ?? this.deviceCode,
      nextInvoiceSequence: nextInvoiceSequence ?? this.nextInvoiceSequence,
      nextReceiptSequence: nextReceiptSequence ?? this.nextReceiptSequence,
      nextReturnSequence: nextReturnSequence ?? this.nextReturnSequence,
      nextSampleSequence: nextSampleSequence ?? this.nextSampleSequence,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      syncOutboxItems: syncOutboxItems is List<_i3.SyncOutbox>?
          ? syncOutboxItems
          : this.syncOutboxItems?.map((e0) => e0.copyWith()).toList(),
    );
  }
}

class DeviceUpdateTable extends _i1.UpdateTable<DeviceTable> {
  DeviceUpdateTable(super.table);

  _i1.ColumnValue<String, String> deviceName(String value) => _i1.ColumnValue(
    table.deviceName,
    value,
  );

  _i1.ColumnValue<_i2.DevicePlatform, _i2.DevicePlatform> platform(
    _i2.DevicePlatform value,
  ) => _i1.ColumnValue(
    table.platform,
    value,
  );

  _i1.ColumnValue<String, String> deviceCode(String value) => _i1.ColumnValue(
    table.deviceCode,
    value,
  );

  _i1.ColumnValue<int, int> nextInvoiceSequence(int value) => _i1.ColumnValue(
    table.nextInvoiceSequence,
    value,
  );

  _i1.ColumnValue<int, int> nextReceiptSequence(int value) => _i1.ColumnValue(
    table.nextReceiptSequence,
    value,
  );

  _i1.ColumnValue<int, int> nextReturnSequence(int value) => _i1.ColumnValue(
    table.nextReturnSequence,
    value,
  );

  _i1.ColumnValue<int, int> nextSampleSequence(int value) => _i1.ColumnValue(
    table.nextSampleSequence,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> lastActiveAt(DateTime value) =>
      _i1.ColumnValue(
        table.lastActiveAt,
        value,
      );
}

class DeviceTable extends _i1.Table<_i1.UuidValue?> {
  DeviceTable({super.tableRelation}) : super(tableName: 'device') {
    updateTable = DeviceUpdateTable(this);
    deviceName = _i1.ColumnString(
      'deviceName',
      this,
    );
    platform = _i1.ColumnEnum(
      'platform',
      this,
      _i1.EnumSerialization.byName,
    );
    deviceCode = _i1.ColumnString(
      'deviceCode',
      this,
    );
    nextInvoiceSequence = _i1.ColumnInt(
      'nextInvoiceSequence',
      this,
      hasDefault: true,
    );
    nextReceiptSequence = _i1.ColumnInt(
      'nextReceiptSequence',
      this,
      hasDefault: true,
    );
    nextReturnSequence = _i1.ColumnInt(
      'nextReturnSequence',
      this,
      hasDefault: true,
    );
    nextSampleSequence = _i1.ColumnInt(
      'nextSampleSequence',
      this,
      hasDefault: true,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
    lastActiveAt = _i1.ColumnDateTime(
      'lastActiveAt',
      this,
    );
  }

  late final DeviceUpdateTable updateTable;

  late final _i1.ColumnString deviceName;

  late final _i1.ColumnEnum<_i2.DevicePlatform> platform;

  late final _i1.ColumnString deviceCode;

  late final _i1.ColumnInt nextInvoiceSequence;

  late final _i1.ColumnInt nextReceiptSequence;

  late final _i1.ColumnInt nextReturnSequence;

  late final _i1.ColumnInt nextSampleSequence;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime lastActiveAt;

  _i3.SyncOutboxTable? ___syncOutboxItems;

  _i1.ManyRelation<_i3.SyncOutboxTable>? _syncOutboxItems;

  _i3.SyncOutboxTable get __syncOutboxItems {
    if (___syncOutboxItems != null) return ___syncOutboxItems!;
    ___syncOutboxItems = _i1.createRelationTable(
      relationFieldName: '__syncOutboxItems',
      field: Device.t.id,
      foreignField: _i3.SyncOutbox.t.deviceId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i3.SyncOutboxTable(tableRelation: foreignTableRelation),
    );
    return ___syncOutboxItems!;
  }

  _i1.ManyRelation<_i3.SyncOutboxTable> get syncOutboxItems {
    if (_syncOutboxItems != null) return _syncOutboxItems!;
    var relationTable = _i1.createRelationTable(
      relationFieldName: 'syncOutboxItems',
      field: Device.t.id,
      foreignField: _i3.SyncOutbox.t.deviceId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i3.SyncOutboxTable(tableRelation: foreignTableRelation),
    );
    _syncOutboxItems = _i1.ManyRelation<_i3.SyncOutboxTable>(
      tableWithRelations: relationTable,
      table: _i3.SyncOutboxTable(
        tableRelation: relationTable.tableRelation!.lastRelation,
      ),
    );
    return _syncOutboxItems!;
  }

  @override
  List<_i1.Column> get columns => [
    id,
    deviceName,
    platform,
    deviceCode,
    nextInvoiceSequence,
    nextReceiptSequence,
    nextReturnSequence,
    nextSampleSequence,
    createdAt,
    lastActiveAt,
  ];

  @override
  _i1.Table? getRelationTable(String relationField) {
    if (relationField == 'syncOutboxItems') {
      return __syncOutboxItems;
    }
    return null;
  }
}

class DeviceInclude extends _i1.IncludeObject {
  DeviceInclude._({_i3.SyncOutboxIncludeList? syncOutboxItems}) {
    _syncOutboxItems = syncOutboxItems;
  }

  _i3.SyncOutboxIncludeList? _syncOutboxItems;

  @override
  Map<String, _i1.Include?> get includes => {
    'syncOutboxItems': _syncOutboxItems,
  };

  @override
  _i1.Table<_i1.UuidValue?> get table => Device.t;
}

class DeviceIncludeList extends _i1.IncludeList {
  DeviceIncludeList._({
    _i1.WhereExpressionBuilder<DeviceTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Device.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue?> get table => Device.t;
}

class DeviceRepository {
  const DeviceRepository._();

  final attach = const DeviceAttachRepository._();

  final attachRow = const DeviceAttachRowRepository._();

  final detach = const DeviceDetachRepository._();

  final detachRow = const DeviceDetachRowRepository._();

  /// Returns a list of [Device]s matching the given query parameters.
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
  Future<List<Device>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<DeviceTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<DeviceTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<DeviceTable>? orderByList,
    _i1.Transaction? transaction,
    DeviceInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Device>(
      where: where?.call(Device.t),
      orderBy: orderBy?.call(Device.t),
      orderByList: orderByList?.call(Device.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Device] matching the given query parameters.
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
  Future<Device?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<DeviceTable>? where,
    int? offset,
    _i1.OrderByBuilder<DeviceTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<DeviceTable>? orderByList,
    _i1.Transaction? transaction,
    DeviceInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Device>(
      where: where?.call(Device.t),
      orderBy: orderBy?.call(Device.t),
      orderByList: orderByList?.call(Device.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Device] by its [id] or null if no such row exists.
  Future<Device?> findById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    DeviceInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Device>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Device]s in the list and returns the inserted rows.
  ///
  /// The returned [Device]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<Device>> insert(
    _i1.DatabaseSession session,
    List<Device> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<Device>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [Device] and returns the inserted row.
  ///
  /// The returned [Device] will have its `id` field set.
  Future<Device> insertRow(
    _i1.DatabaseSession session,
    Device row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Device>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Device]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Device>> update(
    _i1.DatabaseSession session,
    List<Device> rows, {
    _i1.ColumnSelections<DeviceTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Device>(
      rows,
      columns: columns?.call(Device.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Device]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Device> updateRow(
    _i1.DatabaseSession session,
    Device row, {
    _i1.ColumnSelections<DeviceTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Device>(
      row,
      columns: columns?.call(Device.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Device] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Device?> updateById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<DeviceUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Device>(
      id,
      columnValues: columnValues(Device.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Device]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Device>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<DeviceUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<DeviceTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<DeviceTable>? orderBy,
    _i1.OrderByListBuilder<DeviceTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Device>(
      columnValues: columnValues(Device.t.updateTable),
      where: where(Device.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Device.t),
      orderByList: orderByList?.call(Device.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Device]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Device>> delete(
    _i1.DatabaseSession session,
    List<Device> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Device>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Device].
  Future<Device> deleteRow(
    _i1.DatabaseSession session,
    Device row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Device>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Device>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<DeviceTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Device>(
      where: where(Device.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<DeviceTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Device>(
      where: where?.call(Device.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Device] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<DeviceTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Device>(
      where: where(Device.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class DeviceAttachRepository {
  const DeviceAttachRepository._();

  /// Creates a relation between this [Device] and the given [SyncOutbox]s
  /// by setting each [SyncOutbox]'s foreign key `deviceId` to refer to this [Device].
  Future<void> syncOutboxItems(
    _i1.DatabaseSession session,
    Device device,
    List<_i3.SyncOutbox> syncOutbox, {
    _i1.Transaction? transaction,
  }) async {
    if (syncOutbox.any((e) => e.id == null)) {
      throw ArgumentError.notNull('syncOutbox.id');
    }
    if (device.id == null) {
      throw ArgumentError.notNull('device.id');
    }

    var $syncOutbox = syncOutbox
        .map((e) => e.copyWith(deviceId: device.id))
        .toList();
    await session.db.update<_i3.SyncOutbox>(
      $syncOutbox,
      columns: [_i3.SyncOutbox.t.deviceId],
      transaction: transaction,
    );
  }
}

class DeviceAttachRowRepository {
  const DeviceAttachRowRepository._();

  /// Creates a relation between this [Device] and the given [SyncOutbox]
  /// by setting the [SyncOutbox]'s foreign key `deviceId` to refer to this [Device].
  Future<void> syncOutboxItems(
    _i1.DatabaseSession session,
    Device device,
    _i3.SyncOutbox syncOutbox, {
    _i1.Transaction? transaction,
  }) async {
    if (syncOutbox.id == null) {
      throw ArgumentError.notNull('syncOutbox.id');
    }
    if (device.id == null) {
      throw ArgumentError.notNull('device.id');
    }

    var $syncOutbox = syncOutbox.copyWith(deviceId: device.id);
    await session.db.updateRow<_i3.SyncOutbox>(
      $syncOutbox,
      columns: [_i3.SyncOutbox.t.deviceId],
      transaction: transaction,
    );
  }
}

class DeviceDetachRepository {
  const DeviceDetachRepository._();

  /// Detaches the relation between this [Device] and the given [SyncOutbox]
  /// by setting the [SyncOutbox]'s foreign key `deviceId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> syncOutboxItems(
    _i1.DatabaseSession session,
    List<_i3.SyncOutbox> syncOutbox, {
    _i1.Transaction? transaction,
  }) async {
    if (syncOutbox.any((e) => e.id == null)) {
      throw ArgumentError.notNull('syncOutbox.id');
    }

    var $syncOutbox = syncOutbox
        .map((e) => e.copyWith(deviceId: null))
        .toList();
    await session.db.update<_i3.SyncOutbox>(
      $syncOutbox,
      columns: [_i3.SyncOutbox.t.deviceId],
      transaction: transaction,
    );
  }
}

class DeviceDetachRowRepository {
  const DeviceDetachRowRepository._();

  /// Detaches the relation between this [Device] and the given [SyncOutbox]
  /// by setting the [SyncOutbox]'s foreign key `deviceId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> syncOutboxItems(
    _i1.DatabaseSession session,
    _i3.SyncOutbox syncOutbox, {
    _i1.Transaction? transaction,
  }) async {
    if (syncOutbox.id == null) {
      throw ArgumentError.notNull('syncOutbox.id');
    }

    var $syncOutbox = syncOutbox.copyWith(deviceId: null);
    await session.db.updateRow<_i3.SyncOutbox>(
      $syncOutbox,
      columns: [_i3.SyncOutbox.t.deviceId],
      transaction: transaction,
    );
  }
}
