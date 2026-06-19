import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:motaz_app_client/motaz_app_client.dart' as server;

import '../../../core/database/app_database.dart' hide Client;
import '../../../core/database/enums/enums.dart';
import '../../../core/logging/app_logger.dart';

typedef PushRequestHandler =
    Future<server.PushResponse> Function(
      server.PushRequest request,
    );

class OutboxProcessor {
  OutboxProcessor({
    required AppDatabase db,
    required server.Client serverClient,
    PushRequestHandler? pushOverride,
  }) : _db = db,
       _serverClient = serverClient,
       _pushOverride = pushOverride;

  final AppDatabase _db;
  final server.Client _serverClient;
  final PushRequestHandler? _pushOverride;
  static const int maxRetryCount = 5;

  Future<void> processPending() async {
    await _clearStaleFailedRows();
    await _reviveRetryableFailedRows();
    await _coalescePendingUpdates();

    final pending =
        await (_db.select(_db.syncOutbox)
              ..where((t) => t.status.equals(SyncOutboxStatus.PENDING.index))
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get();
    pending.sort((a, b) {
      final priorityCompare = _entityPriority(a.entityType).compareTo(
        _entityPriority(b.entityType),
      );
      if (priorityCompare != 0) return priorityCompare;
      final createdCompare = a.createdAt.compareTo(b.createdAt);
      if (createdCompare != 0) return createdCompare;
      return a.id.compareTo(b.id);
    });
    for (final entry in pending) {
      await _processEntry(entry);
    }
  }

  Future<void> _coalescePendingUpdates() async {
    final pendingUpdates =
        await (_db.select(_db.syncOutbox)
              ..where(
                (t) =>
                    t.status.equals(SyncOutboxStatus.PENDING.index) &
                    t.operation.equals(AuditOperation.UPDATE.index),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get();

    final grouped = <String, List<SyncOutboxData>>{};
    for (final entry in pendingUpdates) {
      if (!_isCoalescibleUpdateEntity(entry.entityType)) continue;
      final key = '${entry.entityType.index}:${entry.entityId}';
      grouped.putIfAbsent(key, () => <SyncOutboxData>[]).add(entry);
    }

    for (final entries in grouped.values) {
      if (entries.length < 2) continue;

      entries.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final latest = entries.last;
      final baseVersion = entries
          .map((entry) => entry.rowVersion)
          .reduce((a, b) => a < b ? a : b);

      for (final oldEntry in entries.take(entries.length - 1)) {
        await (_db.update(
          _db.syncOutbox,
        )..where((t) => t.id.equals(oldEntry.id))).write(
          SyncOutboxCompanion(
            status: Value(SyncOutboxStatus.COMPLETED),
            retryCount: const Value(0),
          ),
        );
      }

      await (_db.update(
        _db.syncOutbox,
      )..where((t) => t.id.equals(latest.id))).write(
        SyncOutboxCompanion(
          rowVersion: Value(baseVersion),
          retryCount: const Value(0),
        ),
      );
    }
  }

  bool _isCoalescibleUpdateEntity(ParentEntityType entityType) {
    switch (entityType) {
      case ParentEntityType.PRODUCT:
      case ParentEntityType.CLIENT:
      case ParentEntityType.SALES_INVOICE:
      case ParentEntityType.RECEIPT:
      case ParentEntityType.EXPENSE:
      case ParentEntityType.SALES_RETURN:
      case ParentEntityType.ATTACHMENT_METADATA:
      case ParentEntityType.MONTHLY_DISTRIBUTION:
      case ParentEntityType.PARTY_ADJUSTMENT:
      case ParentEntityType.BENEFICIARY:
      case ParentEntityType.FREE_SAMPLE:
      case ParentEntityType.FREE_SAMPLE_LINE:
        return true;
      case ParentEntityType.SALES_INVOICE_LINE:
      case ParentEntityType.RECEIPT_ALLOCATION:
      case ParentEntityType.SALES_RETURN_LINE:
        return false;
    }
  }

  int _entityPriority(ParentEntityType entityType) {
    switch (entityType) {
      case ParentEntityType.CLIENT:
      case ParentEntityType.BENEFICIARY:
      case ParentEntityType.PRODUCT:
        return 0;
      case ParentEntityType.SALES_INVOICE:
      case ParentEntityType.FREE_SAMPLE:
        return 1;
      case ParentEntityType.SALES_INVOICE_LINE:
      case ParentEntityType.FREE_SAMPLE_LINE:
        return 2;
      case ParentEntityType.RECEIPT:
        return 3;
      case ParentEntityType.RECEIPT_ALLOCATION:
        return 4;
      case ParentEntityType.SALES_RETURN:
        return 5;
      case ParentEntityType.SALES_RETURN_LINE:
        return 6;
      case ParentEntityType.EXPENSE:
      case ParentEntityType.ATTACHMENT_METADATA:
      case ParentEntityType.MONTHLY_DISTRIBUTION:
      case ParentEntityType.PARTY_ADJUSTMENT:
        return 7;
    }
  }

  Future<void> _processEntry(SyncOutboxData entry) async {
    final now = DateTime.now();
    if (entry.retryCount > 0) {
      final nextRetryAt = entry.createdAt.add(
        _computeCumulativeDelay(entry.retryCount),
      );
      if (now.isBefore(nextRetryAt)) return;
    }
    if (await _hasBlockingDependency(entry)) return;

    await (_db.update(
      _db.syncOutbox,
    )..where((t) => t.id.equals(entry.id))).write(
      SyncOutboxCompanion(
        status: Value(SyncOutboxStatus.IN_PROGRESS),
      ),
    );

    try {
      final entityType = entry.entityType;
      final operation = entry.operation;

      AppLogger.database.info(
        'Push attempt ${entityType.name}/${operation.name}: '
        'outbox=${entry.id}, entity=${entry.entityId}, '
        'rowVersion=${entry.rowVersion}',
      );

      final request = server.PushRequest(
        outboxId: entry.id,
        entityType: entityType.name,
        entityId: entry.entityId,
        operation: operation.name,
        payload: entry.payload,
        rowVersion: entry.rowVersion,
        deviceId: entry.deviceId,
      );
      final response = await (_pushOverride ?? _serverClient.sync.push)(
        request,
      );

      if (response.success) {
        await _markCompleted(entry);
        await _updateEntitySyncStatus(
          entityType.name,
          entry.entityId,
          SyncStatus.SYNCED,
          rowVersion: response.newRowVersion,
        );
      } else if (response.conflictId != null) {
        AppLogger.database.warning(
          'Push conflict for ${entityType.name} ${entry.entityId}: '
          '${response.conflictId}',
        );
        await _markCompleted(entry);
        await _updateEntitySyncStatus(
          entityType.name,
          entry.entityId,
          SyncStatus.CONFLICT,
        );
      } else {
        AppLogger.database.warning(
          'Push rejected for ${entry.id}: ${response.errorCode ?? 'unknown'} '
          '${response.errorMessage ?? ''}',
        );
        final isPermanent = _isPermanentError(response.errorCode);
        if (isPermanent || entry.retryCount >= maxRetryCount) {
          await (_db.update(
            _db.syncOutbox,
          )..where((t) => t.id.equals(entry.id))).write(
            SyncOutboxCompanion(
              status: Value(SyncOutboxStatus.FAILED),
            ),
          );
        } else {
          await (_db.update(
            _db.syncOutbox,
          )..where((t) => t.id.equals(entry.id))).write(
            SyncOutboxCompanion(
              status: Value(SyncOutboxStatus.PENDING),
              retryCount: Value(entry.retryCount + 1),
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.database.warning(
        'Push error for ${entry.id} '
        '(${entry.entityType.name}/${entry.operation.name}, '
        'entity=${entry.entityId}): $e',
      );
      if (entry.retryCount >= maxRetryCount) {
        await (_db.update(
          _db.syncOutbox,
        )..where((t) => t.id.equals(entry.id))).write(
          SyncOutboxCompanion(
            status: Value(SyncOutboxStatus.FAILED),
          ),
        );
      } else {
        await (_db.update(
          _db.syncOutbox,
        )..where((t) => t.id.equals(entry.id))).write(
          SyncOutboxCompanion(
            status: Value(SyncOutboxStatus.PENDING),
            retryCount: Value(entry.retryCount + 1),
          ),
        );
      }
    }
  }

  Future<bool> _hasBlockingDependency(SyncOutboxData entry) async {
    try {
      final payload = jsonDecode(entry.payload) as Map<String, dynamic>;
      if (entry.entityType == ParentEntityType.FREE_SAMPLE) {
        final beneficiaryId = payload['beneficiaryId']?.toString();
        if (beneficiaryId == null || beneficiaryId.isEmpty) return false;
        return _hasOpenOutboxFor(
          ParentEntityType.BENEFICIARY,
          beneficiaryId,
          blockFailed: false,
        );
      }

      if (entry.entityType == ParentEntityType.FREE_SAMPLE_LINE) {
        final sampleId = payload['sampleId']?.toString();
        final productId = payload['productId']?.toString();
        if (sampleId != null &&
            sampleId.isNotEmpty &&
            await _hasOpenOutboxFor(ParentEntityType.FREE_SAMPLE, sampleId)) {
          return true;
        }
        if (productId != null &&
            productId.isNotEmpty &&
            await _hasOpenOutboxFor(ParentEntityType.PRODUCT, productId)) {
          return true;
        }
      }
    } catch (e) {
      AppLogger.database.warning(
        'Could not inspect push dependencies for ${entry.id}: $e',
      );
    }
    return false;
  }

  Future<bool> _hasOpenOutboxFor(
    ParentEntityType entityType,
    String entityId, {
    bool blockFailed = true,
  }) async {
    final statuses = [
      SyncOutboxStatus.PENDING.index,
      SyncOutboxStatus.IN_PROGRESS.index,
      if (blockFailed) SyncOutboxStatus.FAILED.index,
    ];
    final rows =
        await (_db.select(_db.syncOutbox)
              ..where(
                (t) =>
                    t.entityType.equals(entityType.index) &
                    t.entityId.equals(entityId) &
                    t.status.isIn(statuses),
              )
              ..limit(1))
            .get();
    return rows.isNotEmpty;
  }

  Future<void> retryFailed() async {
    await _db.customStatement(
      'UPDATE sync_outbox SET status = ?, retry_count = 0 WHERE status IN (?, ?, ?)',
      [
        SyncOutboxStatus.PENDING.index,
        SyncOutboxStatus.PENDING.index,
        SyncOutboxStatus.IN_PROGRESS.index,
        SyncOutboxStatus.FAILED.index,
      ],
    );
  }

  Duration _computeCumulativeDelay(int retryCount) {
    var totalSeconds = 0;
    for (var i = 1; i <= retryCount; i++) {
      totalSeconds += pow(2, i).toInt();
    }
    final jitterFactor = 0.8 + Random().nextDouble() * 0.4;
    final seconds = (totalSeconds * jitterFactor).round();
    return Duration(seconds: seconds.clamp(1, 32));
  }

  bool _isPermanentError(String? errorCode) {
    if (errorCode == null) return false;
    return errorCode == 'UNAUTHENTICATED' ||
        errorCode == 'UNKNOWN_DEVICE' ||
        errorCode == 'VALIDATION_ERROR' ||
        errorCode == 'ENTITY_NOT_FOUND' ||
        errorCode == 'UNSUPPORTED_ENTITY_TYPE';
  }

  Future<void> _updateEntitySyncStatus(
    String entityType,
    String entityId,
    SyncStatus syncStatus, {
    int? rowVersion,
  }) async {
    final tableName = _syncStatusTableName[entityType];
    if (tableName == null) return;
    if (rowVersion == null) {
      await _db.customStatement(
        'UPDATE "$tableName" SET "sync_status" = ? WHERE "id" = ?',
        [syncStatus.index, entityId],
      );
      return;
    }
    await _db.customStatement(
      'UPDATE "$tableName" SET "sync_status" = ?, "row_version" = ? '
      'WHERE "id" = ?',
      [syncStatus.index, rowVersion, entityId],
    );
  }

  Future<void> _markCompleted(SyncOutboxData entry) async {
    await (_db.update(
      _db.syncOutbox,
    )..where((t) => t.id.equals(entry.id))).write(
      SyncOutboxCompanion(
        status: Value(SyncOutboxStatus.COMPLETED),
        retryCount: const Value(0),
      ),
    );

    await _db.customStatement(
      'UPDATE sync_outbox SET status = ?, retry_count = 0 '
      'WHERE entity_type = ? AND entity_id = ? AND status = ?',
      [
        SyncOutboxStatus.COMPLETED.index,
        entry.entityType.index,
        entry.entityId,
        SyncOutboxStatus.FAILED.index,
      ],
    );
  }

  Future<void> _clearStaleFailedRows() async {
    for (final entry in _syncStatusTableName.entries) {
      final entityType = _parseEntityType(entry.key);
      if (entityType == null) continue;

      await _db.customStatement(
        'UPDATE sync_outbox SET status = ?, retry_count = 0 '
        'WHERE status = ? AND entity_type = ? AND EXISTS ('
        'SELECT 1 FROM "${entry.value}" e '
        'WHERE e.id = sync_outbox.entity_id AND e.sync_status = ?'
        ')',
        [
          SyncOutboxStatus.COMPLETED.index,
          SyncOutboxStatus.FAILED.index,
          entityType.index,
          SyncStatus.SYNCED.index,
        ],
      );
    }
  }

  Future<void> _reviveRetryableFailedRows() async {
    await _db.customStatement(
      'UPDATE sync_outbox SET status = ?, retry_count = 0 '
      'WHERE status = ? AND entity_type IN (?, ?, ?)',
      [
        SyncOutboxStatus.PENDING.index,
        SyncOutboxStatus.FAILED.index,
        ParentEntityType.BENEFICIARY.index,
        ParentEntityType.FREE_SAMPLE.index,
        ParentEntityType.FREE_SAMPLE_LINE.index,
      ],
    );
  }

  ParentEntityType? _parseEntityType(String entityTypeName) {
    for (final value in ParentEntityType.values) {
      if (value.name == entityTypeName) return value;
    }
    return null;
  }

  static const Map<String, String> _syncStatusTableName = {
    'PRODUCT': 'products',
    'CLIENT': 'clients',
    'SALES_INVOICE': 'sales_invoices',
    'RECEIPT': 'receipts',
    'EXPENSE': 'expenses',
    'SALES_RETURN': 'sales_returns',
    'ATTACHMENT_METADATA': 'attachment_metadata',
    'MONTHLY_DISTRIBUTION': 'monthly_distributions',
    'PARTY_ADJUSTMENT': 'party_adjustments',
    'BENEFICIARY': 'beneficiaries',
    'FREE_SAMPLE': 'free_samples',
    'FREE_SAMPLE_LINE': 'free_sample_lines',
  };
}
