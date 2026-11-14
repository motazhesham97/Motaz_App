import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/enums/audit_operation.dart';
import '../../../core/database/enums/parent_entity_type.dart';
import '../../../core/database/enums/record_status.dart';
import '../../../core/database/enums/receipt_type.dart';
import '../../../core/database/enums/sync_outbox_status.dart';
import '../../../core/database/enums/sync_status.dart';
import 'receipt_allocator.dart';

class ReceiptRepository {
  ReceiptRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  Future<({String localRef, int sequence})> _nextReceiptRef(
    String deviceId,
  ) async {
    final device = await (_db.select(
      _db.devices,
    )..where((t) => t.id.equals(deviceId))).getSingle();
    final sequence = device.nextReceiptSequence;
    final localRef =
        'REC-${device.deviceCode}-${sequence.toString().padLeft(3, '0')}';
    return (localRef: localRef, sequence: sequence);
  }

  Future<Receipt> createInvoiceLinked({
    required String clientId,
    required String invoiceId,
    required int amount,
    required DateTime receiptDate,
    String? note,
    required String deviceId,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Amount must be positive');
    }

    final invoice = await (_db.select(
      _db.salesInvoices,
    )..where((t) => t.id.equals(invoiceId))).getSingle();

    if (invoice.status == RecordStatus.VOIDED) {
      throw StateError('Cannot create receipt for a voided invoice');
    }

    if (invoice.clientId != clientId) {
      throw ArgumentError('Invoice does not belong to the specified client');
    }

    final receiptId = _uuid.v4();
    final ref = await _nextReceiptRef(deviceId);
    final now = DateTime.now();

    await _db.transaction(() async {
      await _db
          .into(_db.receipts)
          .insert(
            ReceiptsCompanion(
              id: Value(receiptId),
              localRef: Value(ref.localRef),
              receiptType: Value(ReceiptType.INVOICE_LINKED),
              clientId: Value(clientId),
              invoiceId: Value(invoiceId),
              amount: Value(amount),
              receiptDate: Value(receiptDate),
              note: Value(note),
              status: Value(RecordStatus.ACTIVE),
              voidReason: Value.absent(),
              createdAt: Value(now),
              updatedAt: Value(now),
              deviceId: Value(deviceId),
              rowVersion: const Value(1),
              syncStatus: Value(SyncStatus.PENDING),
            ),
          );

      final receiptPayload = jsonEncode({
        'id': receiptId,
        'localRef': ref.localRef,
        'receiptType': ReceiptType.INVOICE_LINKED.index,
        'clientId': clientId,
        'invoiceId': invoiceId,
        'amount': amount,
        'receiptDate': receiptDate.toIso8601String(),
        'note': note,
        'status': RecordStatus.ACTIVE.index,
        'voidReason': null,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'deviceId': deviceId,
        'rowVersion': 1,
        'syncStatus': SyncStatus.PENDING.index,
      });
      await _db
          .into(_db.syncOutbox)
          .insert(
            SyncOutboxCompanion.insert(
              id: _uuid.v4(),
              entityType: ParentEntityType.RECEIPT,
              entityId: receiptId,
              operation: AuditOperation.CREATE,
              payload: receiptPayload,
              rowVersion: 1,
              deviceId: deviceId,
              createdAt: now,
              status: Value(SyncOutboxStatus.PENDING),
            ),
          );

      await (_db.update(
        _db.devices,
      )..where((t) => t.id.equals(deviceId))).write(
        DevicesCompanion(
          nextReceiptSequence: Value(ref.sequence + 1),
        ),
      );

      await reconcileClientPayments(clientId: clientId, deviceId: deviceId);
    });

    return await getById(receiptId);
  }

