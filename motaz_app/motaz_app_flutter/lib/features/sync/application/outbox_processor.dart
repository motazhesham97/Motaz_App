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
      if (a.entityType == ParentEntityType.RECEIPT_ALLOCATION) {
        final releaseCompare = (_isAllocationRelease(a) ? 0 : 1).compareTo(
          _isAllocationRelease(b) ? 0 : 1,
        );
        if (releaseCompare != 0) return releaseCompare;
      }
      if (a.entityType == ParentEntityType.MONTHLY_DISTRIBUTION &&
          b.entityType == ParentEntityType.MONTHLY_DISTRIBUTION) {
        final left = jsonDecode(a.payload) as Map<String, dynamic>;
        final right = jsonDecode(b.payload) as Map<String, dynamic>;
        final periodCompare =
            ((left['year'] as int) * 12 + (left['month'] as int)).compareTo(
              (right['year'] as int) * 12 + (right['month'] as int),
            );
        if (periodCompare != 0) return periodCompare;
        final operationCompare = a.operation.index.compareTo(b.operation.index);
        if (operationCompare != 0) return operationCompare;
        final versionCompare = a.rowVersion.compareTo(b.rowVersion);
        if (versionCompare != 0) return versionCompare;
      }
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
                    (t.operation.equals(AuditOperation.UPDATE.index) |
                        (t.entityType.equals(
                              ParentEntityType.RECEIPT_ALLOCATION.index,
                            ) &
                            t.operation.equals(AuditOperation.CREATE.index))),
              )
              ..orderBy([
                (t) => OrderingTerm.asc(t.createdAt),
                (_) => OrderingTerm.asc(const CustomExpression<int>('rowid')),
              ]))
            .get();

    final grouped = <String, List<SyncOutboxData>>{};
    for (final entry in pendingUpdates) {
      if (!_isCoalescibleUpdateEntity(entry.entityType)) continue;
      final key = '${entry.entityType.index}:${entry.entityId}';
      grouped.putIfAbsent(key, () => <SyncOutboxData>[]).add(entry);
    }

    for (final entries in grouped.values) {
      if (entries.length < 2) continue;

      // The query keeps insertion order when SQLite timestamps share a second.
      final latest = entries.last;
      final baseVersion = entries
          .map((entry) => entry.rowVersion)
          .reduce((a, b) => a < b ? a : b);
      var payload = const Value<String>.absent();
      if (latest.entityType == ParentEntityType.RECEIPT_ALLOCATION) {
        final first = entries.first;
        final firstPayload = jsonDecode(first.payload) as Map<String, dynamic>;
        final latestPayload =
            jsonDecode(latest.payload) as Map<String, dynamic>;
        // Classify the net mutation against the original queued baseline.
        final previous = first.operation == AuditOperation.CREATE
            ? 0
            : firstPayload['previousAllocatedAmount'];
        if (previous is num) {
          latestPayload['previousAllocatedAmount'] = previous;
        } else {
          latestPayload.remove('previousAllocatedAmount');
        }
        payload = Value(jsonEncode(latestPayload));
      }

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
          payload: payload,
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
      case ParentEntityType.RECEIPT_ALLOCATION:
        return true;
      case ParentEntityType.SALES_INVOICE_LINE:
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
      case ParentEntityType.SALES_RETURN:
        return 4;
      case ParentEntityType.SALES_RETURN_LINE:
        return 5;
      case ParentEntityType.RECEIPT_ALLOCATION:
        return 6;
      case ParentEntityType.EXPENSE:
      case ParentEntityType.ATTACHMENT_METADATA:
      case ParentEntityType.PARTY_ADJUSTMENT:
        return 7;
      case ParentEntityType.MONTHLY_DISTRIBUTION:
        return 8;
    }
  }

  bool _isAllocationRelease(SyncOutboxData entry) {
    if (entry.entityType != ParentEntityType.RECEIPT_ALLOCATION ||
        entry.operation != AuditOperation.UPDATE) {
      return false;
    }
    final payload = jsonDecode(entry.payload) as Map<String, dynamic>;
    final previous = payload['previousAllocatedAmount'];
    final amount = payload['allocatedAmount'];
    if (amount == 0) return true;
    return previous is num && amount is num && previous > amount;
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
        payload: entityType == ParentEntityType.RECEIPT_ALLOCATION
            ? jsonEncode(
                (jsonDecode(entry.payload) as Map<String, dynamic>)
                  ..remove('previousAllocatedAmount'),
              )
            : entry.payload,
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
    if (entry.entityType == ParentEntityType.MONTHLY_DISTRIBUTION) {
      final unresolved =
          await (_db.select(_db.conflictLogs)
                ..where(
                  (t) =>
                      t.resolutionStatus.equals(ConflictStatus.PENDING.index),
                )
                ..limit(1))
              .get();
      if (unresolved.isNotEmpty) return true;
      final open =
          await (_db.select(_db.syncOutbox)..where(
                (t) =>
                    t.status.isNotValue(SyncOutboxStatus.COMPLETED.index) &
                    t.id.isNotValue(entry.id),
              ))
              .get();
      final payload = jsonDecode(entry.payload) as Map<String, dynamic>;
      final period = (payload['year'] as int) * 12 + (payload['month'] as int);
      for (final other in open) {
        if ({
          ParentEntityType.SALES_INVOICE,
          ParentEntityType.SALES_INVOICE_LINE,
          ParentEntityType.SALES_RETURN,
          ParentEntityType.SALES_RETURN_LINE,
          ParentEntityType.EXPENSE,
        }.contains(other.entityType)) {
          return true;
        }
        if (other.entityType == ParentEntityType.MONTHLY_DISTRIBUTION) {
          final previous = jsonDecode(other.payload) as Map<String, dynamic>;
          if ((previous['year'] as int) * 12 + (previous['month'] as int) <
              period) {
            return true;
          }
        }
      }
    }
    try {
      final payload = jsonDecode(entry.payload) as Map<String, dynamic>;
      if (entry.entityType == ParentEntityType.SALES_INVOICE_LINE ||
          entry.entityType == ParentEntityType.RECEIPT ||
          entry.entityType == ParentEntityType.SALES_RETURN ||
          entry.entityType == ParentEntityType.RECEIPT_ALLOCATION) {
        final invoiceId = payload['invoiceId']?.toString();
        if (invoiceId != null && invoiceId.isNotEmpty) {
          if (await _hasOpenOutboxFor(
            ParentEntityType.SALES_INVOICE,
            invoiceId,
          )) {
            return true;
          }
          final invoice = await (_db.select(
            _db.salesInvoices,
          )..where((t) => t.id.equals(invoiceId))).getSingleOrNull();
          if (invoice?.syncStatus == SyncStatus.CONFLICT) return true;
        }
      }
      if (entry.entityType == ParentEntityType.SALES_RETURN_LINE) {
        final returnId = payload['returnId'] as String;
        if (await _hasOpenOutboxFor(ParentEntityType.SALES_RETURN, returnId)) {
          return true;
        }
        final header = await (_db.select(
          _db.salesReturns,
        )..where((t) => t.id.equals(returnId))).getSingle();
        if (header.syncStatus == SyncStatus.CONFLICT) return true;
      }
      if (entry.entityType == ParentEntityType.RECEIPT_ALLOCATION) {
        return await _hasBlockingPaymentDependency(entry, payload);
      }
      if (entry.entityType == ParentEntityType.FREE_SAMPLE) {
        final beneficiaryId = payload['beneficiaryId']?.toString();
        if (beneficiaryId == null || beneficiaryId.isEmpty) return false;
        return await _hasOpenOutboxFor(
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
      if (entry.entityType == ParentEntityType.RECEIPT_ALLOCATION ||
          entry.entityType == ParentEntityType.SALES_RETURN ||
          entry.entityType == ParentEntityType.SALES_RETURN_LINE) {
        return true;
      }
    }
    return false;
  }

  Future<bool> _hasBlockingPaymentDependency(
    SyncOutboxData entry,
    Map<String, dynamic> payload,
  ) async {
    final receipt = await (_db.select(
      _db.receipts,
    )..where((t) => t.id.equals(payload['receiptId'] as String))).getSingle();
    final receipts = await (_db.select(
      _db.receipts,
    )..where((t) => t.clientId.equals(receipt.clientId))).get();
    final receiptIds = receipts.map((row) => row.id).toSet();
    final ownedInvoices = await (_db.select(
      _db.salesInvoices,
    )..where((t) => t.clientId.equals(receipt.clientId))).get();
    final allocations = await (_db.select(
      _db.receiptAllocations,
    )..where((t) => t.receiptId.isIn(receiptIds))).get();
    // Tombstones retain the account's dependency on moved invoices.
    final invoiceIds = {
      for (final invoice in ownedInvoices) invoice.id,
      for (final row in receipts)
        if (row.invoiceId != null) row.invoiceId!,
      for (final allocation in allocations) allocation.invoiceId,
      if (payload['invoiceId'] is String) payload['invoiceId'] as String,
    };
    final relatedAllocations = await (_db.select(
      _db.receiptAllocations,
    )..where((t) => t.invoiceId.isIn(invoiceIds))).get();
    receiptIds.addAll(relatedAllocations.map((row) => row.receiptId));
    final relatedReceipts =
        await (_db.select(_db.receipts)..where(
              (t) => t.id.isIn(receiptIds) | t.invoiceId.isIn(invoiceIds),
            ))
            .get();
    receiptIds.addAll(relatedReceipts.map((row) => row.id));
    final returns = await (_db.select(
      _db.salesReturns,
    )..where((t) => t.invoiceId.isIn(invoiceIds))).get();
    final returnIds = returns.map((row) => row.id).toSet();
    final conflictedInvoices =
        await (_db.select(_db.salesInvoices)
              ..where(
                (t) =>
                    t.id.isIn(invoiceIds) &
                    t.syncStatus.equals(SyncStatus.CONFLICT.index),
              )
              ..limit(1))
            .get();
    if (conflictedInvoices.isNotEmpty ||
        relatedReceipts.any((row) => row.syncStatus == SyncStatus.CONFLICT) ||
        returns.any((row) => row.syncStatus == SyncStatus.CONFLICT)) {
      return true;
    }
    final openHeaders =
        await (_db.select(_db.syncOutbox)
              ..where(
                (t) =>
                    t.status.isIn([
                      SyncOutboxStatus.PENDING.index,
                      SyncOutboxStatus.IN_PROGRESS.index,
                      SyncOutboxStatus.FAILED.index,
                    ]) &
                    ((t.entityType.equals(
                              ParentEntityType.SALES_INVOICE.index,
                            ) &
                            t.entityId.isIn(invoiceIds)) |
                        (t.entityType.equals(ParentEntityType.RECEIPT.index) &
                            t.entityId.isIn(receiptIds)) |
                        (t.entityType.equals(
                              ParentEntityType.SALES_RETURN.index,
                            ) &
                            t.entityId.isIn(returnIds))),
              )
              ..limit(1))
            .get();
    if (openHeaders.isNotEmpty) return true;
    if (!_isAllocationRelease(entry)) {
      final openAllocations =
          await (_db.select(_db.syncOutbox)..where(
                (t) =>
                    t.entityType.equals(
                      ParentEntityType.RECEIPT_ALLOCATION.index,
                    ) &
                    t.status.isIn([
                      SyncOutboxStatus.PENDING.index,
                      SyncOutboxStatus.IN_PROGRESS.index,
                      SyncOutboxStatus.FAILED.index,
                    ]),
              ))
              .get();
      for (final other in openAllocations) {
        if (!_isAllocationRelease(other)) continue;
        final release = jsonDecode(other.payload) as Map<String, dynamic>;
        if (receiptIds.contains(release['receiptId']) ||
            invoiceIds.contains(release['invoiceId'])) {
          return true;
        }
      }
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
