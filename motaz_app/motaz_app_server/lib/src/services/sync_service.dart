// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../generated/audit_event.dart';
import '../generated/conflict_log.dart';
import '../generated/device.dart';
import '../generated/enums/audit_operation.dart';
import '../generated/enums/conflict_status.dart';
import '../generated/enums/parent_entity_type.dart';

class SyncService {
  static ParentEntityType? _parseParentEntityType(String name) {
    for (final e in ParentEntityType.values) {
      if (e.name == name) return e;
    }
    return null;
  }

  static AuditOperation? _parseAuditOperation(String name) {
    for (final e in AuditOperation.values) {
      if (e.name == name) return e;
    }
    return null;
  }

  static bool supportsEntityType(String entityType) {
    return _entityTableMap.containsKey(entityType);
  }

  static Future<bool> validateDeviceIdentity(
    Session session,
    String deviceId,
  ) async {
    final uuid = UuidValue.fromString(deviceId);
    final device = await Device.db.findById(session, uuid);
    return device != null;
  }

  static Future<int?> checkRowVersion(
    Session session,
    String entityType,
    String entityId,
  ) async {
    final tableName = _entityTableName(entityType);
    if (tableName == null) return null;
    if (!_hasRowVersion(entityType)) return null;

    final rows = await session.db.unsafeQuery(
      'SELECT "rowVersion" FROM "' + tableName + '" WHERE "id" = @entityId',
      parameters: QueryParameters.named({'entityId': entityId}),
    );
    if (rows.isEmpty) return null;
    return rows.first.first as int?;
  }

  static Future<Map<String, dynamic>?> loadEntityRow(
    Session session,
    String entityType,
    String entityId,
  ) async {
    final tableName = _entityTableName(entityType);
    if (tableName == null) return null;

    final rows = await session.db.unsafeQuery(
      'SELECT * FROM "' + tableName + '" WHERE "id" = @entityId',
      parameters: QueryParameters.named({'entityId': entityId}),
    );
    if (rows.isEmpty) return null;

    final columnNames = await _getColumnNames(session, tableName);
    final row = rows.first;
    final Map<String, dynamic> result = {};
    for (int i = 0; i < columnNames.length; i++) {
      result[columnNames[i]] = row[i];
    }
    return result;
  }

  static Set<String> classifyChangedFields(
    String entityType,
    Map<String, dynamic> localPayload,
    Map<String, dynamic> remotePayload,
  ) {
    final changedFields = <String>{};
    for (final key in localPayload.keys) {
      if (key == 'id' || key == 'rowVersion' || key == 'syncStatus') continue;
      if (_canonicalCompareValue(key, localPayload[key]) !=
          _canonicalCompareValue(key, remotePayload[key])) {
        changedFields.add(key);
      }
    }
    return changedFields;
  }

  static bool hasConflictRequiredFieldChanges(
    String entityType,
    Set<String> changedFields,
  ) {
    final conflictFields = _conflictRequiredFields[entityType] ?? {};
    return changedFields.intersection(conflictFields).isNotEmpty;
  }

  static bool applyVoidWinsRule(Object? localStatus, Object? remoteStatus) {
    final localVoided =
        _canonicalCompareValue('status', localStatus) == 'VOIDED';
    final remoteVoided =
        _canonicalCompareValue('status', remoteStatus) == 'VOIDED';
    return localVoided || remoteVoided;
  }

  static bool isVoidedStatus(Object? status) {
    return _canonicalCompareValue('status', status) == 'VOIDED';
  }

  static Future<Map<String, dynamic>> applyAutoMerge(
    Session session,
    String entityType,
    String entityId,
    Map<String, dynamic> incomingPayload,
  ) async {
    final tableName = _entityTableName(entityType);
    if (tableName == null) {
      throw ArgumentError('Unknown entity type: ' + entityType);
    }

    final currentRow = await loadEntityRow(session, entityType, entityId);
    if (currentRow == null) {
      throw StateError('Entity not found: ' + entityType + '/' + entityId);
    }

    final autoFields = _autoMergeFields[entityType] ?? {};
    final merged = Map<String, dynamic>.from(currentRow);

    for (final field in autoFields) {
      if (incomingPayload.containsKey(field)) {
        merged[field] = incomingPayload[field];
      }
    }

    final now = DateTime.now().toUtc();
    merged['updatedAt'] = now.toIso8601String();

    return merged;
  }

