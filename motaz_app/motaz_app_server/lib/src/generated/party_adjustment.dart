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
import 'enums/party_account.dart' as _i4;
import 'device.dart' as _i5;
import 'package:motaz_app_server/src/generated/protocol.dart' as _i6;

abstract class PartyAdjustment
    implements _i1.TableRow<_i1.UuidValue?>, _i1.ProtocolSerialization {
  PartyAdjustment._({
    this.id,
    required this.party,
    required this.amount,
    required this.adjustmentDate,
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

  factory PartyAdjustment({
    _i1.UuidValue? id,
    required _i4.PartyAccount party,
    required int amount,
    required DateTime adjustmentDate,
    String? note,
    _i2.RecordStatus? status,
    String? voidReason,
    required DateTime createdAt,
    required DateTime updatedAt,
    required _i1.UuidValue deviceId,
    _i5.Device? device,
    int? rowVersion,
    _i3.SyncStatus? syncStatus,
  }) = _PartyAdjustmentImpl;

  factory PartyAdjustment.fromJson(Map<String, dynamic> jsonSerialization) {
    return PartyAdjustment(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      party: _i4.PartyAccount.fromJson((jsonSerialization['party'] as String)),
      amount: jsonSerialization['amount'] as int,
      adjustmentDate: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['adjustmentDate'],
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

  static final t = PartyAdjustmentTable();

  static const db = PartyAdjustmentRepository._();

  @override
  _i1.UuidValue? id;

  _i4.PartyAccount party;

  int amount;

  DateTime adjustmentDate;

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

  /// Returns a shallow copy of this [PartyAdjustment]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PartyAdjustment copyWith({
    _i1.UuidValue? id,
    _i4.PartyAccount? party,
    int? amount,
    DateTime? adjustmentDate,
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
      '__className__': 'PartyAdjustment',
      if (id != null) 'id': id?.toJson(),
      'party': party.toJson(),
      'amount': amount,
      'adjustmentDate': adjustmentDate.toJson(),
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
      '__className__': 'PartyAdjustment',
      if (id != null) 'id': id?.toJson(),
      'party': party.toJson(),
      'amount': amount,
      'adjustmentDate': adjustmentDate.toJson(),
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

  static PartyAdjustmentInclude include({_i5.DeviceInclude? device}) {
    return PartyAdjustmentInclude._(device: device);
  }

  static PartyAdjustmentIncludeList includeList({
    _i1.WhereExpressionBuilder<PartyAdjustmentTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<PartyAdjustmentTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<PartyAdjustmentTable>? orderByList,
    PartyAdjustmentInclude? include,
  }) {
    return PartyAdjustmentIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PartyAdjustment.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(PartyAdjustment.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PartyAdjustmentImpl extends PartyAdjustment {
  _PartyAdjustmentImpl({
    _i1.UuidValue? id,
    required _i4.PartyAccount party,
    required int amount,
    required DateTime adjustmentDate,
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
         party: party,
         amount: amount,
         adjustmentDate: adjustmentDate,
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

  /// Returns a shallow copy of this [PartyAdjustment]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PartyAdjustment copyWith({
    Object? id = _Undefined,
    _i4.PartyAccount? party,
    int? amount,
    DateTime? adjustmentDate,
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
    return PartyAdjustment(
      id: id is _i1.UuidValue? ? id : this.id,
      party: party ?? this.party,
      amount: amount ?? this.amount,
      adjustmentDate: adjustmentDate ?? this.adjustmentDate,
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

class PartyAdjustmentUpdateTable extends _i1.UpdateTable<PartyAdjustmentTable> {
  PartyAdjustmentUpdateTable(super.table);

  _i1.ColumnValue<_i4.PartyAccount, _i4.PartyAccount> party(
    _i4.PartyAccount value,
  ) => _i1.ColumnValue(
    table.party,
    value,
  );

  _i1.ColumnValue<int, int> amount(int value) => _i1.ColumnValue(
    table.amount,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> adjustmentDate(DateTime value) =>
      _i1.ColumnValue(
        table.adjustmentDate,
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

class PartyAdjustmentTable extends _i1.Table<_i1.UuidValue?> {
  PartyAdjustmentTable({super.tableRelation})
    : super(tableName: 'party_adjustment') {
    updateTable = PartyAdjustmentUpdateTable(this);
    party = _i1.ColumnEnum(
      'party',
      this,
      _i1.EnumSerialization.byName,
    );
    amount = _i1.ColumnInt(
      'amount',
      this,
    );
    adjustmentDate = _i1.ColumnDateTime(
      'adjustmentDate',
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

  late final PartyAdjustmentUpdateTable updateTable;

  late final _i1.ColumnEnum<_i4.PartyAccount> party;

  late final _i1.ColumnInt amount;

  late final _i1.ColumnDateTime adjustmentDate;

  late final _i1.ColumnString note;

  late final _i1.ColumnEnum<_i2.RecordStatus> status;

  late final _i1.ColumnString voidReason;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  late final _i1.ColumnUuid deviceId;

  _i5.DeviceTable? _device;

  late final _i1.ColumnInt rowVersion;

  late final _i1.ColumnEnum<_i3.SyncStatus> syncStatus;

  _i5.DeviceTable get device {
    if (_device != null) return _device!;
    _device = _i1.createRelationTable(
      relationFieldName: 'device',
      field: PartyAdjustment.t.deviceId,
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
    party,
    amount,
    adjustmentDate,
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
    if (relationField == 'device') {
      return device;
    }
    return null;
  }
}

class PartyAdjustmentInclude extends _i1.IncludeObject {
  PartyAdjustmentInclude._({_i5.DeviceInclude? device}) {
    _device = device;
  }

  _i5.DeviceInclude? _device;

  @override
  Map<String, _i1.Include?> get includes => {'device': _device};

  @override
  _i1.Table<_i1.UuidValue?> get table => PartyAdjustment.t;
}

class PartyAdjustmentIncludeList extends _i1.IncludeList {
  PartyAdjustmentIncludeList._({
    _i1.WhereExpressionBuilder<PartyAdjustmentTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(PartyAdjustment.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue?> get table => PartyAdjustment.t;
}

class PartyAdjustmentRepository {
  const PartyAdjustmentRepository._();

  final attachRow = const PartyAdjustmentAttachRowRepository._();

  /// Returns a list of [PartyAdjustment]s matching the given query parameters.
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
  Future<List<PartyAdjustment>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<PartyAdjustmentTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<PartyAdjustmentTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<PartyAdjustmentTable>? orderByList,
    _i1.Transaction? transaction,
    PartyAdjustmentInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<PartyAdjustment>(
      where: where?.call(PartyAdjustment.t),
      orderBy: orderBy?.call(PartyAdjustment.t),
      orderByList: orderByList?.call(PartyAdjustment.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [PartyAdjustment] matching the given query parameters.
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
  Future<PartyAdjustment?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<PartyAdjustmentTable>? where,
    int? offset,
    _i1.OrderByBuilder<PartyAdjustmentTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<PartyAdjustmentTable>? orderByList,
    _i1.Transaction? transaction,
    PartyAdjustmentInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<PartyAdjustment>(
      where: where?.call(PartyAdjustment.t),
      orderBy: orderBy?.call(PartyAdjustment.t),
      orderByList: orderByList?.call(PartyAdjustment.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [PartyAdjustment] by its [id] or null if no such row exists.
  Future<PartyAdjustment?> findById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    PartyAdjustmentInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<PartyAdjustment>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [PartyAdjustment]s in the list and returns the inserted rows.
  ///
  /// The returned [PartyAdjustment]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<PartyAdjustment>> insert(
    _i1.DatabaseSession session,
    List<PartyAdjustment> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<PartyAdjustment>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [PartyAdjustment] and returns the inserted row.
  ///
  /// The returned [PartyAdjustment] will have its `id` field set.
  Future<PartyAdjustment> insertRow(
    _i1.DatabaseSession session,
    PartyAdjustment row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<PartyAdjustment>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [PartyAdjustment]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<PartyAdjustment>> update(
    _i1.DatabaseSession session,
    List<PartyAdjustment> rows, {
    _i1.ColumnSelections<PartyAdjustmentTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<PartyAdjustment>(
      rows,
      columns: columns?.call(PartyAdjustment.t),
      transaction: transaction,
    );
  }

  /// Updates a single [PartyAdjustment]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<PartyAdjustment> updateRow(
    _i1.DatabaseSession session,
    PartyAdjustment row, {
    _i1.ColumnSelections<PartyAdjustmentTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<PartyAdjustment>(
      row,
      columns: columns?.call(PartyAdjustment.t),
      transaction: transaction,
    );
  }

  /// Updates a single [PartyAdjustment] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<PartyAdjustment?> updateById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<PartyAdjustmentUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<PartyAdjustment>(
      id,
      columnValues: columnValues(PartyAdjustment.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [PartyAdjustment]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<PartyAdjustment>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<PartyAdjustmentUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<PartyAdjustmentTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<PartyAdjustmentTable>? orderBy,
    _i1.OrderByListBuilder<PartyAdjustmentTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<PartyAdjustment>(
      columnValues: columnValues(PartyAdjustment.t.updateTable),
      where: where(PartyAdjustment.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PartyAdjustment.t),
      orderByList: orderByList?.call(PartyAdjustment.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [PartyAdjustment]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<PartyAdjustment>> delete(
    _i1.DatabaseSession session,
    List<PartyAdjustment> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<PartyAdjustment>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [PartyAdjustment].
  Future<PartyAdjustment> deleteRow(
    _i1.DatabaseSession session,
    PartyAdjustment row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<PartyAdjustment>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<PartyAdjustment>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<PartyAdjustmentTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<PartyAdjustment>(
      where: where(PartyAdjustment.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<PartyAdjustmentTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<PartyAdjustment>(
      where: where?.call(PartyAdjustment.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [PartyAdjustment] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<PartyAdjustmentTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<PartyAdjustment>(
      where: where(PartyAdjustment.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class PartyAdjustmentAttachRowRepository {
  const PartyAdjustmentAttachRowRepository._();

  /// Creates a relation between the given [PartyAdjustment] and [Device]
  /// by setting the [PartyAdjustment]'s foreign key `deviceId` to refer to the [Device].
  Future<void> device(
    _i1.DatabaseSession session,
    PartyAdjustment partyAdjustment,
    _i5.Device device, {
    _i1.Transaction? transaction,
  }) async {
    if (partyAdjustment.id == null) {
      throw ArgumentError.notNull('partyAdjustment.id');
    }
    if (device.id == null) {
      throw ArgumentError.notNull('device.id');
    }

    var $partyAdjustment = partyAdjustment.copyWith(deviceId: device.id);
    await session.db.updateRow<PartyAdjustment>(
      $partyAdjustment,
      columns: [PartyAdjustment.t.deviceId],
      transaction: transaction,
    );
  }
}
