import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/enums/audit_operation.dart';
import '../../../core/database/enums/parent_entity_type.dart';
import '../../../core/database/enums/record_status.dart';
import '../../../core/database/enums/sync_outbox_status.dart';
import '../../../core/database/enums/sync_status.dart';
import 'profit_engine.dart';

class DistributionRepository {
  DistributionRepository(this._db, this._engine);

  final AppDatabase _db;
  final ProfitEngine _engine;
  final _uuid = const Uuid();

  Future<MonthlyDistribution> distribute({
    required int year,
    required int month,
    required String deviceId,
  }) async {
    if (month < 1 || month > 12) {
      throw ArgumentError('Month must be between 1 and 12');
    }

    if (!_engine.isPastMonth(year, month)) {
      throw StateError('Cannot distribute for current or future month');
    }

    final existing = await getForMonth(year, month);
    if (existing != null) {
      throw StateError('Distribution already exists for $year-$month');
    }

    final netProfit = await _engine.computeMonthlyNetProfit(year, month);
    final shares = _engine.computeDistribution(netProfit);

    final id = _uuid.v4();
    final now = DateTime.now();

    final payload = jsonEncode({
      'id': id,
      'year': year,
      'month': month,
      'netProfit': netProfit,
      'ownerShare': shares.ownerShare,
      'partnerShare': shares.partnerShare,
      'marginShare': shares.marginShare,
      'status': RecordStatus.ACTIVE.index,
      'voidReason': null,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'deviceId': deviceId,
      'rowVersion': 1,
      'syncStatus': SyncStatus.PENDING.index,
    });

    await _db.transaction(() async {
      await _db.into(_db.monthlyDistributions).insert(
        MonthlyDistributionsCompanion(
          id: Value(id),
          year: Value(year),
          month: Value(month),
          netProfit: Value(netProfit),
          ownerShare: Value(shares.ownerShare),
          partnerShare: Value(shares.partnerShare),
          marginShare: Value(shares.marginShare),
          status: Value(RecordStatus.ACTIVE),
          voidReason: Value.absent(),
          createdAt: Value(now),
          updatedAt: Value(now),
          deviceId: Value(deviceId),
          rowVersion: const Value(1),
          syncStatus: Value(SyncStatus.PENDING),
        ),
      );
      await _db.into(_db.syncOutbox).insert(
        SyncOutboxCompanion.insert(
          id: _uuid.v4(),
          entityType: ParentEntityType.MONTHLY_DISTRIBUTION,
          entityId: id,
          operation: AuditOperation.CREATE,
          payload: payload,
          rowVersion: 1,
          deviceId: deviceId,
          createdAt: now,
          status: Value(SyncOutboxStatus.PENDING),
        ),
      );
    });

    return await getById(id);
  }

  Future<void> voidDistribution(
    String id,
    String reason,
    String deviceId,
  ) async {
    if (reason.trim().isEmpty) {
      throw ArgumentError('Void reason is required');
    }

    final existing = await getById(id);

    if (existing.status == RecordStatus.VOIDED) {
      throw StateError('Distribution is already voided');
    }

    final now = DateTime.now();
    final newVersion = existing.rowVersion + 1;

    final payload = jsonEncode({
      'id': id,
      'year': existing.year,
      'month': existing.month,
      'netProfit': existing.netProfit,
      'ownerShare': existing.ownerShare,
      'partnerShare': existing.partnerShare,
      'marginShare': existing.marginShare,
      'status': RecordStatus.VOIDED.index,
      'voidReason': reason,
      'createdAt': existing.createdAt.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'deviceId': existing.deviceId,
      'rowVersion': newVersion,
      'syncStatus': SyncStatus.PENDING.index,
    });

    await _db.transaction(() async {
      await (_db.update(_db.monthlyDistributions)
            ..where((t) => t.id.equals(id)))
          .write(
        MonthlyDistributionsCompanion(
          status: Value(RecordStatus.VOIDED),
          voidReason: Value(reason),
          updatedAt: Value(now),
          rowVersion: Value(newVersion),
          syncStatus: Value(SyncStatus.PENDING),
        ),
      );
      await _db.into(_db.syncOutbox).insert(
        SyncOutboxCompanion.insert(
          id: _uuid.v4(),
          entityType: ParentEntityType.MONTHLY_DISTRIBUTION,
          entityId: id,
          operation: AuditOperation.UPDATE,
          payload: payload,
          rowVersion: newVersion,
          deviceId: deviceId,
          createdAt: now,
          status: Value(SyncOutboxStatus.PENDING),
        ),
      );
    });
  }

  Future<MonthlyDistribution> getById(String id) async {
    return (_db.select(_db.monthlyDistributions)
          ..where((t) => t.id.equals(id)))
        .getSingle();
  }

  Stream<List<MonthlyDistribution>> watchAll() {
    return (_db.select(_db.monthlyDistributions)
          ..orderBy([
            (t) => OrderingTerm.desc(t.year),
            (t) => OrderingTerm.desc(t.month),
          ]))
        .watch();
  }

  Future<MonthlyDistribution?> getForMonth(int year, int month) async {
    final results = await (_db.select(_db.monthlyDistributions)
          ..where((t) =>
              t.year.equals(year) &
              t.month.equals(month) &
              t.status.equals(RecordStatus.ACTIVE.index)))
        .get();
    return results.isEmpty ? null : results.first;
  }
}