  static Future<String> emitConflict(
    Session session,
    String entityType,
    String entityId,
    String localPayload,
    String remotePayload,
    String conflictType,
    String deviceId,
  ) async {
    final parsed = _parseParentEntityType(entityType);
    if (parsed == null) {
      throw ArgumentError('Unknown entity type: ' + entityType);
    }
    final entityUuid = UuidValue.fromString(entityId);
    final deviceUuid = UuidValue.fromString(deviceId);

    final existingConflicts = await ConflictLog.db.find(
      session,
      where: (t) =>
          t.entityType.equals(parsed) &
          t.entityId.equals(entityUuid) &
          t.resolutionStatus.equals(ConflictStatus.PENDING),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
    );

    if (existingConflicts.isNotEmpty) {
      final latest = existingConflicts.first;
      final updated = await ConflictLog.db.updateRow(
        session,
        latest.copyWith(
          localPayload: localPayload,
          remotePayload: remotePayload,
          conflictType: conflictType,
          createdAt: DateTime.now().toUtc(),
          deviceId: deviceUuid,
        ),
      );

      for (final stale in existingConflicts.skip(1)) {
        await ConflictLog.db.updateRow(
          session,
          stale.copyWith(
            resolutionStatus: ConflictStatus.RESOLVED,
            resolvedAt: DateTime.now().toUtc(),
            resolutionData: 'superseded',
          ),
        );
      }

      return updated.id.toString();
    }

    final conflict = ConflictLog(
      entityType: parsed,
      entityId: entityUuid,
      localPayload: localPayload,
      remotePayload: remotePayload,
      conflictType: conflictType,
      resolutionStatus: ConflictStatus.PENDING,
      createdAt: DateTime.now().toUtc(),
      deviceId: deviceUuid,
    );

    final inserted = await ConflictLog.db.insertRow(session, conflict);
    return inserted.id.toString();
  }

