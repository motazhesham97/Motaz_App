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

abstract class ClientRecord
    implements _i1.TableRow<_i1.UuidValue?>, _i1.ProtocolSerialization {
  ClientRecord._({
    this.id,
    required this.displayName,
    this.phone,
    this.email,
    this.address,
    this.note,
    this.clientCode,
    this.creditLimit,
    this.invoiceCheckIntervalDays,
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

  factory ClientRecord({
    _i1.UuidValue? id,
    required String displayName,
    String? phone,
    String? email,
    String? address,
    String? note,
    String? clientCode,
    int? creditLimit,
    int? invoiceCheckIntervalDays,
    bool? isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
    required _i1.UuidValue deviceId,
    _i3.Device? device,
    int? rowVersion,
    _i2.SyncStatus? syncStatus,
  }) = _ClientRecordImpl;

  factory ClientRecord.fromJson(Map<String, dynamic> jsonSerialization) {
    return ClientRecord(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      displayName: jsonSerialization['displayName'] as String,
      phone: jsonSerialization['phone'] as String?,
      email: jsonSerialization['email'] as String?,
      address: jsonSerialization['address'] as String?,
      note: jsonSerialization['note'] as String?,
      clientCode: jsonSerialization['clientCode'] as String?,
      creditLimit: jsonSerialization['creditLimit'] as int?,
      invoiceCheckIntervalDays:
          jsonSerialization['invoiceCheckIntervalDays'] as int?,
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

  static final t = ClientRecordTable();

  static const db = ClientRecordRepository._();

  @override
  _i1.UuidValue? id;

  String displayName;

  String? phone;

  String? email;

  String? address;

  String? note;

  String? clientCode;

  int? creditLimit;

  int? invoiceCheckIntervalDays;

  bool isActive;

  DateTime createdAt;

  DateTime updatedAt;

  _i1.UuidValue deviceId;

  _i3.Device? device;

  int rowVersion;

  _i2.SyncStatus syncStatus;

  @override
  _i1.Table<_i1.UuidValue?> get table => t;

  /// Returns a shallow copy of this [ClientRecord]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ClientRecord copyWith({
    _i1.UuidValue? id,
    String? displayName,
    String? phone,
    String? email,
    String? address,
    String? note,
    String? clientCode,
    int? creditLimit,
    int? invoiceCheckIntervalDays,
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
      '__className__': 'ClientRecord',
      if (id != null) 'id': id?.toJson(),
      'displayName': displayName,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (note != null) 'note': note,
      if (clientCode != null) 'clientCode': clientCode,
      if (creditLimit != null) 'creditLimit': creditLimit,
      if (invoiceCheckIntervalDays != null)
        'invoiceCheckIntervalDays': invoiceCheckIntervalDays,
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
      '__className__': 'ClientRecord',
      if (id != null) 'id': id?.toJson(),
      'displayName': displayName,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (note != null) 'note': note,
      if (clientCode != null) 'clientCode': clientCode,
      if (creditLimit != null) 'creditLimit': creditLimit,
      if (invoiceCheckIntervalDays != null)
        'invoiceCheckIntervalDays': invoiceCheckIntervalDays,
      'isActive': isActive,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      'deviceId': deviceId.toJson(),
      if (device != null) 'device': device?.toJsonForProtocol(),
      'rowVersion': rowVersion,
      'syncStatus': syncStatus.toJson(),
    };
  }

  static ClientRecordInclude include({_i3.DeviceInclude? device}) {
    return ClientRecordInclude._(device: device);
  }

  static ClientRecordIncludeList includeList({
    _i1.WhereExpressionBuilder<ClientRecordTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ClientRecordTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ClientRecordTable>? orderByList,
    ClientRecordInclude? include,
  }) {
    return ClientRecordIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ClientRecord.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(ClientRecord.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ClientRecordImpl extends ClientRecord {
  _ClientRecordImpl({
    _i1.UuidValue? id,
    required String displayName,
    String? phone,
    String? email,
    String? address,
    String? note,
    String? clientCode,
    int? creditLimit,
    int? invoiceCheckIntervalDays,
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
         email: email,
         address: address,
         note: note,
         clientCode: clientCode,
         creditLimit: creditLimit,
         invoiceCheckIntervalDays: invoiceCheckIntervalDays,
         isActive: isActive,
         createdAt: createdAt,
         updatedAt: updatedAt,
         deviceId: deviceId,
         device: device,
         rowVersion: rowVersion,
         syncStatus: syncStatus,
       );

  /// Returns a shallow copy of this [ClientRecord]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ClientRecord copyWith({
    Object? id = _Undefined,
    String? displayName,
    Object? phone = _Undefined,
    Object? email = _Undefined,
    Object? address = _Undefined,
    Object? note = _Undefined,
    Object? clientCode = _Undefined,
    Object? creditLimit = _Undefined,
    Object? invoiceCheckIntervalDays = _Undefined,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    _i1.UuidValue? deviceId,
    Object? device = _Undefined,
    int? rowVersion,
    _i2.SyncStatus? syncStatus,
  }) {
    return ClientRecord(
      id: id is _i1.UuidValue? ? id : this.id,
      displayName: displayName ?? this.displayName,
      phone: phone is String? ? phone : this.phone,
      email: email is String? ? email : this.email,
      address: address is String? ? address : this.address,
      note: note is String? ? note : this.note,
      clientCode: clientCode is String? ? clientCode : this.clientCode,
      creditLimit: creditLimit is int? ? creditLimit : this.creditLimit,
      invoiceCheckIntervalDays: invoiceCheckIntervalDays is int?
          ? invoiceCheckIntervalDays
          : this.invoiceCheckIntervalDays,
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

class ClientRecordUpdateTable extends _i1.UpdateTable<ClientRecordTable> {
  ClientRecordUpdateTable(super.table);

  _i1.ColumnValue<String, String> displayName(String value) => _i1.ColumnValue(
    table.displayName,
    value,
  );

  _i1.ColumnValue<String, String> phone(String? value) => _i1.ColumnValue(
    table.phone,
    value,
  );

  _i1.ColumnValue<String, String> email(String? value) => _i1.ColumnValue(
    table.email,
    value,
  );

  _i1.ColumnValue<String, String> address(String? value) => _i1.ColumnValue(
    table.address,
    value,
  );

  _i1.ColumnValue<String, String> note(String? value) => _i1.ColumnValue(
    table.note,
    value,
  );

  _i1.ColumnValue<String, String> clientCode(String? value) => _i1.ColumnValue(
    table.clientCode,
    value,
  );

  _i1.ColumnValue<int, int> creditLimit(int? value) => _i1.ColumnValue(
    table.creditLimit,
    value,
  );

  _i1.ColumnValue<int, int> invoiceCheckIntervalDays(int? value) =>
      _i1.ColumnValue(
        table.invoiceCheckIntervalDays,
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

class ClientRecordTable extends _i1.Table<_i1.UuidValue?> {
  ClientRecordTable({super.tableRelation}) : super(tableName: 'client') {
    updateTable = ClientRecordUpdateTable(this);
    displayName = _i1.ColumnString(
      'displayName',
      this,
    );
    phone = _i1.ColumnString(
      'phone',
      this,
    );
    email = _i1.ColumnString(
      'email',
      this,
    );
    address = _i1.ColumnString(
      'address',
      this,
    );
    note = _i1.ColumnString(
      'note',
      this,
    );
    clientCode = _i1.ColumnString(
      'clientCode',
      this,
    );
    creditLimit = _i1.ColumnInt(
      'creditLimit',
      this,
    );
    invoiceCheckIntervalDays = _i1.ColumnInt(
      'invoiceCheckIntervalDays',
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

  late final ClientRecordUpdateTable updateTable;

  late final _i1.ColumnString displayName;

  late final _i1.ColumnString phone;

  late final _i1.ColumnString email;

  late final _i1.ColumnString address;

  late final _i1.ColumnString note;

  late final _i1.ColumnString clientCode;

  late final _i1.ColumnInt creditLimit;

  late final _i1.ColumnInt invoiceCheckIntervalDays;

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
      field: ClientRecord.t.deviceId,
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
    email,
    address,
    note,
    clientCode,
    creditLimit,
    invoiceCheckIntervalDays,
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

class ClientRecordInclude extends _i1.IncludeObject {
  ClientRecordInclude._({_i3.DeviceInclude? device}) {
    _device = device;
  }

  _i3.DeviceInclude? _device;

  @override
  Map<String, _i1.Include?> get includes => {'device': _device};

  @override
  _i1.Table<_i1.UuidValue?> get table => ClientRecord.t;
}

class ClientRecordIncludeList extends _i1.IncludeList {
  ClientRecordIncludeList._({
    _i1.WhereExpressionBuilder<ClientRecordTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ClientRecord.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue?> get table => ClientRecord.t;
}

class ClientRecordRepository {
  const ClientRecordRepository._();

  final attachRow = const ClientRecordAttachRowRepository._();

  /// Returns a list of [ClientRecord]s matching the given query parameters.
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
  Future<List<ClientRecord>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ClientRecordTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ClientRecordTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ClientRecordTable>? orderByList,
    _i1.Transaction? transaction,
    ClientRecordInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ClientRecord>(
      where: where?.call(ClientRecord.t),
      orderBy: orderBy?.call(ClientRecord.t),
      orderByList: orderByList?.call(ClientRecord.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ClientRecord] matching the given query parameters.
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
  Future<ClientRecord?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ClientRecordTable>? where,
    int? offset,
    _i1.OrderByBuilder<ClientRecordTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ClientRecordTable>? orderByList,
    _i1.Transaction? transaction,
    ClientRecordInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ClientRecord>(
      where: where?.call(ClientRecord.t),
      orderBy: orderBy?.call(ClientRecord.t),
      orderByList: orderByList?.call(ClientRecord.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ClientRecord] by its [id] or null if no such row exists.
  Future<ClientRecord?> findById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    ClientRecordInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ClientRecord>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ClientRecord]s in the list and returns the inserted rows.
  ///
  /// The returned [ClientRecord]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<ClientRecord>> insert(
    _i1.DatabaseSession session,
    List<ClientRecord> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<ClientRecord>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [ClientRecord] and returns the inserted row.
  ///
  /// The returned [ClientRecord] will have its `id` field set.
  Future<ClientRecord> insertRow(
    _i1.DatabaseSession session,
    ClientRecord row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<ClientRecord>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [ClientRecord]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<ClientRecord>> update(
    _i1.DatabaseSession session,
    List<ClientRecord> rows, {
    _i1.ColumnSelections<ClientRecordTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<ClientRecord>(
      rows,
      columns: columns?.call(ClientRecord.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ClientRecord]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ClientRecord> updateRow(
    _i1.DatabaseSession session,
    ClientRecord row, {
    _i1.ColumnSelections<ClientRecordTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<ClientRecord>(
      row,
      columns: columns?.call(ClientRecord.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ClientRecord] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ClientRecord?> updateById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<ClientRecordUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<ClientRecord>(
      id,
      columnValues: columnValues(ClientRecord.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ClientRecord]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<ClientRecord>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<ClientRecordUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<ClientRecordTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ClientRecordTable>? orderBy,
    _i1.OrderByListBuilder<ClientRecordTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<ClientRecord>(
      columnValues: columnValues(ClientRecord.t.updateTable),
      where: where(ClientRecord.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ClientRecord.t),
      orderByList: orderByList?.call(ClientRecord.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [ClientRecord]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<ClientRecord>> delete(
    _i1.DatabaseSession session,
    List<ClientRecord> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<ClientRecord>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [ClientRecord].
  Future<ClientRecord> deleteRow(
    _i1.DatabaseSession session,
    ClientRecord row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ClientRecord>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<ClientRecord>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ClientRecordTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<ClientRecord>(
      where: where(ClientRecord.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ClientRecordTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<ClientRecord>(
      where: where?.call(ClientRecord.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ClientRecord] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ClientRecordTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ClientRecord>(
      where: where(ClientRecord.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class ClientRecordAttachRowRepository {
  const ClientRecordAttachRowRepository._();

  /// Creates a relation between the given [ClientRecord] and [Device]
  /// by setting the [ClientRecord]'s foreign key `deviceId` to refer to the [Device].
  Future<void> device(
    _i1.DatabaseSession session,
    ClientRecord clientRecord,
    _i3.Device device, {
    _i1.Transaction? transaction,
  }) async {
    if (clientRecord.id == null) {
      throw ArgumentError.notNull('clientRecord.id');
    }
    if (device.id == null) {
      throw ArgumentError.notNull('device.id');
    }

    var $clientRecord = clientRecord.copyWith(deviceId: device.id);
    await session.db.updateRow<ClientRecord>(
      $clientRecord,
      columns: [ClientRecord.t.deviceId],
      transaction: transaction,
    );
  }
}
