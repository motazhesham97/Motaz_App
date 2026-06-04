import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:motaz_app_client/motaz_app_client.dart' as server;
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart' hide Client;
import '../../../core/database/enums/enums.dart';
import '../../../core/logging/app_logger.dart';
import '../../settings/data/local_database_backup_service.dart';
import '../domain/field_classifier.dart';

class PullProcessor {
  PullProcessor({
    required AppDatabase db,
    required server.Client serverClient,
  }) : _db = db,
       _serverClient = serverClient;

  final AppDatabase _db;
  final server.Client _serverClient;
  static const int _defaultLimit = 100;
  static final _uuid = const Uuid();

  Future<void> pullAllEntityTypes() async {
    final detectRestoreConflicts =
        await LocalDatabaseBackupService.hasRestoreReconcileMarker();
    for (final entityType in _syncableEntityTypes) {
      await _pullForEntityType(
        entityType,
        forceFull: detectRestoreConflicts,
        detectRestoreConflicts: detectRestoreConflicts,
      );
    }
    if (detectRestoreConflicts) {
      await LocalDatabaseBackupService.clearRestoreReconcileMarker();
    }
  }

  Future<void> reconcileAllEntityTypes() async {
    AppLogger.sync.info('Starting full server reconciliation');
    for (final entityType in _syncableEntityTypes) {
      await _pullForEntityType(entityType, forceFull: true);
    }
  }

  Future<void> pullEntityType(ParentEntityType entityType) async {
    await _pullForEntityType(entityType);
  }

  Future<void> pullPendingConflicts() async {
    final conflicts = await _serverClient.sync.listPendingConflicts();
    AppLogger.sync.info('Pulled ${conflicts.length} pending conflicts');
    final serverConflictIds = <String>[];
    for (final conflict in conflicts) {
      final conflictId = conflict.id?.toString();
      if (conflictId != null) {
        serverConflictIds.add(conflictId);
      }
      await _upsertConflict(conflict);
    }
    await _closeLocalConflictsMissingFromServer(serverConflictIds);
  }

  Future<void> _pullForEntityType(
    ParentEntityType entityType, {
    bool forceFull = false,
    bool detectRestoreConflicts = false,
  }) async {
    final device = await _currentDevice();
    if (device == null) return;

    var currentCursor =
        await (_db.select(
                _db.syncCursor,
              )
              ..where((t) => t.entityType.equals(entityType.index))
              ..orderBy([(t) => OrderingTerm.desc(t.lastRowVersion)])
              ..limit(1))
            .getSingleOrNull();
    var sinceRowVersion = forceFull ? 0 : currentCursor?.lastRowVersion ?? 0;
    var hasMore = true;

    while (hasMore) {
      final request = server.PullRequest(
        entityType: entityType.name,
        sinceRowVersion: sinceRowVersion,
        deviceId: device.id,
        limit: _defaultLimit,
      );
      final response = await _serverClient.sync.pull(request);
      if (response.rows.isEmpty) {
        hasMore = false;
        break;
      }

      for (final rowJson in response.rows) {
        final row = jsonDecode(rowJson) as Map<String, dynamic>;
        await _upsertRow(
          entityType,
          row,
          detectRestoreConflicts: detectRestoreConflicts,
        );
      }
      sinceRowVersion = response.latestRowVersion;
      hasMore = response.hasMore;
      currentCursor = await _upsertCursor(
        entityType,
        sinceRowVersion,
        currentCursor,
      );
    }
  }

  Future<Device?> _currentDevice() async {
    final platform = Platform.isWindows
        ? DevicePlatform.WINDOWS
        : DevicePlatform.ANDROID;
    final hostName = Platform.localHostname;

    final byHost =
        await (_db.select(_db.devices)
              ..where(
                (tbl) =>
                    tbl.platform.equals(platform.index) &
                    tbl.deviceName.equals(hostName),
              )
              ..limit(1))
            .getSingleOrNull();
    if (byHost != null) return byHost;

    final byPlatform =
        await (_db.select(_db.devices)
              ..where(
                (tbl) =>
                    tbl.platform.equals(platform.index) &
                    tbl.deviceName.like('Synced device %').not(),
              )
              ..limit(1))
            .getSingleOrNull();
    if (byPlatform != null) return byPlatform;

    return (_db.select(_db.devices)..limit(1)).getSingleOrNull();
  }