  static Future<int> acceptMutation(
    Session session,
    String entityType,
    String entityId,
    Map<String, dynamic> payload,
    String operation,
    String deviceId,
  ) async {
    final tableName = _entityTableName(entityType);
    if (tableName == null) {
      throw ArgumentError('Unknown entity type: ' + entityType);
    }

    final allowedColumns = _columnAllowlist[entityType];
    if (allowedColumns == null) {
      throw ArgumentError('No column allowlist for entity type: ' + entityType);
    }

    final now = DateTime.now().toUtc();
    final hasRowVersion = _hasRowVersion(entityType);

    final existingRow = await loadEntityRow(session, entityType, entityId);
    _ensureDocumentReference(entityType, entityId, payload);
    await _ensureOfficialNumber(session, entityType, payload, existingRow);
    await _ensureServerSideReferences(
      session,
      entityType,
      payload,
      now,
    );

    int currentVersion = 0;
    if (hasRowVersion &&
        existingRow != null &&
        existingRow['rowVersion'] != null) {
      currentVersion = existingRow['rowVersion'] as int;
    }
    final newVersion = currentVersion + 1;

    final setClauses = <String>[];
    final params = <String, dynamic>{};
    params['entityId'] = entityId;

    for (final entry in payload.entries) {
      if (entry.key == 'id' ||
          entry.key == 'rowVersion' ||
          entry.key == 'syncStatus' ||
          entry.key == 'createdAt' ||
          entry.key == 'updatedAt') {
        continue;
      }
      if (entityType == 'PRODUCT' && entry.key == 'costPrice') {
        continue;
      }
      if (!allowedColumns.contains(entry.key)) {
        throw ArgumentError(
          'Column "' +
              entry.key +
              '" not allowed for entity type ' +
              entityType,
        );
      }
      setClauses.add('"' + entry.key + '" = @' + entry.key);
      params[entry.key] = _normalizePayloadValue(entry.key, entry.value);
    }
    if (hasRowVersion) {
      setClauses.add('"rowVersion" = @rowVersion');
      params['rowVersion'] = newVersion;
      setClauses.add('"syncStatus" = @syncStatus');
      params['syncStatus'] = 'SYNCED';
    }
    setClauses.add('"updatedAt" = @updatedAt');
    params['updatedAt'] = now.toIso8601String();

    if (existingRow != null) {
      await session.db.unsafeExecute(
        'UPDATE "' +
            tableName +
            '" SET ' +
            setClauses.join(', ') +
            ' WHERE "id" = @entityId',
        parameters: QueryParameters.named(params),
      );
    } else {
      final columns = payload.keys
          .where(
            (k) =>
                k != 'id' &&
                k != 'rowVersion' &&
                k != 'syncStatus' &&
                k != 'createdAt' &&
                k != 'updatedAt' &&
                !(entityType == 'PRODUCT' && k == 'costPrice'),
          )
          .toList();
      final insertCols = [
        '"id"',
        ...columns.map((c) => '"' + c + '"'),
        '"createdAt"',
        '"updatedAt"',
      ];
      final insertVals = [
        '@entityId',
        ...columns.map((c) => '@' + c),
        '@createdAt',
        '@updatedAt',
      ];
      if (hasRowVersion) {
        insertCols.insert(insertCols.length - 1, '"rowVersion"');
        insertVals.insert(insertVals.length - 1, '@rowVersion');
        insertCols.insert(insertCols.length - 1, '"syncStatus"');
        insertVals.insert(insertVals.length - 1, '@syncStatus');
      }
      params['createdAt'] = now.toIso8601String();
      await session.db.unsafeExecute(
        'INSERT INTO "' +
            tableName +
            '" (' +
            insertCols.join(', ') +
            ') VALUES (' +
            insertVals.join(', ') +
            ')',
        parameters: QueryParameters.named(params),
      );
    }

    final parsedEntityType = _parseParentEntityType(entityType);
    final parsedOperation = _parseAuditOperation(operation);
    if (parsedEntityType == null || parsedOperation == null) {
      throw ArgumentError(
        'Invalid entity type (' +
            entityType +
            ') or operation (' +
            operation +
            ')',
      );
    }

    final auditEvent = AuditEvent(
      entityType: parsedEntityType,
      entityId: UuidValue.fromString(entityId),
      operation: parsedOperation,
      diffData: jsonEncode(_jsonSafe(payload)),
      deviceId: UuidValue.fromString(deviceId),
      createdAt: now,
    );
    await AuditEvent.db.insertRow(session, auditEvent);

    return newVersion;
  }

  static Future<void> _ensureServerSideReferences(
    Session session,
    String entityType,
    Map<String, dynamic> payload,
    DateTime now,
  ) async {
    if (entityType == 'FREE_SAMPLE') {
      await _ensureBeneficiaryForSample(
        session,
        payload['beneficiaryId']?.toString(),
        now,
      );
    }
  }

  static Future<void> _ensureBeneficiaryForSample(
    Session session,
    String? beneficiaryId,
    DateTime now,
  ) async {
    if (beneficiaryId == null || beneficiaryId.isEmpty) return;

    final existingBeneficiary = await session.db.unsafeQuery(
      'SELECT "id" FROM "beneficiary" WHERE "id" = @beneficiaryId LIMIT 1',
      parameters: QueryParameters.named({'beneficiaryId': beneficiaryId}),
    );
    if (existingBeneficiary.isNotEmpty) return;

    final existingClient = await session.db.unsafeQuery(
      'SELECT "id" FROM "client" WHERE "id" = @beneficiaryId LIMIT 1',
      parameters: QueryParameters.named({'beneficiaryId': beneficiaryId}),
    );
    if (existingClient.isEmpty) {
      throw StateError(
        'Missing beneficiary for free sample: ' + beneficiaryId,
      );
    }

    final versionRows = await session.db.unsafeQuery(
      'SELECT COALESCE(MAX("rowVersion"), 0) + 1 FROM "beneficiary"',
    );
    final rowVersion = (versionRows.first.first as num).toInt();

    await session.db.unsafeExecute(
      'INSERT INTO "beneficiary" ('
      '"id", "displayName", "phone", "sourceClientId", "isActive", '
      '"createdAt", "updatedAt", "deviceId", "rowVersion", "syncStatus"'
      ') '
      'SELECT '
      '"id", "displayName", "phone", "id", "isActive", '
      '"createdAt", @updatedAt, "deviceId", '
      '@rowVersion, \'SYNCED\' '
      'FROM "client" '
      'WHERE "id" = @beneficiaryId '
      'ON CONFLICT ("id") DO NOTHING',
      parameters: QueryParameters.named({
        'beneficiaryId': beneficiaryId,
        'updatedAt': now.toIso8601String(),
        'rowVersion': rowVersion,
      }),
    );
  }

