import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/enums/audit_operation.dart';
import '../../../core/database/enums/parent_entity_type.dart';
import '../../../core/database/enums/record_status.dart';
import '../../../core/database/enums/sync_outbox_status.dart';
import '../../../core/database/enums/sync_status.dart';
import '../../receipts/data/receipt_repository.dart';

typedef InvoicePayment = ({Receipt receipt, int allocatedAmount});

class InvoiceRepository {
  InvoiceRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  Future<SalesInvoice> create({
    required String clientId,
    required DateTime invoiceDate,
    required int discount,
    required String note,
    required List<SalesInvoiceLinesCompanion> lines,
    required int paidAmount,
    required String deviceId,
  }) async {
    if (lines.isEmpty) {
      throw ArgumentError('Invoice must have at least one line');
    }
    if (paidAmount < 0) {
      throw ArgumentError('Paid amount cannot be negative');
    }

    var subtotal = 0;
    final preparedLines = <SalesInvoiceLinesCompanion>[];
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final qty = line.quantity.present ? line.quantity.value : 1;
      final price = line.unitPrice.present ? line.unitPrice.value : 0;
      final lineTotal = qty * price;
      preparedLines.add(
        line.copyWith(
          lineTotal: Value(lineTotal),
        ),
      );
      subtotal += lineTotal;
    }

    if (discount > subtotal) {
      throw ArgumentError('Discount cannot exceed subtotal');
    }

    final total = subtotal - discount;

    final device = await (_db.select(
      _db.devices,
    )..where((t) => t.id.equals(deviceId))).getSingle();
    final sequence = device.nextInvoiceSequence;
    final localRef =
        'INV-${device.deviceCode}-${sequence.toString().padLeft(3, '0')}';

    final invoiceId = _uuid.v4();
    final now = DateTime.now();

    await _db.transaction(() async {
      await _db
          .into(_db.salesInvoices)
          .insert(
            SalesInvoicesCompanion(
              id: Value(invoiceId),
              localRef: Value(localRef),
              officialNo: Value.absent(),
              clientId: Value(clientId),
              invoiceDate: Value(invoiceDate),
              discount: Value(discount),
              total: Value(total),
              note: Value(note.isEmpty ? null : note),
              status: Value(RecordStatus.ACTIVE),
              voidReason: Value.absent(),
              createdAt: Value(now),
              updatedAt: Value(now),
              deviceId: Value(deviceId),
              rowVersion: const Value(1),
              syncStatus: Value(SyncStatus.PENDING),
            ),
          );

      for (final line in preparedLines) {
        final lineId = _uuid.v4();
        await _db
            .into(_db.salesInvoiceLines)
            .insert(
              line.copyWith(
                id: Value(lineId),
                invoiceId: Value(invoiceId),
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );

        final linePayload = jsonEncode({
          'id': lineId,
          'invoiceId': invoiceId,
          'productId': line.productId.present ? line.productId.value : null,
          'quantity': line.quantity.present ? line.quantity.value : null,
          'unitPrice': line.unitPrice.present ? line.unitPrice.value : null,
          'lineTotal': line.lineTotal.present ? line.lineTotal.value : null,
          'productionDate': line.productionDate.present
              ? line.productionDate.value?.toIso8601String()
              : null,
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        });
        await _db
            .into(_db.syncOutbox)
            .insert(
              SyncOutboxCompanion.insert(
                id: _uuid.v4(),
                entityType: ParentEntityType.SALES_INVOICE_LINE,
                entityId: lineId,
                operation: AuditOperation.CREATE,
                payload: linePayload,
                rowVersion: 1,
                deviceId: deviceId,
                createdAt: now,
                status: Value(SyncOutboxStatus.PENDING),
              ),
            );
      }

      await (_db.update(
        _db.devices,
      )..where((t) => t.id.equals(deviceId))).write(
        DevicesCompanion(
          nextInvoiceSequence: Value(sequence + 1),
        ),
      );

      final invoicePayload = jsonEncode({
        'id': invoiceId,
        'localRef': localRef,
        'officialNo': null,
        'clientId': clientId,
        'invoiceDate': invoiceDate.toIso8601String(),
        'discount': discount,
        'total': total,
        'note': note.isEmpty ? null : note,
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
              entityType: ParentEntityType.SALES_INVOICE,
              entityId: invoiceId,
              operation: AuditOperation.CREATE,
              payload: invoicePayload,
              rowVersion: 1,
              deviceId: deviceId,
              createdAt: now,
              status: Value(SyncOutboxStatus.PENDING),
            ),
          );

      if (paidAmount > 0) {
        await ReceiptRepository(_db).createInvoiceLinked(
          clientId: clientId,
          invoiceId: invoiceId,
          amount: paidAmount,
          receiptDate: invoiceDate,
          deviceId: deviceId,
        );
      } else {
        await ReceiptRepository(_db).reconcileClientPayments(
          clientId: clientId,
          deviceId: deviceId,
        );
      }
    });

    return await getById(invoiceId);
  }

