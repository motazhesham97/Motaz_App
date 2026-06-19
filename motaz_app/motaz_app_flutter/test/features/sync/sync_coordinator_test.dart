import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_client/motaz_app_client.dart' as server;
import 'package:motaz_app_flutter/core/connectivity/connectivity_provider.dart';
import 'package:motaz_app_flutter/core/database/app_database.dart';
import 'package:motaz_app_flutter/core/database/device_service.dart';
import 'package:motaz_app_flutter/core/database/enums/enums.dart';
import 'package:motaz_app_flutter/core/server/app_config.dart';
import 'package:motaz_app_flutter/core/server/local_server_launcher.dart';
import 'package:motaz_app_flutter/features/profit_distribution/data/distribution_repository.dart';
import 'package:motaz_app_flutter/features/profit_distribution/data/profit_engine.dart';
import 'package:motaz_app_flutter/features/sync/application/sync_coordinator.dart';
import 'package:motaz_app_flutter/features/sync/domain/sync_state.dart';

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
const _productId = 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12';
const _outboxId = 'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a13';
final _now = DateTime(2026, 1, 1, 10);

Future<void> _seedPendingProduct(AppDatabase db) async {
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
  await db
      .into(db.products)
      .insert(
        ProductsCompanion(
          id: const Value(_productId),
          name: const Value('Offline Product'),
          defaultSalePrice: const Value(25000),
          createdAt: Value(_now),
          updatedAt: Value(_now),
          deviceId: const Value(_deviceId),
          syncStatus: const Value(SyncStatus.PENDING),
        ),
      );
  await db
      .into(db.syncOutbox)
      .insert(
        SyncOutboxCompanion.insert(
          id: _outboxId,
          entityType: ParentEntityType.PRODUCT,
          entityId: _productId,
          operation: AuditOperation.CREATE,
          payload: jsonEncode({
            'id': _productId,
            'name': 'Offline Product',
            'syncStatus': SyncStatus.PENDING.index,
          }),
          rowVersion: 1,
          deviceId: _deviceId,
          createdAt: _now,
          status: const Value(SyncOutboxStatus.PENDING),
        ),
      );
}

class _SessionManager {
  bool get isAuthenticated => false;
}

void main() {
  late AppDatabase db;
  late SyncCoordinator coordinator;

  setUp(() async {
    db = _createInMemoryDatabase();
    await _seedPendingProduct(db);
    coordinator = SyncCoordinator(
      db: db,
      serverClient: server.Client('http://127.0.0.1:1/'),
      deviceService: DeviceService(db),
      distributionRepository: DistributionRepository(db, ProfitEngine(db)),
      connectivityStream: const Stream<ConnectivityStatus>.empty(),
      localServerLauncher: LocalServerLauncher(
        const AppConfig(
          apiUrl: 'http://127.0.0.1:1',
          apiUrlAndroid: 'http://127.0.0.1:1',
          runMode: 'test',
        ),
      ),
      sessionManager: _SessionManager(),
    );
  });

  tearDown(() async {
    coordinator.dispose();
    await db.close();
  });

  group('SyncCoordinator offline-first behavior', () {
    test(
      'keeps pending local data unchanged when sync is requested offline',
      () async {
        await coordinator.syncNow();

        final product = await (db.select(
          db.products,
        )..where((t) => t.id.equals(_productId))).getSingle();
        final outbox = await (db.select(
          db.syncOutbox,
        )..where((t) => t.id.equals(_outboxId))).getSingle();

        expect(coordinator.currentState.status, SyncPhase.error);
        expect(coordinator.currentState.errorMessage, 'No internet connection');
        expect(product.name, 'Offline Product');
        expect(product.syncStatus, SyncStatus.PENDING);
        expect(outbox.entityType, ParentEntityType.PRODUCT);
        expect(outbox.entityId, _productId);
        expect(outbox.status, SyncOutboxStatus.PENDING);
        expect(outbox.retryCount, 0);
      },
    );
  });
}
