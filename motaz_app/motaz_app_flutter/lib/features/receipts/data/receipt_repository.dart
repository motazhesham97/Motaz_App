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

    final collectedRow = await _db
        .customSelect(
          'SELECT COALESCE(SUM(ra.allocated_amount), 0) AS collected '
          'FROM receipt_allocations ra '
          'INNER JOIN receipts r ON ra.receipt_id = r.id '
          'WHERE ra.invoice_id = ? AND r.status = ?',
          variables: [
            Variable(invoiceId),
            Variable(RecordStatus.ACTIVE.index),
          ],
        )
        .getSingle();
    final collected = collectedRow.read<int>('collected');
    final remainingBalance = invoice.total - collected;

    final allocatedAmount = remainingBalance <= 0
        ? 0
        : amount < remainingBalance
        ? amount
        : remainingBalance;

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

      String? allocationId;
      if (allocatedAmount > 0) {
        allocationId = _uuid.v4();
        await _db
            .into(_db.receiptAllocations)
            .insert(
              ReceiptAllocationsCompanion(
                id: Value(allocationId),
                receiptId: Value(receiptId),
                invoiceId: Value(invoiceId),
                allocatedAmount: Value(allocatedAmount),
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );
      }

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

      if (allocationId != null) {
        final allocPayload = jsonEncode({
          'id': allocationId,
          'receiptId': receiptId,
          'invoiceId': invoiceId,
          'allocatedAmount': allocatedAmount,
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        });
        await _db
            .into(_db.syncOutbox)
            .insert(
              SyncOutboxCompanion.insert(
                id: _uuid.v4(),
                entityType: ParentEntityType.RECEIPT_ALLOCATION,
                entityId: allocationId,
                operation: AuditOperation.CREATE,
                payload: allocPayload,
                rowVersion: 1,
                deviceId: deviceId,
                createdAt: now,
                status: Value(SyncOutboxStatus.PENDING),
              ),
            );
      }
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
    final allocator = ReceiptAllocator(_db);
    final allocations = await allocator.allocateFifo(clientId, amount);

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

      for (final alloc in allocations) {
        final allocWithReceipt = alloc.copyWith(
          receiptId: Value(receiptId),
        );
        await _db.into(_db.receiptAllocations).insert(allocWithReceipt);

        final allocId = allocWithReceipt.id.value;
        final allocPayload = jsonEncode({
          'id': allocId,
          'receiptId': receiptId,
          'invoiceId': allocWithReceipt.invoiceId.value,
          'allocatedAmount': allocWithReceipt.allocatedAmount.value,
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        });
        await _db
            .into(_db.syncOutbox)
            .insert(
              SyncOutboxCompanion.insert(
                id: _uuid.v4(),
                entityType: ParentEntityType.RECEIPT_ALLOCATION,
                entityId: allocId,
                operation: AuditOperation.CREATE,
                payload: allocPayload,
                rowVersion: 1,
                deviceId: deviceId,
                createdAt: now,
                status: Value(SyncOutboxStatus.PENDING),
              ),
            );
      }

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
    List<ReceiptAllocationsCompanion> desiredAllocations;

    if (existing.receiptType == ReceiptType.INVOICE_LINKED &&
        existing.invoiceId != null) {
      final invoice = await (_db.select(
        _db.salesInvoices,
      )..where((t) => t.id.equals(existing.invoiceId!))).getSingle();

      if (invoice.status == RecordStatus.VOIDED) {
        throw StateError('Cannot edit receipt for a voided invoice');
      }

      effectiveClientId = invoice.clientId;
      final collectedRow = await _db
          .customSelect(
            'SELECT COALESCE(SUM(ra.allocated_amount), 0) AS collected '
            'FROM receipt_allocations ra '
            'INNER JOIN receipts r ON ra.receipt_id = r.id '
            'WHERE ra.invoice_id = ? AND r.status = ? AND r.id != ?',
            variables: [
              Variable(existing.invoiceId!),
              Variable(RecordStatus.ACTIVE.index),
              Variable(id),
            ],
          )
          .getSingle();
      final collected = collectedRow.read<int>('collected');
      final remainingBalance = invoice.total - collected;
      final allocatedAmount = remainingBalance <= 0
          ? 0
          : amount < remainingBalance
          ? amount
          : remainingBalance;

      desiredAllocations = allocatedAmount > 0
          ? [
              ReceiptAllocationsCompanion(
                id: Value(_uuid.v4()),
                receiptId: Value(id),
                invoiceId: Value(existing.invoiceId!),
                allocatedAmount: Value(allocatedAmount),
                createdAt: Value(DateTime.now()),
                updatedAt: Value(DateTime.now()),
              ),
            ]
          : const [];
    } else {
      final allocator = ReceiptAllocator(_db);
      desiredAllocations = await allocator.allocateFifo(
        effectiveClientId,
        amount,
        excludeReceiptId: id,
      );
    }

    final now = DateTime.now();
    final baseVersion = _baseServerRowVersion(existing);
    final newVersion = baseVersion + 1;

    await _db.transaction(() async {
      await (_db.update(_db.receipts)..where((t) => t.id.equals(id))).write(
        ReceiptsCompanion(
          clientId: Value(effectiveClientId),
          amount: Value(amount),
          receiptDate: Value(receiptDate),
          note: Value(note),
          updatedAt: Value(now),
          rowVersion: Value(newVersion),
          syncStatus: Value(SyncStatus.PENDING),
        ),
      );

      final receiptPayload = jsonEncode({
        'id': id,
        'localRef': existing.localRef,
        'receiptType': existing.receiptType.index,
        'clientId': effectiveClientId,
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
              entityId: id,
              operation: AuditOperation.UPDATE,
              payload: receiptPayload,
              rowVersion: baseVersion,
              deviceId: deviceId,
              createdAt: now,
              status: Value(SyncOutboxStatus.PENDING),
            ),
          );

      await _replaceAllocations(
        receiptId: id,
        desiredAllocations: desiredAllocations,
        deviceId: deviceId,
        now: now,
      );
    });
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
      await (_db.delete(
        _db.receiptAllocations,
      )..where((t) => t.receiptId.equals(id))).go();

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
    final maxLength = desiredAllocations.length > existingAllocations.length
        ? desiredAllocations.length
        : existingAllocations.length;

    for (var i = 0; i < maxLength; i++) {
      if (i < desiredAllocations.length) {
        final desired = desiredAllocations[i];
        final invoiceId = desired.invoiceId.value;
        final allocatedAmount = desired.allocatedAmount.value;

        if (i < existingAllocations.length) {
          final existing = existingAllocations[i];
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
      } else {
        final existing = existingAllocations[i];
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
          createdAt: existing.createdAt,
          updatedAt: now,
          operation: AuditOperation.UPDATE,
          deviceId: deviceId,
        );
      }
    }
  }

  Future<void> _enqueueAllocationMutation({
    required String id,
    required String receiptId,
    required String invoiceId,
    required int allocatedAmount,
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