  Future<SalesInvoice> getById(String id) async {
    return (_db.select(
      _db.salesInvoices,
    )..where((t) => t.id.equals(id))).getSingle();
  }

  Stream<List<SalesInvoice>> watchAll() {
    return (_db.select(_db.salesInvoices)..orderBy([
          (t) => OrderingTerm.desc(t.invoiceDate),
          (t) => OrderingTerm.desc(t.createdAt),
        ]))
        .watch();
  }

  Future<List<SalesInvoiceLine>> getLinesForInvoice(String invoiceId) async {
    return (_db.select(
      _db.salesInvoiceLines,
    )..where((t) => t.invoiceId.equals(invoiceId))).get();
  }

  Future<List<Receipt>> getReceiptsForInvoice(String invoiceId) async {
    return (_db.select(_db.receipts)..where(
          (t) =>
              t.invoiceId.equals(invoiceId) &
              t.status.equals(RecordStatus.ACTIVE.index),
        ))
        .get();
  }

  Future<int> getCollectedAmount(String invoiceId) async {
    final row = await _db
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
    return row.read<int>('collected');
  }

  Future<List<InvoicePayment>> getPaymentsForInvoice(String invoiceId) async {
    final rows = await _db
        .customSelect(
          'SELECT r.*, COALESCE((SELECT SUM(a.allocated_amount) FROM receipt_allocations a '
          'WHERE a.receipt_id = r.id AND a.invoice_id = ?), 0) AS allocated_to_invoice '
          'FROM receipts r WHERE r.status = ? AND (r.invoice_id = ? OR EXISTS('
          'SELECT 1 FROM receipt_allocations a WHERE a.receipt_id = r.id '
          'AND a.invoice_id = ? AND a.allocated_amount > 0)) '
          'ORDER BY r.receipt_date, r.created_at, r.id',
          variables: [
            Variable(invoiceId),
            Variable(RecordStatus.ACTIVE.index),
            Variable(invoiceId),
            Variable(invoiceId),
          ],
        )
        .get();
    return [
      for (final row in rows)
        (
          receipt: _db.receipts.map(row.data),
          allocatedAmount: row.read<int>('allocated_to_invoice'),
        ),
    ];
  }

  Future<int> getRemainingBalance(String invoiceId) async {
    final invoice = await getById(invoiceId);
    final collected = await getCollectedAmount(invoiceId);
    final returned = await getActiveReturnTotal(invoiceId);
    return invoice.total - collected - returned;
  }

  Future<int> getActiveReturnTotal(String invoiceId) async {
    final row = await _db
        .customSelect(
          'SELECT COALESCE(SUM(total_returned_amount), 0) AS returned '
          'FROM sales_returns '
          'WHERE invoice_id = ? AND status = ?',
          variables: [
            Variable(invoiceId),
            Variable(RecordStatus.ACTIVE.index),
          ],
        )
        .getSingle();
    return row.read<int>('returned');
  }

  Future<bool> hasActiveReceipts(String invoiceId) async {
    final row = await _db
        .customSelect(
          'SELECT COUNT(*) AS cnt FROM receipts '
          'WHERE invoice_id = ? AND status = ?',
          variables: [
            Variable(invoiceId),
            Variable(RecordStatus.ACTIVE.index),
          ],
        )
        .getSingle();
    return row.read<int>('cnt') > 0;
  }

