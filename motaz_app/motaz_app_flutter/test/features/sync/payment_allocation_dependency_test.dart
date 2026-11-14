import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_client/motaz_app_client.dart' as server;
import 'package:motaz_app_flutter/core/database/app_database.dart';
import 'package:motaz_app_flutter/core/database/enums/enums.dart';
import 'package:motaz_app_flutter/features/sync/application/outbox_processor.dart';

String _id(int value) =>
    '00000000-0000-4000-8000-${value.toString().padLeft(12, '0')}';

final _deviceId = _id(1);
final _clientId = _id(2);
final _otherClientId = _id(3);
final _sourceId = _id(10);
final _targetId = _id(11);
final _receiptId = _id(20);
final _secondReceiptId = _id(21);
final _now = DateTime(2026, 1, 1);

Future<void> _seed(AppDatabase db) async {
  await db
      .into(db.devices)
      .insert(
        DevicesCompanion.insert(
          id: _deviceId,
          deviceName: 'Dependency test',
          platform: DevicePlatform.WINDOWS,
          deviceCode: 'deps',
          createdAt: _now,
          lastActiveAt: _now,
        ),
      );
  for (final clientId in [_clientId, _otherClientId]) {
    await db
        .into(db.clients)
        .insert(
          ClientsCompanion.insert(
            id: clientId,
            displayName: clientId,
            createdAt: _now,
            updatedAt: _now,
            deviceId: _deviceId,
          ),
        );
  }
  for (final invoiceId in [_sourceId, _targetId]) {
    await db
        .into(db.salesInvoices)
        .insert(
          SalesInvoicesCompanion.insert(
            id: invoiceId,
            localRef: 'INV-$invoiceId',
            clientId: _clientId,
            invoiceDate: _now,
            discount: const Value(0),
            total: 100,
            createdAt: _now,
            updatedAt: _now,
            deviceId: _deviceId,
            syncStatus: const Value(SyncStatus.SYNCED),
          ),
        );
  }
  for (final receiptId in [_receiptId, _secondReceiptId]) {
    await db
        .into(db.receipts)
        .insert(
          ReceiptsCompanion.insert(
            id: receiptId,
            localRef: Value('REC-$receiptId'),
            receiptType: ReceiptType.GENERAL,
            clientId: _clientId,
            amount: 100,
            receiptDate: _now,
            createdAt: _now,
            updatedAt: _now,
            deviceId: _deviceId,
            syncStatus: const Value(SyncStatus.SYNCED),
          ),
        );
  }
}

Future<void> _allocation(
  AppDatabase db,
  String id,
  String receiptId,
  String invoiceId,
  int amount,
) => db
    .into(db.receiptAllocations)
    .insert(
      ReceiptAllocationsCompanion.insert(
        id: id,
        receiptId: receiptId,
        invoiceId: invoiceId,
        allocatedAmount: amount,
        createdAt: _now,
        updatedAt: _now,
      ),
    );

Future<void> _enqueue(
  AppDatabase db,
  int id,
  ParentEntityType type,
  String entityId,
  Map<String, dynamic> payload, {
  AuditOperation operation = AuditOperation.UPDATE,
  SyncOutboxStatus status = SyncOutboxStatus.PENDING,
}) async {
  await db
      .into(db.syncOutbox)
      .insert(
        SyncOutboxCompanion.insert(
          id: _id(id),
          entityType: type,
          entityId: entityId,
          operation: operation,
          payload: jsonEncode({'id': entityId, ...payload}),
          rowVersion: 1,
          deviceId: _deviceId,
          createdAt: _now,
          status: Value(status),
        ),
      );
}

OutboxProcessor _processor(AppDatabase db, PushRequestHandler handler) =>
    OutboxProcessor(
      db: db,
      serverClient: server.Client('http://127.0.0.1:1/'),
      pushOverride: handler,
    );

