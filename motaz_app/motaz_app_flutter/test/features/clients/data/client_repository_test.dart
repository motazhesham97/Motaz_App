import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/core/database/app_database.dart';
import 'package:motaz_app_flutter/core/database/enums/enums.dart';
import 'package:motaz_app_flutter/features/clients/data/client_repository.dart';

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
  late ClientRepository repository;

  setUp(() async {
    db = _createInMemoryDatabase();
    repository = ClientRepository(db);
    await _insertDevice(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ClientRepository offline-first behavior', () {
    test(
      'recent transactions include only the client active returns in date order',
      () async {
        final client = await repository.createAndReturn(
          const ClientsCompanion(
            displayName: Value('Dubai Chocolate Store'),
            deviceId: Value(_deviceId),
          ),
        );
        final otherClient = await repository.createAndReturn(
          const ClientsCompanion(
            displayName: Value('Another Store'),
            deviceId: Value(_deviceId),
          ),
        );
        const invoiceIds = [
          '00000000-0000-4000-8000-000000000021',
          '00000000-0000-4000-8000-000000000022',
        ];
        for (var index = 0; index < 2; index++) {
          await db
              .into(db.salesInvoices)
              .insert(
                SalesInvoicesCompanion.insert(
                  id: invoiceIds[index],
                  localRef: 'INV-test-$index',
                  clientId: index == 0 ? client.id : otherClient.id,
                  invoiceDate: DateTime(2026, 8, 11),
                  total: 250000,
                  createdAt: _now,
                  updatedAt: _now,
                  deviceId: _deviceId,
                ),
              );
        }
        await db
            .into(db.receipts)
            .insert(
              ReceiptsCompanion.insert(
                id: '00000000-0000-4000-8000-000000000023',
                localRef: const Value('REC-test-1'),
                receiptType: ReceiptType.GENERAL,
                clientId: client.id,
                amount: 50000,
                receiptDate: DateTime(2026, 8, 12),
                createdAt: _now,
                updatedAt: _now,
                deviceId: _deviceId,
              ),
            );
        for (var index = 0; index < 3; index++) {
          await db
              .into(db.salesReturns)
              .insert(
                SalesReturnsCompanion.insert(
                  id: '00000000-0000-4000-8000-00000000002${index + 4}',
                  localRef: Value('RET-test-$index'),
                  officialNo: const Value('7'),
                  invoiceId: index == 2 ? invoiceIds[1] : invoiceIds[0],
                  returnDate: DateTime(2026, 8, 13 + index),
                  totalReturnedAmount: 20000,
                  status: Value(
                    index == 1 ? RecordStatus.VOIDED : RecordStatus.ACTIVE,
                  ),
                  createdAt: _now,
                  updatedAt: _now,
                  deviceId: _deviceId,
                ),
              );
        }
        final pendingBeforeRead = await db.select(db.syncOutbox).get();

        final transactions = await repository.getRecentTransactions(client.id);

        expect(transactions.map((row) => row['type']), [
          'RETURN',
          'RECEIPT',
          'INVOICE',
        ]);
        expect(
          transactions.first['id'],
          '00000000-0000-4000-8000-000000000024',
        );
        expect(transactions.first['localRef'], 'RET-test-0');
        expect(transactions.first['officialNo'], '7');
        expect(transactions.first['amount'], 20000);
        expect(transactions.first['date'], DateTime(2026, 8, 13));
        expect(await repository.getOutstandingBalance(client.id), 180000);
        final latest = await repository.getRecentTransactions(
          client.id,
          limit: 2,
        );
        expect(latest.map((row) => row['type']), ['RETURN', 'RECEIPT']);
        expect(await db.select(db.syncOutbox).get(), pendingBeforeRead);
      },
    );

    test('saves client locally and enqueues sync before remote work', () async {
      final client = await repository.createAndReturn(
        const ClientsCompanion(
          displayName: Value('Test Client'),
          phone: Value('+967700000001'),
          clientCode: Value('CL-001'),
          deviceId: Value(_deviceId),
        ),
      );

      final savedClient = await repository.getById(client.id);
      final savedBeneficiary = await (db.select(
        db.beneficiaries,
      )..where((t) => t.sourceClientId.equals(client.id))).getSingle();
      final outboxRows = await (db.select(
        db.syncOutbox,
      )..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).get();

      expect(savedClient.displayName, 'Test Client');
      expect(savedClient.syncStatus, SyncStatus.PENDING);
      expect(savedBeneficiary.displayName, savedClient.displayName);
      expect(savedBeneficiary.syncStatus, SyncStatus.PENDING);
      expect(outboxRows, hasLength(2));

      final clientOutbox = outboxRows.singleWhere(
        (row) => row.entityType == ParentEntityType.CLIENT,
      );
      final beneficiaryOutbox = outboxRows.singleWhere(
        (row) => row.entityType == ParentEntityType.BENEFICIARY,
      );
      final payload = jsonDecode(clientOutbox.payload) as Map<String, dynamic>;

      expect(clientOutbox.operation, AuditOperation.CREATE);
      expect(clientOutbox.entityId, savedClient.id);
      expect(clientOutbox.status, SyncOutboxStatus.PENDING);
      expect(payload['displayName'], savedClient.displayName);
      expect(payload['syncStatus'], 0);
      expect(beneficiaryOutbox.operation, AuditOperation.CREATE);
      expect(beneficiaryOutbox.entityId, savedBeneficiary.id);
      expect(beneficiaryOutbox.status, SyncOutboxStatus.PENDING);
    });

    test(
      'updates client locally and enqueues sync before remote work',
      () async {
        final client = await repository.createAndReturn(
          const ClientsCompanion(
            displayName: Value('Client Before Update'),
            phone: Value('+967700000001'),
            clientCode: Value('CL-001'),
            deviceId: Value(_deviceId),
          ),
        );

        await repository.update(
          client.id,
          const ClientsCompanion(
            displayName: Value('Client After Update'),
            phone: Value('+967700000002'),
            creditLimit: Value(150000),
          ),
        );

        final savedClient = await repository.getById(client.id);
        final savedBeneficiary = await (db.select(
          db.beneficiaries,
        )..where((t) => t.sourceClientId.equals(client.id))).getSingle();
        final outboxRows = await db.select(db.syncOutbox).get();
        final clientUpdateOutbox = outboxRows.singleWhere(
          (row) =>
              row.entityType == ParentEntityType.CLIENT &&
              row.operation == AuditOperation.UPDATE,
        );
        final beneficiaryUpdateOutbox = outboxRows.singleWhere(
          (row) =>
              row.entityType == ParentEntityType.BENEFICIARY &&
              row.operation == AuditOperation.UPDATE,
        );
        final payload =
            jsonDecode(clientUpdateOutbox.payload) as Map<String, dynamic>;

        expect(savedClient.displayName, 'Client After Update');
        expect(savedClient.phone, '+967700000002');
        expect(savedClient.creditLimit, 150000);
        expect(savedClient.rowVersion, 2);
        expect(savedClient.syncStatus, SyncStatus.PENDING);
        expect(savedBeneficiary.displayName, savedClient.displayName);
        expect(savedBeneficiary.phone, savedClient.phone);
        expect(savedBeneficiary.syncStatus, SyncStatus.PENDING);
        expect(clientUpdateOutbox.entityId, savedClient.id);
        expect(clientUpdateOutbox.status, SyncOutboxStatus.PENDING);
        expect(payload['displayName'], savedClient.displayName);
        expect(payload['phone'], savedClient.phone);
        expect(payload['creditLimit'], savedClient.creditLimit);
        expect(payload['rowVersion'], savedClient.rowVersion);
        expect(beneficiaryUpdateOutbox.entityId, savedBeneficiary.id);
        expect(beneficiaryUpdateOutbox.status, SyncOutboxStatus.PENDING);
      },
    );

    test(
      'toggles client active state locally and enqueues sync before remote work',
      () async {
        final client = await repository.createAndReturn(
          const ClientsCompanion(
            displayName: Value('Toggle Client'),
            phone: Value('+967700000001'),
            deviceId: Value(_deviceId),
          ),
        );

        await repository.setActive(client.id, false);

        final savedClient = await repository.getById(client.id);
        final savedBeneficiary = await (db.select(
          db.beneficiaries,
        )..where((t) => t.sourceClientId.equals(client.id))).getSingle();
        final outboxRows = await db.select(db.syncOutbox).get();
        final clientUpdateOutbox = outboxRows.singleWhere(
          (row) =>
              row.entityType == ParentEntityType.CLIENT &&
              row.operation == AuditOperation.UPDATE,
        );
        final beneficiaryUpdateOutbox = outboxRows.singleWhere(
          (row) =>
              row.entityType == ParentEntityType.BENEFICIARY &&
              row.operation == AuditOperation.UPDATE,
        );
        final payload =
            jsonDecode(clientUpdateOutbox.payload) as Map<String, dynamic>;

        expect(savedClient.isActive, isFalse);
        expect(savedClient.rowVersion, 2);
        expect(savedClient.syncStatus, SyncStatus.PENDING);
        expect(savedBeneficiary.isActive, isFalse);
        expect(savedBeneficiary.syncStatus, SyncStatus.PENDING);
        expect(clientUpdateOutbox.entityId, savedClient.id);
        expect(clientUpdateOutbox.status, SyncOutboxStatus.PENDING);
        expect(payload['isActive'], isFalse);
        expect(payload['rowVersion'], savedClient.rowVersion);
        expect(beneficiaryUpdateOutbox.entityId, savedBeneficiary.id);
        expect(beneficiaryUpdateOutbox.status, SyncOutboxStatus.PENDING);
      },
    );
  });
}