  Future<bool> hasActiveReturns(String invoiceId) async {
    final row = await _db
        .customSelect(
          'SELECT COUNT(*) AS cnt FROM sales_returns '
          'WHERE invoice_id = ? AND status = ?',
          variables: [
            Variable(invoiceId),
            Variable(RecordStatus.ACTIVE.index),
          ],
        )
        .getSingle();
    return row.read<int>('cnt') > 0;
  }

  Future<void> update({
    required String id,
    required String clientId,
    required DateTime invoiceDate,
    required int discount,
    required String? note,
    required List<SalesInvoiceLinesCompanion> lines,
    required String deviceId,
    int? paidAmount,
  }) async {
    final existing = await getById(id);

    if (existing.status == RecordStatus.VOIDED) {
      throw StateError('Cannot update a voided invoice');
    }

    if (await hasActiveReturns(id)) {
      throw StateError(
        'Cannot update invoice with active returns. Use updateNote instead.',
      );
    }

    if (lines.isEmpty) {
      throw ArgumentError('Invoice must have at least one line');
    }

    var subtotal = 0;
    final preparedLines = <SalesInvoiceLinesCompanion>[];
    for (final line in lines) {
      final qty = line.quantity.present ? line.quantity.value : 1;
      final price = line.unitPrice.present ? line.unitPrice.value : 0;
      final lineTotal = qty * price;
      preparedLines.add(
        line.copyWith(
          lineTotal: Value(lineTotal),
        ),
      );
      subtotal += lineTotal;
    }

    if (discount > subtotal) {
      throw ArgumentError('Discount cannot exceed subtotal');
    }

    final total = subtotal - discount;

    final now = DateTime.now();
    final baseVersion =
        existing.syncStatus == SyncStatus.SYNCED || existing.rowVersion <= 1
        ? existing.rowVersion
        : existing.rowVersion - 1;
    final newVersion = baseVersion + 1;

    await _db.transaction(() async {
      if (!await _hasSameLines(id, preparedLines)) {
        await (_db.delete(
          _db.salesInvoiceLines,
        )..where((t) => t.invoiceId.equals(id))).go();
        for (final line in preparedLines) {
          final lineId = _uuid.v4();
          await _db
              .into(_db.salesInvoiceLines)
              .insert(
                line.copyWith(
                  id: Value(lineId),
                  invoiceId: Value(id),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                ),
              );
          final linePayload = jsonEncode({
            'id': lineId,
            'invoiceId': id,
            'productId': line.productId.present ? line.productId.value : null,
            'quantity': line.quantity.present ? line.quantity.value : null,
            'unitPrice': line.unitPrice.present ? line.unitPrice.value : null,
            'lineTotal': line.lineTotal.present ? line.lineTotal.value : null,
            'productionDate': line.productionDate.present
                ? line.productionDate.value?.toIso8601String()
                : null,
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          });
          await _db
              .into(_db.syncOutbox)
              .insert(
                SyncOutboxCompanion.insert(
                  id: _uuid.v4(),
                  entityType: ParentEntityType.SALES_INVOICE_LINE,
                  entityId: lineId,
                  operation: AuditOperation.CREATE,
                  payload: linePayload,
                  rowVersion: newVersion,
                  deviceId: deviceId,
                  createdAt: now,
                  status: const Value(SyncOutboxStatus.PENDING),
                ),
              );
        }
      }

      await (_db.update(
        _db.salesInvoices,
      )..where((t) => t.id.equals(id))).write(
        SalesInvoicesCompanion(
          clientId: Value(clientId),
          invoiceDate: Value(invoiceDate),
          discount: Value(discount),
          total: Value(total),
          note: Value(note),
          updatedAt: Value(now),
          rowVersion: Value(newVersion),
          syncStatus: Value(SyncStatus.PENDING),
        ),
      );

      final invoicePayload = jsonEncode({
        'id': id,
        'localRef': existing.localRef,
        'officialNo': existing.officialNo,
        'clientId': clientId,
        'invoiceDate': invoiceDate.toIso8601String(),
        'discount': discount,
        'total': total,
        'note': note,
        'status': existing.status.index,
        'voidReason': existing.voidReason,
        'createdAt': existing.createdAt.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'deviceId': deviceId,
        'rowVersion': newVersion,
        'syncStatus': SyncStatus.PENDING.index,
      });
      await _db
          .into(_db.syncOutbox)
          .insert(
            SyncOutboxCompanion.insert(
              id: _uuid.v4(),
              entityType: ParentEntityType.SALES_INVOICE,
              entityId: id,
              operation: AuditOperation.UPDATE,
              payload: invoicePayload,
              rowVersion: baseVersion,
              deviceId: deviceId,
              createdAt: now,
              status: Value(SyncOutboxStatus.PENDING),
            ),
          );
      await ReceiptRepository(_db).updateInvoiceLinkedPayments(
        invoiceId: id,
        paidAmount: paidAmount,
        deviceId: deviceId,
        previousClientId: existing.clientId,
      );
    });
  }

