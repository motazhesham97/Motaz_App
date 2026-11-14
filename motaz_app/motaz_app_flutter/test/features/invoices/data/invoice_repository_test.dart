import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_client/motaz_app_client.dart' as server;
import 'package:motaz_app_flutter/core/database/app_database.dart';
import 'package:motaz_app_flutter/core/database/enums/enums.dart';
import 'package:motaz_app_flutter/features/clients/data/client_repository.dart';
import 'package:motaz_app_flutter/features/invoices/data/invoice_repository.dart';
import 'package:motaz_app_flutter/features/receipts/data/receipt_repository.dart';
import 'package:motaz_app_flutter/core/utils/date_range.dart';
import 'package:motaz_app_flutter/features/reports/data/client_statement_queries.dart';
import 'package:motaz_app_flutter/features/returns/data/return_repository.dart';
import 'package:motaz_app_flutter/features/sync/application/outbox_processor.dart';

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
const _clientId = 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12';
const _productId = 'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a13';
const _otherClientId = 'd0eebc99-9c0b-4ef8-bb6d-6bb9bd380a14';
const _editLines = [
  SalesInvoiceLinesCompanion(
    productId: Value(_productId),
    quantity: Value(1),
    unitPrice: Value(1350000),
  ),
];
final _now = DateTime(2026, 1, 1, 10);

Future<SalesInvoice> _createEditableInvoice(
  InvoiceRepository repository, {
  int paidAmount = 1125000,
}) {
  return repository.create(
    clientId: _clientId,
    invoiceDate: _now,
    discount: 0,
    note: '',
    lines: _editLines,
    paidAmount: paidAmount,
    deviceId: _deviceId,
  );
}

Future<void> _seedInvoiceDependencies(AppDatabase db) async {
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
      .into(db.clients)
      .insert(
        ClientsCompanion(
          id: const Value(_clientId),
          displayName: const Value('Test Client'),
          createdAt: Value(_now),
          updatedAt: Value(_now),
          deviceId: const Value(_deviceId),
        ),
      );
  await db
      .into(db.products)
      .insert(
        ProductsCompanion(
          id: const Value(_productId),
          name: const Value('Test Product'),
          defaultSalePrice: const Value(125000),
          createdAt: Value(_now),
          updatedAt: Value(_now),
          deviceId: const Value(_deviceId),
        ),
      );
}

