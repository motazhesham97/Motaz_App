import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/enums/audit_operation.dart';
import '../../../core/database/enums/expense_category.dart';
import '../../../core/database/enums/parent_entity_type.dart';
import '../../../core/database/enums/record_status.dart';
import '../../../core/database/enums/sync_outbox_status.dart';
import '../../../core/database/enums/sync_status.dart';

class ExpenseRepository {
  ExpenseRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  static const _categoryLabels = {
    ExpenseCategory.OWNER_DRAW: 'سحب مالك',
    ExpenseCategory.PARTNER_DRAW: 'سحب شريك',
    ExpenseCategory.MARGIN_DRAW: 'سحب هامش',
    ExpenseCategory.OPERATIONAL: 'تشغيلي',
    ExpenseCategory.PRODUCTION: 'إنتاج',
  };

  Future<Expense> create({
    required ExpenseCategory category,
    required int amount,
    required DateTime expenseDate,
    String? note,
    required String deviceId,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Amount must be positive');
    }

    final id = _uuid.v4();
    final now = DateTime.now();

    final payload = jsonEncode({
      'id': id,
      'category': category.index,
      'amount': amount,
      'expenseDate': expenseDate.toIso8601String(),
      'note': note,
      'status': RecordStatus.ACTIVE.index,
      'voidReason': null,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'deviceId': deviceId,
      'rowVersion': 1,
      'syncStatus': SyncStatus.PENDING.index,
    });

    await _db.transaction(() async {
      await _db.into(_db.expenses).insert(
        ExpensesCompanion(
          id: Value(id),
          category: Value(category),
          amount: Value(amount),
          expenseDate: Value(expenseDate),
          note: Value(note),
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
          entityType: ParentEntityType.EXPENSE,
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

  Future<void> update({
    required String id,
    required ExpenseCategory category,
    required int amount,
    required DateTime expenseDate,
    String? note,
    required String deviceId,
  }) async {
    final existing = await getById(id);

    if (existing.status == RecordStatus.VOIDED) {
      throw StateError('Cannot update a voided expense');
    }

    if (amount <= 0) {
      throw ArgumentError('Amount must be positive');
    }

    final now = DateTime.now();
    final newVersion = existing.rowVersion + 1;

    final payload = jsonEncode({
      'id': id,
      'category': category.index,
      'amount': amount,
      'expenseDate': expenseDate.toIso8601String(),
      'note': note,
      'status': RecordStatus.ACTIVE.index,
      'voidReason': null,
      'createdAt': existing.createdAt.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'deviceId': deviceId,
      'rowVersion': newVersion,
      'syncStatus': SyncStatus.PENDING.index,
    });

    await _db.transaction(() async {
      await (_db.update(_db.expenses)..where((t) => t.id.equals(id))).write(
        ExpensesCompanion(
          category: Value(category),
          amount: Value(amount),
          expenseDate: Value(expenseDate),
          note: Value(note),
          updatedAt: Value(now),
          rowVersion: Value(newVersion),
          syncStatus: Value(SyncStatus.PENDING),
        ),
      );
      await _db.into(_db.syncOutbox).insert(
        SyncOutboxCompanion.insert(
          id: _uuid.v4(),
          entityType: ParentEntityType.EXPENSE,
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

  Future<void> voidExpense(String id, String reason, String deviceId) async {
    if (reason.trim().isEmpty) {
      throw ArgumentError('Void reason is required');
    }

    final existing = await getById(id);

    if (existing.status == RecordStatus.VOIDED) {
      throw StateError('Expense is already voided');
    }

    final now = DateTime.now();
    final newVersion = existing.rowVersion + 1;

    final payload = jsonEncode({
      'id': id,
      'category': existing.category.index,
      'amount': existing.amount,
      'expenseDate': existing.expenseDate.toIso8601String(),
      'note': existing.note,
      'status': RecordStatus.VOIDED.index,
      'voidReason': reason,
      'createdAt': existing.createdAt.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'deviceId': existing.deviceId,
      'rowVersion': newVersion,
      'syncStatus': SyncStatus.PENDING.index,
    });

    await _db.transaction(() async {
      await (_db.update(_db.expenses)..where((t) => t.id.equals(id))).write(
        ExpensesCompanion(
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
          entityType: ParentEntityType.EXPENSE,
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

  Future<Expense> getById(String id) async {
    return (_db.select(_db.expenses)..where((t) => t.id.equals(id)))
        .getSingle();
  }

  Stream<List<Expense>> watchAll() {
    return (_db.select(_db.expenses)
          ..orderBy([
            (t) => OrderingTerm.desc(t.expenseDate),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .watch();
  }

  Stream<List<Expense>> searchByText(String query) {
    final q = query.trim().toLowerCase();
    final expenseStream = (_db.select(_db.expenses)
          ..orderBy([
            (t) => OrderingTerm.desc(t.expenseDate),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .watch();

    return expenseStream.map((expenses) {
      if (q.isEmpty) return expenses;

      final matchingCategories = <ExpenseCategory>[];
      for (final entry in _categoryLabels.entries) {
        if (entry.value.contains(q)) {
          matchingCategories.add(entry.key);
        }
      }

      return expenses.where((e) {
        if (matchingCategories.contains(e.category)) return true;
        if (e.note != null && e.note!.toLowerCase().contains(q)) return true;
        return false;
      }).toList();
    });
  }

  Future<int> getMonthlyTotalByCategory(
    ExpenseCategory category,
    int year,
    int month,
  ) async {
    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTime(year, month + 1, 1);

    final result = await (_db.select(_db.expenses)
          ..where((t) =>
              t.category.equals(category.index) &
              t.status.equals(RecordStatus.ACTIVE.index) &
              t.expenseDate.isBiggerOrEqualValue(monthStart) &
              t.expenseDate.isSmallerThanValue(monthEnd)))
        .get();

    return result.fold<int>(0, (sum, e) => sum + e.amount);
  }
}