  static Future<List<String>> queryChangedRows(
    Session session,
    String entityType,
    int sinceRowVersion,
    int limit,
  ) async {
    final tableName = _entityTableName(entityType);
    if (tableName == null) return [];
    if (!_hasRowVersion(entityType)) return [];
    await _backfillOfficialNumbers(session, entityType, tableName);

    final rows = await session.db.unsafeQuery(
      'SELECT row_to_json(t) FROM "' +
          tableName +
          '" t WHERE "rowVersion" > @sinceRowVersion ORDER BY "rowVersion" ASC LIMIT @limit',
      parameters: QueryParameters.named({
        'sinceRowVersion': sinceRowVersion,
        'limit': limit,
      }),
    );
    return rows.map((row) {
      final value = row.first;
      if (value is String) return value;
      return jsonEncode(value);
    }).toList();
  }

  static Future<int> getLatestRowVersion(
    Session session,
    String entityType,
  ) async {
    final tableName = _entityTableName(entityType);
    if (tableName == null) return 0;
    if (!_hasRowVersion(entityType)) return 0;

    final rows = await session.db.unsafeQuery(
      'SELECT COALESCE(MAX("rowVersion"), 0) FROM "' + tableName + '"',
    );
    if (rows.isEmpty) return 0;
    return rows.first.first as int;
  }

  static int latestRowVersionFromRows(
    List<String> rows,
    int fallbackRowVersion,
  ) {
    var latest = fallbackRowVersion;
    for (final rowJson in rows) {
      final row = jsonDecode(rowJson) as Map<String, dynamic>;
      final value = row['rowVersion'];
      if (value is int && value > latest) {
        latest = value;
      } else if (value is num && value.toInt() > latest) {
        latest = value.toInt();
      }
    }
    return latest;
  }

  static Future<int> countRowsAboveVersion(
    Session session,
    String entityType,
    int sinceRowVersion,
  ) async {
    final tableName = _entityTableName(entityType);
    if (tableName == null) return 0;
    if (!_hasRowVersion(entityType)) return 0;

    final rows = await session.db.unsafeQuery(
      'SELECT COUNT(*) FROM "' +
          tableName +
          '" WHERE "rowVersion" > @sinceRowVersion',
      parameters: QueryParameters.named({'sinceRowVersion': sinceRowVersion}),
    );
    if (rows.isEmpty) return 0;
    return (rows.first.first as num).toInt();
  }

  static Future<List<ConflictLog>> getPendingConflicts(
    Session session,
    String entityType,
    String deviceId,
  ) async {
    final entityTypeEnum = _parseParentEntityType(entityType);
    if (entityTypeEnum == null) {
      throw ArgumentError('Unknown entity type: ' + entityType);
    }
    final deviceUuid = UuidValue.fromString(deviceId);
    return ConflictLog.db.find(
      session,
      where: (t) =>
          t.entityType.equals(entityTypeEnum) &
          t.deviceId.equals(deviceUuid) &
          t.resolutionStatus.equals(ConflictStatus.PENDING),
    );
  }

  static String? _entityTableName(String entityType) {
    return _entityTableMap[entityType];
  }

