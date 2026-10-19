import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/enums/enums.dart';
import '../domain/monthly_profit.dart';
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
  }) => _db.transaction(() async {
    _checkPastMonth(year, month);
    final months = await _engine.timeline(year, month);
    final target = months.last;
    if (target.recorded?.status == RecordStatus.ACTIVE && !target.needsReview) {
      throw StateError('هذا الشهر معتمد بالفعل');
    }
    if (months.any(
      (m) =>
          m.needsReview &&
          !(m == target && m.recorded?.status == RecordStatus.VOIDED),
    )) {
      throw StateError(
        'تغيرت حسابات أشهر سابقة. أعد اعتماد الأشهر المتأثرة بالترتيب',
      );
    }
    for (final entry in months) {
      if (entry.recorded == null || entry.needsReview) {
        await _persist(entry.profit, deviceId, entry.recorded);
      }
    }
    return getForMonth(year, month).then((value) => value!);
  });

  Future<List<MonthSettlement>> reviewTimeline({DateTime? now}) {
    final today = now ?? _engine.today;
    final previous = DateTime(today.year, today.month - 1);
    return _engine.timeline(previous.year, previous.month);
  }

  Future<void> reapproveAffected({required String deviceId}) =>
      _db.transaction(() async {
        final months = await reviewTimeline();
        if (!months.any((m) => m.needsReview)) return;
        var changed = false;
        for (final entry in months) {
          changed = changed || entry.needsReview;
          if (changed || entry.recorded == null) {
            await _persist(entry.profit, deviceId, entry.recorded);
          }
        }
      });

  Future<MonthlyDistribution?> ensurePreviousMonthDistributed({
    required String deviceId,
    DateTime? now,
  }) async {
    final pending =
        await (_db.select(_db.syncOutbox)
              ..where(
                (t) => t.status.isNotValue(SyncOutboxStatus.COMPLETED.index),
              )
              ..limit(1))
            .get();
    final conflicts =
        await (_db.select(_db.conflictLogs)
              ..where(
                (t) => t.resolutionStatus.equals(ConflictStatus.PENDING.index),
              )
              ..limit(1))
            .get();
    if (pending.isNotEmpty || conflicts.isNotEmpty) return null;
    return _db.transaction(() async {
      final months = await reviewTimeline(now: now);
      if (months.any((m) => m.needsReview)) return null;
      MonthlyDistribution? created;
      for (final entry in months) {
        if (entry.recorded == null) {
          created = await _persist(entry.profit, deviceId, null);
        }
      }
      return created;
    });
  }

  Future<void> voidDistribution(String id, String reason, String deviceId) =>
      _db.transaction(() async {
        if (reason.trim().isEmpty) throw ArgumentError('سبب الإلغاء مطلوب');
        final saved = await getById(id);
        if (saved.status == RecordStatus.VOIDED) {
          throw StateError('التسوية ملغاة بالفعل');
        }
        await _persist(
          MonthlyProfit(
            year: saved.year,
            month: saved.month,
            netSales: saved.netSales,
            operationalExpenses: saved.operationalExpenses,
            productionExpenses: saved.productionExpenses,
            carriedLossIn: saved.carriedLossIn,
          ),
          deviceId,
          saved,
          status: RecordStatus.VOIDED,
          reason: reason.trim(),
        );
      });

  Future<MonthlyDistribution> _persist(
    MonthlyProfit profit,
    String deviceId,
    MonthlyDistribution? previous, {
    RecordStatus status = RecordStatus.ACTIVE,
    String? reason,
  }) async {
    final id = previous?.id ?? _distributionId(profit.year, profit.month);
    final now = DateTime.now();
    final version = (previous?.rowVersion ?? 0) + 1;
    final shares = profit.shares;
    final payload = {
      'id': id,
      'year': profit.year,
      'month': profit.month,
      'netSales': profit.netSales,
      'operationalExpenses': profit.operationalExpenses,
      'productionExpenses': profit.productionExpenses,
      'profitBeforeCarry': profit.profitBeforeCarry,
      'currentMonthLoss': profit.currentMonthLoss,
      'carriedLossIn': profit.carriedLossIn,
      'carriedLossOut': profit.carriedLossOut,
      'netProfit': profit.netProfit,
      'ownerShare': shares.ownerShare,
      'partnerShare': shares.partnerShare,
      'marginShare': shares.marginShare,
      'status': status.name,
      'voidReason': reason,
      'createdAt': (previous?.createdAt ?? now).toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'deviceId': deviceId,
      'rowVersion': version,
      'syncStatus': SyncStatus.PENDING.name,
    };
    final companion = MonthlyDistributionsCompanion(
      id: Value(id),
      year: Value(profit.year),
      month: Value(profit.month),
      netSales: Value(profit.netSales),
      operationalExpenses: Value(profit.operationalExpenses),
      productionExpenses: Value(profit.productionExpenses),
      profitBeforeCarry: Value(profit.profitBeforeCarry),
      currentMonthLoss: Value(profit.currentMonthLoss),
      carriedLossIn: Value(profit.carriedLossIn),
      carriedLossOut: Value(profit.carriedLossOut),
      netProfit: Value(profit.netProfit),
      ownerShare: Value(shares.ownerShare),
      partnerShare: Value(shares.partnerShare),
      marginShare: Value(shares.marginShare),
      status: Value(status),
      voidReason: Value(reason),
      createdAt: Value(previous?.createdAt ?? now),
      updatedAt: Value(now),
      deviceId: Value(deviceId),
      rowVersion: Value(version),
      syncStatus: Value(SyncStatus.PENDING),
    );
    if (previous == null) {
      await _db.into(_db.monthlyDistributions).insert(companion);
    } else {
      await (_db.update(
        _db.monthlyDistributions,
      )..where((t) => t.id.equals(id))).write(companion);
    }
    final operation = previous == null
        ? AuditOperation.CREATE
        : AuditOperation.UPDATE;
    await _db
        .into(_db.syncOutbox)
        .insert(
          SyncOutboxCompanion.insert(
            id: _uuid.v4(),
            entityType: ParentEntityType.MONTHLY_DISTRIBUTION,
            entityId: id,
            operation: operation,
            payload: jsonEncode(payload),
            rowVersion: previous?.rowVersion ?? 1,
            deviceId: deviceId,
            createdAt: now,
          ),
        );
    await _db
        .into(_db.auditEvents)
        .insert(
          AuditEventsCompanion.insert(
            id: _uuid.v4(),
            entityType: ParentEntityType.MONTHLY_DISTRIBUTION,
            entityId: id,
            operation: operation,
            diffData: jsonEncode({
              'before': previous?.toJson(),
              'after': payload,
            }),
            deviceId: deviceId,
            createdAt: now,
          ),
        );
    return getById(id);
  }

  void _checkPastMonth(int year, int month) {
    if (year < 1 || month < 1 || month > 12) {
      throw ArgumentError('Invalid month');
    }
    if (!_engine.isPastMonth(year, month)) {
      throw StateError('الشهر الحالي أو المستقبلي للمعاينة فقط');
    }
  }

  String _distributionId(int year, int month) {
    final suffix =
        ('${year.toString().padLeft(4, '0')}'
                '${month.toString().padLeft(2, '0')}')
            .padLeft(12, '0');
    return '00000000-0000-4000-8000-$suffix';
  }

  Future<MonthlyDistribution> getById(String id) => (_db.select(
    _db.monthlyDistributions,
  )..where((t) => t.id.equals(id))).getSingle();

  Stream<List<MonthlyDistribution>> watchAll() =>
      (_db.select(_db.monthlyDistributions)..orderBy([
            (t) => OrderingTerm.desc(t.year),
            (t) => OrderingTerm.desc(t.month),
          ]))
          .watch();

  Future<MonthlyDistribution?> getForMonth(int year, int month) =>
      (_db.select(_db.monthlyDistributions)..where(
            (t) =>
                t.year.equals(year) &
                t.month.equals(month) &
                t.status.equals(RecordStatus.ACTIVE.index),
          ))
          .getSingleOrNull();

  Future<MonthlyDistribution?> getAnyForMonth(int year, int month) =>
      (_db.select(_db.monthlyDistributions)
            ..where((t) => t.year.equals(year) & t.month.equals(month)))
          .getSingleOrNull();
}
