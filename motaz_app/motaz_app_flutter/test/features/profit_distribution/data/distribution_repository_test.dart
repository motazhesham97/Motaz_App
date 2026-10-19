import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/core/database/app_database.dart';
import 'package:motaz_app_flutter/core/database/enums/enums.dart';
import 'package:motaz_app_flutter/features/profit_distribution/data/distribution_repository.dart';
import 'package:motaz_app_flutter/features/profit_distribution/data/profit_engine.dart';
import 'package:motaz_app_flutter/features/party_balances/data/party_balance_calculator.dart';

const deviceId = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
const expenseId = 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
final now = DateTime(2026, 7, 10);

Future<void> seedDevice(AppDatabase db) => db
    .into(db.devices)
    .insert(
      DevicesCompanion.insert(
        id: deviceId,
        deviceName: 'Test',
        platform: DevicePlatform.ANDROID,
        deviceCode: 'test',
        createdAt: now,
        lastActiveAt: now,
      ),
    )
    .then((_) {});

Future<void> seedLoss(
  AppDatabase db, {
  DateTime? date,
  int amount = 500000,
  String id = expenseId,
  ExpenseCategory category = ExpenseCategory.OPERATIONAL,
}) => db
    .into(db.expenses)
    .insert(
      ExpensesCompanion.insert(
        id: id,
        category: category,
        amount: amount,
        expenseDate: date ?? DateTime(2026, 1, 15),
        createdAt: now,
        updatedAt: now,
        deviceId: deviceId,
      ),
    )
    .then((_) {});