Future<void> _returnHeader(
  AppDatabase db,
  String id,
  String invoiceId, {
  SyncStatus syncStatus = SyncStatus.PENDING,
}) async {
  await db
      .into(db.salesReturns)
      .insert(
        SalesReturnsCompanion.insert(
          id: id,
          localRef: Value('RET-$id'),
          invoiceId: invoiceId,
          returnDate: _now,
          totalReturnedAmount: 50,
          createdAt: _now,
          updatedAt: _now,
          deviceId: _deviceId,
          syncStatus: Value(syncStatus),
        ),
      );
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(
      NativeDatabase.memory(
        setup: (rawDb) => rawDb.execute('PRAGMA foreign_keys = ON'),
      ),
    );
    await _seed(db);
  });

  tearDown(() => db.close());

  test(
    'moved invoice conflict blocks reallocation through a zero tombstone',
    () async {
      await (db.update(
        db.salesInvoices,
      )..where((t) => t.id.equals(_sourceId))).write(
        SalesInvoicesCompanion(
          clientId: Value(_otherClientId),
          syncStatus: const Value(SyncStatus.PENDING),
        ),
      );
      final releaseId = _id(30);
      final grantId = _id(31);
      await _allocation(db, releaseId, _receiptId, _sourceId, 0);
      await _allocation(db, grantId, _receiptId, _targetId, 100);
      await _enqueue(db, 200, ParentEntityType.SALES_INVOICE, _sourceId, {
        'clientId': _otherClientId,
      });
      await _enqueue(db, 201, ParentEntityType.RECEIPT_ALLOCATION, releaseId, {
        'receiptId': _receiptId,
        'invoiceId': _sourceId,
        'allocatedAmount': 0,
        'previousAllocatedAmount': 100,
      });
      await _enqueue(db, 202, ParentEntityType.RECEIPT_ALLOCATION, grantId, {
        'receiptId': _receiptId,
        'invoiceId': _targetId,
        'allocatedAmount': 100,
      }, operation: AuditOperation.CREATE);
      final pushed = <String>[];
      final processor = _processor(db, (request) async {
        pushed.add(request.entityId);
        return request.entityId == _sourceId
            ? server.PushResponse(
                success: false,
                conflictId: 'invoice-conflict',
              )
            : server.PushResponse(success: true, newRowVersion: 2);
      });

      await processor.processPending();
      await processor.processPending();

      expect(pushed, [_sourceId]);
      final allocations =
          await (db.select(db.syncOutbox)..where(
                (t) => t.entityType.equals(
                  ParentEntityType.RECEIPT_ALLOCATION.index,
                ),
              ))
              .get();
      expect(allocations, hasLength(2));
      expect(
        allocations.every((row) => row.status == SyncOutboxStatus.PENDING),
        isTrue,
      );
    },
  );

  test(
    'failed account release blocks another receipt grant until retry succeeds',
    () async {
      final releaseId = _id(30);
      final grantId = _id(31);
      await _allocation(db, releaseId, _receiptId, _sourceId, 0);
      await _allocation(db, grantId, _secondReceiptId, _sourceId, 100);
      await _enqueue(db, 200, ParentEntityType.RECEIPT_ALLOCATION, grantId, {
        'receiptId': _secondReceiptId,
        'invoiceId': _sourceId,
        'allocatedAmount': 100,
      }, operation: AuditOperation.CREATE);
      await _enqueue(db, 201, ParentEntityType.RECEIPT_ALLOCATION, releaseId, {
        'receiptId': _receiptId,
        'invoiceId': _sourceId,
        'allocatedAmount': 0,
        'previousAllocatedAmount': 100,
      });
      var allowRelease = false;
      var released = false;
      final pushed = <String>[];
      final payloads = <Map<String, dynamic>>[];
      final processor = _processor(db, (request) async {
        pushed.add(request.entityId);
        payloads.add(jsonDecode(request.payload) as Map<String, dynamic>);
        if (request.entityId == releaseId) {
          if (!allowRelease) {
            return server.PushResponse(
              success: false,
              errorCode: 'VALIDATION_ERROR',
            );
          }
          released = true;
        } else if (!released) {
          fail('Grant was pushed before its account release succeeded');
        }
        return server.PushResponse(success: true, newRowVersion: 1);
      });

      await processor.processPending();
      expect(pushed, [releaseId]);
      expect(
        (await (db.select(
          db.syncOutbox,
        )..where((t) => t.id.equals(_id(201)))).getSingle()).status,
        SyncOutboxStatus.FAILED,
      );
      await processor.processPending();
      expect(pushed, [releaseId]);

      allowRelease = true;
      await processor.retryFailed();
      await processor.processPending();

      expect(pushed, [releaseId, releaseId, grantId]);
      expect(
        payloads.every(
          (payload) => !payload.containsKey('previousAllocatedAmount'),
        ),
        isTrue,
      );
      expect(
        (await db.select(db.syncOutbox).get()).every(
          (row) => row.status == SyncOutboxStatus.COMPLETED,
        ),
        isTrue,
      );
    },
  );

  test(
    'return header and lines precede allocation releases and grants',
    () async {
      final returnId = _id(40);
      final lineId = _id(41);
      final releaseId = _id(30);
      final grantId = _id(31);
      await _returnHeader(db, returnId, _sourceId);
      await _allocation(db, releaseId, _receiptId, _sourceId, 50);
      await _allocation(db, grantId, _receiptId, _targetId, 50);
      await _enqueue(db, 200, ParentEntityType.RECEIPT_ALLOCATION, grantId, {
        'receiptId': _receiptId,
        'invoiceId': _targetId,
        'allocatedAmount': 50,
      }, operation: AuditOperation.CREATE);
      await _enqueue(db, 201, ParentEntityType.RECEIPT_ALLOCATION, releaseId, {
        'receiptId': _receiptId,
        'invoiceId': _sourceId,
        'allocatedAmount': 50,
        'previousAllocatedAmount': 100,
      });
      await _enqueue(db, 202, ParentEntityType.SALES_RETURN, returnId, {
        'invoiceId': _sourceId,
      }, operation: AuditOperation.CREATE);
      await _enqueue(db, 203, ParentEntityType.SALES_RETURN_LINE, lineId, {
        'returnId': returnId,
        'invoiceLineId': _id(42),
      }, operation: AuditOperation.CREATE);
      final pushed = <String>[];
      final processor = _processor(db, (request) async {
        pushed.add(request.entityId);
        return server.PushResponse(success: true, newRowVersion: 1);
      });

      await processor.processPending();

      expect(pushed, [returnId, lineId, releaseId, grantId]);
    },
  );

  test(
    'coalescing a reduction then increase retains the original release baseline',
    () async {
      final releaseId = _id(30);
      final grantId = _id(31);
      await _allocation(db, releaseId, _receiptId, _sourceId, 75);
      await _allocation(db, grantId, _secondReceiptId, _sourceId, 25);
      await _enqueue(db, 200, ParentEntityType.RECEIPT_ALLOCATION, grantId, {
        'receiptId': _secondReceiptId,
        'invoiceId': _sourceId,
        'allocatedAmount': 25,
      }, operation: AuditOperation.CREATE);
      await _enqueue(db, 201, ParentEntityType.RECEIPT_ALLOCATION, releaseId, {
        'receiptId': _receiptId,
        'invoiceId': _sourceId,
        'previousAllocatedAmount': 100,
        'allocatedAmount': 50,
      });
      await _enqueue(db, 202, ParentEntityType.RECEIPT_ALLOCATION, releaseId, {
        'receiptId': _receiptId,
        'invoiceId': _sourceId,
        'previousAllocatedAmount': 50,
        'allocatedAmount': 75,
      });
      final pushed = <String>[];
      final processor = _processor(db, (request) async {
        pushed.add(request.entityId);
        return server.PushResponse(success: true, newRowVersion: 1);
      });

      await processor.processPending();

      expect(pushed, [releaseId, grantId]);
      final latest = await (db.select(
        db.syncOutbox,
      )..where((t) => t.id.equals(_id(202)))).getSingle();
      expect(jsonDecode(latest.payload)['previousAllocatedAmount'], 100);
    },
  );

  test(
    'return parent conflicts and failures block lines and account allocations',
    () async {
      final returnId = _id(40);
      final lineId = _id(41);
      final releaseId = _id(30);
      final grantId = _id(31);
      await (db.update(
        db.salesInvoices,
      )..where((t) => t.id.equals(_sourceId))).write(
        const SalesInvoicesCompanion(syncStatus: Value(SyncStatus.CONFLICT)),
      );
      await _returnHeader(db, returnId, _sourceId);
      await _allocation(db, releaseId, _receiptId, _sourceId, 50);
      await _allocation(db, grantId, _receiptId, _targetId, 50);
      await _enqueue(db, 200, ParentEntityType.SALES_RETURN, returnId, {
        'invoiceId': _sourceId,
      }, operation: AuditOperation.CREATE);
      await _enqueue(db, 201, ParentEntityType.SALES_RETURN_LINE, lineId, {
        'returnId': returnId,
        'invoiceLineId': _id(42),
      }, operation: AuditOperation.CREATE);
      await _enqueue(db, 202, ParentEntityType.RECEIPT_ALLOCATION, releaseId, {
        'receiptId': _receiptId,
        'invoiceId': _sourceId,
        'allocatedAmount': 50,
        'previousAllocatedAmount': 100,
      });
      await _enqueue(db, 203, ParentEntityType.RECEIPT_ALLOCATION, grantId, {
        'receiptId': _receiptId,
        'invoiceId': _targetId,
        'allocatedAmount': 50,
      }, operation: AuditOperation.CREATE);
      var allowReturn = false;
      final pushed = <String>[];
      final processor = _processor(db, (request) async {
        pushed.add(request.entityId);
        if (request.entityId == returnId && !allowReturn) {
          return server.PushResponse(
            success: false,
            errorCode: 'VALIDATION_ERROR',
          );
        }
        return server.PushResponse(success: true, newRowVersion: 1);
      });

      await processor.processPending();
      expect(pushed, isEmpty);
      await (db.update(
        db.salesInvoices,
      )..where((t) => t.id.equals(_sourceId))).write(
        const SalesInvoicesCompanion(syncStatus: Value(SyncStatus.SYNCED)),
      );
      await processor.processPending();
      await processor.processPending();
      expect(pushed, [returnId]);

      allowReturn = true;
      await processor.retryFailed();
      await processor.processPending();
      expect(pushed, [returnId, returnId, lineId, releaseId, grantId]);
    },
  );

  test(
    'coalescing an increase then reduction cannot bypass a failed release',
    () async {
      final releaseId = _id(30);
      final grantId = _id(31);
      await _allocation(db, releaseId, _secondReceiptId, _sourceId, 0);
      await _allocation(db, grantId, _receiptId, _targetId, 120);
      await _enqueue(db, 200, ParentEntityType.RECEIPT_ALLOCATION, grantId, {
        'receiptId': _receiptId,
        'invoiceId': _targetId,
        'previousAllocatedAmount': 100,
        'allocatedAmount': 150,
      });
      await _enqueue(db, 201, ParentEntityType.RECEIPT_ALLOCATION, grantId, {
        'receiptId': _receiptId,
        'invoiceId': _targetId,
        'previousAllocatedAmount': 150,
        'allocatedAmount': 120,
      });
      await _enqueue(db, 202, ParentEntityType.RECEIPT_ALLOCATION, releaseId, {
        'receiptId': _secondReceiptId,
        'invoiceId': _sourceId,
        'previousAllocatedAmount': 50,
        'allocatedAmount': 0,
      }, status: SyncOutboxStatus.FAILED);
      final pushed = <String>[];
      final processor = _processor(db, (request) async {
        pushed.add(request.entityId);
        return server.PushResponse(success: true, newRowVersion: 1);
      });

      await processor.processPending();
      expect(pushed, isEmpty);
      final latest = await (db.select(
        db.syncOutbox,
      )..where((t) => t.id.equals(_id(201)))).getSingle();
      expect(jsonDecode(latest.payload)['previousAllocatedAmount'], 100);
      await processor.retryFailed();
      await processor.processPending();
      expect(pushed, [releaseId, grantId]);
    },
  );

  test(
    'unrelated client conflicts and failed releases do not block a grant',
    () async {
      final unrelatedInvoiceId = _id(12);
      final unrelatedReturnId = _id(40);
      final releaseId = _id(30);
      final grantId = _id(31);
      await db
          .into(db.salesInvoices)
          .insert(
            SalesInvoicesCompanion.insert(
              id: unrelatedInvoiceId,
              localRef: 'INV-unrelated',
              clientId: _otherClientId,
              invoiceDate: _now,
              total: 100,
              createdAt: _now,
              updatedAt: _now,
              deviceId: _deviceId,
              syncStatus: const Value(SyncStatus.CONFLICT),
            ),
          );
      await (db.update(
        db.receipts,
      )..where((t) => t.id.equals(_secondReceiptId))).write(
        ReceiptsCompanion(
          clientId: Value(_otherClientId),
          syncStatus: const Value(SyncStatus.CONFLICT),
        ),
      );
      await _returnHeader(
        db,
        unrelatedReturnId,
        unrelatedInvoiceId,
        syncStatus: SyncStatus.CONFLICT,
      );
      await _allocation(db, releaseId, _secondReceiptId, unrelatedInvoiceId, 0);
      await _allocation(db, grantId, _receiptId, _targetId, 100);
      await _enqueue(
        db,
        200,
        ParentEntityType.SALES_INVOICE,
        unrelatedInvoiceId,
        {
          'clientId': _otherClientId,
        },
        status: SyncOutboxStatus.FAILED,
      );
      await _enqueue(db, 201, ParentEntityType.RECEIPT, _secondReceiptId, {
        'clientId': _otherClientId,
      }, status: SyncOutboxStatus.FAILED);
      await _enqueue(
        db,
        202,
        ParentEntityType.SALES_RETURN,
        unrelatedReturnId,
        {
          'invoiceId': unrelatedInvoiceId,
        },
        status: SyncOutboxStatus.FAILED,
      );
      await _enqueue(db, 203, ParentEntityType.RECEIPT_ALLOCATION, releaseId, {
        'receiptId': _secondReceiptId,
        'invoiceId': unrelatedInvoiceId,
        'previousAllocatedAmount': 100,
        'allocatedAmount': 0,
      }, status: SyncOutboxStatus.FAILED);
      await _enqueue(db, 204, ParentEntityType.RECEIPT_ALLOCATION, grantId, {
        'receiptId': _receiptId,
        'invoiceId': _targetId,
        'allocatedAmount': 100,
      }, operation: AuditOperation.CREATE);
      final pushed = <String>[];
      final processor = _processor(db, (request) async {
        pushed.add(request.entityId);
        return server.PushResponse(success: true, newRowVersion: 1);
      });

      await processor.processPending();

      expect(pushed, [grantId]);
      expect(
        (await (db.select(
          db.syncOutbox,
        )..where((t) => t.id.equals(_id(203)))).getSingle()).status,
        SyncOutboxStatus.FAILED,
      );
    },
  );

  test('moved receipt conflict blocks grants in its former account', () async {
    final grantId = _id(31);
    await (db.update(
      db.receipts,
    )..where((t) => t.id.equals(_secondReceiptId))).write(
      ReceiptsCompanion(
        clientId: Value(_otherClientId),
        syncStatus: const Value(SyncStatus.PENDING),
      ),
    );
    await _allocation(db, _id(30), _secondReceiptId, _sourceId, 0);
    await _allocation(db, grantId, _receiptId, _targetId, 100);
    await _enqueue(db, 200, ParentEntityType.RECEIPT, _secondReceiptId, {
      'clientId': _otherClientId,
    });
    await _enqueue(db, 201, ParentEntityType.RECEIPT_ALLOCATION, grantId, {
      'receiptId': _receiptId,
      'invoiceId': _targetId,
      'allocatedAmount': 100,
    }, operation: AuditOperation.CREATE);
    final pushed = <String>[];
    final processor = _processor(db, (request) async {
      pushed.add(request.entityId);
      return request.entityId == _secondReceiptId
          ? server.PushResponse(success: false, conflictId: 'receipt-conflict')
          : server.PushResponse(success: true, newRowVersion: 1);
    });

    await processor.processPending();
    await processor.processPending();

    expect(pushed, [_secondReceiptId]);
    expect(
      (await (db.select(
        db.syncOutbox,
      )..where((t) => t.id.equals(_id(201)))).getSingle()).status,
      SyncOutboxStatus.PENDING,
    );
  });

  test(
    'legacy zero updates release first and block grants after failure until retry',
    () async {
      final releaseId = _id(30);
      final grantId = _id(31);
      await _allocation(db, releaseId, _receiptId, _sourceId, 0);
      await _allocation(db, grantId, _secondReceiptId, _sourceId, 100);
      await _enqueue(db, 200, ParentEntityType.RECEIPT_ALLOCATION, grantId, {
        'receiptId': _secondReceiptId,
        'invoiceId': _sourceId,
        'allocatedAmount': 100,
      }, operation: AuditOperation.CREATE);
      await _enqueue(db, 201, ParentEntityType.RECEIPT_ALLOCATION, releaseId, {
        'receiptId': _receiptId,
        'invoiceId': _sourceId,
        'allocatedAmount': 0,
      });
      var allowRelease = false;
      final pushed = <String>[];
      final processor = _processor(db, (request) async {
        pushed.add(request.entityId);
        if (request.entityId == releaseId && !allowRelease) {
          return server.PushResponse(
            success: false,
            errorCode: 'VALIDATION_ERROR',
          );
        }
        return server.PushResponse(success: true, newRowVersion: 1);
      });

      await processor.processPending();
      expect(pushed, [releaseId]);
      await processor.processPending();
      expect(pushed, [releaseId]);
      expect(
        (await (db.select(
          db.syncOutbox,
        )..where((t) => t.id.equals(_id(201)))).getSingle()).status,
        SyncOutboxStatus.FAILED,
      );

      allowRelease = true;
      await processor.retryFailed();
      await processor.processPending();

      expect(pushed, [releaseId, releaseId, grantId]);
      expect(
        (await db.select(db.syncOutbox).get()).every(
          (row) => row.status == SyncOutboxStatus.COMPLETED,
        ),
        isTrue,
      );
    },
  );
}