  Future<SyncCursorData> _upsertCursor(
    ParentEntityType entityType,
    int lastRowVersion,
    SyncCursorData? existingCursor,
  ) async {
    final now = DateTime.now();
    if (existingCursor == null) {
      final id = _uuid.v4();
      await _db
          .into(_db.syncCursor)
          .insert(
            SyncCursorCompanion.insert(
              id: id,
              entityType: entityType,
              lastRowVersion: Value(lastRowVersion),
              lastPulledAt: Value(now),
              updatedAt: now,
            ),
          );
      return (_db.select(
        _db.syncCursor,
      )..where((t) => t.id.equals(id))).getSingle();
    }

    await (_db.update(
      _db.syncCursor,
    )..where((t) => t.id.equals(existingCursor.id))).write(
      SyncCursorCompanion(
        lastRowVersion: Value(lastRowVersion),
        lastPulledAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    return existingCursor.copyWith(
      lastRowVersion: lastRowVersion,
      lastPulledAt: Value(now),
      updatedAt: now,
    );
  }

  Future<void> _upsertRow(
    ParentEntityType entityType,
    Map<String, dynamic> row, {
    bool detectRestoreConflicts = false,
  }) async {
    final tableName = _entityTableName[entityType];
    if (tableName == null) return;
    final id = row['id'];
    if (id == null) return;
    final sqlValues = <String, dynamic>{};
    for (final entry in row.entries) {
      final snakeKey = _camelToSnake(entry.key);
      var value = entry.value;
      if (value is bool) {
        value = value ? 1 : 0;
      } else if (value is String && _isDateTimeColumn(snakeKey)) {
        value = DateTime.parse(value).millisecondsSinceEpoch ~/ 1000;
      } else if (value is String) {
        value = _enumIndexValue(snakeKey, value) ?? value;
      }
      sqlValues[snakeKey] = value;
    }
    _ensureLocalDocumentReference(entityType, id.toString(), sqlValues);
    await _ensureReferencedDevice(sqlValues);
    sqlValues['sync_status'] = SyncStatus.SYNCED.index;
    final existing = await _db
        .customSelect(
          'SELECT * FROM "$tableName" WHERE id = ?',
          variables: [Variable.withString(id)],
        )
        .getSingleOrNull();
    if (existing == null) {
      if (await _hasPendingLocalConflict(entityType, id.toString())) {
        return;
      }
      if (detectRestoreConflicts) {
        await _createRestorePullConflict(
          entityType: entityType,
          entityId: id.toString(),
          localPayload: {'id': id.toString(), '_missingLocally': true},
          remotePayload: row,
        );
        return;
      }
      final columns = sqlValues.keys.map((c) => '"$c"').join(', ');
      final placeholders = List.filled(sqlValues.length, '?').join(', ');
      await _db.customStatement(
        'INSERT INTO "$tableName" ($columns) VALUES ($placeholders)',
        sqlValues.values.toList(),
      );
      _notifyTableChanged(tableName, UpdateKind.insert);
    } else {
      final localSyncStatus = existing.data['sync_status'];
      if (detectRestoreConflicts &&
          localSyncStatus != SyncStatus.CONFLICT.index &&
          _hasRestoreConflictDifference(entityType, existing.data, sqlValues)) {
        await _createRestorePullConflict(
          entityType: entityType,
          entityId: id.toString(),
          localPayload: _sqlRowToPayload(existing.data),
          remotePayload: row,
        );
        await _markEntityConflict(tableName, id.toString());
        return;
      }
      if (localSyncStatus == SyncStatus.PENDING.index ||
          localSyncStatus == SyncStatus.FAILED.index) {
        return;
      }
      if (localSyncStatus == SyncStatus.CONFLICT.index) {
        final hasPendingConflict = await _hasPendingLocalConflict(
          entityType,
          id.toString(),
        );
        if (hasPendingConflict) return;
      }
      final setClauses = sqlValues.entries
          .where((e) => e.key != 'id')
          .map((e) => '"${e.key}" = ?')
          .join(', ');
      final updateValues = sqlValues.entries
          .where((e) => e.key != 'id')
          .map((e) => e.value)
          .toList();
      await _db.customStatement(
        'UPDATE "$tableName" SET $setClauses WHERE "id" = ?',
        [...updateValues, id],
      );
      _notifyTableChanged(tableName, UpdateKind.update);
    }
  }

  Future<void> _createRestorePullConflict({
    required ParentEntityType entityType,
    required String entityId,
    required Map<String, dynamic> localPayload,
    required Map<String, dynamic> remotePayload,
  }) async {
    if (await _hasPendingLocalConflict(entityType, entityId)) return;
    final device = await _currentDevice();
    if (device == null) return;
    final now = DateTime.now();
    await _db
        .into(_db.conflictLogs)
        .insert(
          ConflictLogsCompanion.insert(
            id: _uuid.v4(),
            entityType: entityType,
            entityId: entityId,
            localPayload: jsonEncode(localPayload),
            remotePayload: jsonEncode(remotePayload),
            conflictType: 'RESTORE_PULL_CONFLICT',
            resolutionStatus: Value(ConflictStatus.PENDING),
            createdAt: now,
            deviceId: device.id,
          ),
        );
  }

  Future<void> _markEntityConflict(String tableName, String entityId) async {
    await _db.customStatement(
      'UPDATE "$tableName" SET sync_status = ? WHERE id = ?',
      [SyncStatus.CONFLICT.index, entityId],
    );
    _notifyTableChanged(tableName, UpdateKind.update);
  }

  void _notifyTableChanged(String tableName, UpdateKind kind) {
    _db.notifyUpdates({TableUpdate(tableName, kind: kind)});
  }

  bool _hasRestoreConflictDifference(
    ParentEntityType entityType,
    Map<String, dynamic> localRow,
    Map<String, dynamic> remoteSqlValues,
  ) {
    final fields = FieldClassifier.getConflictRequiredFields(entityType.name);
    if (fields.isEmpty) return false;
    for (final field in fields) {
      final column = _camelToSnake(field);
      if (_normalizeSqlValue(localRow[column]) !=
          _normalizeSqlValue(remoteSqlValues[column])) {
        return true;
      }
    }
    return false;
  }

  Map<String, dynamic> _sqlRowToPayload(Map<String, dynamic> row) {
    final payload = <String, dynamic>{};
    for (final entry in row.entries) {
      final key = entry.key;
      if (key == 'sync_status') continue;
      final camelKey = _snakeToCamel(key);
      var value = entry.value;
      if (value is int && _isDateTimeColumn(key)) {
        value = DateTime.fromMillisecondsSinceEpoch(
          value * 1000,
        ).toIso8601String();
      }
      payload[camelKey] = value;
    }
    return payload;
  }

  Object? _normalizeSqlValue(Object? value) {
    if (value is DateTime) return value.millisecondsSinceEpoch ~/ 1000;
    return value;
  }

  Future<bool> _hasPendingLocalConflict(
    ParentEntityType entityType,
    String entityId,
  ) async {
    final existing =
        await (_db.select(_db.conflictLogs)
              ..where(
                (tbl) =>
                    tbl.entityType.equals(entityType.index) &
                    tbl.entityId.equals(entityId) &
                    tbl.resolutionStatus.equals(ConflictStatus.PENDING.index),
              )
              ..limit(1))
            .getSingleOrNull();
    return existing != null;
  }

  Future<void> _ensureReferencedDevice(Map<String, dynamic> sqlValues) async {
    final deviceId = sqlValues['device_id'];
    if (deviceId is! String || deviceId.length != 36) return;

    final existing = await (_db.select(
      _db.devices,
    )..where((tbl) => tbl.id.equals(deviceId))).getSingleOrNull();
    if (existing != null) return;

    final now = DateTime.now();
    final deviceCode = await _uniqueDeviceCodeFor(deviceId);
    await _db
        .into(_db.devices)
        .insert(
          DevicesCompanion(
            id: Value(deviceId),
            deviceName: Value('Synced device $deviceCode'),
            platform: const Value(DevicePlatform.WINDOWS),
            deviceCode: Value(deviceCode),
            createdAt: Value(now),
            lastActiveAt: Value(now),
          ),
        );
  }

  Future<void> _upsertConflict(server.ConflictLog conflict) async {
    final conflictId = conflict.id?.toString();
    if (conflictId == null) return;

    await _ensureServerDevice(
      conflict.device,
      fallbackDeviceId: conflict.deviceId.toString(),
    );

    final entityType = _serverParentEntityType(conflict.entityType.name);
    final resolutionStatus = _serverConflictStatus(
      conflict.resolutionStatus.name,
    );

    final existing = await (_db.select(
      _db.conflictLogs,
    )..where((tbl) => tbl.id.equals(conflictId))).getSingleOrNull();

    final companion = ConflictLogsCompanion(
      id: Value(conflictId),
      entityType: Value(entityType),
      entityId: Value(conflict.entityId.toString()),
      localPayload: Value(conflict.localPayload),
      remotePayload: Value(conflict.remotePayload),
      conflictType: Value(conflict.conflictType),
      resolutionStatus: Value(resolutionStatus),
      resolvedAt: Value(conflict.resolvedAt),
      resolutionData: Value(conflict.resolutionData),
      createdAt: Value(conflict.createdAt),
      deviceId: Value(conflict.deviceId.toString()),
    );

    if (existing == null) {
      await _db.into(_db.conflictLogs).insert(companion);
    } else {
      await (_db.update(
        _db.conflictLogs,
      )..where((tbl) => tbl.id.equals(conflictId))).write(companion);
    }
  }

  Future<void> _closeLocalConflictsMissingFromServer(
    List<String> serverConflictIds,
  ) async {
    if (serverConflictIds.isEmpty) {
      await _db.customStatement(
        'UPDATE conflict_logs SET resolution_status = ?, resolved_at = ? '
        'WHERE resolution_status = ? AND conflict_type != ?',
        [
          ConflictStatus.RESOLVED.index,
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          ConflictStatus.PENDING.index,
          'RESTORE_PULL_CONFLICT',
        ],
      );
      _notifyTableChanged('conflict_logs', UpdateKind.update);
      return;
    }

    final placeholders = List.filled(serverConflictIds.length, '?').join(', ');
    await _db.customStatement(
      'UPDATE conflict_logs SET resolution_status = ?, resolved_at = ? '
      'WHERE resolution_status = ? AND conflict_type != ? '
      'AND id NOT IN ($placeholders)',
      [
        ConflictStatus.RESOLVED.index,
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ConflictStatus.PENDING.index,
        'RESTORE_PULL_CONFLICT',
        ...serverConflictIds,
      ],
    );
    _notifyTableChanged('conflict_logs', UpdateKind.update);
  }

  Future<void> _ensureServerDevice(
    server.Device? device, {
    required String fallbackDeviceId,
  }) async {
    final existing = await (_db.select(
      _db.devices,
    )..where((tbl) => tbl.id.equals(fallbackDeviceId))).getSingleOrNull();
    if (existing != null) return;

    if (device == null) {
      final now = DateTime.now();
      final deviceCode = await _uniqueDeviceCodeFor(fallbackDeviceId);
      await _db
          .into(_db.devices)
          .insert(
            DevicesCompanion(
              id: Value(fallbackDeviceId),
              deviceName: Value('Synced device $deviceCode'),
              platform: const Value(DevicePlatform.WINDOWS),
              deviceCode: Value(deviceCode),
              createdAt: Value(now),
              lastActiveAt: Value(now),
            ),
          );
      return;
    }

    var deviceCode = device.deviceCode;
    final codeOwner = await (_db.select(
      _db.devices,
    )..where((tbl) => tbl.deviceCode.equals(deviceCode))).getSingleOrNull();
    if (codeOwner != null && codeOwner.id != fallbackDeviceId) {
      deviceCode = await _uniqueDeviceCodeFor(fallbackDeviceId);
    }

    await _db
        .into(_db.devices)
        .insert(
          DevicesCompanion(
            id: Value(fallbackDeviceId),
            deviceName: Value(device.deviceName),
            platform: Value(_serverDevicePlatform(device.platform.name)),
            deviceCode: Value(deviceCode),
            nextInvoiceSequence: Value(device.nextInvoiceSequence),
            nextReceiptSequence: Value(device.nextReceiptSequence),
            nextReturnSequence: Value(device.nextReturnSequence),
            nextSampleSequence: Value(device.nextSampleSequence),
            createdAt: Value(device.createdAt),
            lastActiveAt: Value(device.lastActiveAt),
          ),
        );
  }

  ParentEntityType _serverParentEntityType(String name) {
    return ParentEntityType.values.firstWhere((value) => value.name == name);
  }

  ConflictStatus _serverConflictStatus(String name) {
    return ConflictStatus.values.firstWhere((value) => value.name == name);
  }

  DevicePlatform _serverDevicePlatform(String name) {
    return DevicePlatform.values.firstWhere(
      (value) => value.name == name,
      orElse: () => DevicePlatform.WINDOWS,
    );
  }

  Future<String> _uniqueDeviceCodeFor(String deviceId) async {
    final compact = deviceId.replaceAll('-', '').toUpperCase();
    final candidates = <String>[];
    for (var i = 0; i + 4 <= compact.length; i += 4) {
      candidates.add(compact.substring(i, i + 4));
    }
    for (var i = 1; i <= 9999; i++) {
      candidates.add(i.toString().padLeft(4, '0'));
    }

    for (final candidate in candidates) {
      final existing = await (_db.select(
        _db.devices,
      )..where((tbl) => tbl.deviceCode.equals(candidate))).getSingleOrNull();
      if (existing == null || existing.id == deviceId) {
        return candidate;
      }
    }
    return compact.substring(0, 4);
  }

  String _camelToSnake(String input) {
    return input.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
  }

  String _snakeToCamel(String input) {
    return input.replaceAllMapped(
      RegExp(r'_([a-z])'),
      (match) => match.group(1)!.toUpperCase(),
    );
  }

  bool _isDateTimeColumn(String columnName) {
    return columnName == 'created_at' ||
        columnName == 'updated_at' ||
        columnName == 'last_active_at' ||
        columnName == 'last_pulled_at' ||
        columnName == 'resolved_at' ||
        columnName.endsWith('_date');
  }

  int? _enumIndexValue(String columnName, String value) {
    final values = _enumValues[columnName];
    if (values == null) return null;
    final index = values.indexOf(value);
    return index < 0 ? null : index;
  }

  void _ensureLocalDocumentReference(
    ParentEntityType entityType,
    String entityId,
    Map<String, dynamic> sqlValues,
  ) {
    if (entityType != ParentEntityType.RECEIPT &&
        entityType != ParentEntityType.SALES_RETURN &&
        entityType != ParentEntityType.FREE_SAMPLE) {
      return;
    }
    final existing = sqlValues['local_ref'];
    if (existing is String && existing.trim().isNotEmpty) return;

    final compactId = entityId.replaceAll('-', '');
    final suffix = compactId.length <= 8
        ? compactId
        : compactId.substring(0, 8);
    if (entityType == ParentEntityType.RECEIPT) {
      sqlValues['local_ref'] = 'REC-LEG-$suffix';
    } else if (entityType == ParentEntityType.SALES_RETURN) {
      sqlValues['local_ref'] = 'RET-LEG-$suffix';
    } else {
      sqlValues['local_ref'] = 'SAM-LEG-$suffix';
    }
  }

  static const List<ParentEntityType> _syncableEntityTypes = [
    ParentEntityType.PRODUCT,
    ParentEntityType.CLIENT,
    ParentEntityType.SALES_INVOICE,
    ParentEntityType.RECEIPT,
    ParentEntityType.EXPENSE,
    ParentEntityType.SALES_RETURN,
    ParentEntityType.ATTACHMENT_METADATA,
    ParentEntityType.MONTHLY_DISTRIBUTION,
    ParentEntityType.PARTY_ADJUSTMENT,
    ParentEntityType.BENEFICIARY,
    ParentEntityType.FREE_SAMPLE,
    ParentEntityType.FREE_SAMPLE_LINE,
  ];

  static const Map<ParentEntityType, String> _entityTableName = {
    ParentEntityType.PRODUCT: 'products',
    ParentEntityType.CLIENT: 'clients',
    ParentEntityType.SALES_INVOICE: 'sales_invoices',
    ParentEntityType.RECEIPT: 'receipts',
    ParentEntityType.EXPENSE: 'expenses',
    ParentEntityType.SALES_RETURN: 'sales_returns',
    ParentEntityType.ATTACHMENT_METADATA: 'attachment_metadata',
    ParentEntityType.MONTHLY_DISTRIBUTION: 'monthly_distributions',
    ParentEntityType.PARTY_ADJUSTMENT: 'party_adjustments',
    ParentEntityType.BENEFICIARY: 'beneficiaries',
    ParentEntityType.FREE_SAMPLE: 'free_samples',
    ParentEntityType.FREE_SAMPLE_LINE: 'free_sample_lines',
  };

  static const Map<String, List<String>> _enumValues = {
    'category': [
      'OWNER_DRAW',
      'PARTNER_DRAW',
      'MARGIN_DRAW',
      'OPERATIONAL',
      'PRODUCTION',
    ],
    'party': ['OWNER', 'PARTNER', 'MARGIN'],
    'parent_entity_type': [
      'SALES_INVOICE',
      'SALES_INVOICE_LINE',
      'RECEIPT',
      'RECEIPT_ALLOCATION',
      'PRODUCT',
      'CLIENT',
      'EXPENSE',
      'SALES_RETURN',
      'SALES_RETURN_LINE',
      'ATTACHMENT_METADATA',
      'MONTHLY_DISTRIBUTION',
      'PARTY_ADJUSTMENT',
      'BENEFICIARY',
      'FREE_SAMPLE',
      'FREE_SAMPLE_LINE',
    ],
    'receipt_type': ['INVOICE_LINKED', 'GENERAL'],
    'status': ['ACTIVE', 'VOIDED'],
  };
}