  Future<Receipt> createGeneral({
    required String clientId,
    required int amount,
    required DateTime receiptDate,
    String? note,
    required String deviceId,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Amount must be positive');
    }

    final receiptId = _uuid.v4();
    final ref = await _nextReceiptRef(deviceId);
    final now = DateTime.now();

    await _db.transaction(() async {
      await _db
          .into(_db.receipts)
          .insert(
            ReceiptsCompanion(
              id: Value(receiptId),
              localRef: Value(ref.localRef),
              receiptType: Value(ReceiptType.GENERAL),
              clientId: Value(clientId),
              invoiceId: Value.absent(),
              amount: Value(amount),
              receiptDate: Value(receiptDate),
              note: Value(note),
              status: Value(RecordStatus.ACTIVE),
              voidReason: Value.absent(),
              createdAt: Value(now),
              updatedAt: Value(now),
              deviceId: Value(deviceId),
              rowVersion: const Value(1),
              syncStatus: Value(SyncStatus.PENDING),
            ),
          );

      final receiptPayload = jsonEncode({
        'id': receiptId,
        'localRef': ref.localRef,
        'receiptType': ReceiptType.GENERAL.index,
        'clientId': clientId,
        'invoiceId': null,
        'amount': amount,
        'receiptDate': receiptDate.toIso8601String(),
        'note': note,
        'status': RecordStatus.ACTIVE.index,
        'voidReason': null,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'deviceId': deviceId,
        'rowVersion': 1,
        'syncStatus': SyncStatus.PENDING.index,
      });
      await _db
          .into(_db.syncOutbox)
          .insert(
            SyncOutboxCompanion.insert(
              id: _uuid.v4(),
              entityType: ParentEntityType.RECEIPT,
              entityId: receiptId,
              operation: AuditOperation.CREATE,
              payload: receiptPayload,
              rowVersion: 1,
              deviceId: deviceId,
              createdAt: now,
              status: Value(SyncOutboxStatus.PENDING),
            ),
          );

      await (_db.update(
        _db.devices,
      )..where((t) => t.id.equals(deviceId))).write(
        DevicesCompanion(
          nextReceiptSequence: Value(ref.sequence + 1),
        ),
      );
      await reconcileClientPayments(clientId: clientId, deviceId: deviceId);
    });

    return await getById(receiptId);
  }

  Future<void> updateReceipt({
    required String id,
    required String clientId,
    required int amount,
    required DateTime receiptDate,
    String? note,
    required String deviceId,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Amount must be positive');
    }

    final existing = await getById(id);
    if (existing.status == RecordStatus.VOIDED) {
      throw StateError('Cannot edit a voided receipt');
    }

    var effectiveClientId = clientId;

    if (existing.receiptType == ReceiptType.INVOICE_LINKED &&
        existing.invoiceId != null) {
      final invoice = await (_db.select(
        _db.salesInvoices,
      )..where((t) => t.id.equals(existing.invoiceId!))).getSingle();

      if (invoice.status == RecordStatus.VOIDED) {
        throw StateError('Cannot edit receipt for a voided invoice');
      }

      effectiveClientId = invoice.clientId;
    }

    final now = DateTime.now();

    await _db.transaction(() async {
      await _writeReceiptUpdate(
        existing: existing,
        clientId: effectiveClientId,
        amount: amount,
        receiptDate: receiptDate,
        note: note,
        deviceId: deviceId,
        now: now,
      );

      for (final affectedClientId in {existing.clientId, effectiveClientId}) {
        await reconcileClientPayments(
          clientId: affectedClientId,
          deviceId: deviceId,
        );
      }
    });
  }

