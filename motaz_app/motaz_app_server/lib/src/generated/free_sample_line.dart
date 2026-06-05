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
import 'free_sample.dart' as _i3;
import 'product.dart' as _i4;
import 'device.dart' as _i5;
import 'package:motaz_app_server/src/generated/protocol.dart' as _i6;

abstract class FreeSampleLine
    implements _i1.TableRow<_i1.UuidValue?>, _i1.ProtocolSerialization {
  FreeSampleLine._({
    this.id,
    required this.sampleId,
    this.sample,
    required this.productId,
    this.product,
    required this.quantity,
    required this.createdAt,
    required this.updatedAt,
    required this.deviceId,
    this.device,
    int? rowVersion,
    _i2.SyncStatus? syncStatus,
  }) : rowVersion = rowVersion ?? 1,
       syncStatus = syncStatus ?? _i2.SyncStatus.PENDING;

  factory FreeSampleLine({
    _i1.UuidValue? id,
    required _i1.UuidValue sampleId,
    _i3.FreeSample? sample,
    required _i1.UuidValue productId,
    _i4.Product? product,
    required int quantity,
    required DateTime createdAt,
    required DateTime updatedAt,
    required _i1.UuidValue deviceId,
    _i5.Device? device,
    int? rowVersion,
    _i2.SyncStatus? syncStatus,
  }) = _FreeSampleLineImpl;

  factory FreeSampleLine.fromJson(Map<String, dynamic> jsonSerialization) {
    return FreeSampleLine(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      sampleId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['sampleId'],
      ),
      sample: jsonSerialization['sample'] == null
          ? null
          : _i6.Protocol().deserialize<_i3.FreeSample>(
              jsonSerialization['sample'],
            ),
      productId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['productId'],
      ),
      product: jsonSerialization['product'] == null
          ? null
          : _i6.Protocol().deserialize<_i4.Product>(
              jsonSerialization['product'],
            ),
      quantity: jsonSerialization['quantity'] as int,
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
          : _i2.SyncStatus.fromJson(
              (jsonSerialization['syncStatus'] as String),
            ),
    );
  }

  static final t = FreeSampleLineTable();

  static const db = FreeSampleLineRepository._();

  @override
  _i1.UuidValue? id;

  _i1.UuidValue sampleId;

  _i3.FreeSample? sample;

  _i1.UuidValue productId;

  _i4.Product? product;

  int quantity;

  DateTime createdAt;

  DateTime updatedAt;

  _i1.UuidValue deviceId;

  _i5.Device? device;

  int rowVersion;

  _i2.SyncStatus syncStatus;

  @override
  _i1.Table<_i1.UuidValue?> get table => t;

  /// Returns a shallow copy of this [FreeSampleLine]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  FreeSampleLine copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? sampleId,
    _i3.FreeSample? sample,
    _i1.UuidValue? productId,
    _i4.Product? product,
    int? quantity,
    DateTime? createdAt,
    DateTime? updatedAt,
    _i1.UuidValue? deviceId,
    _i5.Device? device,
    int? rowVersion,
    _i2.SyncStatus? syncStatus,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FreeSampleLine',
      if (id != null) 'id': id?.toJson(),
      'sampleId': sampleId.toJson(),
      if (sample != null) 'sample': sample?.toJson(),
      'productId': productId.toJson(),
      if (product != null) 'product': product?.toJson(),
      'quantity': quantity,
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
      '__className__': 'FreeSampleLine',
      if (id != null) 'id': id?.toJson(),
      'sampleId': sampleId.toJson(),
      if (sample != null) 'sample': sample?.toJsonForProtocol(),
      'productId': productId.toJson(),
      if (product != null) 'product': product?.toJsonForProtocol(),
      'quantity': quantity,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      'deviceId': deviceId.toJson(),
      if (device != null) 'device': device?.toJsonForProtocol(),
      'rowVersion': rowVersion,
      'syncStatus': syncStatus.toJson(),
    };
  }

  static FreeSampleLineInclude include({
    _i3.FreeSampleInclude? sample,
    _i4.ProductInclude? product,
    _i5.DeviceInclude? device,
  }) {
    return FreeSampleLineInclude._(
      sample: sample,
      product: product,
      device: device,
    );
  }

  static FreeSampleLineIncludeList includeList({
    _i1.WhereExpressionBuilder<FreeSampleLineTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<FreeSampleLineTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<FreeSampleLineTable>? orderByList,
    FreeSampleLineInclude? include,
  }) {
    return FreeSampleLineIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(FreeSampleLine.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(FreeSampleLine.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _FreeSampleLineImpl extends FreeSampleLine {
  _FreeSampleLineImpl({
    _i1.UuidValue? id,
    required _i1.UuidValue sampleId,
    _i3.FreeSample? sample,
    required _i1.UuidValue productId,
    _i4.Product? product,
    required int quantity,
    required DateTime createdAt,
    required DateTime updatedAt,
    required _i1.UuidValue deviceId,
    _i5.Device? device,
    int? rowVersion,
    _i2.SyncStatus? syncStatus,
  }) : super._(
         id: id,
         sampleId: sampleId,
         sample: sample,
         productId: productId,
         product: product,
         quantity: quantity,
         createdAt: createdAt,
         updatedAt: updatedAt,
         deviceId: deviceId,
         device: device,
         rowVersion: rowVersion,
         syncStatus: syncStatus,
       );

  /// Returns a shallow copy of this [FreeSampleLine]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  FreeSampleLine copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? sampleId,
    Object? sample = _Undefined,
    _i1.UuidValue? productId,
    Object? product = _Undefined,
    int? quantity,
    DateTime? createdAt,
    DateTime? updatedAt,
    _i1.UuidValue? deviceId,
    Object? device = _Undefined,
    int? rowVersion,
    _i2.SyncStatus? syncStatus,
  }) {
    return FreeSampleLine(
      id: id is _i1.UuidValue? ? id : this.id,
      sampleId: sampleId ?? this.sampleId,
      sample: sample is _i3.FreeSample? ? sample : this.sample?.copyWith(),
      productId: productId ?? this.productId,
      product: product is _i4.Product? ? product : this.product?.copyWith(),
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      device: device is _i5.Device? ? device : this.device?.copyWith(),
      rowVersion: rowVersion ?? this.rowVersion,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}

class FreeSampleLineUpdateTable extends _i1.UpdateTable<FreeSampleLineTable> {
  FreeSampleLineUpdateTable(super.table);

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> sampleId(_i1.UuidValue value) =>
      _i1.ColumnValue(
        table.sampleId,
        value,
      );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> productId(
    _i1.UuidValue value,
  ) => _i1.ColumnValue(
    table.productId,
    value,
  );

  _i1.ColumnValue<int, int> quantity(int value) => _i1.ColumnValue(
    table.quantity,
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

class FreeSampleLineTable extends _i1.Table<_i1.UuidValue?> {
  FreeSampleLineTable({super.tableRelation})
    : super(tableName: 'free_sample_line') {
    updateTable = FreeSampleLineUpdateTable(this);
    sampleId = _i1.ColumnUuid(
      'sampleId',
      this,
    );
    productId = _i1.ColumnUuid(
      'productId',
      this,
    );
    quantity = _i1.ColumnInt(
      'quantity',
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

  late final FreeSampleLineUpdateTable updateTable;

  late final _i1.ColumnUuid sampleId;

  _i3.FreeSampleTable? _sample;

  late final _i1.ColumnUuid productId;

  _i4.ProductTable? _product;

  late final _i1.ColumnInt quantity;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  late final _i1.ColumnUuid deviceId;

  _i5.DeviceTable? _device;

  late final _i1.ColumnInt rowVersion;

  late final _i1.ColumnEnum<_i2.SyncStatus> syncStatus;

  _i3.FreeSampleTable get sample {
    if (_sample != null) return _sample!;
    _sample = _i1.createRelationTable(
      relationFieldName: 'sample',
      field: FreeSampleLine.t.sampleId,
      foreignField: _i3.FreeSample.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i3.FreeSampleTable(tableRelation: foreignTableRelation),
    );
    return _sample!;
  }

  _i4.ProductTable get product {
    if (_product != null) return _product!;
    _product = _i1.createRelationTable(
      relationFieldName: 'product',
      field: FreeSampleLine.t.productId,
      foreignField: _i4.Product.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i4.ProductTable(tableRelation: foreignTableRelation),
    );
    return _product!;
  }

  _i5.DeviceTable get device {
    if (_device != null) return _device!;
    _device = _i1.createRelationTable(
      relationFieldName: 'device',
      field: FreeSampleLine.t.deviceId,
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
    sampleId,
    productId,
    quantity,
    createdAt,
    updatedAt,
    deviceId,
    rowVersion,
    syncStatus,
  ];

  @override
  _i1.Table? getRelationTable(String relationField) {
    if (relationField == 'sample') {
      return sample;
    }
    if (relationField == 'product') {
      return product;
    }
    if (relationField == 'device') {
      return device;
    }
    return null;
  }
}

class FreeSampleLineInclude extends _i1.IncludeObject {
  FreeSampleLineInclude._({
    _i3.FreeSampleInclude? sample,
    _i4.ProductInclude? product,
    _i5.DeviceInclude? device,
  }) {
    _sample = sample;
    _product = product;
    _device = device;
  }

  _i3.FreeSampleInclude? _sample;

  _i4.ProductInclude? _product;

  _i5.DeviceInclude? _device;

  @override
  Map<String, _i1.Include?> get includes => {
    'sample': _sample,
    'product': _product,
    'device': _device,
  };

  @override
  _i1.Table<_i1.UuidValue?> get table => FreeSampleLine.t;
}

class FreeSampleLineIncludeList extends _i1.IncludeList {
  FreeSampleLineIncludeList._({
    _i1.WhereExpressionBuilder<FreeSampleLineTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(FreeSampleLine.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue?> get table => FreeSampleLine.t;
}

class FreeSampleLineRepository {
  const FreeSampleLineRepository._();

  final attachRow = const FreeSampleLineAttachRowRepository._();

  /// Returns a list of [FreeSampleLine]s matching the given query parameters.
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
  Future<List<FreeSampleLine>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<FreeSampleLineTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<FreeSampleLineTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<FreeSampleLineTable>? orderByList,
    _i1.Transaction? transaction,
    FreeSampleLineInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<FreeSampleLine>(
      where: where?.call(FreeSampleLine.t),
      orderBy: orderBy?.call(FreeSampleLine.t),
      orderByList: orderByList?.call(FreeSampleLine.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [FreeSampleLine] matching the given query parameters.
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
  Future<FreeSampleLine?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<FreeSampleLineTable>? where,
    int? offset,
    _i1.OrderByBuilder<FreeSampleLineTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<FreeSampleLineTable>? orderByList,
    _i1.Transaction? transaction,
    FreeSampleLineInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<FreeSampleLine>(
      where: where?.call(FreeSampleLine.t),
      orderBy: orderBy?.call(FreeSampleLine.t),
      orderByList: orderByList?.call(FreeSampleLine.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [FreeSampleLine] by its [id] or null if no such row exists.
  Future<FreeSampleLine?> findById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    FreeSampleLineInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<FreeSampleLine>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [FreeSampleLine]s in the list and returns the inserted rows.
  ///
  /// The returned [FreeSampleLine]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<FreeSampleLine>> insert(
    _i1.DatabaseSession session,
    List<FreeSampleLine> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<FreeSampleLine>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [FreeSampleLine] and returns the inserted row.
  ///
  /// The returned [FreeSampleLine] will have its `id` field set.
  Future<FreeSampleLine> insertRow(
    _i1.DatabaseSession session,
    FreeSampleLine row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<FreeSampleLine>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [FreeSampleLine]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<FreeSampleLine>> update(
    _i1.DatabaseSession session,
    List<FreeSampleLine> rows, {
    _i1.ColumnSelections<FreeSampleLineTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<FreeSampleLine>(
      rows,
      columns: columns?.call(FreeSampleLine.t),
      transaction: transaction,
    );
  }

  /// Updates a single [FreeSampleLine]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<FreeSampleLine> updateRow(
    _i1.DatabaseSession session,
    FreeSampleLine row, {
    _i1.ColumnSelections<FreeSampleLineTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<FreeSampleLine>(
      row,
      columns: columns?.call(FreeSampleLine.t),
      transaction: transaction,
    );
  }

  /// Updates a single [FreeSampleLine] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<FreeSampleLine?> updateById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<FreeSampleLineUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<FreeSampleLine>(
      id,
      columnValues: columnValues(FreeSampleLine.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [FreeSampleLine]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<FreeSampleLine>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<FreeSampleLineUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<FreeSampleLineTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<FreeSampleLineTable>? orderBy,
    _i1.OrderByListBuilder<FreeSampleLineTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<FreeSampleLine>(
      columnValues: columnValues(FreeSampleLine.t.updateTable),
      where: where(FreeSampleLine.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(FreeSampleLine.t),
      orderByList: orderByList?.call(FreeSampleLine.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [FreeSampleLine]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<FreeSampleLine>> delete(
    _i1.DatabaseSession session,
    List<FreeSampleLine> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<FreeSampleLine>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [FreeSampleLine].
  Future<FreeSampleLine> deleteRow(
    _i1.DatabaseSession session,
    FreeSampleLine row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<FreeSampleLine>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<FreeSampleLine>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<FreeSampleLineTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<FreeSampleLine>(
      where: where(FreeSampleLine.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<FreeSampleLineTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<FreeSampleLine>(
      where: where?.call(FreeSampleLine.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [FreeSampleLine] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<FreeSampleLineTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<FreeSampleLine>(
      where: where(FreeSampleLine.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class FreeSampleLineAttachRowRepository {
  const FreeSampleLineAttachRowRepository._();

  /// Creates a relation between the given [FreeSampleLine] and [FreeSample]
  /// by setting the [FreeSampleLine]'s foreign key `sampleId` to refer to the [FreeSample].
  Future<void> sample(
    _i1.DatabaseSession session,
    FreeSampleLine freeSampleLine,
    _i3.FreeSample sample, {
    _i1.Transaction? transaction,
  }) async {
    if (freeSampleLine.id == null) {
      throw ArgumentError.notNull('freeSampleLine.id');
    }
    if (sample.id == null) {
      throw ArgumentError.notNull('sample.id');
    }

    var $freeSampleLine = freeSampleLine.copyWith(sampleId: sample.id);
    await session.db.updateRow<FreeSampleLine>(
      $freeSampleLine,
      columns: [FreeSampleLine.t.sampleId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [FreeSampleLine] and [Product]
  /// by setting the [FreeSampleLine]'s foreign key `productId` to refer to the [Product].
  Future<void> product(
    _i1.DatabaseSession session,
    FreeSampleLine freeSampleLine,
    _i4.Product product, {
    _i1.Transaction? transaction,
  }) async {
    if (freeSampleLine.id == null) {
      throw ArgumentError.notNull('freeSampleLine.id');
    }
    if (product.id == null) {
      throw ArgumentError.notNull('product.id');
    }

    var $freeSampleLine = freeSampleLine.copyWith(productId: product.id);
    await session.db.updateRow<FreeSampleLine>(
      $freeSampleLine,
      columns: [FreeSampleLine.t.productId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [FreeSampleLine] and [Device]
  /// by setting the [FreeSampleLine]'s foreign key `deviceId` to refer to the [Device].
  Future<void> device(
    _i1.DatabaseSession session,
    FreeSampleLine freeSampleLine,
    _i5.Device device, {
    _i1.Transaction? transaction,
  }) async {
    if (freeSampleLine.id == null) {
      throw ArgumentError.notNull('freeSampleLine.id');
    }
    if (device.id == null) {
      throw ArgumentError.notNull('device.id');
    }

    var $freeSampleLine = freeSampleLine.copyWith(deviceId: device.id);
    await session.db.updateRow<FreeSampleLine>(
      $freeSampleLine,
      columns: [FreeSampleLine.t.deviceId],
      transaction: transaction,
    );
  }
}
