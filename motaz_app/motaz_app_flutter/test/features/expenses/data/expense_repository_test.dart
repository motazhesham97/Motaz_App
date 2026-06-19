import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/core/database/app_database.dart';
import 'package:motaz_app_flutter/core/database/enums/enums.dart';
import 'package:motaz_app_flutter/features/expenses/data/expense_repository.dart';

AppDatabase _createInMemoryDatabase() {
  return AppDatabase(
    NativeDatabase.memory(
      setup: (rawDb) {
        rawDb.execute('PRAGMA foreign_keys = ON');
      },
    ),
  );
}

const _deviceId = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
final _now = DateTime(2026, 1, 1, 10);

Future<void> _seedDevice(AppDatabase db) async {
  await db
      .into(db.devices)
      .insert(
        DevicesCompanion(
          id: const Value(_deviceId),
          deviceName: const Value('Test Device'),
          platform: const Value(DevicePlatform.ANDROID),
          deviceCode: const Value('t001'),
          createdAt: Value(_now),
          lastActiveAt: Value(_now),
        ),
      );
}

void main() {
  late AppDatabase db;
  late ExpenseRepository repository;

  setUp(() async {
    db = _createInMemoryDatabase();
    repository = ExpenseRepository(db);
    await _seedDevice(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ExpenseRepository offline-first behavior', () {
    test(
      'saves expense locally and enqueues sync before remote work',
      () async {
        final expense = await repository.create(
          category: ExpenseCategory.OPERATIONAL,
          amount: 45000,
          expenseDate: DateTime(2026, 1, 2),
          note: 'Fuel',
          deviceId: _deviceId,
        );

        final savedExpense = await repository.getById(expense.id);
        final outboxRows = await db.select(db.syncOutbox).get();
        final expenseOutbox = outboxRows.singleWhere(
          (row) => row.entityType == ParentEntityType.EXPENSE,
        );
        final payload =
            jsonDecode(expenseOutbox.payload) as Map<String, dynamic>;

        expect(savedExpense.category, ExpenseCategory.OPERATIONAL);
        expect(savedExpense.amount, 45000);
        expect(savedExpense.note, 'Fuel');
        expect(savedExpense.status, RecordStatus.ACTIVE);
        expect(savedExpense.syncStatus, SyncStatus.PENDING);
        expect(outboxRows, hasLength(1));
        expect(expenseOutbox.operation, AuditOperation.CREATE);
        expect(expenseOutbox.entityId, savedExpense.id);
        expect(expenseOutbox.status, SyncOutboxStatus.PENDING);
        expect(payload['category'], ExpenseCategory.OPERATIONAL.index);
        expect(payload['amount'], 45000);
        expect(payload['syncStatus'], SyncStatus.PENDING.index);
      },
    );
  });
}