  Future<List<Receipt>> _activeInvoiceLinkedReceipts(String invoiceId) {
    return (_db.select(_db.receipts)
          ..where(
            (t) =>
                t.invoiceId.equals(invoiceId) &
                t.receiptType.equals(ReceiptType.INVOICE_LINKED.index) &
                t.status.equals(RecordStatus.ACTIVE.index),
          )
          ..orderBy([
            (t) => OrderingTerm.asc(t.createdAt),
            (t) => OrderingTerm.asc(t.receiptDate),
            (t) => OrderingTerm.asc(t.localRef),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();
  }

  Future<int> getInvoiceLinkedPaidAmount(String invoiceId) async {
    final receipts = await _activeInvoiceLinkedReceipts(invoiceId);
    return receipts.fold<int>(0, (total, receipt) => total + receipt.amount);
  }

  Future<void> reconcileClientPayments({
    required String clientId,
    required String deviceId,
  }) async {
    await _db.transaction(() async {
      final plan = await ReceiptAllocator(_db).planForClient(clientId);
      final now = DateTime.now();
      for (final entry in plan.entries) {
        await _replaceAllocations(
          receiptId: entry.key,
          desiredAllocations: entry.value,
          deviceId: deviceId,
          now: now,
        );
      }
    });
  }

  Future<void> updateInvoiceLinkedPayments({
    required String invoiceId,
    required String deviceId,
    int? paidAmount,
    String? previousClientId,
  }) async {
    await _db.transaction(() async {
      final invoice = await (_db.select(
        _db.salesInvoices,
      )..where((t) => t.id.equals(invoiceId))).getSingle();
      if (invoice.status == RecordStatus.VOIDED) {
        throw StateError('Cannot edit payments for a voided invoice');
      }
      final linked = await _activeInvoiceLinkedReceipts(invoiceId);
      final currentPaid = linked.fold<int>(
        0,
        (total, receipt) => total + receipt.amount,
      );
      final desiredPaid = paidAmount ?? currentPaid;
      if (desiredPaid < 0) {
        throw ArgumentError('Paid amount cannot be negative');
      }

      final affectedClients = {
        invoice.clientId,
        ?previousClientId,
        for (final receipt in linked) receipt.clientId,
      };

      if (linked.isEmpty) {
        if (desiredPaid > 0) {
          await createInvoiceLinked(
            clientId: invoice.clientId,
            invoiceId: invoiceId,
            amount: desiredPaid,
            receiptDate: invoice.invoiceDate,
            deviceId: deviceId,
          );
        }
      } else {
        final now = DateTime.now();
        var remaining = desiredPaid;
        for (var index = 0; index < linked.length; index++) {
          final receipt = linked[index];
          // Preserve earlier payments where possible; adjust the final payment.
          final amount =
              index == linked.length - 1 || remaining < receipt.amount
              ? remaining
              : receipt.amount;
          remaining -= amount;
          if (amount == 0) {
            await voidReceipt(
              receipt.id,
              'إلغاء الدفعة من تعديل الفاتورة',
              deviceId,
            );
            continue;
          }
          if (receipt.clientId != invoice.clientId ||
              receipt.amount != amount) {
            await _writeReceiptUpdate(
              existing: receipt,
              clientId: invoice.clientId,
              amount: amount,
              receiptDate: receipt.receiptDate,
              note: receipt.note,
              deviceId: deviceId,
              now: now,
            );
          }
        }
      }
      for (final clientId in affectedClients) {
        await reconcileClientPayments(clientId: clientId, deviceId: deviceId);
      }
    });
  }

  Future<void> _writeReceiptUpdate({
    required Receipt existing,
    required String clientId,
    required int amount,
    required DateTime receiptDate,
    required String? note,
    required String deviceId,
    required DateTime now,
  }) async {
    final baseVersion = _baseServerRowVersion(existing);
    final newVersion = baseVersion + 1;
    await (_db.update(
      _db.receipts,
    )..where((t) => t.id.equals(existing.id))).write(
      ReceiptsCompanion(
        clientId: Value(clientId),
        amount: Value(amount),
        receiptDate: Value(receiptDate),
        note: Value(note),
        updatedAt: Value(now),
        rowVersion: Value(newVersion),
        syncStatus: Value(SyncStatus.PENDING),
      ),
    );
    final payload = jsonEncode({
      'id': existing.id,
      'localRef': existing.localRef,
      'receiptType': existing.receiptType.index,
      'clientId': clientId,
      'invoiceId': existing.invoiceId,
      'amount': amount,
      'receiptDate': receiptDate.toIso8601String(),
      'note': note,
      'status': existing.status.index,
      'voidReason': existing.voidReason,
      'createdAt': existing.createdAt.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'deviceId': existing.deviceId,
      'rowVersion': newVersion,
      'syncStatus': SyncStatus.PENDING.index,
    });
    await _db
        .into(_db.syncOutbox)
        .insert(
          SyncOutboxCompanion.insert(
            id: _uuid.v4(),
            entityType: ParentEntityType.RECEIPT,
            entityId: existing.id,
            operation: AuditOperation.UPDATE,
            payload: payload,
            rowVersion: baseVersion,
            deviceId: deviceId,
            createdAt: now,
            status: const Value(SyncOutboxStatus.PENDING),
          ),
        );
  }

  Future<void> voidReceipt(String id, String reason, String deviceId) async {
    if (reason.trim().isEmpty) {
      throw ArgumentError('Void reason is required');
    }

    final existing = await getById(id);

    if (existing.status == RecordStatus.VOIDED) {
      throw StateError('Receipt is already voided');
    }

    final now = DateTime.now();
    final baseVersion = _baseServerRowVersion(existing);
    final newVersion = baseVersion + 1;

    await _db.transaction(() async {
      await _replaceAllocations(
        receiptId: id,
        desiredAllocations: const [],
        deviceId: deviceId,
        now: now,
      );

      await (_db.update(_db.receipts)..where((t) => t.id.equals(id))).write(
        ReceiptsCompanion(
          status: Value(RecordStatus.VOIDED),
          voidReason: Value(reason),
          updatedAt: Value(now),
          rowVersion: Value(newVersion),
          syncStatus: Value(SyncStatus.PENDING),
        ),
      );

      final receiptPayload = jsonEncode({
        'id': id,
        'localRef': existing.localRef,
        'receiptType': existing.receiptType.index,
        'clientId': existing.clientId,
        'invoiceId': existing.invoiceId,
        'amount': existing.amount,
        'receiptDate': existing.receiptDate.toIso8601String(),
        'note': existing.note,
        'status': RecordStatus.VOIDED.index,
        'voidReason': reason,
        'createdAt': existing.createdAt.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'deviceId': existing.deviceId,
        'rowVersion': newVersion,
        'syncStatus': SyncStatus.PENDING.index,
      });
      await _db
          .into(_db.syncOutbox)
          .insert(
            SyncOutboxCompanion.insert(
              id: _uuid.v4(),
              entityType: ParentEntityType.RECEIPT,
              entityId: id,
              operation: AuditOperation.UPDATE,
              payload: receiptPayload,
              rowVersion: baseVersion,
              deviceId: deviceId,
              createdAt: now,
              status: Value(SyncOutboxStatus.PENDING),
            ),
          );
      await reconcileClientPayments(
        clientId: existing.clientId,
        deviceId: deviceId,
      );
    });
  }

  Future<Receipt> getById(String id) async {
    return (_db.select(
      _db.receipts,
    )..where((t) => t.id.equals(id))).getSingle();
  }

  Stream<List<Receipt>> watchAll() {
    return (_db.select(_db.receipts)..orderBy([
          (t) => OrderingTerm.desc(t.receiptDate),
          (t) => OrderingTerm.desc(t.createdAt),
        ]))
        .watch();
  }

  Future<Map<String, String>> getClientNamesByReceiptId() async {
    final rows = await _db
        .customSelect(
          'SELECT r.id AS receipt_id, '
          'COALESCE(MAX(c.display_name), MAX(invoice_client.display_name), MAX(allocation_client.display_name)) AS client_name '
          'FROM receipts r '
          'LEFT JOIN clients c ON c.id = r.client_id '
          'LEFT JOIN sales_invoices invoice ON invoice.id = r.invoice_id '
          'LEFT JOIN clients invoice_client ON invoice_client.id = invoice.client_id '
          'LEFT JOIN receipt_allocations ra ON ra.receipt_id = r.id '
          'LEFT JOIN sales_invoices allocation_invoice ON allocation_invoice.id = ra.invoice_id '
          'LEFT JOIN clients allocation_client ON allocation_client.id = allocation_invoice.client_id '
          'GROUP BY r.id '
          'HAVING client_name IS NOT NULL',
        )
        .get();

    return {
      for (final row in rows)
        row.read<String>('receipt_id'): row.read<String>('client_name'),
    };
  }

  Future<List<ReceiptAllocation>> getAllocationsForReceipt(
    String receiptId,
  ) async {
    return (_db.select(
      _db.receiptAllocations,
    )..where((t) => t.receiptId.equals(receiptId))).get();
  }

  Future<void> _replaceAllocations({
    required String receiptId,
    required List<ReceiptAllocationsCompanion> desiredAllocations,
    required String deviceId,
    required DateTime now,
  }) async {
    final existingAllocations = await getAllocationsForReceipt(receiptId);
    final unmatched = existingAllocations.toList();
    for (final desired in desiredAllocations) {
      final invoiceId = desired.invoiceId.value;
      final allocatedAmount = desired.allocatedAmount.value;
      final index = unmatched.indexWhere((row) => row.invoiceId == invoiceId);
      if (index >= 0) {
        final existing = unmatched.removeAt(index);
        if (existing.allocatedAmount == allocatedAmount) {
          continue;
        }
        await (_db.update(
          _db.receiptAllocations,
        )..where((t) => t.id.equals(existing.id))).write(
          ReceiptAllocationsCompanion(
            invoiceId: Value(invoiceId),
            allocatedAmount: Value(allocatedAmount),
            updatedAt: Value(now),
          ),
        );
        await _enqueueAllocationMutation(
          id: existing.id,
          receiptId: receiptId,
          invoiceId: invoiceId,
          allocatedAmount: allocatedAmount,
          previousAllocatedAmount: existing.allocatedAmount,
          createdAt: existing.createdAt,
          updatedAt: now,
          operation: AuditOperation.UPDATE,
          deviceId: deviceId,
        );
      } else {
        final allocationId = desired.id.value;
        await _db
            .into(_db.receiptAllocations)
            .insert(
              desired.copyWith(
                receiptId: Value(receiptId),
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );
        await _enqueueAllocationMutation(
          id: allocationId,
          receiptId: receiptId,
          invoiceId: invoiceId,
          allocatedAmount: allocatedAmount,
          createdAt: now,
          updatedAt: now,
          operation: AuditOperation.CREATE,
          deviceId: deviceId,
        );
      }
    }
    for (final existing in unmatched) {
      if (existing.allocatedAmount == 0) continue;
      await (_db.update(
        _db.receiptAllocations,
      )..where((t) => t.id.equals(existing.id))).write(
        ReceiptAllocationsCompanion(
          allocatedAmount: const Value(0),
          updatedAt: Value(now),
        ),
      );
      await _enqueueAllocationMutation(
        id: existing.id,
        receiptId: receiptId,
        invoiceId: existing.invoiceId,
        allocatedAmount: 0,
        previousAllocatedAmount: existing.allocatedAmount,
        createdAt: existing.createdAt,
        updatedAt: now,
        operation: AuditOperation.UPDATE,
        deviceId: deviceId,
      );
    }
  }

  Future<void> _enqueueAllocationMutation({
    required String id,
    required String receiptId,
    required String invoiceId,
    required int allocatedAmount,
    int? previousAllocatedAmount,
    required DateTime createdAt,
    required DateTime updatedAt,
    required AuditOperation operation,
    required String deviceId,
  }) async {
    final payload = jsonEncode({
      'id': id,
      'receiptId': receiptId,
      'invoiceId': invoiceId,
      'allocatedAmount': allocatedAmount,
      'previousAllocatedAmount': ?previousAllocatedAmount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    });
    await _db
        .into(_db.syncOutbox)
        .insert(
          SyncOutboxCompanion.insert(
            id: _uuid.v4(),
            entityType: ParentEntityType.RECEIPT_ALLOCATION,
            entityId: id,
            operation: operation,
            payload: payload,
            rowVersion: 1,
            deviceId: deviceId,
            createdAt: updatedAt,
            status: Value(SyncOutboxStatus.PENDING),
          ),
        );
  }

  int _baseServerRowVersion(Receipt receipt) {
    if (receipt.syncStatus == SyncStatus.SYNCED || receipt.rowVersion <= 1) {
      return receipt.rowVersion;
    }
    return receipt.rowVersion - 1;
  }
}
