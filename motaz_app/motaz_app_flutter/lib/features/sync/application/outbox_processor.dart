import 'dart:math';

import 'package:drift/drift.dart';
import 'package:motaz_app_client/motaz_app_client.dart' as server;

import '../../../core/database/app_database.dart' hide Client;
import '../../../core/database/enums/enums.dart';
import '../../../core/logging/app_logger.dart';

class OutboxProcessor {
  OutboxProcessor({
    required AppDatabase db,
    required server.Client serverClient,
  })  : _db = db,
        _serverClient = serverClient;

  final AppDatabase _db;
  final server.Client _serverClient;
  static const int maxRetryCount = 5;

  Future<void> processPending() async {
    final pending = await (_db.select(_db.syncOutbox)
          ..where((t) => t.status.equals(SyncOutboxStatus.PENDING.index))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    for (final entry in pending) {
      await _processEntry(entry);
    }
  }

  Future<void> _processEntry(SyncOutboxData entry) async {
    final now = DateTime.now();
    if (entry.retryCount > 0) {
      final nextRetryAt = entry.createdAt.add(_computeCumulativeDelay(entry.retryCount));
      if (now.isBefore(nextRetryAt)) return;
    }

    await (_db.update(_db.syncOutbox)..where((t) => t.id.equals(entry.id)))
        .write(SyncOutboxCompanion(
      status: Value(SyncOutboxStatus.IN_PROGRESS),
    ));

    try {
      final entityType = entry.entityType;
      final operation = entry.operation;

      final request = server.PushRequest(
        outboxId: entry.id,
        entityType: entityType.name,
        entityId: entry.entityId,
        operation: operation.name,
        payload: entry.payload,
        rowVersion: entry.rowVersion,
        deviceId: entry.deviceId,
      );
      final response = await _serverClient.sync.push(request);

      if (response.success) {
        await (_db.update(_db.syncOutbox)..where((t) => t.id.equals(entry.id)))
            .write(SyncOutboxCompanion(
          status: Value(SyncOutboxStatus.COMPLETED),
        ));
        await _updateEntitySyncStatus(
          entityType.name,
          entry.entityId,
          SyncStatus.SYNCED,
        );
      } else if (response.conflictId != null) {
        await (_db.update(_db.syncOutbox)..where((t) => t.id.equals(entry.id)))
            .write(SyncOutboxCompanion(
          status: Value(SyncOutboxStatus.COMPLETED),
        ));
        await _updateEntitySyncStatus(
          entityType.name,
          entry.entityId,
          SyncStatus.CONFLICT,
        );
      } else {
        final isPermanent = _isPermanentError(response.errorCode);
        if (isPermanent || entry.retryCount >= maxRetryCount) {
          await (_db.update(_db.syncOutbox)..where((t) => t.id.equals(entry.id)))
              .write(SyncOutboxCompanion(
            status: Value(SyncOutboxStatus.FAILED),
          ));
        } else {
          await (_db.update(_db.syncOutbox)..where((t) => t.id.equals(entry.id)))
              .write(SyncOutboxCompanion(
            status: Value(SyncOutboxStatus.PENDING),
            retryCount: Value(entry.retryCount + 1),
          ));
        }
      }
    } catch (e) {
      AppLogger.database.warning('Push error for ${entry.id}: $e');
      if (entry.retryCount >= maxRetryCount) {
        await (_db.update(_db.syncOutbox)..where((t) => t.id.equals(entry.id)))
            .write(SyncOutboxCompanion(
          status: Value(SyncOutboxStatus.FAILED),
        ));
      } else {
        await (_db.update(_db.syncOutbox)..where((t) => t.id.equals(entry.id)))
            .write(SyncOutboxCompanion(
          status: Value(SyncOutboxStatus.PENDING),
          retryCount: Value(entry.retryCount + 1),
        ));
      }
    }
  }

  Future<void> retryFailed() async {
    final failed = await (_db.select(_db.syncOutbox)
          ..where((t) => t.status.equals(SyncOutboxStatus.FAILED.index)))
        .get();
    for (final entry in failed) {
      await (_db.update(_db.syncOutbox)..where((t) => t.id.equals(entry.id)))
          .write(SyncOutboxCompanion(
        status: Value(SyncOutboxStatus.PENDING),
        retryCount: Value(0),
      ));
    }
  }

  Duration _computeCumulativeDelay(int retryCount) {
    var totalSeconds = 0;
    for (int i = 1; i <= retryCount; i++) {
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
        errorCode == 'ENTITY_NOT_FOUND';
  }

  Future<void> _updateEntitySyncStatus(
    String entityType,
    String entityId,
    SyncStatus syncStatus,
  ) async {
    final tableName = _entityTableName[entityType];
    if (tableName == null) return;
    await _db.customStatement(
      'UPDATE "$tableName" SET "syncStatus" = ? WHERE "id" = ?',
      [syncStatus.index, entityId],
    );
  }

  static const Map<String, String> _entityTableName = {
    'PRODUCT': 'products',
    'CLIENT': 'clients',
    'SALES_INVOICE': 'sales_invoices',
    'SALES_INVOICE_LINE': 'sales_invoice_lines',
    'RECEIPT': 'receipts',
    'RECEIPT_ALLOCATION': 'receipt_allocations',
    'EXPENSE': 'expenses',
    'SALES_RETURN': 'sales_returns',
    'SALES_RETURN_LINE': 'sales_return_lines',
    'ATTACHMENT_METADATA': 'attachment_metadata',
  };
}
