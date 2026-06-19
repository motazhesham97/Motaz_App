import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/core/database/app_database.dart';
import 'package:motaz_app_flutter/core/database/enums/enums.dart';
import 'package:motaz_app_flutter/features/party_balances/data/party_adjustment_repository.dart';

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
  late PartyAdjustmentRepository repository;

  setUp(() async {
    db = _createInMemoryDatabase();
    repository = PartyAdjustmentRepository(db);
    await _seedDevice(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('PartyAdjustmentRepository offline-first behavior', () {
    test(
      'saves party adjustment locally and enqueues sync before remote work',
      () async {
        final adjustment = await repository.create(
          party: PartyAccount.PARTNER,
          amount: 75000,
          adjustmentDate: DateTime(2026, 1, 2),
          note: 'Capital addition',
          deviceId: _deviceId,
        );

        final savedAdjustment = await repository.getById(adjustment.id);
        final outboxRows = await db.select(db.syncOutbox).get();
        final adjustmentOutbox = outboxRows.singleWhere(
          (row) => row.entityType == ParentEntityType.PARTY_ADJUSTMENT,
        );
        final payload =
            jsonDecode(adjustmentOutbox.payload) as Map<String, dynamic>;

        expect(savedAdjustment.party, PartyAccount.PARTNER);
        expect(savedAdjustment.amount, 75000);
        expect(savedAdjustment.note, 'Capital addition');
        expect(savedAdjustment.status, RecordStatus.ACTIVE);
        expect(savedAdjustment.syncStatus, SyncStatus.PENDING);
        expect(outboxRows, hasLength(1));
        expect(adjustmentOutbox.operation, AuditOperation.CREATE);
        expect(adjustmentOutbox.entityId, savedAdjustment.id);
        expect(adjustmentOutbox.status, SyncOutboxStatus.PENDING);
        expect(payload['party'], PartyAccount.PARTNER.index);
        expect(payload['amount'], 75000);
        expect(payload['syncStatus'], SyncStatus.PENDING.index);
      },
    );
  });
}
