import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_client/motaz_app_client.dart' as server;
import 'package:motaz_app_flutter/core/database/app_database.dart';
import 'package:motaz_app_flutter/core/database/enums/enums.dart';
import 'package:motaz_app_flutter/features/profit_distribution/data/distribution_repository.dart';
import 'package:motaz_app_flutter/features/profit_distribution/data/profit_engine.dart';
import 'package:motaz_app_flutter/features/sync/application/outbox_processor.dart';
import 'package:motaz_app_flutter/features/sync/application/pull_processor.dart';
import 'package:motaz_app_flutter/features/sync/domain/field_classifier.dart';

const device = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
Future<void> seedDevice(AppDatabase db) async {
  final now = DateTime(2026, 1, 1);
  await db
      .into(db.devices)
      .insert(
        DevicesCompanion.insert(
          id: device,
          deviceName: 'Offline device',
          platform: DevicePlatform.ANDROID,
          deviceCode: 'test',
          createdAt: now,
          lastActiveAt: now,
        ),
      );
}

void main() {
  test(
    'uploads monthly settlements chronologically and pauses successors when a predecessor fails',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final client = server.Client('http://127.0.0.1:1/');
      try {
        await seedDevice(db);
        final now = DateTime(2026, 1, 10);
        await db
            .into(db.expenses)
            .insert(
              ExpensesCompanion.insert(
                id: 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12',
                category: ExpenseCategory.OPERATIONAL,
                amount: 100000,
                expenseDate: now,
                createdAt: now,
                updatedAt: now,
                deviceId: device,
              ),
            );
        await DistributionRepository(
          db,
          ProfitEngine(db),
        ).distribute(year: 2026, month: 3, deviceId: device);
        await db
            .update(db.syncOutbox)
            .write(SyncOutboxCompanion(createdAt: Value(now)));
        final order = <int>[];
        var fail = true;
        final processor = OutboxProcessor(
          db: db,
          serverClient: client,
          pushOverride: (request) async {
            order.add(
              (jsonDecode(request.payload) as Map<String, dynamic>)['month']
                  as int,
            );
            return fail
                ? server.PushResponse(success: false, errorCode: 'SERVER_ERROR')
                : server.PushResponse(success: true, newRowVersion: 1);
          },
        );
        await processor.processPending();
        expect(order, [1]);
        fail = false;
        await processor.retryFailed();
        await processor.processPending();
        expect(order, [1, 1, 2, 3]);
        expect(
          (await db.select(db.syncOutbox).get()).every(
            (row) => row.status == SyncOutboxStatus.COMPLETED,
          ),
          isTrue,
        );
      } finally {
        await db.close();
        client.close();
      }
    },
  );
  test(
    'retains loss on auth failure, retries once and transfers all loss fields to a second device',
    () async {
      final client = server.Client('http://127.0.0.1:1/');
      final first = AppDatabase(NativeDatabase.memory());
      final cloudRows = <String>[];
      try {
        await seedDevice(first);
        final now = DateTime(2026, 1, 10);
        await first
            .into(first.expenses)
            .insert(
              ExpensesCompanion.insert(
                id: 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12',
                category: ExpenseCategory.PRODUCTION,
                amount: 123456,
                expenseDate: now,
                createdAt: now,
                updatedAt: now,
                deviceId: device,
              ),
            );
        await DistributionRepository(
          first,
          ProfitEngine(first),
        ).distribute(year: 2026, month: 1, deviceId: device);
        var authenticated = false;
        final processor = OutboxProcessor(
          db: first,
          serverClient: client,
          pushOverride: (request) async {
            if (!authenticated) {
              return server.PushResponse(
                success: false,
                errorCode: 'UNAUTHENTICATED',
              );
            }
            final payload = jsonDecode(request.payload) as Map<String, dynamic>;
            final canonical = server.MonthlyDistribution.fromJson(
              payload,
            ).toJson()..remove('__className__');
            cloudRows.add(
              jsonEncode({
                ...canonical,
                'rowVersion': 1,
                'syncStatus': 'SYNCED',
              }),
            );
            return server.PushResponse(success: true, newRowVersion: 1);
          },
        );
        await processor.processPending();
        expect(
          (await first.select(first.monthlyDistributions).getSingle())
              .carriedLossOut,
          -123456,
        );
        expect(
          (await first.select(first.syncOutbox).getSingle()).status,
          SyncOutboxStatus.FAILED,
        );
        authenticated = true;
        await processor.retryFailed();
        await processor.processPending();
        await processor.processPending();
        expect(cloudRows, hasLength(1));
        expect(
          (await first.select(first.monthlyDistributions).getSingle())
              .syncStatus,
          SyncStatus.SYNCED,
        );
      } finally {
        await first.close();
      }
      final second = AppDatabase(NativeDatabase.memory());
      try {
        await seedDevice(second);
        await PullProcessor(
          db: second,
          serverClient: client,
          pullOverride: (request) async => server.PullResponse(
            entityType: request.entityType,
            rows: cloudRows,
            latestRowVersion: 1,
            hasMore: false,
          ),
        ).pullEntityType(ParentEntityType.MONTHLY_DISTRIBUTION);
        final restored = await second
            .select(second.monthlyDistributions)
            .getSingle();
        expect(restored.currentMonthLoss, -123456);
        expect(restored.carriedLossIn, 0);
        expect(restored.carriedLossOut, -123456);
        expect(
          restored.ownerShare + restored.partnerShare + restored.marginShare,
          0,
        );
        expect(
          FieldClassifier.hasConflictRequiredFieldChanges(
            'MONTHLY_DISTRIBUTION',
            {'carriedLossIn', 'carriedLossOut'},
          ),
          isTrue,
        );
      } finally {
        await second.close();
        client.close();
      }
    },
  );
}
