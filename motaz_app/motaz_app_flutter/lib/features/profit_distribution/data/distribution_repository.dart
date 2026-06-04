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

    final recordedDistribution = await getAnyForMonth(year, month);
    if (recordedDistribution?.status == RecordStatus.ACTIVE) {
      throw StateError('Distribution already exists for $year-$month');
    }

    final netProfit = await _engine.computeMonthlyNetProfit(year, month);
    final shares = _engine.computeDistribution(netProfit);

    final id = recordedDistribution?.id ?? _distributionId(year, month);
    final now = DateTime.now();

    if (recordedDistribution != null) {
      final newVersion = recordedDistribution.rowVersion + 1;
      final payload = jsonEncode({
        'id': id,
        'year': year,
        'month': month,
        'netProfit': netProfit,
        'ownerShare': shares.ownerShare,
        'partnerShare': shares.partnerShare,
        'marginShare': shares.marginShare,
        'status': RecordStatus.ACTIVE.name,
        'voidReason': null,
        'createdAt': recordedDistribution.createdAt.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'deviceId': deviceId,
        'rowVersion': newVersion,
        'syncStatus': SyncStatus.PENDING.name,
      });

      await _db.transaction(() async {
        await (_db.update(
          _db.monthlyDistributions,
        )..where((t) => t.id.equals(id))).write(
          MonthlyDistributionsCompanion(
            netProfit: Value(netProfit),
            ownerShare: Value(shares.ownerShare),
            partnerShare: Value(shares.partnerShare),
            marginShare: Value(shares.marginShare),
            status: Value(RecordStatus.ACTIVE),
            voidReason: const Value<String?>(null),
            updatedAt: Value(now),
            deviceId: Value(deviceId),
            rowVersion: Value(newVersion),
            syncStatus: Value(SyncStatus.PENDING),
          ),
        );
        await _db
            .into(_db.syncOutbox)
            .insert(
              SyncOutboxCompanion.insert(
                id: _uuid.v4(),
                entityType: ParentEntityType.MONTHLY_DISTRIBUTION,
                entityId: id,
                operation: AuditOperation.UPDATE,
                payload: payload,
                rowVersion: recordedDistribution.rowVersion,
                deviceId: deviceId,
                createdAt: now,
                status: Value(SyncOutboxStatus.PENDING),
              ),
            );
      });

      return await getById(id);
    }

    final payload = jsonEncode({
      'id': id,
      'year': year,
      'month': month,
      'netProfit': netProfit,
      'ownerShare': shares.ownerShare,
      'partnerShare': shares.partnerShare,
      'marginShare': shares.marginShare,
      'status': RecordStatus.ACTIVE.name,
      'voidReason': null,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'deviceId': deviceId,
      'rowVersion': 1,
      'syncStatus': SyncStatus.PENDING.name,
    });

    await _db.transaction(() async {
      await _db
          .into(_db.monthlyDistributions)
          .insert(
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
      await _db
          .into(_db.syncOutbox)
          .insert(
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

  String _distributionId(int year, int month) {
    final suffix =
        '${year.toString().padLeft(4, '0')}'
                '${month.toString().padLeft(2, '0')}'
            .padLeft(12, '0');
    return '00000000-0000-4000-8000-$suffix';
  }

  Future<MonthlyDistribution?> ensurePreviousMonthDistributed({
    required String deviceId,
    DateTime? now,
  }) async {
    final today = now ?? DateTime.now();
    final previousMonthDate = DateTime(today.year, today.month - 1, 1);
    final year = previousMonthDate.year;
    final month = previousMonthDate.month;

    final previouslyRecorded = await getAnyForMonth(year, month);
    if (previouslyRecorded != null) return null;

    return distribute(year: year, month: month, deviceId: deviceId);
  }

  Future<void> voidDistribution(
    String id,
    String reason,
    String deviceId,
  ) async {
    if (reason.trim().isEmpty) {
      throw ArgumentError('Void reason is required');
    }

    final selected = await getById(id);

    if (selected.status == RecordStatus.VOIDED) {
      throw StateError('Distribution is already voided');
    }

    final now = DateTime.now();
    final activeRows =
        await (_db.select(_db.monthlyDistributions)
              ..where(
                (t) =>
                    t.year.equals(selected.year) &
                    t.month.equals(selected.month) &
                    t.status.equals(RecordStatus.ACTIVE.index),
              )
              ..orderBy([
                (t) => OrderingTerm.desc(t.updatedAt),
                (t) => OrderingTerm.desc(t.createdAt),
              ]))
            .get();

    if (activeRows.isEmpty) {
      throw StateError('No active distribution exists for this month');
    }

    await _db.transaction(() async {
      for (final distribution in activeRows) {
        final newVersion = distribution.rowVersion + 1;
        final payload = jsonEncode({
          'id': distribution.id,
          'year': distribution.year,
          'month': distribution.month,
          'netProfit': distribution.netProfit,
          'ownerShare': distribution.ownerShare,
          'partnerShare': distribution.partnerShare,
          'marginShare': distribution.marginShare,
          'status': RecordStatus.VOIDED.name,
          'voidReason': reason,
          'createdAt': distribution.createdAt.toIso8601String(),
          'updatedAt': now.toIso8601String(),
          'deviceId': distribution.deviceId,
          'rowVersion': newVersion,
          'syncStatus': SyncStatus.PENDING.name,
        });

        await (_db.update(
          _db.monthlyDistributions,
        )..where((t) => t.id.equals(distribution.id))).write(
          MonthlyDistributionsCompanion(
            status: Value(RecordStatus.VOIDED),
            voidReason: Value(reason),
            updatedAt: Value(now),
            rowVersion: Value(newVersion),
            syncStatus: Value(SyncStatus.PENDING),
          ),
        );
        await _db
            .into(_db.syncOutbox)
            .insert(
              SyncOutboxCompanion.insert(
                id: _uuid.v4(),
                entityType: ParentEntityType.MONTHLY_DISTRIBUTION,
                entityId: distribution.id,
                operation: AuditOperation.UPDATE,
                payload: payload,
                rowVersion: distribution.rowVersion,
                deviceId: deviceId,
                createdAt: now,
                status: Value(SyncOutboxStatus.PENDING),
              ),
            );
      }
    });
  }

  Future<MonthlyDistribution> getById(String id) async {
    return (_db.select(
      _db.monthlyDistributions,
    )..where((t) => t.id.equals(id))).getSingle();
  }

  Stream<List<MonthlyDistribution>> watchAll() {
    return (_db.select(_db.monthlyDistributions)..orderBy([
          (t) => OrderingTerm.desc(t.year),
          (t) => OrderingTerm.desc(t.month),
          (t) => OrderingTerm.desc(t.updatedAt),
          (t) => OrderingTerm.desc(t.createdAt),
        ]))
        .watch();
  }

  Future<MonthlyDistribution?> getForMonth(int year, int month) async {
    final results =
        await (_db.select(_db.monthlyDistributions)
              ..where(
                (t) =>
                    t.year.equals(year) &
                    t.month.equals(month) &
                    t.status.equals(RecordStatus.ACTIVE.index),
              )
              ..orderBy([
                (t) => OrderingTerm.desc(t.updatedAt),
                (t) => OrderingTerm.desc(t.createdAt),
              ]))
            .get();
    return results.isEmpty ? null : results.first;
  }

  Future<MonthlyDistribution?> getAnyForMonth(int year, int month) async {
    final results =
        await (_db.select(_db.monthlyDistributions)
              ..where((t) => t.year.equals(year) & t.month.equals(month))
              ..orderBy([
                (t) => OrderingTerm.desc(t.updatedAt),
                (t) => OrderingTerm.desc(t.createdAt),
              ]))
            .get();
    return results.isEmpty ? null : results.first;
  }
}
