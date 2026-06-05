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
import 'device.dart' as _i3;
import 'package:motaz_app_server/src/generated/protocol.dart' as _i4;

abstract class Beneficiary
    implements _i1.TableRow<_i1.UuidValue?>, _i1.ProtocolSerialization {
  Beneficiary._({
    this.id,
    required this.displayName,
    this.phone,
    this.sourceClientId,
    bool? isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.deviceId,
    this.device,
    int? rowVersion,
    _i2.SyncStatus? syncStatus,
  }) : isActive = isActive ?? true,
       rowVersion = rowVersion ?? 1,
       syncStatus = syncStatus ?? _i2.SyncStatus.PENDING;

  factory Beneficiary({
    _i1.UuidValue? id,
    required String displayName,
    String? phone,
    _i1.UuidValue? sourceClientId,
    bool? isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
    required _i1.UuidValue deviceId,
    _i3.Device? device,
    int? rowVersion,
    _i2.SyncStatus? syncStatus,
  }) = _BeneficiaryImpl;

  factory Beneficiary.fromJson(Map<String, dynamic> jsonSerialization) {
    return Beneficiary(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      displayName: jsonSerialization['displayName'] as String,
      phone: jsonSerialization['phone'] as String?,
      sourceClientId: jsonSerialization['sourceClientId'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(
              jsonSerialization['sourceClientId'],
            ),
      isActive: jsonSerialization['isActive'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['isActive']),
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
          : _i4.Protocol().deserialize<_i3.Device>(jsonSerialization['device']),
      rowVersion: jsonSerialization['rowVersion'] as int?,
      syncStatus: jsonSerialization['syncStatus'] == null
          ? null
          : _i2.SyncStatus.fromJson(
              (jsonSerialization['syncStatus'] as String),
            ),
    );
  }

  static final t = BeneficiaryTable();

  static const db = BeneficiaryRepository._();

  @override
  _i1.UuidValue? id;

  String displayName;

  String? phone;

  _i1.UuidValue? sourceClientId;

  bool isActive;

  DateTime createdAt;

  DateTime updatedAt;

  _i1.UuidValue deviceId;

  _i3.Device? device;

  int rowVersion;

  _i2.SyncStatus syncStatus;

  @override
  _i1.Table<_i1.UuidValue?> get table => t;

  /// Returns a shallow copy of this [Beneficiary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Beneficiary copyWith({
    _i1.UuidValue? id,
    String? displayName,
    String? phone,
    _i1.UuidValue? sourceClientId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    _i1.UuidValue? deviceId,
    _i3.Device? device,
    int? rowVersion,
    _i2.SyncStatus? syncStatus,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Beneficiary',
      if (id != null) 'id': id?.toJson(),
      'displayName': displayName,
      if (phone != null) 'phone': phone,
      if (sourceClientId != null) 'sourceClientId': sourceClientId?.toJson(),
      'isActive': isActive,
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
      '__className__': 'Beneficiary',
      if (id != null) 'id': id?.toJson(),
      'displayName': displayName,
      if (phone != null) 'phone': phone,
      if (sourceClientId != null) 'sourceClientId': sourceClientId?.toJson(),
      'isActive': isActive,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      'deviceId': deviceId.toJson(),
      if (device != null) 'device': device?.toJsonForProtocol(),
      'rowVersion': rowVersion,
      'syncStatus': syncStatus.toJson(),
    };
  }

  static BeneficiaryInclude include({_i3.DeviceInclude? device}) {
    return BeneficiaryInclude._(device: device);
  }

  static BeneficiaryIncludeList includeList({
    _i1.WhereExpressionBuilder<BeneficiaryTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<BeneficiaryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<BeneficiaryTable>? orderByList,
    BeneficiaryInclude? include,
  }) {
    return BeneficiaryIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Beneficiary.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Beneficiary.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BeneficiaryImpl extends Beneficiary {
  _BeneficiaryImpl({
    _i1.UuidValue? id,
    required String displayName,
    String? phone,
    _i1.UuidValue? sourceClientId,
    bool? isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
    required _i1.UuidValue deviceId,
    _i3.Device? device,
    int? rowVersion,
    _i2.SyncStatus? syncStatus,
  }) : super._(
         id: id,
         displayName: displayName,
         phone: phone,
         sourceClientId: sourceClientId,
         isActive: isActive,
         createdAt: createdAt,
         updatedAt: updatedAt,
         deviceId: deviceId,
         device: device,
         rowVersion: rowVersion,
         syncStatus: syncStatus,
       );

  /// Returns a shallow copy of this [Beneficiary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Beneficiary copyWith({
    Object? id = _Undefined,
    String? displayName,
    Object? phone = _Undefined,
    Object? sourceClientId = _Undefined,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    _i1.UuidValue? deviceId,
    Object? device = _Undefined,
    int? rowVersion,
    _i2.SyncStatus? syncStatus,
  }) {
    return Beneficiary(
      id: id is _i1.UuidValue? ? id : this.id,
      displayName: displayName ?? this.displayName,
      phone: phone is String? ? phone : this.phone,
      sourceClientId: sourceClientId is _i1.UuidValue?
          ? sourceClientId
          : this.sourceClientId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      device: device is _i3.Device? ? device : this.device?.copyWith(),
      rowVersion: rowVersion ?? this.rowVersion,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}

class BeneficiaryUpdateTable extends _i1.UpdateTable<BeneficiaryTable> {
  BeneficiaryUpdateTable(super.table);

  _i1.ColumnValue<String, String> displayName(String value) => _i1.ColumnValue(
    table.displayName,
    value,
  );

  _i1.ColumnValue<String, String> phone(String? value) => _i1.ColumnValue(
    table.phone,
    value,
  );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> sourceClientId(
    _i1.UuidValue? value,
  ) => _i1.ColumnValue(
    table.sourceClientId,
    value,
  );

  _i1.ColumnValue<bool, bool> isActive(bool value) => _i1.ColumnValue(
    table.isActive,
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

class BeneficiaryTable extends _i1.Table<_i1.UuidValue?> {
  BeneficiaryTable({super.tableRelation}) : super(tableName: 'beneficiary') {
    updateTable = BeneficiaryUpdateTable(this);
    displayName = _i1.ColumnString(
      'displayName',
      this,
    );
    phone = _i1.ColumnString(
      'phone',
      this,
    );
    sourceClientId = _i1.ColumnUuid(
      'sourceClientId',
      this,
    );
    isActive = _i1.ColumnBool(
      'isActive',
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

  late final BeneficiaryUpdateTable updateTable;

  late final _i1.ColumnString displayName;

  late final _i1.ColumnString phone;

  late final _i1.ColumnUuid sourceClientId;

  late final _i1.ColumnBool isActive;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  late final _i1.ColumnUuid deviceId;

  _i3.DeviceTable? _device;

  late final _i1.ColumnInt rowVersion;

  late final _i1.ColumnEnum<_i2.SyncStatus> syncStatus;

  _i3.DeviceTable get device {
    if (_device != null) return _device!;
    _device = _i1.createRelationTable(
      relationFieldName: 'device',
      field: Beneficiary.t.deviceId,
      foreignField: _i3.Device.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i3.DeviceTable(tableRelation: foreignTableRelation),
    );
    return _device!;
  }

  @override
  List<_i1.Column> get columns => [
    id,
    displayName,
    phone,
    sourceClientId,
    isActive,
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

class BeneficiaryInclude extends _i1.IncludeObject {
  BeneficiaryInclude._({_i3.DeviceInclude? device}) {
    _device = device;
  }

  _i3.DeviceInclude? _device;

  @override
  Map<String, _i1.Include?> get includes => {'device': _device};

  @override
  _i1.Table<_i1.UuidValue?> get table => Beneficiary.t;
}

class BeneficiaryIncludeList extends _i1.IncludeList {
  BeneficiaryIncludeList._({
    _i1.WhereExpressionBuilder<BeneficiaryTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Beneficiary.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue?> get table => Beneficiary.t;
}

class BeneficiaryRepository {
  const BeneficiaryRepository._();

  final attachRow = const BeneficiaryAttachRowRepository._();

  /// Returns a list of [Beneficiary]s matching the given query parameters.
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
  Future<List<Beneficiary>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<BeneficiaryTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<BeneficiaryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<BeneficiaryTable>? orderByList,
    _i1.Transaction? transaction,
    BeneficiaryInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Beneficiary>(
      where: where?.call(Beneficiary.t),
      orderBy: orderBy?.call(Beneficiary.t),
      orderByList: orderByList?.call(Beneficiary.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Beneficiary] matching the given query parameters.
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
  Future<Beneficiary?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<BeneficiaryTable>? where,
    int? offset,
    _i1.OrderByBuilder<BeneficiaryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<BeneficiaryTable>? orderByList,
    _i1.Transaction? transaction,
    BeneficiaryInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Beneficiary>(
      where: where?.call(Beneficiary.t),
      orderBy: orderBy?.call(Beneficiary.t),
      orderByList: orderByList?.call(Beneficiary.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Beneficiary] by its [id] or null if no such row exists.
  Future<Beneficiary?> findById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    BeneficiaryInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Beneficiary>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Beneficiary]s in the list and returns the inserted rows.
  ///
  /// The returned [Beneficiary]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<Beneficiary>> insert(
    _i1.DatabaseSession session,
    List<Beneficiary> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<Beneficiary>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [Beneficiary] and returns the inserted row.
  ///
  /// The returned [Beneficiary] will have its `id` field set.
  Future<Beneficiary> insertRow(
    _i1.DatabaseSession session,
    Beneficiary row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Beneficiary>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Beneficiary]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Beneficiary>> update(
    _i1.DatabaseSession session,
    List<Beneficiary> rows, {
    _i1.ColumnSelections<BeneficiaryTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Beneficiary>(
      rows,
      columns: columns?.call(Beneficiary.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Beneficiary]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Beneficiary> updateRow(
    _i1.DatabaseSession session,
    Beneficiary row, {
    _i1.ColumnSelections<BeneficiaryTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Beneficiary>(
      row,
      columns: columns?.call(Beneficiary.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Beneficiary] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Beneficiary?> updateById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<BeneficiaryUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Beneficiary>(
      id,
      columnValues: columnValues(Beneficiary.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Beneficiary]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Beneficiary>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<BeneficiaryUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<BeneficiaryTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<BeneficiaryTable>? orderBy,
    _i1.OrderByListBuilder<BeneficiaryTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Beneficiary>(
      columnValues: columnValues(Beneficiary.t.updateTable),
      where: where(Beneficiary.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Beneficiary.t),
      orderByList: orderByList?.call(Beneficiary.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Beneficiary]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Beneficiary>> delete(
    _i1.DatabaseSession session,
    List<Beneficiary> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Beneficiary>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Beneficiary].
  Future<Beneficiary> deleteRow(
    _i1.DatabaseSession session,
    Beneficiary row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Beneficiary>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Beneficiary>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<BeneficiaryTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Beneficiary>(
      where: where(Beneficiary.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<BeneficiaryTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Beneficiary>(
      where: where?.call(Beneficiary.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Beneficiary] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<BeneficiaryTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Beneficiary>(
      where: where(Beneficiary.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class BeneficiaryAttachRowRepository {
  const BeneficiaryAttachRowRepository._();

  /// Creates a relation between the given [Beneficiary] and [Device]
  /// by setting the [Beneficiary]'s foreign key `deviceId` to refer to the [Device].
  Future<void> device(
    _i1.DatabaseSession session,
    Beneficiary beneficiary,
    _i3.Device device, {
    _i1.Transaction? transaction,
  }) async {
    if (beneficiary.id == null) {
      throw ArgumentError.notNull('beneficiary.id');
    }
    if (device.id == null) {
      throw ArgumentError.notNull('device.id');
    }

    var $beneficiary = beneficiary.copyWith(deviceId: device.id);
    await session.db.updateRow<Beneficiary>(
      $beneficiary,
      columns: [Beneficiary.t.deviceId],
      transaction: transaction,
    );
  }
}
