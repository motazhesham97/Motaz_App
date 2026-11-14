import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_client/motaz_app_client.dart' as server;
import 'package:motaz_app_flutter/core/database/app_database.dart';
import 'package:motaz_app_flutter/core/database/enums/enums.dart';
import 'package:motaz_app_flutter/features/sync/application/pull_processor.dart';
import 'package:motaz_app_flutter/features/reports/data/report_queries.dart';
import 'package:motaz_app_flutter/features/invoices/data/invoice_repository.dart';

void main() {
  test('remote invoice lines never overwrite pending local edits', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) => raw.execute('PRAGMA foreign_keys = ON'),
      ),
    );
    addTearDown(db.close);
    final now = DateTime.utc(2026, 11, 14);
    const device = '00000000-0000-4000-8000-000000000021';
    const client = '00000000-0000-4000-8000-000000000022';
    const product = '00000000-0000-4000-8000-000000000023';
    await db
        .into(db.devices)
        .insert(
          DevicesCompanion.insert(
            id: device,
            deviceName: 'Test Device',
            platform: DevicePlatform.ANDROID,
            deviceCode: 't021',
            createdAt: now,
            lastActiveAt: now,
          ),
        );
    await db
        .into(db.clients)
        .insert(
          ClientsCompanion.insert(
            id: client,
            displayName: 'Test Client',
            deviceId: device,
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db
        .into(db.products)
        .insert(
          ProductsCompanion.insert(
            id: product,
            name: 'Test Product',
            defaultSalePrice: 100000,
            deviceId: device,
            createdAt: now,
            updatedAt: now,
          ),
        );
    final invoice = await InvoiceRepository(db).create(
      clientId: client,
      invoiceDate: now,
      discount: 0,
      note: '',
      lines: const [
        SalesInvoiceLinesCompanion(
          productId: Value(product),
          quantity: Value(3),
          unitPrice: Value(100000),
        ),
      ],
      paidAmount: 0,
      deviceId: device,
    );
    final line = await db.select(db.salesInvoiceLines).getSingle();
    final processor = PullProcessor(
      db: db,
      serverClient: server.Client('http://127.0.0.1:1/'),
      pullOverride: (request) async => server.PullResponse(
        entityType: request.entityType,
        rows: [
          jsonEncode({
            'id': line.id,
            'invoiceId': invoice.id,
            'productId': product,
            'quantity': 1,
            'unitPrice': 100000,
            'lineTotal': 100000,
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          }),
        ],
        hasMore: false,
        latestRowVersion: now.microsecondsSinceEpoch,
      ),
    );

    await processor.pullEntityType(ParentEntityType.SALES_INVOICE_LINE);
    expect((await db.select(db.salesInvoiceLines).getSingle()).quantity, 3);
    await db
        .update(db.syncOutbox)
        .write(
          const SyncOutboxCompanion(status: Value(SyncOutboxStatus.COMPLETED)),
        );
    await processor.pullEntityType(ParentEntityType.SALES_INVOICE_LINE);
    expect((await db.select(db.salesInvoiceLines).getSingle()).quantity, 3);
    await db
        .update(db.salesInvoices)
        .write(
          const SalesInvoicesCompanion(syncStatus: Value(SyncStatus.SYNCED)),
        );
    await processor.pullEntityType(ParentEntityType.SALES_INVOICE_LINE);
    expect((await db.select(db.salesInvoiceLines).getSingle()).quantity, 1);
  });

  test(
    'unchanged server rows do not notify the UI but changed values do',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final now = DateTime.utc(2026, 11, 14);
      const device = '00000000-0000-4000-8000-000000000011';
      await db
          .into(db.devices)
          .insert(
            DevicesCompanion.insert(
              id: device,
              deviceName: 'Test Device',
              platform: DevicePlatform.ANDROID,
              deviceCode: 't011',
              createdAt: now,
              lastActiveAt: now,
            ),
          );
      var price = 100000;
      final processor = PullProcessor(
        db: db,
        serverClient: server.Client('http://127.0.0.1:1/'),
        pullOverride: (request) async => server.PullResponse(
          entityType: request.entityType,
          rows: [
            jsonEncode({
              'id': '00000000-0000-4000-8000-000000000012',
              'deviceId': device,
              'name': 'شوكولاتة دبي',
              'defaultSalePrice': price,
              'rowVersion': 1,
              'createdAt': now.toIso8601String(),
              'updatedAt': now.toIso8601String(),
            }),
          ],
          hasMore: false,
          latestRowVersion: now.microsecondsSinceEpoch,
        ),
      );
      await processor.pullEntityType(ParentEntityType.PRODUCT);
      final updates = <Set<TableUpdate>>[];
      final subscription = db
          .tableUpdates(TableUpdateQuery.onTable(db.products))
          .listen(updates.add);
      addTearDown(subscription.cancel);

      await processor.pullEntityType(ParentEntityType.PRODUCT);
      await db.select(db.products).get();
      expect(updates, isEmpty);
      price = 125000;
      await processor.pullEntityType(ParentEntityType.PRODUCT);
      expect(
        (await db.select(db.products).getSingle()).defaultSalePrice,
        125000,
      );
      expect(updates, hasLength(1));
    },
  );

  test(
    'fresh pull restores invoice products quantities prices and allocations',
    () async {
      final db = AppDatabase(
        NativeDatabase.memory(
          setup: (raw) => raw.execute('PRAGMA foreign_keys = ON'),
        ),
      );
      addTearDown(db.close);
      final now = DateTime.utc(2026, 11, 14);
      const device = '00000000-0000-4000-8000-000000000001';
      const client = '00000000-0000-4000-8000-000000000002';
      const product = '00000000-0000-4000-8000-000000000003';
      const invoice = '00000000-0000-4000-8000-000000000004';
      const line = '00000000-0000-4000-8000-000000000005';
      const receipt = '00000000-0000-4000-8000-000000000006';
      const allocation = '00000000-0000-4000-8000-000000000007';
      const returned = '00000000-0000-4000-8000-000000000008';
      await db
          .into(db.devices)
          .insert(
            DevicesCompanion.insert(
              id: device,
              deviceName: 'Test Device',
              platform: DevicePlatform.ANDROID,
              deviceCode: 'test',
              createdAt: now,
              lastActiveAt: now,
            ),
          );
      final common = {
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };
      final versioned = {...common, 'deviceId': device, 'rowVersion': 1};
      final fixtures = <String, Map<String, dynamic>>{
        'CLIENT': {...versioned, 'id': client, 'displayName': 'متجر الاختبار'},
        'PRODUCT': {
          ...versioned,
          'id': product,
          'name': 'شوكولاتة دبي',
          'defaultSalePrice': 100000,
        },
        'SALES_INVOICE': {
          ...versioned,
          'id': invoice,
          'localRef': 'INV-test-001',
          'clientId': client,
          'invoiceDate': now.toIso8601String(),
          'discount': 0,
          'total': 200000,
        },
        'SALES_INVOICE_LINE': {
          ...common,
          'id': line,
          'invoiceId': invoice,
          'productId': product,
          'quantity': 2,
          'unitPrice': 100000,
          'lineTotal': 200000,
        },
        'RECEIPT': {
          ...versioned,
          'id': receipt,
          'localRef': 'REC-test-001',
          'clientId': client,
          'invoiceId': invoice,
          'receiptType': 0,
          'amount': 150000,
          'receiptDate': now.toIso8601String(),
        },
        'RECEIPT_ALLOCATION': {
          ...common,
          'id': allocation,
          'receiptId': receipt,
          'invoiceId': invoice,
          'allocatedAmount': 150000,
        },
        'SALES_RETURN': {
          ...versioned,
          'id': returned,
          'localRef': 'RET-test-001',
          'invoiceId': invoice,
          'returnDate': now.toIso8601String(),
          'totalReturnedAmount': 20000,
        },
        'SALES_RETURN_LINE': {
          ...common,
          'id': '00000000-0000-4000-8000-000000000009',
          'returnId': returned,
          'invoiceLineId': line,
          'returnedQuantity': 1,
          'returnedAmount': 20000,
        },
      };
      final pulled = <String>[];
      await PullProcessor(
        db: db,
        serverClient: server.Client('http://127.0.0.1:1/'),
        restoreReconcileCheck: () async => false,
        pullOverride: (request) async {
          pulled.add(request.entityType);
          final row = fixtures[request.entityType];
          return server.PullResponse(
            entityType: request.entityType,
            rows: row == null ? [] : [jsonEncode(row)],
            hasMore: false,
            latestRowVersion: now.microsecondsSinceEpoch,
          );
        },
      ).pullAllEntityTypes();

      expect(
        pulled.indexOf('SALES_INVOICE_LINE'),
        greaterThan(pulled.indexOf('SALES_INVOICE')),
      );
      final restored = await db.select(db.salesInvoiceLines).getSingle();
      expect(restored.productId, product);
      expect(restored.quantity, 2);
      expect(restored.unitPrice, 100000);
      expect(restored.lineTotal, 200000);
      expect(
        (await db.select(db.receiptAllocations).getSingle()).allocatedAmount,
        150000,
      );
      expect(
        (await db.select(db.salesReturnLines).getSingle()).invoiceLineId,
        line,
      );
      final report = await ReportQueries(
        db,
      ).getFinalMonthlyReport(year: 2026, month: 11);
      expect(report.productSales.single.productName, 'شوكولاتة دبي');
      expect(report.productSales.single.quantity, 2);
      expect(report.productSales.single.totalSales, 200000);
      expect(await db.select(db.syncOutbox).get(), isEmpty);
    },
  );

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