  static void _ensureDocumentReference(
    String entityType,
    String entityId,
    Map<String, dynamic> payload,
  ) {
    if (payload.containsKey('localRef')) return;

    final safeId = entityId.replaceAll('-', '');
    final suffix = safeId.length <= 8 ? safeId : safeId.substring(0, 8);
    if (entityType == 'RECEIPT') {
      payload['localRef'] = 'REC-LEG-' + suffix;
    } else if (entityType == 'SALES_RETURN') {
      payload['localRef'] = 'RET-LEG-' + suffix;
    } else if (entityType == 'FREE_SAMPLE') {
      payload['localRef'] = 'SAM-LEG-' + suffix;
    }
  }

  static Future<void> _ensureOfficialNumber(
    Session session,
    String entityType,
    Map<String, dynamic> payload,
    Map<String, dynamic>? existingRow,
  ) async {
    if (!_officialNumberedEntityTypes.contains(entityType)) return;

    final existingOfficial = existingRow?['officialNo']?.toString().trim();
    if (existingOfficial != null && existingOfficial.isNotEmpty) {
      payload['officialNo'] = existingOfficial;
      return;
    }

    final incomingOfficial = payload['officialNo']?.toString().trim();
    if (incomingOfficial != null && incomingOfficial.isNotEmpty) return;

    final tableName = _entityTableName(entityType);
    if (tableName == null) return;

    payload['officialNo'] = (await _nextOfficialNumber(
      session,
      tableName,
    )).toString();
  }

  static Future<int> _nextOfficialNumber(
    Session session,
    String tableName,
  ) async {
    final rows = await session.db.unsafeQuery(
      'SELECT COALESCE(MAX(CAST("officialNo" AS INTEGER)), 0) + 1 '
              'FROM "' +
          tableName +
          '" WHERE "officialNo" ~ ' +
          r"'^[0-9]+$'",
    );
    return (rows.first.first as num).toInt();
  }

  static Future<void> _backfillOfficialNumbers(
    Session session,
    String entityType,
    String tableName,
  ) async {
    if (!_officialNumberedEntityTypes.contains(entityType)) return;

    await session.db.unsafeExecute(
      'WITH base AS ('
              '  SELECT COALESCE(MAX(CAST("officialNo" AS INTEGER)), 0) AS max_no '
              '  FROM "' +
          tableName +
          '" WHERE "officialNo" ~ ' +
          r"'^[0-9]+$'" +
          '), version_base AS ('
              '  SELECT COALESCE(MAX("rowVersion"), 0) AS max_version '
              '  FROM "' +
          tableName +
          '"), missing AS ('
              '  SELECT "id", ROW_NUMBER() OVER (ORDER BY "createdAt", "id") AS seq '
              '  FROM "' +
          tableName +
          '" WHERE "officialNo" IS NULL OR "officialNo" = \'\''
              ') '
              'UPDATE "' +
          tableName +
          '" t SET '
              '"officialNo" = (base.max_no + missing.seq)::text, '
              '"rowVersion" = version_base.max_version + missing.seq, '
              '"syncStatus" = \'SYNCED\', '
              '"updatedAt" = NOW() '
              'FROM missing, base, version_base '
              'WHERE t."id" = missing."id"',
    );
  }

  static bool _hasRowVersion(String entityType) {
    return !_nonVersionedEntityTypes.contains(entityType);
  }

  static Future<List<String>> _getColumnNames(
    Session session,
    String tableName,
  ) async {
    final rows = await session.db.unsafeQuery(
      "SELECT column_name FROM information_schema.columns WHERE table_name = @tableName ORDER BY ordinal_position",
      parameters: QueryParameters.named({'tableName': tableName}),
    );
    return rows.map((row) => row.first.toString()).toList();
  }

  static const Map<String, String> _entityTableMap = {
    'PRODUCT': 'product',
    'CLIENT': 'client',
    'SALES_INVOICE': 'sales_invoice',
    'SALES_INVOICE_LINE': 'sales_invoice_line',
    'RECEIPT': 'receipt',
    'RECEIPT_ALLOCATION': 'receipt_allocation',
    'EXPENSE': 'expense',
    'SALES_RETURN': 'sales_return',
    'SALES_RETURN_LINE': 'sales_return_line',
    'ATTACHMENT_METADATA': 'attachment_metadata',
    'MONTHLY_DISTRIBUTION': 'monthly_distribution',
    'PARTY_ADJUSTMENT': 'party_adjustment',
    'BENEFICIARY': 'beneficiary',
    'FREE_SAMPLE': 'free_sample',
    'FREE_SAMPLE_LINE': 'free_sample_line',
  };