void main() {
  late AppDatabase db;
  late ProfitEngine engine;
  late DistributionRepository repo;
  Directory? folderToDelete;
  setUp(() async {
    folderToDelete = null;
    db = AppDatabase(
      NativeDatabase.memory(
        setup: (db) => db.execute('PRAGMA foreign_keys = ON'),
      ),
    );
    engine = ProfitEngine(db, now: () => now);
    repo = DistributionRepository(db, engine);
    await seedDevice(db);
  });
  tearDown(() async {
    await db.close();
    await folderToDelete?.delete(recursive: true);
  });

  test(
    'automatic settlement catches up once and does not bypass a voided loss month',
    () async {
      await seedLoss(db);
      final last = await repo.ensurePreviousMonthDistributed(
        deviceId: deviceId,
        now: now,
      );
      expect(last!.month, 6);
      expect(last.carriedLossOut, -500000);
      expect(await db.select(db.monthlyDistributions).get(), hasLength(6));
      await db
          .update(db.syncOutbox)
          .write(
            const SyncOutboxCompanion(
              status: Value(SyncOutboxStatus.COMPLETED),
            ),
          );
      expect(
        await repo.ensurePreviousMonthDistributed(deviceId: deviceId, now: now),
        isNull,
      );
      final january = (await repo.getForMonth(2026, 1))!;
      await repo.voidDistribution(january.id, 'recheck month', deviceId);
      await db
          .update(db.syncOutbox)
          .write(
            const SyncOutboxCompanion(
              status: Value(SyncOutboxStatus.COMPLETED),
            ),
          );
      expect(
        await repo.ensurePreviousMonthDistributed(deviceId: deviceId, now: now),
        isNull,
      );
      expect(
        (await engine.timeline(2026, 6)).last.profit.carriedLossOut,
        -500000,
      );
      expect(
        (await engine.timeline(2026, 6)).every((m) => m.needsReview),
        isTrue,
      );
    },
  );

  test(
    'distributes only recovered surplus and reapproval preserves existing draws',
    () async {
      await seedLoss(db);
      const client = 'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a13';
      await db
          .into(db.clients)
          .insert(
            ClientsCompanion.insert(
              id: client,
              displayName: 'Client',
              createdAt: now,
              updatedAt: now,
              deviceId: deviceId,
            ),
          );
      await db
          .into(db.salesInvoices)
          .insert(
            SalesInvoicesCompanion.insert(
              id: 'd0eebc99-9c0b-4ef8-bb6d-6bb9bd380a14',
              localRef: 'INV-test',
              clientId: client,
              invoiceDate: DateTime(2026, 3, 15),
              total: 1000000,
              createdAt: now,
              updatedAt: now,
              deviceId: deviceId,
            ),
          );
      await seedLoss(
        db,
        date: DateTime(2026, 3, 20),
        amount: 150000,
        id: 'e0eebc99-9c0b-4ef8-bb6d-6bb9bd380a15',
        category: ExpenseCategory.OWNER_DRAW,
      );
      final march = await repo.distribute(
        year: 2026,
        month: 3,
        deviceId: deviceId,
      );
      expect(march.netProfit, 500000);
      expect(march.carriedLossIn, -500000);
      expect(march.carriedLossOut, 0);
      expect(march.currentMonthLoss, 0);
      final balances = PartyBalanceCalculator(db);
      expect((await balances.computeAllBalances()).ownerBalance, 16000);
      await (db.update(db.expenses)..where((t) => t.id.equals(expenseId)))
          .write(const ExpensesCompanion(amount: Value(700000)));
      expect((await balances.computeAllBalances()).ownerBalance, 16000);
      await repo.reapproveAffected(deviceId: deviceId);
      expect((await repo.getForMonth(2026, 3))!.netProfit, 300000);
      expect((await balances.computeAllBalances()).ownerBalance, -50000);
    },
  );

  test(
    'preserves pending loss and carries December into January after reopening',
    () async {
      final folder = await Directory.systemTemp.createTemp('loss-restart-');
      folderToDelete = folder;
      final file = File('${folder.path}/test.db');
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      final first = db;
      final clock = DateTime(2027, 2, 10);
      await seedDevice(first);
      await seedLoss(first, date: DateTime(2026, 12, 15));
      await DistributionRepository(
        first,
        ProfitEngine(first, now: () => clock),
      ).distribute(year: 2026, month: 12, deviceId: deviceId);
      await first.close();
      db = AppDatabase(NativeDatabase(file));
      final reopened = db;
      final chain = await ProfitEngine(reopened).timeline(2027, 1);
      expect(chain.last.profit.currentMonthLoss, 0);
      expect(chain.last.profit.carriedLossIn, -500000);
      expect(chain.last.profit.carriedLossOut, -500000);
      expect(
        (await reopened.select(reopened.syncOutbox).getSingle()).status,
        SyncOutboxStatus.PENDING,
      );
    },
  );

  test(
    'rolls back the settlement and audit when its sync enqueue fails',
    () async {
      await seedLoss(db);
      await db.customStatement(
        "CREATE TRIGGER fail_queue BEFORE INSERT ON sync_outbox BEGIN SELECT RAISE(ABORT, 'queue unavailable'); END;",
      );
      await expectLater(
        repo.distribute(year: 2026, month: 1, deviceId: deviceId),
        throwsA(isA<Exception>()),
      );
      expect(await db.select(db.monthlyDistributions).get(), isEmpty);
      expect(await db.select(db.auditEvents).get(), isEmpty);
      expect((await db.select(db.expenses).getSingle()).amount, 500000);
    },
  );

  test(
    'fills missing months and requires explicit chronological reapproval after an edit',
    () async {
      await seedLoss(db);
      await repo.distribute(year: 2026, month: 3, deviceId: deviceId);
      final months = await engine.timeline(2026, 3);
      expect(months.map((m) => m.profit.carriedLossOut), [
        -500000,
        -500000,
        -500000,
      ]);
      expect(months.every((m) => !m.needsReview), isTrue);
      await (db.update(db.expenses)..where((t) => t.id.equals(expenseId)))
          .write(const ExpensesCompanion(amount: Value(700000)));
      expect((await repo.getForMonth(2026, 3))!.carriedLossOut, -500000);
      expect(
        (await engine.timeline(2026, 3)).every((m) => m.needsReview),
        isTrue,
      );
      await expectLater(
        repo.distribute(year: 2026, month: 4, deviceId: deviceId),
        throwsStateError,
      );
      await repo.reapproveAffected(deviceId: deviceId);
      final revised = (await engine.timeline(2026, 3));
      expect(revised.every((m) => !m.needsReview), isTrue);
      expect(revised.last.recorded!.carriedLossOut, -700000);
      expect(revised.last.recorded!.rowVersion, 2);
      await expectLater(
        repo.distribute(year: 2026, month: 3, deviceId: deviceId),
        throwsStateError,
      );
    },
  );

  test(
    'saves loss locally with zero shares, audit and pending outbox atomically',
    () async {
      await seedLoss(db);
      final saved = await repo.distribute(
        year: 2026,
        month: 1,
        deviceId: deviceId,
      );
      expect(saved.netProfit, -500000);
      expect(saved.currentMonthLoss, -500000);
      expect(saved.carriedLossIn, 0);
      expect(saved.carriedLossOut, -500000);
      expect(
        [saved.ownerShare, saved.partnerShare, saved.marginShare],
        [0, 0, 0],
      );
      final queue = await db.select(db.syncOutbox).getSingle();
      expect(queue.status, SyncOutboxStatus.PENDING);
      expect(jsonDecode(queue.payload)['carriedLossOut'], -500000);
      expect((await db.select(db.auditEvents).get()).length, 1);
      expect((await engine.timeline(2026, 1)).single.needsReview, isFalse);
    },
  );
}