  Future<bool> _hasSameLines(
    String invoiceId,
    List<SalesInvoiceLinesCompanion> lines,
  ) async {
    final existing = await getLinesForInvoice(invoiceId);
    if (existing.length != lines.length) return false;
    final unmatched = existing
        .map(
          (line) => (
            line.productId,
            line.quantity,
            line.unitPrice,
            line.productionDate?.millisecondsSinceEpoch,
          ),
        )
        .toList();
    for (final line in lines) {
      final key = (
        line.productId.present ? line.productId.value : '',
        line.quantity.present ? line.quantity.value : 1,
        line.unitPrice.present ? line.unitPrice.value : 0,
        line.productionDate.present
            ? line.productionDate.value?.millisecondsSinceEpoch
            : null,
      );
      if (!unmatched.remove(key)) return false;
    }
    return true;
  }

  Future<void> updateNote(String id, String? note, String deviceId) async {
    final existing = await getById(id);

    if (existing.status == RecordStatus.VOIDED) {
      throw StateError('Cannot update a voided invoice');
    }

    final now = DateTime.now();
    final newVersion = existing.rowVersion + 1;

    await _db.transaction(() async {
      await (_db.update(
        _db.salesInvoices,
      )..where((t) => t.id.equals(id))).write(
        SalesInvoicesCompanion(
          note: Value(note),
          updatedAt: Value(now),
          rowVersion: Value(newVersion),
          syncStatus: Value(SyncStatus.PENDING),
        ),
      );

      final invoicePayload = jsonEncode({
        'id': id,
        'localRef': existing.localRef,
        'officialNo': existing.officialNo,
        'clientId': existing.clientId,
        'invoiceDate': existing.invoiceDate.toIso8601String(),
        'discount': existing.discount,
        'total': existing.total,
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
              entityType: ParentEntityType.SALES_INVOICE,
              entityId: id,
              operation: AuditOperation.UPDATE,
              payload: invoicePayload,
              rowVersion: existing.rowVersion,
              deviceId: deviceId,
              createdAt: now,
              status: Value(SyncOutboxStatus.PENDING),
            ),
          );
    });
  }

  Future<void> voidInvoice(String id, String reason, String deviceId) async {
    if (reason.trim().isEmpty) {
      throw ArgumentError('Void reason is required');
    }

    final existing = await getById(id);

    if (existing.status == RecordStatus.VOIDED) {
      throw StateError('Invoice is already voided');
    }

    final now = DateTime.now();
    final newVersion = existing.rowVersion + 1;

    await _db.transaction(() async {
      await (_db.update(
        _db.salesInvoices,
      )..where((t) => t.id.equals(id))).write(
        SalesInvoicesCompanion(
          status: Value(RecordStatus.VOIDED),
          voidReason: Value(reason),
          updatedAt: Value(now),
          rowVersion: Value(newVersion),
          syncStatus: Value(SyncStatus.PENDING),
        ),
      );

      final invoicePayload = jsonEncode({
        'id': id,
        'localRef': existing.localRef,
        'officialNo': existing.officialNo,
        'clientId': existing.clientId,
        'invoiceDate': existing.invoiceDate.toIso8601String(),
        'discount': existing.discount,
        'total': existing.total,
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
              entityType: ParentEntityType.SALES_INVOICE,
              entityId: id,
              operation: AuditOperation.UPDATE,
              payload: invoicePayload,
              rowVersion: existing.rowVersion,
              deviceId: deviceId,
              createdAt: now,
              status: Value(SyncOutboxStatus.PENDING),
            ),
          );

      await ReceiptRepository(_db).reconcileClientPayments(
        clientId: existing.clientId,
        deviceId: deviceId,
      );
    });
  }
}