  static const Set<String> _nonVersionedEntityTypes = {
    'SALES_INVOICE_LINE',
    'RECEIPT_ALLOCATION',
    'SALES_RETURN_LINE',
  };

  static const Set<String> _officialNumberedEntityTypes = {
    'SALES_INVOICE',
    'RECEIPT',
    'SALES_RETURN',
    'FREE_SAMPLE',
  };

  static Object? _jsonSafe(Object? value) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    if (value is DateTime) {
      return value.toUtc().toIso8601String();
    }
    if (value is UuidValue) {
      return value.toString();
    }
    if (value is Enum) {
      return value.name;
    }
    if (value is Iterable) {
      return value.map(_jsonSafe).toList();
    }
    if (value is Map) {
      return value.map(
        (key, mapValue) => MapEntry(key.toString(), _jsonSafe(mapValue)),
      );
    }

    return value.toString();
  }

  static Object? _normalizePayloadValue(String columnName, Object? value) {
    final enumValues = _textEnumValues[columnName];
    if (enumValues != null && value is int) {
      if (value >= 0 && value < enumValues.length) {
        return enumValues[value];
      }
    }
    return value;
  }

  static String _canonicalCompareValue(String columnName, Object? value) {
    final normalized = _normalizePayloadValue(columnName, value);
    if (normalized == null) return '';
    if (normalized is DateTime) {
      return normalized.toUtc().toIso8601String();
    }
    if (normalized is String && _looksLikeIsoDate(normalized)) {
      final parsed = DateTime.tryParse(normalized);
      if (parsed != null) {
        return parsed.toUtc().toIso8601String();
      }
    }
    return normalized.toString();
  }

  static bool _looksLikeIsoDate(String value) {
    return RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(value);
  }

  static const Map<String, Set<String>> _columnAllowlist = {
    'PRODUCT': {
      'name',
      'description',
      'sku',
      'defaultSalePrice',
      'unit',
      'shelfLifeDays',
      'isActive',
      'status',
      'voidReason',
      'deviceId',
    },
    'CLIENT': {
      'displayName',
      'phone',
      'email',
      'address',
      'note',
      'clientCode',
      'creditLimit',
      'invoiceCheckIntervalDays',
      'isActive',
      'status',
      'voidReason',
      'deviceId',
    },
    'SALES_INVOICE': {
      'localRef',
      'officialNo',
      'clientId',
      'invoiceDate',
      'dueDate',
      'discount',
      'total',
      'status',
      'voidReason',
      'note',
      'deviceId',
    },
    'SALES_INVOICE_LINE': {
      'invoiceId',
      'productId',
      'quantity',
      'unitPrice',
      'lineTotal',
      'productionDate',
    },
    'RECEIPT': {
      'localRef',
      'officialNo',
      'receiptType',
      'clientId',
      'invoiceId',
      'amount',
      'paymentMethod',
      'receiptDate',
      'reference',
      'note',
      'status',
      'voidReason',
      'deviceId',
    },
    'RECEIPT_ALLOCATION': {
      'receiptId',
      'invoiceId',
      'allocatedAmount',
    },
    'EXPENSE': {
      'category',
      'amount',
      'description',
      'expenseDate',
      'paymentMethod',
      'reference',
      'note',
      'status',
      'voidReason',
      'deviceId',
    },
    'SALES_RETURN': {
      'localRef',
      'officialNo',
      'invoiceId',
      'returnDate',
      'totalReturnedAmount',
      'note',
      'status',
      'voidReason',
      'deviceId',
    },
    'SALES_RETURN_LINE': {
      'returnId',
      'invoiceLineId',
      'returnedQuantity',
      'returnedAmount',
    },
    'ATTACHMENT_METADATA': {
      'parentEntityType',
      'parentEntityId',
      'storageReference',
      'secureUrl',
      'fileType',
      'fileSize',
      'deviceId',
    },
    'MONTHLY_DISTRIBUTION': {
      'year',
      'month',
      'netProfit',
      'ownerShare',
      'partnerShare',
      'marginShare',
      'status',
      'voidReason',
      'deviceId',
    },
    'PARTY_ADJUSTMENT': {
      'party',
      'amount',
      'adjustmentDate',
      'note',
      'status',
      'voidReason',
      'deviceId',
    },
    'BENEFICIARY': {
      'displayName',
      'phone',
      'sourceClientId',
      'isActive',
      'deviceId',
    },
    'FREE_SAMPLE': {
      'localRef',
      'officialNo',
      'beneficiaryId',
      'sampleDate',
      'note',
      'status',
      'voidReason',
      'deviceId',
    },
    'FREE_SAMPLE_LINE': {
      'sampleId',
      'productId',
      'quantity',
      'deviceId',
    },
  };

  static const Map<String, Set<String>> _autoMergeFields = {
    'CLIENT': {
      'displayName',
      'phone',
      'note',
      'clientCode',
      'creditLimit',
      'invoiceCheckIntervalDays',
      'isActive',
      'email',
      'address',
    },
    'PRODUCT': {'description', 'isActive', 'unit', 'sku'},
    'SALES_INVOICE': {'note'},
    'RECEIPT': {'note'},
    'EXPENSE': {'note'},
    'SALES_RETURN': {'note'},
    'ATTACHMENT_METADATA': {
      'storageReference',
      'secureUrl',
      'fileType',
      'fileSize',
    },
    'MONTHLY_DISTRIBUTION': {'voidReason'},
    'PARTY_ADJUSTMENT': {'note'},
    'BENEFICIARY': {'displayName', 'phone', 'sourceClientId', 'isActive'},
    'FREE_SAMPLE': {'note'},
    'FREE_SAMPLE_LINE': {'quantity'},
  };

  static const Map<String, Set<String>> _conflictRequiredFields = {
    'PRODUCT': {'name', 'defaultSalePrice', 'shelfLifeDays'},
    'SALES_INVOICE': {
      'clientId',
      'invoiceDate',
      'discount',
      'total',
      'status',
      'voidReason',
    },
    'SALES_INVOICE_LINE': {
      'invoiceId',
      'productId',
      'quantity',
      'unitPrice',
      'lineTotal',
      'productionDate',
    },
    'RECEIPT': {
      'receiptType',
      'clientId',
      'invoiceId',
      'amount',
      'receiptDate',
      'status',
      'voidReason',
    },
    'RECEIPT_ALLOCATION': {'receiptId', 'invoiceId', 'allocatedAmount'},
    'EXPENSE': {
      'category',
      'amount',
      'expenseDate',
      'status',
      'voidReason',
    },
    'SALES_RETURN': {
      'invoiceId',
      'returnDate',
      'totalReturnedAmount',
      'status',
      'voidReason',
    },
    'SALES_RETURN_LINE': {
      'returnId',
      'invoiceLineId',
      'returnedQuantity',
      'returnedAmount',
    },
    'MONTHLY_DISTRIBUTION': {
      'year',
      'month',
      'netProfit',
      'ownerShare',
      'partnerShare',
      'marginShare',
      'status',
      'voidReason',
    },
    'PARTY_ADJUSTMENT': {
      'party',
      'amount',
      'adjustmentDate',
      'status',
      'voidReason',
    },
    'BENEFICIARY': {'displayName', 'isActive'},
    'FREE_SAMPLE': {
      'beneficiaryId',
      'sampleDate',
      'status',
      'voidReason',
    },
    'FREE_SAMPLE_LINE': {'sampleId', 'productId', 'quantity'},
  };

  static const Map<String, List<String>> _textEnumValues = {
    'category': [
      'OWNER_DRAW',
      'PARTNER_DRAW',
      'MARGIN_DRAW',
      'OPERATIONAL',
      'PRODUCTION',
    ],
    'party': ['OWNER', 'PARTNER', 'MARGIN'],
    'parentEntityType': [
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
    'receiptType': ['INVOICE_LINKED', 'GENERAL'],
    'status': ['ACTIVE', 'VOIDED'],
  };
}