void main() {
  late AppDatabase db;
  late InvoiceRepository repository;

  setUp(() async {
    db = _createInMemoryDatabase();
    repository = InvoiceRepository(db);
    await _seedInvoiceDependencies(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('InvoiceRepository offline-first behavior', () {
    test(
      'invoice credit and pending allocations survive a database restart offline',
      () async {
        await db.close();
        final directory = await Directory.systemTemp.createTemp(
          'motaz-payment-restart-',
        );
        final file = File(
          '${directory.path}${Platform.pathSeparator}test.sqlite',
        );
        var persistent = AppDatabase(NativeDatabase(file));
        try {
          await _seedInvoiceDependencies(persistent);
          final invoice = await _createEditableInvoice(
            InvoiceRepository(persistent),
            paidAmount: 1850000,
          );
          await persistent.close();
          persistent = AppDatabase(NativeDatabase(file));

          expect(
            await ClientRepository(persistent).getOutstandingBalance(_clientId),
            -500000,
          );
          expect(
            (await persistent.select(persistent.receipts).getSingle()).amount,
            1850000,
          );
          expect(
            await InvoiceRepository(persistent).getRemainingBalance(invoice.id),
            0,
          );
          final queue = await persistent.select(persistent.syncOutbox).get();
          expect(queue, isNotEmpty);
          expect(
            queue.every((row) => row.status == SyncOutboxStatus.PENDING),
            isTrue,
          );
        } finally {
          await persistent.close();
          await directory.delete(recursive: true);
          db = _createInMemoryDatabase();
        }
      },
    );

    test(
      'invoice payment details show incoming settlements separately from the full payment',
      () async {
        final older = await _createEditableInvoice(repository, paidAmount: 0);
        final current = await _createEditableInvoice(
          repository,
          paidAmount: 1850000,
        );

        final oldDetails = await repository.getPaymentsForInvoice(older.id);
        final currentDetails = await repository.getPaymentsForInvoice(
          current.id,
        );

        expect(oldDetails.single.receipt.invoiceId, current.id);
        expect(oldDetails.single.receipt.amount, 1850000);
        expect(oldDetails.single.allocatedAmount, 500000);
        expect(currentDetails.single.allocatedAmount, 1350000);
        expect(currentDetails.single.receipt.id, oldDetails.single.receipt.id);
      },
    );

    test(
      'returns release payment to other debt and cancelling the return restores allocation',
      () async {
        final paid = await _createEditableInvoice(
          repository,
          paidAmount: 1350000,
        );
        final next = await _createEditableInvoice(repository, paidAmount: 0);
        final line = (await repository.getLinesForInvoice(paid.id)).single;

        final returned = await ReturnRepository(db).create(
          invoiceId: paid.id,
          returnDate: _now,
          lines: [
            (
              invoiceLineId: line.id,
              returnedQuantity: 1,
              returnedAmount: 500000,
            ),
          ],
          deviceId: _deviceId,
        );

        expect(await repository.getCollectedAmount(paid.id), 850000);
        expect(await repository.getCollectedAmount(next.id), 500000);
        expect(await repository.getRemainingBalance(next.id), 850000);
        await ReturnRepository(
          db,
        ).voidReturn(returned.id, 'Wrong return', _deviceId);
        expect(await repository.getCollectedAmount(paid.id), 1350000);
        expect(await repository.getCollectedAmount(next.id), 0);
        expect(await repository.getRemainingBalance(next.id), 1350000);
        expect(await db.select(db.receipts).get(), hasLength(1));
      },
    );

    test(
      'statement counts invoice overpayment once and distinguishes it from a paper receipt',
      () async {
        final invoice = await _createEditableInvoice(
          repository,
          paidAmount: 1850000,
        );
        await (db.update(db.salesInvoices)
              ..where((t) => t.id.equals(invoice.id)))
            .write(const SalesInvoicesCompanion(officialNo: Value('123')));
        await ReceiptRepository(db).createGeneral(
          clientId: _clientId,
          amount: 100000,
          receiptDate: _now,
          deviceId: _deviceId,
        );

        final statement = await ClientStatementQueries(db).getClientStatement(
          _clientId,
          DateRange.custom(DateTime(2026, 1, 1), DateTime(2026, 2)),
        );
        final payment = statement.entries.singleWhere(
          (row) => row.isInvoicePayment,
        );
        expect(statement.entries, hasLength(3));
        expect(payment.amount, 1850000);
        expect(payment.reference, 'الفاتورة رقم 123');
        expect(payment.copyWith().isInvoicePayment, isTrue);
        expect(statement.closingBalance, -600000);
        final history = await ClientRepository(
          db,
        ).getRecentTransactions(_clientId);
        expect(
          history.where(
            (row) => row['receiptType'] == ReceiptType.INVOICE_LINKED,
          ),
          hasLength(1),
        );
        expect(
          history.singleWhere(
            (row) => row['receiptType'] == ReceiptType.INVOICE_LINKED,
          )['invoiceOfficialNo'],
          '123',
        );
        expect(
          history.where((row) => row['receiptType'] == ReceiptType.GENERAL),
          hasLength(1),
        );
      },
    );

    test(
      'voiding an overpaid invoice keeps received money and reallocates it without duplication',
      () async {
        final older = await _createEditableInvoice(repository, paidAmount: 0);
        final current = await repository.create(
          clientId: _clientId,
          invoiceDate: _now.add(const Duration(days: 1)),
          discount: 0,
          note: '',
          lines: _editLines,
          paidAmount: 1850000,
          deviceId: _deviceId,
        );

        await repository.voidInvoice(current.id, 'Cancelled sale', _deviceId);

        expect(await repository.getCollectedAmount(current.id), 0);
        expect(await repository.getCollectedAmount(older.id), 1350000);
        expect(
          await ClientRepository(db).getOutstandingBalance(_clientId),
          -500000,
        );
        final receipt = await db.select(db.receipts).getSingle();
        expect(receipt.amount, 1850000);
        expect(receipt.status, RecordStatus.ACTIVE);
        final allocations = await ReceiptRepository(
          db,
        ).getAllocationsForReceipt(receipt.id);
        expect(
          allocations.fold<int>(0, (sum, row) => sum + row.allocatedAmount),
          1350000,
        );
        expect(
          allocations
              .where((row) => row.invoiceId == current.id)
              .every((row) => row.allocatedAmount == 0),
          isTrue,
        );
        final zeroUpdates =
            await (db.select(db.syncOutbox)..where(
                  (t) =>
                      t.entityType.equals(
                        ParentEntityType.RECEIPT_ALLOCATION.index,
                      ) &
                      t.operation.equals(AuditOperation.UPDATE.index),
                ))
                .get();
        expect(
          zeroUpdates.any(
            (row) => jsonDecode(row.payload)['allocatedAmount'] == 0,
          ),
          isTrue,
        );
      },
    );

    test(
      'editing an internal payment reallocates its excess to older invoices',
      () async {
        final older = await _createEditableInvoice(repository, paidAmount: 0);
        final current = await repository.create(
          clientId: _clientId,
          invoiceDate: _now.add(const Duration(days: 1)),
          discount: 0,
          note: '',
          lines: _editLines,
          paidAmount: 1350000,
          deviceId: _deviceId,
        );
        final receipt = (await repository.getReceiptsForInvoice(
          current.id,
        )).single;

        await ReceiptRepository(db).updateReceipt(
          id: receipt.id,
          clientId: _clientId,
          amount: 1850000,
          receiptDate: _now,
          deviceId: _deviceId,
        );

        expect(await repository.getCollectedAmount(current.id), 1350000);
        expect(await repository.getCollectedAmount(older.id), 500000);
        expect(await repository.getRemainingBalance(older.id), 850000);
        expect(await db.select(db.receipts).get(), hasLength(1));
      },
    );

    test(
      'unused invoice payment stays as credit and settles a later invoice once',
      () async {
        await _createEditableInvoice(repository, paidAmount: 1850000);
        expect(
          await ClientRepository(db).getOutstandingBalance(_clientId),
          -500000,
        );

        final next = await repository.create(
          clientId: _clientId,
          invoiceDate: _now.add(const Duration(days: 1)),
          discount: 0,
          note: '',
          lines: _editLines,
          paidAmount: 0,
          deviceId: _deviceId,
        );

        expect(await db.select(db.receipts).get(), hasLength(1));
        expect(await repository.getCollectedAmount(next.id), 500000);
        expect(await repository.getRemainingBalance(next.id), 850000);
        expect(
          await ClientRepository(db).getOutstandingBalance(_clientId),
          850000,
        );
        final count = (await db.select(db.syncOutbox).get()).length;
        await ReceiptRepository(
          db,
        ).reconcileClientPayments(clientId: _clientId, deviceId: _deviceId);
        expect((await db.select(db.syncOutbox).get()).length, count);
      },
    );

    test('voiding an invoice payment reopens all debts it settled', () async {
      final older = await repository.create(
        clientId: _clientId,
        invoiceDate: _now.subtract(const Duration(days: 1)),
        discount: 0,
        note: '',
        lines: _editLines,
        paidAmount: 0,
        deviceId: _deviceId,
      );
      final invoice = await _createEditableInvoice(
        repository,
        paidAmount: 1850000,
      );
      final receipt = (await repository.getReceiptsForInvoice(
        invoice.id,
      )).single;

      await ReceiptRepository(
        db,
      ).voidReceipt(receipt.id, 'Wrong payment', _deviceId);

      expect(await repository.getRemainingBalance(invoice.id), 1350000);
      expect(await repository.getRemainingBalance(older.id), 1350000);
      expect(
        await ClientRepository(db).getOutstandingBalance(_clientId),
        2700000,
      );
      final allocations = await ReceiptRepository(
        db,
      ).getAllocationsForReceipt(receipt.id);
      expect(allocations, hasLength(2));
      expect(allocations.every((row) => row.allocatedAmount == 0), isTrue);
      final queue =
          await (db.select(db.syncOutbox)..where(
                (t) =>
                    t.entityType.equals(
                      ParentEntityType.RECEIPT_ALLOCATION.index,
                    ) &
                    t.operation.equals(AuditOperation.UPDATE.index),
              ))
              .get();
      expect(queue, hasLength(2));
      expect(
        queue.every((row) => jsonDecode(row.payload)['allocatedAmount'] == 0),
        isTrue,
      );
    });

    test(
      'editing invoice overpayment recalculates the old debt without creating another payment',
      () async {
        final older = await repository.create(
          clientId: _clientId,
          invoiceDate: _now.subtract(const Duration(days: 1)),
          discount: 0,
          note: '',
          lines: const [
            SalesInvoiceLinesCompanion(
              productId: Value(_productId),
              quantity: Value(1),
              unitPrice: Value(800000),
            ),
          ],
          paidAmount: 0,
          deviceId: _deviceId,
        );
        final invoice = await _createEditableInvoice(
          repository,
          paidAmount: 1850000,
        );
        final receipt = (await repository.getReceiptsForInvoice(
          invoice.id,
        )).single;

        await repository.update(
          id: invoice.id,
          clientId: _clientId,
          invoiceDate: _now,
          discount: 0,
          note: null,
          lines: _editLines,
          paidAmount: 1550000,
          deviceId: _deviceId,
        );

        final updated = await db.select(db.receipts).getSingle();
        expect(updated.id, receipt.id);
        expect(updated.amount, 1550000);
        expect(await repository.getRemainingBalance(invoice.id), 0);
        expect(await repository.getCollectedAmount(older.id), 200000);
        expect(await repository.getRemainingBalance(older.id), 600000);
        expect(
          await ClientRepository(db).getOutstandingBalance(_clientId),
          600000,
        );
      },
    );

    test(
      'invoice overpayment settles its invoice then older debt without a separate receipt',
      () async {
        final older = await repository.create(
          clientId: _clientId,
          invoiceDate: _now.subtract(const Duration(days: 1)),
          discount: 0,
          note: '',
          lines: const [
            SalesInvoiceLinesCompanion(
              productId: Value(_productId),
              quantity: Value(1),
              unitPrice: Value(800000),
            ),
          ],
          paidAmount: 0,
          deviceId: _deviceId,
        );

        final current = await repository.create(
          clientId: _clientId,
          invoiceDate: _now,
          discount: 0,
          note: '',
          lines: const [
            SalesInvoiceLinesCompanion(
              productId: Value(_productId),
              quantity: Value(1),
              unitPrice: Value(1000000),
            ),
          ],
          paidAmount: 1500000,
          deviceId: _deviceId,
        );

        final receipt = await db.select(db.receipts).getSingle();
        expect(receipt.receiptType, ReceiptType.INVOICE_LINKED);
        expect(receipt.invoiceId, current.id);
        expect(receipt.amount, 1500000);
        expect(await repository.getCollectedAmount(current.id), 1000000);
        expect(await repository.getCollectedAmount(older.id), 500000);
        expect(await repository.getRemainingBalance(current.id), 0);
        expect(await repository.getRemainingBalance(older.id), 300000);
        expect(
          await ClientRepository(db).getOutstandingBalance(_clientId),
          300000,
        );
        final queue = await db.select(db.syncOutbox).get();
        expect(
          queue.where((row) => row.entityType == ParentEntityType.RECEIPT),
          hasLength(1),
        );
        expect(
          queue.where(
            (row) => row.entityType == ParentEntityType.RECEIPT_ALLOCATION,
          ),
          hasLength(2),
        );
        expect(
          queue.every((row) => row.status == SyncOutboxStatus.PENDING),
          isTrue,
        );
      },
    );

    test(
      'raising invoice capacity reallocates unchanged earlier credit before adjusting later payments',
      () async {
        final invoice = await repository.create(
          clientId: _clientId,
          invoiceDate: _now,
          discount: 675000,
          note: '',
          lines: _editLines,
          paidAmount: 0,
          deviceId: _deviceId,
        );
        final receipts = ReceiptRepository(db);
        final first = await receipts.createInvoiceLinked(
          clientId: _clientId,
          invoiceId: invoice.id,
          amount: 1000000,
          receiptDate: _now,
          deviceId: _deviceId,
        );
        final second = await receipts.createInvoiceLinked(
          clientId: _clientId,
          invoiceId: invoice.id,
          amount: 500000,
          receiptDate: DateTime(2026, 1, 2),
          deviceId: _deviceId,
        );

        await repository.update(
          id: invoice.id,
          clientId: _clientId,
          invoiceDate: _now,
          discount: 0,
          note: null,
          lines: _editLines,
          paidAmount: 1250000,
          deviceId: _deviceId,
        );

        expect((await receipts.getById(first.id)).amount, 1000000);
        expect((await receipts.getById(second.id)).amount, 250000);
        expect(
          (await receipts.getAllocationsForReceipt(
            first.id,
          )).single.allocatedAmount,
          1000000,
        );
        expect(
          (await receipts.getAllocationsForReceipt(
            second.id,
          )).single.allocatedAmount,
          250000,
        );
        expect(await repository.getCollectedAmount(invoice.id), 1250000);
        expect(await repository.getRemainingBalance(invoice.id), 100000);
        expect(
          await ClientRepository(db).getOutstandingBalance(_clientId),
          100000,
        );
      },
    );

    test(
      'moving an invoice preserves existing overpayment credit without overallocating it',
      () async {
        await db
            .into(db.clients)
            .insert(
              ClientsCompanion.insert(
                id: _otherClientId,
                displayName: 'بقالة طيبة',
                createdAt: _now,
                updatedAt: _now,
                deviceId: _deviceId,
              ),
            );
        final invoice = await _createEditableInvoice(repository, paidAmount: 0);
        final receipt = await ReceiptRepository(db).createInvoiceLinked(
          clientId: _clientId,
          invoiceId: invoice.id,
          amount: 1500000,
          receiptDate: _now,
          deviceId: _deviceId,
        );

        await repository.update(
          id: invoice.id,
          clientId: _otherClientId,
          invoiceDate: _now,
          discount: 0,
          note: null,
          lines: _editLines,
          paidAmount: 1500000,
          deviceId: _deviceId,
        );

        final updated = await db.select(db.receipts).getSingle();
        expect(updated.id, receipt.id);
        expect(updated.amount, 1500000);
        expect(updated.clientId, _otherClientId);
        expect(await repository.getCollectedAmount(invoice.id), 1350000);
        expect(await repository.getRemainingBalance(invoice.id), 0);
        expect(await ClientRepository(db).getOutstandingBalance(_clientId), 0);
        expect(
          await ClientRepository(db).getOutstandingBalance(_otherClientId),
          -150000,
        );
      },
    );

    test(
      'an invoice conflict keeps linked payment changes local and blocks their push',
      () async {
        final invoice = await _createEditableInvoice(repository);
        await db.delete(db.syncOutbox).go();
        await repository.update(
          id: invoice.id,
          clientId: _clientId,
          invoiceDate: _now,
          discount: 0,
          note: null,
          lines: _editLines,
          paidAmount: 1000000,
          deviceId: _deviceId,
        );
        final requests = <String>[];
        final processor = OutboxProcessor(
          db: db,
          serverClient: server.Client('http://127.0.0.1:1/'),
          pushOverride: (request) async {
            requests.add(request.entityType);
            return server.PushResponse(
              success: false,
              conflictId: 'invoice-conflict',
            );
          },
        );

        await processor.processPending();
        await processor.processPending();

        expect(requests, ['SALES_INVOICE']);
        expect(
          (await repository.getById(invoice.id)).syncStatus,
          SyncStatus.CONFLICT,
        );
        final receipt = await db.select(db.receipts).getSingle();
        expect(receipt.amount, 1000000);
        expect(receipt.syncStatus, SyncStatus.PENDING);
        final outbox = await db.select(db.syncOutbox).get();
        expect(
          outbox
              .where((row) => row.entityType != ParentEntityType.SALES_INVOICE)
              .every((row) => row.status == SyncOutboxStatus.PENDING),
          isTrue,
        );
        expect(await repository.getRemainingBalance(invoice.id), 350000);
      },
    );

    test(
      'repeated offline payment edits push the latest snapshots with original server versions',
      () async {
        final invoice = await _createEditableInvoice(repository);
        await db
            .update(db.salesInvoices)
            .write(
              const SalesInvoicesCompanion(
                rowVersion: Value(7),
                syncStatus: Value(SyncStatus.SYNCED),
              ),
            );
        await db
            .update(db.receipts)
            .write(
              const ReceiptsCompanion(
                rowVersion: Value(6),
                syncStatus: Value(SyncStatus.SYNCED),
              ),
            );
        await db.delete(db.syncOutbox).go();
        for (final paid in [1000000, 900000]) {
          await repository.update(
            id: invoice.id,
            clientId: _clientId,
            invoiceDate: _now,
            discount: 0,
            note: null,
            lines: _editLines,
            paidAmount: paid,
            deviceId: _deviceId,
          );
        }
        final requests = <server.PushRequest>[];
        final processor = OutboxProcessor(
          db: db,
          serverClient: server.Client('http://127.0.0.1:1/'),
          pushOverride: (request) async {
            requests.add(request);
            return server.PushResponse(
              success: true,
              newRowVersion: request.entityType == 'SALES_INVOICE' ? 8 : 7,
            );
          },
        );

        await processor.processPending();

        expect(requests.map((request) => request.entityType), [
          'SALES_INVOICE',
          'RECEIPT',
          'RECEIPT_ALLOCATION',
        ]);
        expect(requests[0].rowVersion, 7);
        expect(requests[1].rowVersion, 6);
        expect(jsonDecode(requests[1].payload)['amount'], 900000);
        expect(jsonDecode(requests[2].payload)['allocatedAmount'], 900000);
        expect((await repository.getById(invoice.id)).rowVersion, 8);
        expect((await db.select(db.receipts).getSingle()).rowVersion, 7);
        expect(await repository.getRemainingBalance(invoice.id), 450000);
      },
    );

    test(
      'a newer zero allocation supersedes an older payment allocation waiting to retry',
      () async {
        final invoice = await _createEditableInvoice(repository);
        await (db.delete(db.syncOutbox)..where(
              (t) => t.entityType.isNotValue(
                ParentEntityType.RECEIPT_ALLOCATION.index,
              ),
            ))
            .go();
        final original = await db.select(db.syncOutbox).getSingle();
        await repository.update(
          id: invoice.id,
          clientId: _clientId,
          invoiceDate: _now,
          discount: 0,
          note: null,
          lines: _editLines,
          paidAmount: 0,
          deviceId: _deviceId,
        );
        // Equal stored timestamps must use insertion order, not random UUIDs.
        await db
            .update(db.syncOutbox)
            .write(
              SyncOutboxCompanion(createdAt: Value(DateTime(2100))),
            );
        await (db.update(db.syncOutbox)..where((t) => t.id.equals(original.id)))
            .write(const SyncOutboxCompanion(retryCount: Value(1)));
        final pushedAmounts = <int>[];
        final processor = OutboxProcessor(
          db: db,
          serverClient: server.Client('http://127.0.0.1:1/'),
          pushOverride: (request) async {
            if (request.entityType == 'RECEIPT_ALLOCATION') {
              pushedAmounts.add(
                jsonDecode(request.payload)['allocatedAmount'] as int,
              );
            }
            return server.PushResponse(success: true, newRowVersion: 2);
          },
        );

        await processor.processPending();

        expect(pushedAmounts, [0]);
        final outbox = await db.select(db.syncOutbox).get();
        expect(
          outbox.every((row) => row.status == SyncOutboxStatus.COMPLETED),
          isTrue,
        );
        await (db.update(db.syncOutbox)..where((t) => t.id.equals(original.id)))
            .write(const SyncOutboxCompanion(retryCount: Value(0)));
        await processor.processPending();
        expect(pushedAmounts, [0]);
        expect(await repository.getCollectedAmount(invoice.id), 0);
      },
    );

    test(
      'failed invoice sync holds linked payment changes until the invoice retry succeeds',
      () async {
        final invoice = await _createEditableInvoice(repository);
        await db.delete(db.syncOutbox).go();
        await repository.update(
          id: invoice.id,
          clientId: _clientId,
          invoiceDate: _now,
          discount: 0,
          note: null,
          lines: _editLines,
          paidAmount: 1000000,
          deviceId: _deviceId,
        );
        var failInvoice = true;
        final pushedTypes = <String>[];
        final processor = OutboxProcessor(
          db: db,
          serverClient: server.Client('http://127.0.0.1:1/'),
          pushOverride: (request) async {
            pushedTypes.add(request.entityType);
            if (failInvoice && request.entityType == 'SALES_INVOICE') {
              throw Exception('Simulated temporary network loss');
            }
            return server.PushResponse(success: true, newRowVersion: 2);
          },
        );

        await processor.processPending();

        expect(pushedTypes, ['SALES_INVOICE']);
        expect((await db.select(db.receipts).getSingle()).amount, 1000000);
        expect(
          (await db.select(db.receipts).getSingle()).syncStatus,
          SyncStatus.PENDING,
        );
        expect(
          (await db.select(db.syncOutbox).get()).every(
            (row) => row.status == SyncOutboxStatus.PENDING,
          ),
          isTrue,
        );

        failInvoice = false;
        await db
            .update(db.syncOutbox)
            .write(const SyncOutboxCompanion(retryCount: Value(0)));
        await processor.processPending();

        expect(pushedTypes, [
          'SALES_INVOICE',
          'SALES_INVOICE',
          'RECEIPT',
          'RECEIPT_ALLOCATION',
        ]);
        expect(
          (await db.select(db.syncOutbox).get()).every(
            (row) => row.status == SyncOutboxStatus.COMPLETED,
          ),
          isTrue,
        );
        expect(
          (await db.select(db.receipts).getSingle()).syncStatus,
          SyncStatus.SYNCED,
        );
        expect(await repository.getRemainingBalance(invoice.id), 350000);
      },
    );

    test(
      'payment-only edits preserve invoice line identities and do not enqueue duplicate lines',
      () async {
        final invoice = await _createEditableInvoice(repository);
        final originalLines = await repository.getLinesForInvoice(invoice.id);
        await db.delete(db.syncOutbox).go();

        await repository.update(
          id: invoice.id,
          clientId: _clientId,
          invoiceDate: _now,
          discount: 0,
          note: null,
          lines: _editLines,
          paidAmount: 1000000,
          deviceId: _deviceId,
        );

        expect(await repository.getLinesForInvoice(invoice.id), originalLines);
        final outbox = await db.select(db.syncOutbox).get();
        expect(
          outbox.where(
            (row) => row.entityType == ParentEntityType.SALES_INVOICE_LINE,
          ),
          isEmpty,
        );
        expect(
          (await repository.getReceiptsForInvoice(invoice.id)).single.amount,
          1000000,
        );
      },
    );

    test(
      'general payments are not moved to another client or counted twice during invoice edits',
      () async {
        await db
            .into(db.clients)
            .insert(
              ClientsCompanion.insert(
                id: _otherClientId,
                displayName: 'بقالة طيبة',
                createdAt: _now,
                updatedAt: _now,
                deviceId: _deviceId,
              ),
            );
        final invoice = await _createEditableInvoice(
          repository,
          paidAmount: 500000,
        );
        await ReceiptRepository(db).createGeneral(
          clientId: _clientId,
          amount: 200000,
          receiptDate: _now,
          deviceId: _deviceId,
        );
        await db.delete(db.syncOutbox).go();

        await repository.update(
          id: invoice.id,
          clientId: _otherClientId,
          invoiceDate: _now,
          discount: 0,
          note: null,
          lines: _editLines,
          paidAmount: 1125000,
          deviceId: _deviceId,
        );
        final receipts = await db.select(db.receipts).get();
        expect(receipts, hasLength(2));
        expect(
          receipts
              .singleWhere((r) => r.receiptType == ReceiptType.GENERAL)
              .clientId,
          _clientId,
        );
        expect(
          receipts
              .singleWhere((r) => r.receiptType == ReceiptType.INVOICE_LINKED)
              .clientId,
          _otherClientId,
        );
        expect(await repository.getCollectedAmount(invoice.id), 1125000);
        expect(
          await ClientRepository(db).getOutstandingBalance(_clientId),
          -200000,
        );
        expect(
          await ClientRepository(db).getOutstandingBalance(_otherClientId),
          225000,
        );
      },
    );

    test(
      'editing total paid preserves earlier linked payments and adjusts the last receipt',
      () async {
        final invoice = await _createEditableInvoice(
          repository,
          paidAmount: 500000,
        );
        final receipts = ReceiptRepository(db);
        final second = await receipts.createInvoiceLinked(
          clientId: _clientId,
          invoiceId: invoice.id,
          amount: 400000,
          receiptDate: DateTime(2026, 1, 2),
          note: 'Second payment',
          deviceId: _deviceId,
        );
        final first = (await db.select(db.receipts).get()).firstWhere(
          (receipt) => receipt.id != second.id,
        );

        await repository.update(
          id: invoice.id,
          clientId: _clientId,
          invoiceDate: _now,
          discount: 0,
          note: null,
          lines: _editLines,
          paidAmount: 750000,
          deviceId: _deviceId,
        );

        expect((await receipts.getById(first.id)).amount, 500000);
        final updatedSecond = await receipts.getById(second.id);
        expect(updatedSecond.amount, 250000);
        expect(updatedSecond.note, second.note);
        expect(updatedSecond.receiptDate, second.receiptDate);
        expect(await receipts.getInvoiceLinkedPaidAmount(invoice.id), 750000);
        expect(await repository.getCollectedAmount(invoice.id), 750000);
        expect(await repository.getRemainingBalance(invoice.id), 600000);
        expect(await db.select(db.receipts).get(), hasLength(2));
      },
    );

    test(
      'resaving an already moved invoice repairs a legacy mismatched receipt client',
      () async {
        await db
            .into(db.clients)
            .insert(
              ClientsCompanion.insert(
                id: _otherClientId,
                displayName: 'بقالة طيبة',
                createdAt: _now,
                updatedAt: _now,
                deviceId: _deviceId,
              ),
            );
        final invoice = await _createEditableInvoice(repository);
        await (db.update(
          db.salesInvoices,
        )..where((t) => t.id.equals(invoice.id))).write(
          const SalesInvoicesCompanion(clientId: Value(_otherClientId)),
        );
        await db.delete(db.syncOutbox).go();

        await repository.update(
          id: invoice.id,
          clientId: _otherClientId,
          invoiceDate: _now,
          discount: 0,
          note: null,
          lines: _editLines,
          paidAmount: 1125000,
          deviceId: _deviceId,
        );

        final receipt = await db.select(db.receipts).getSingle();
        expect(receipt.clientId, _otherClientId);
        expect(receipt.amount, 1125000);
        expect(await ClientRepository(db).getOutstandingBalance(_clientId), 0);
        expect(
          await ClientRepository(db).getOutstandingBalance(_otherClientId),
          225000,
        );
        final mutations = await db.select(db.syncOutbox).get();
        expect(
          mutations.any((row) => row.entityType == ParentEntityType.RECEIPT),
          isTrue,
        );
      },
    );

    test(
      'a failed receipt outbox write rolls back the invoice and payment atomically',
      () async {
        final invoice = await _createEditableInvoice(repository);
        final receipt = await db.select(db.receipts).getSingle();
        final allocation = await db.select(db.receiptAllocations).getSingle();
        await db.delete(db.syncOutbox).go();
        await db.customStatement('''
CREATE TEMP TRIGGER fail_receipt_outbox BEFORE INSERT ON sync_outbox
WHEN NEW.entity_type = ${ParentEntityType.RECEIPT.index}
BEGIN
  SELECT RAISE(ABORT, 'Simulated local queue failure');
END;
''');

        await expectLater(
          repository.update(
            id: invoice.id,
            clientId: _clientId,
            invoiceDate: _now,
            discount: 0,
            note: 'Must roll back',
            lines: _editLines,
            paidAmount: 1000000,
            deviceId: _deviceId,
          ),
          throwsA(isA<Exception>()),
        );

        expect(await repository.getById(invoice.id), invoice);
        expect(await db.select(db.receipts).getSingle(), receipt);
        expect(await db.select(db.receiptAllocations).getSingle(), allocation);
        expect(await db.select(db.syncOutbox).get(), isEmpty);
      },
    );

    test(
      'negative paid amounts roll back invoice lines receipt and outbox changes',
      () async {
        final invoice = await _createEditableInvoice(repository);
        final receipt = await db.select(db.receipts).getSingle();
        final originalLines = await repository.getLinesForInvoice(invoice.id);
        final allocation = await db.select(db.receiptAllocations).getSingle();
        await db.delete(db.syncOutbox).go();

        for (final invalidAmount in [-1]) {
          await expectLater(
            repository.update(
              id: invoice.id,
              clientId: _clientId,
              invoiceDate: DateTime(2026, 1, 2),
              discount: 0,
              note: 'Must not persist',
              lines: _editLines,
              paidAmount: invalidAmount,
              deviceId: _deviceId,
            ),
            throwsArgumentError,
          );
          expect(await repository.getById(invoice.id), invoice);
          expect(
            await repository.getLinesForInvoice(invoice.id),
            originalLines,
          );
          expect(await db.select(db.receipts).getSingle(), receipt);
          expect(
            await db.select(db.receiptAllocations).getSingle(),
            allocation,
          );
          expect(await db.select(db.syncOutbox).get(), isEmpty);
        }
      },
    );

    test(
      'adding payment to an unpaid invoice creates one linked receipt without duplicates on resave',
      () async {
        final invoice = await _createEditableInvoice(repository, paidAmount: 0);

        for (var attempt = 0; attempt < 2; attempt++) {
          await repository.update(
            id: invoice.id,
            clientId: _clientId,
            invoiceDate: _now,
            discount: 0,
            note: null,
            lines: _editLines,
            paidAmount: 1125000,
            deviceId: _deviceId,
          );
        }

        final receipts = await db.select(db.receipts).get();
        expect(receipts, hasLength(1));
        expect(receipts.single.amount, 1125000);
        expect(receipts.single.invoiceId, invoice.id);
        expect(receipts.single.clientId, _clientId);
        final allocations = await db.select(db.receiptAllocations).get();
        expect(allocations, hasLength(1));
        expect(allocations.single.allocatedAmount, 1125000);
        expect(
          (await db.select(db.devices).getSingle()).nextReceiptSequence,
          2,
        );
        final pending = await db.select(db.syncOutbox).get();
        expect(
          pending.where((row) => row.entityType == ParentEntityType.RECEIPT),
          hasLength(1),
        );
        expect(await repository.getRemainingBalance(invoice.id), 225000);
      },
    );

    test(
      'setting paid amount to zero voids the receipt and queues a zero allocation',
      () async {
        final invoice = await _createEditableInvoice(repository);
        final receipt = (await repository.getReceiptsForInvoice(
          invoice.id,
        )).single;
        await db.delete(db.syncOutbox).go();

        await repository.update(
          id: invoice.id,
          clientId: _clientId,
          invoiceDate: _now,
          discount: 0,
          note: null,
          lines: _editLines,
          paidAmount: 0,
          deviceId: _deviceId,
        );

        final voided = await db.select(db.receipts).getSingle();
        expect(voided.id, receipt.id);
        expect(voided.status, RecordStatus.VOIDED);
        expect(voided.voidReason, isNotEmpty);
        expect(await repository.getReceiptsForInvoice(invoice.id), isEmpty);
        expect(await repository.getCollectedAmount(invoice.id), 0);
        expect(
          await ClientRepository(db).getOutstandingBalance(_clientId),
          1350000,
        );
        final mutations = await db.select(db.syncOutbox).get();
        final receiptMutation = mutations.singleWhere(
          (row) => row.entityType == ParentEntityType.RECEIPT,
        );
        expect(
          jsonDecode(receiptMutation.payload)['status'],
          RecordStatus.VOIDED.index,
        );
        final allocationMutation = mutations.singleWhere(
          (row) => row.entityType == ParentEntityType.RECEIPT_ALLOCATION,
        );
        expect(jsonDecode(allocationMutation.payload)['allocatedAmount'], 0);
        expect(allocationMutation.operation, AuditOperation.UPDATE);
      },
    );

    test(
      'editing paid amount updates the same receipt and allocation with a lower invoice total',
      () async {
        final invoice = await _createEditableInvoice(repository);
        final receipt = (await repository.getReceiptsForInvoice(
          invoice.id,
        )).single;
        final allocation = await db.select(db.receiptAllocations).getSingle();
        await db.delete(db.syncOutbox).go();

        await repository.update(
          id: invoice.id,
          clientId: _clientId,
          invoiceDate: _now,
          discount: 350000,
          note: null,
          lines: _editLines,
          paidAmount: 750000,
          deviceId: _deviceId,
        );

        final saved = await repository.getById(invoice.id);
        final updatedReceipt = await db.select(db.receipts).getSingle();
        final updatedAllocation = await db
            .select(db.receiptAllocations)
            .getSingle();
        expect(saved.total, 1000000);
        expect(updatedReceipt.id, receipt.id);
        expect(updatedReceipt.amount, 750000);
        expect(updatedReceipt.syncStatus, SyncStatus.PENDING);
        expect(updatedAllocation.id, allocation.id);
        expect(updatedAllocation.allocatedAmount, 750000);
        expect(await repository.getRemainingBalance(invoice.id), 250000);
        expect(
          await ClientRepository(db).getOutstandingBalance(_clientId),
          250000,
        );
        final outbox = await db.select(db.syncOutbox).get();
        for (final type in [
          ParentEntityType.RECEIPT,
          ParentEntityType.RECEIPT_ALLOCATION,
        ]) {
          final mutation = outbox.singleWhere((row) => row.entityType == type);
          expect(mutation.operation, AuditOperation.UPDATE);
          expect(mutation.status, SyncOutboxStatus.PENDING);
        }
        expect(
          jsonDecode(
            outbox
                .singleWhere(
                  (row) => row.entityType == ParentEntityType.RECEIPT,
                )
                .payload,
          )['amount'],
          750000,
        );
        expect(
          jsonDecode(
            outbox
                .singleWhere(
                  (row) =>
                      row.entityType == ParentEntityType.RECEIPT_ALLOCATION,
                )
                .payload,
          )['allocatedAmount'],
          750000,
        );
      },
    );

    test(
      'moving a paid invoice moves its linked receipt and both client balances locally',
      () async {
        await db
            .into(db.clients)
            .insert(
              ClientsCompanion.insert(
                id: _otherClientId,
                displayName: 'بقالة طيبة',
                createdAt: _now,
                updatedAt: _now,
                deviceId: _deviceId,
              ),
            );
        final invoice = await repository.create(
          clientId: _clientId,
          invoiceDate: _now,
          discount: 0,
          note: '',
          lines: _editLines,
          paidAmount: 1125000,
          deviceId: _deviceId,
        );
        final receipt = (await repository.getReceiptsForInvoice(
          invoice.id,
        )).single;
        await (db.update(
          db.salesInvoices,
        )..where((t) => t.id.equals(invoice.id))).write(
          const SalesInvoicesCompanion(
            officialNo: Value('40'),
            rowVersion: Value(7),
            syncStatus: Value(SyncStatus.SYNCED),
          ),
        );
        await (db.update(
          db.receipts,
        )..where((t) => t.id.equals(receipt.id))).write(
          const ReceiptsCompanion(
            officialNo: Value('9'),
            rowVersion: Value(6),
            syncStatus: Value(SyncStatus.SYNCED),
          ),
        );
        await db.delete(db.syncOutbox).go();

        await repository.update(
          id: invoice.id,
          clientId: _otherClientId,
          invoiceDate: _now,
          discount: 0,
          note: null,
          lines: _editLines,
          deviceId: _deviceId,
        );

        final updatedInvoice = await repository.getById(invoice.id);
        final updatedReceipt = await db.select(db.receipts).getSingle();
        final clients = ClientRepository(db);
        expect(updatedInvoice.clientId, _otherClientId);
        expect(updatedInvoice.officialNo, '40');
        expect(updatedReceipt.id, receipt.id);
        expect(updatedReceipt.localRef, receipt.localRef);
        expect(updatedReceipt.officialNo, '9');
        expect(updatedReceipt.clientId, _otherClientId);
        expect(updatedReceipt.invoiceId, invoice.id);
        expect(updatedReceipt.amount, 1125000);
        expect(updatedReceipt.receiptDate, receipt.receiptDate);
        expect(updatedReceipt.syncStatus, SyncStatus.PENDING);
        expect(await clients.getOutstandingBalance(_clientId), 0);
        expect(await clients.getOutstandingBalance(_otherClientId), 225000);
        expect(await repository.getRemainingBalance(invoice.id), 225000);
        final outbox = await db.select(db.syncOutbox).get();
        final receiptUpdate = outbox.singleWhere(
          (row) => row.entityType == ParentEntityType.RECEIPT,
        );
        expect(receiptUpdate.operation, AuditOperation.UPDATE);
        expect(receiptUpdate.rowVersion, 6);
        expect(receiptUpdate.status, SyncOutboxStatus.PENDING);
        expect(jsonDecode(receiptUpdate.payload)['clientId'], _otherClientId);
      },
    );

    test(
      'saves invoice and line locally and enqueues sync before remote work',
      () async {
        final invoice = await repository.create(
          clientId: _clientId,
          invoiceDate: DateTime(2026, 1, 2),
          discount: 5000,
          note: 'Invoice note',
          lines: const [
            SalesInvoiceLinesCompanion(
              productId: Value(_productId),
              quantity: Value(2),
              unitPrice: Value(125000),
            ),
          ],
          paidAmount: 0,
          deviceId: _deviceId,
        );

        final savedInvoice = await repository.getById(invoice.id);
        final savedLines = await repository.getLinesForInvoice(invoice.id);
        final device = await (db.select(
          db.devices,
        )..where((t) => t.id.equals(_deviceId))).getSingle();
        final outboxRows = await db.select(db.syncOutbox).get();
        final invoiceOutbox = outboxRows.singleWhere(
          (row) => row.entityType == ParentEntityType.SALES_INVOICE,
        );
        final lineOutbox = outboxRows.singleWhere(
          (row) => row.entityType == ParentEntityType.SALES_INVOICE_LINE,
        );
        final invoicePayload =
            jsonDecode(invoiceOutbox.payload) as Map<String, dynamic>;
        final linePayload =
            jsonDecode(lineOutbox.payload) as Map<String, dynamic>;

        expect(savedInvoice.localRef, 'INV-t001-001');
        expect(savedInvoice.clientId, _clientId);
        expect(savedInvoice.discount, 5000);
        expect(savedInvoice.total, 245000);
        expect(savedInvoice.syncStatus, SyncStatus.PENDING);
        expect(savedLines, hasLength(1));
        expect(savedLines.single.productId, _productId);
        expect(savedLines.single.quantity, 2);
        expect(savedLines.single.unitPrice, 125000);
        expect(savedLines.single.lineTotal, 250000);
        expect(device.nextInvoiceSequence, 2);
        expect(outboxRows, hasLength(2));
        expect(invoiceOutbox.operation, AuditOperation.CREATE);
        expect(invoiceOutbox.entityId, savedInvoice.id);
        expect(invoiceOutbox.status, SyncOutboxStatus.PENDING);
        expect(invoicePayload['total'], savedInvoice.total);
        expect(invoicePayload['syncStatus'], SyncStatus.PENDING.index);
        expect(lineOutbox.operation, AuditOperation.CREATE);
        expect(lineOutbox.entityId, savedLines.single.id);
        expect(lineOutbox.status, SyncOutboxStatus.PENDING);
        expect(linePayload['invoiceId'], savedInvoice.id);
        expect(linePayload['lineTotal'], savedLines.single.lineTotal);
      },
    );

    test(
      'saves paid invoice receipt and allocation locally before remote work',
      () async {
        final invoice = await repository.create(
          clientId: _clientId,
          invoiceDate: DateTime(2026, 1, 2),
          discount: 0,
          note: '',
          lines: const [
            SalesInvoiceLinesCompanion(
              productId: Value(_productId),
              quantity: Value(2),
              unitPrice: Value(125000),
            ),
          ],
          paidAmount: 100000,
          deviceId: _deviceId,
        );

        final receipts = await repository.getReceiptsForInvoice(invoice.id);
        final allocations = await (db.select(
          db.receiptAllocations,
        )..where((t) => t.invoiceId.equals(invoice.id))).get();
        final device = await (db.select(
          db.devices,
        )..where((t) => t.id.equals(_deviceId))).getSingle();
        final outboxRows = await db.select(db.syncOutbox).get();
        final receiptOutbox = outboxRows.singleWhere(
          (row) => row.entityType == ParentEntityType.RECEIPT,
        );
        final allocationOutbox = outboxRows.singleWhere(
          (row) => row.entityType == ParentEntityType.RECEIPT_ALLOCATION,
        );
        final receiptPayload =
            jsonDecode(receiptOutbox.payload) as Map<String, dynamic>;
        final allocationPayload =
            jsonDecode(allocationOutbox.payload) as Map<String, dynamic>;

        expect(receipts, hasLength(1));
        expect(receipts.single.localRef, 'REC-t001-001');
        expect(receipts.single.amount, 100000);
        expect(receipts.single.syncStatus, SyncStatus.PENDING);
        expect(allocations, hasLength(1));
        expect(allocations.single.receiptId, receipts.single.id);
        expect(allocations.single.allocatedAmount, 100000);
        expect(device.nextInvoiceSequence, 2);
        expect(device.nextReceiptSequence, 2);
        expect(outboxRows, hasLength(4));
        expect(receiptOutbox.operation, AuditOperation.CREATE);
        expect(receiptOutbox.entityId, receipts.single.id);
        expect(receiptOutbox.status, SyncOutboxStatus.PENDING);
        expect(receiptPayload['amount'], receipts.single.amount);
        expect(allocationOutbox.operation, AuditOperation.CREATE);
        expect(allocationOutbox.entityId, allocations.single.id);
        expect(allocationOutbox.status, SyncOutboxStatus.PENDING);
        expect(allocationPayload['receiptId'], receipts.single.id);
        expect(allocationPayload['allocatedAmount'], 100000);
      },
    );
  });
}
