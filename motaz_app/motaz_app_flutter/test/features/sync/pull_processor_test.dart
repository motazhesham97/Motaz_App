import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_client/motaz_app_client.dart' as server;
import 'package:motaz_app_flutter/core/database/app_database.dart';
import 'package:motaz_app_flutter/core/database/enums/enums.dart';
import 'package:motaz_app_flutter/features/sync/application/pull_processor.dart';

void main() {
  test('normal pull uses saved cursor and full pull starts at zero', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final now = DateTime(2026, 1, 1);
    const deviceId = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

    await db
        .into(db.devices)
        .insert(
          DevicesCompanion(
            id: const Value(deviceId),
            deviceName: const Value('Test Device'),
            platform: const Value(DevicePlatform.ANDROID),
            deviceCode: const Value('t001'),
            createdAt: Value(now),
            lastActiveAt: Value(now),
          ),
        );
    await db
        .into(db.syncCursor)
        .insert(
          SyncCursorCompanion.insert(
            id: 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12',
            entityType: ParentEntityType.PRODUCT,
            lastRowVersion: const Value(7),
            updatedAt: now,
          ),
        );

    final requestedVersions = <int>[];
    final processor = PullProcessor(
      db: db,
      serverClient: server.Client('http://127.0.0.1:1/'),
      pullOverride: (request) async {
        requestedVersions.add(request.sinceRowVersion);
        return server.PullResponse(
          entityType: request.entityType,
          rows: [],
          hasMore: false,
          latestRowVersion: request.sinceRowVersion,
        );
      },
    );

    await processor.pullEntityType(ParentEntityType.PRODUCT);
    await processor.pullEntityType(ParentEntityType.PRODUCT, forceFull: true);

    expect(requestedVersions, [7, 0]);
    final cursor = await db.select(db.syncCursor).getSingle();
    expect(cursor.lastRowVersion, 7);
  });

  test('pulls every row sharing a version before saving the cursor', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final now = DateTime(2026, 1, 1);
    const deviceId = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
    const firstId = 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12';
    const secondId = 'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a13';

    await db
        .into(db.devices)
        .insert(
          DevicesCompanion(
            id: const Value(deviceId),
            deviceName: const Value('Test Device'),
            platform: const Value(DevicePlatform.ANDROID),
            deviceCode: const Value('t001'),
            createdAt: Value(now),
            lastActiveAt: Value(now),
          ),
        );
    for (final id in [firstId, secondId]) {
      await db
          .into(db.products)
          .insert(
            ProductsCompanion(
              id: Value(id),
              name: Value('Product $id'),
              defaultSalePrice: const Value(100),
              createdAt: Value(now),
              updatedAt: Value(now),
              deviceId: const Value(deviceId),
              syncStatus: const Value(SyncStatus.SYNCED),
            ),
          );
    }
    await db
        .into(db.syncCursor)
        .insert(
          SyncCursorCompanion.insert(
            id: 'd0eebc99-9c0b-4ef8-bb6d-6bb9bd380a14',
            entityType: ParentEntityType.PRODUCT,
            lastRowVersion: const Value(7),
            updatedAt: now,
          ),
        );

    final requests = <server.PullRequest>[];
    final processor = PullProcessor(
      db: db,
      serverClient: server.Client('http://127.0.0.1:1/'),
      pullOverride: (request) async {
        requests.add(request);
        if (requests.length == 1) {
          return server.PullResponse(
            entityType: request.entityType,
            rows: [
              jsonEncode({'id': firstId, 'rowVersion': 8}),
            ],
            hasMore: true,
            latestRowVersion: 8,
          );
        }
        expect((await db.select(db.syncCursor).getSingle()).lastRowVersion, 7);
        return server.PullResponse(
          entityType: request.entityType,
          rows: [
            jsonEncode({'id': secondId, 'rowVersion': 8}),
          ],
          hasMore: false,
          latestRowVersion: 8,
        );
      },
    );

    await processor.pullEntityType(ParentEntityType.PRODUCT);

    expect(requests, hasLength(2));
    expect(requests.first.sinceRowVersion, 7);
    expect(requests.first.afterId, null);
    expect(requests.last.sinceRowVersion, 8);
    expect(requests.last.afterId, firstId);
    expect((await db.select(db.syncCursor).getSingle()).lastRowVersion, 8);
  });
}
