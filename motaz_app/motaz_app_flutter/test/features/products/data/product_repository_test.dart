import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/core/database/app_database.dart';
import 'package:motaz_app_flutter/core/database/enums/enums.dart';
import 'package:motaz_app_flutter/features/products/data/product_repository.dart';

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

Future<void> _insertDevice(AppDatabase db) {
  return db
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
  late ProductRepository repository;

  setUp(() async {
    db = _createInMemoryDatabase();
    repository = ProductRepository(db);
    await _insertDevice(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ProductRepository offline-first behavior', () {
    test(
      'saves product locally and enqueues sync before remote work',
      () async {
        final product = await repository.createAndReturn(
          const ProductsCompanion(
            name: Value('Test Product'),
            description: Value('Primary test item'),
            defaultSalePrice: Value(125000),
            unit: Value('carton'),
            sku: Value('SKU-001'),
            shelfLifeDays: Value(30),
            deviceId: Value(_deviceId),
          ),
        );

        final savedProduct = await repository.getById(product.id);
        final outboxRows = await db.select(db.syncOutbox).get();
        final productOutbox = outboxRows.singleWhere(
          (row) => row.entityType == ParentEntityType.PRODUCT,
        );
        final payload =
            jsonDecode(productOutbox.payload) as Map<String, dynamic>;

        expect(savedProduct.name, 'Test Product');
        expect(savedProduct.defaultSalePrice, 125000);
        expect(savedProduct.unit, 'carton');
        expect(savedProduct.sku, 'SKU-001');
        expect(savedProduct.shelfLifeDays, 30);
        expect(savedProduct.rowVersion, 1);
        expect(savedProduct.syncStatus, SyncStatus.PENDING);
        expect(outboxRows, hasLength(1));
        expect(productOutbox.operation, AuditOperation.CREATE);
        expect(productOutbox.entityId, savedProduct.id);
        expect(productOutbox.status, SyncOutboxStatus.PENDING);
        expect(payload['name'], savedProduct.name);
        expect(payload['defaultSalePrice'], savedProduct.defaultSalePrice);
        expect(payload['syncStatus'], 0);
      },
    );

    test(
      'updates product locally and enqueues sync before remote work',
      () async {
        final product = await repository.createAndReturn(
          const ProductsCompanion(
            name: Value('Product Before Update'),
            defaultSalePrice: Value(100000),
            unit: Value('box'),
            deviceId: Value(_deviceId),
          ),
        );

        await repository.update(
          product.id,
          const ProductsCompanion(
            name: Value('Product After Update'),
            defaultSalePrice: Value(135000),
            unit: Value('carton'),
            shelfLifeDays: Value(45),
          ),
        );

        final savedProduct = await repository.getById(product.id);
        final outboxRows = await db.select(db.syncOutbox).get();
        final productUpdateOutbox = outboxRows.singleWhere(
          (row) =>
              row.entityType == ParentEntityType.PRODUCT &&
              row.operation == AuditOperation.UPDATE,
        );
        final payload =
            jsonDecode(productUpdateOutbox.payload) as Map<String, dynamic>;

        expect(savedProduct.name, 'Product After Update');
        expect(savedProduct.defaultSalePrice, 135000);
        expect(savedProduct.unit, 'carton');
        expect(savedProduct.shelfLifeDays, 45);
        expect(savedProduct.rowVersion, 2);
        expect(savedProduct.syncStatus, SyncStatus.PENDING);
        expect(productUpdateOutbox.entityId, savedProduct.id);
        expect(productUpdateOutbox.status, SyncOutboxStatus.PENDING);
        expect(payload['name'], savedProduct.name);
        expect(payload['defaultSalePrice'], savedProduct.defaultSalePrice);
        expect(payload['unit'], savedProduct.unit);
        expect(payload['shelfLifeDays'], savedProduct.shelfLifeDays);
        expect(payload['rowVersion'], savedProduct.rowVersion);
      },
    );

    test(
      'toggles product active state locally and enqueues sync before remote work',
      () async {
        final product = await repository.createAndReturn(
          const ProductsCompanion(
            name: Value('Toggle Product'),
            defaultSalePrice: Value(99000),
            deviceId: Value(_deviceId),
          ),
        );

        await repository.toggleActive(product.id, false);

        final savedProduct = await repository.getById(product.id);
        final outboxRows = await db.select(db.syncOutbox).get();
        final toggleOutbox = outboxRows.singleWhere(
          (row) =>
              row.entityType == ParentEntityType.PRODUCT &&
              row.operation == AuditOperation.UPDATE,
        );
        final payload =
            jsonDecode(toggleOutbox.payload) as Map<String, dynamic>;

        expect(savedProduct.isActive, isFalse);
        expect(savedProduct.rowVersion, 2);
        expect(savedProduct.syncStatus, SyncStatus.PENDING);
        expect(toggleOutbox.entityId, savedProduct.id);
        expect(toggleOutbox.status, SyncOutboxStatus.PENDING);
        expect(payload['isActive'], isFalse);
        expect(payload['rowVersion'], savedProduct.rowVersion);
      },
    );
  });
}
