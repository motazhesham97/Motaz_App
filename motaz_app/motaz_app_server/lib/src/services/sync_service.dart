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

  static Future<bool> validateDeviceIdentity(
    Session session,
    String deviceId,
  ) async {
    final uuid = UuidValue(deviceId);
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
      if (localPayload[key].toString() != remotePayload[key].toString()) {
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

  static bool applyVoidWinsRule(String? localStatus, String? remoteStatus) {
    final localVoided = localStatus == 'VOIDED';
    final remoteVoided = remoteStatus == 'VOIDED';
    return localVoided || remoteVoided;
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

    final conflict = ConflictLog(
      entityType: parsed,
      entityId: UuidValue(entityId),
      localPayload: localPayload,
      remotePayload: remotePayload,
      conflictType: conflictType,
      resolutionStatus: ConflictStatus.PENDING,
      createdAt: DateTime.now().toUtc(),
      deviceId: UuidValue(deviceId),
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

    final existingRow = await loadEntityRow(session, entityType, entityId);
    int currentVersion = 0;
    if (existingRow != null && existingRow['rowVersion'] != null) {
      currentVersion = existingRow['rowVersion'] as int;
    }
    final newVersion = currentVersion + 1;

    final setClauses = <String>[];
    final params = <String, dynamic>{};
    params['entityId'] = entityId;

    for (final entry in payload.entries) {
      if (entry.key == 'id' ||
          entry.key == 'rowVersion' ||
          entry.key == 'syncStatus') {
        continue;
      }
      if (!allowedColumns.contains(entry.key)) {
        throw ArgumentError(
          'Column "' + entry.key + '" not allowed for entity type ' + entityType,
        );
      }
      final snakeKey = _camelToSnake(entry.key);
      setClauses.add('"' + snakeKey + '" = @' + entry.key);
      params[entry.key] = entry.value;
    }
    setClauses.add('"rowVersion" = @rowVersion');
    params['rowVersion'] = newVersion;
    setClauses.add('"updatedAt" = @updatedAt');
    params['updatedAt'] = now.toIso8601String();

    if (existingRow != null) {
      await session.db.unsafeExecute(
        'UPDATE "' + tableName + '" SET ' + setClauses.join(', ') + ' WHERE "id" = @entityId',
        parameters: QueryParameters.named(params),
      );
    } else {
      final columns = payload.keys
          .where((k) => k != 'id' && k != 'rowVersion' && k != 'syncStatus')
          .toList();
      final insertCols = [
        '"id"',
        ...columns.map((c) => '"' + _camelToSnake(c) + '"'),
        '"rowVersion"',
        '"updatedAt"',
      ];
      final insertVals = [
        '@entityId',
        ...columns.map((c) => '@' + c),
        '@rowVersion',
        '@updatedAt',
      ];
      await session.db.unsafeExecute(
        'INSERT INTO "' + tableName + '" (' + insertCols.join(', ') + ') VALUES (' + insertVals.join(', ') + ')',
        parameters: QueryParameters.named(params),
      );
    }

    final parsedEntityType = _parseParentEntityType(entityType);
    final parsedOperation = _parseAuditOperation(operation);
    if (parsedEntityType == null || parsedOperation == null) {
      throw ArgumentError(
        'Invalid entity type (' + entityType + ') or operation (' + operation + ')',
      );
    }

    final auditEvent = AuditEvent(
      entityType: parsedEntityType,
      entityId: UuidValue(entityId),
      operation: parsedOperation,
      diffData: jsonEncode(payload),
      deviceId: UuidValue(deviceId),
      createdAt: now,
    );
    await AuditEvent.db.insertRow(session, auditEvent);

    return newVersion;
  }

  static Future<List<String>> queryChangedRows(
    Session session,
    String entityType,
    int sinceRowVersion,
    int limit,
  ) async {
    final tableName = _entityTableName(entityType);
    if (tableName == null) return [];

    final rows = await session.db.unsafeQuery(
      'SELECT row_to_json(t) FROM "' + tableName + '" t WHERE "rowVersion" > @sinceRowVersion ORDER BY "rowVersion" ASC LIMIT @limit',
      parameters: QueryParameters.named({
        'sinceRowVersion': sinceRowVersion,
        'limit': limit,
      }),
    );
    return rows.map((row) => row.first.toString()).toList();
  }

  static Future<int> getLatestRowVersion(
    Session session,
    String entityType,
  ) async {
    final tableName = _entityTableName(entityType);
    if (tableName == null) return 0;

    final rows = await session.db.unsafeQuery(
      'SELECT COALESCE(MAX("rowVersion"), 0) FROM "' + tableName + '"',
    );
    if (rows.isEmpty) return 0;
    return rows.first.first as int;
  }

  static Future<int> countRowsAboveVersion(
    Session session,
    String entityType,
    int sinceRowVersion,
  ) async {
    final tableName = _entityTableName(entityType);
    if (tableName == null) return 0;

    final rows = await session.db.unsafeQuery(
      'SELECT COUNT(*) FROM "' + tableName + '" WHERE "rowVersion" > @sinceRowVersion',
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
    final deviceUuid = UuidValue(deviceId);
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

  static String _camelToSnake(String input) {
    return input.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_' + match.group(0)!.toLowerCase(),
    );
  }

  static const Map<String, String> _entityTableMap = {
    'PRODUCT': 'product',
    'CLIENT': 'client_record',
    'SALES_INVOICE': 'sales_invoice',
    'SALES_INVOICE_LINE': 'sales_invoice_line',
    'RECEIPT': 'receipt',
    'RECEIPT_ALLOCATION': 'receipt_allocation',
    'EXPENSE': 'expense',
    'SALES_RETURN': 'sales_return',
    'SALES_RETURN_LINE': 'sales_return_line',
    'ATTACHMENT_METADATA': 'attachment_metadata',
  };

  static const Map<String, Set<String>> _columnAllowlist = {
    'PRODUCT': {
      'name', 'description', 'sku', 'defaultSalePrice', 'costPrice',
      'unit', 'isActive', 'status', 'voidReason', 'deviceId',
    },
    'CLIENT': {
      'displayName', 'phone', 'email', 'address', 'note', 'clientCode',
      'status', 'voidReason', 'deviceId',
    },
    'SALES_INVOICE': {
      'clientId', 'invoiceDate', 'dueDate', 'discount', 'total',
      'status', 'voidReason', 'note', 'deviceId',
    },
    'SALES_INVOICE_LINE': {
      'invoiceId', 'productId', 'description', 'quantity', 'unitPrice',
      'lineTotal', 'deviceId',
    },
    'RECEIPT': {
      'receiptType', 'clientId', 'invoiceId', 'amount', 'paymentMethod',
      'receiptDate', 'reference', 'note', 'status', 'voidReason', 'deviceId',
    },
    'RECEIPT_ALLOCATION': {
      'receiptId', 'invoiceId', 'allocatedAmount', 'deviceId',
    },
    'EXPENSE': {
      'category', 'amount', 'description', 'expenseDate', 'paymentMethod',
      'reference', 'note', 'status', 'voidReason', 'deviceId',
    },
    'SALES_RETURN': {
      'invoiceId', 'returnDate', 'totalReturnedAmount', 'note',
      'status', 'voidReason', 'deviceId',
    },
    'SALES_RETURN_LINE': {
      'returnId', 'invoiceLineId', 'returnedQuantity', 'returnedAmount',
      'reason', 'deviceId',
    },
    'ATTACHMENT_METADATA': {
      'parentEntityType', 'parentEntityId', 'storageReference', 'secureUrl',
      'fileType', 'fileSize', 'deviceId',
    },
  };

  static const Map<String, Set<String>> _autoMergeFields = {
    'CLIENT': {'displayName', 'phone', 'note', 'clientCode'},
    'PRODUCT': {'description', 'isActive'},
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
  };

  static const Map<String, Set<String>> _conflictRequiredFields = {
    'PRODUCT': {'name', 'defaultSalePrice'},
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
  };
}
