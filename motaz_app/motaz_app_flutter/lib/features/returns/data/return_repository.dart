import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/enums/audit_operation.dart';
import '../../../core/database/enums/parent_entity_type.dart';
import '../../../core/database/enums/record_status.dart';
import '../../../core/database/enums/sync_outbox_status.dart';
import '../../../core/database/enums/sync_status.dart';

class ReturnRepository {
  ReturnRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  Future<({String localRef, int sequence})> _nextReturnRef(
    String deviceId,
  ) async {
    final device = await (_db.select(
      _db.devices,
    )..where((t) => t.id.equals(deviceId))).getSingle();
    final sequence = device.nextReturnSequence;
    final localRef =
        'RET-${device.deviceCode}-${sequence.toString().padLeft(3, '0')}';
    return (localRef: localRef, sequence: sequence);
  }

  Future<SalesReturn> create({
    required String invoiceId,
    required DateTime returnDate,
    String? note,
    required List<
      ({String invoiceLineId, int returnedQuantity, int returnedAmount})
    >
    lines,
    required String deviceId,
  }) async {
    if (lines.isEmpty) {
      throw ArgumentError('Return must have at least one line');
    }

    for (final line in lines) {
      if (line.returnedQuantity <= 0) {
        throw ArgumentError('Returned quantity must be positive');
      }
      if (line.returnedAmount <= 0) {
        throw ArgumentError('Returned amount must be positive');
      }
    }

    final invoice = await (_db.select(
      _db.salesInvoices,
    )..where((t) => t.id.equals(invoiceId))).getSingleOrNull();

    if (invoice == null) {
      throw StateError('Invoice not found');
    }

    if (invoice.status != RecordStatus.ACTIVE) {
      throw StateError('Invoice must be active to create a return');
    }

    final invoiceLines = await (_db.select(
      _db.salesInvoiceLines,
    )..where((t) => t.invoiceId.equals(invoiceId))).get();

    final invoiceLineMap = {for (var line in invoiceLines) line.id: line};

    for (final line in lines) {
      final invoiceLine = invoiceLineMap[line.invoiceLineId];
      if (invoiceLine == null) {
        throw StateError('Invoice line not found: ${line.invoiceLineId}');
      }

      final alreadyReturned = await getReturnedQuantityForInvoiceLine(
        line.invoiceLineId,
      );
      final availableQuantity = invoiceLine.quantity - alreadyReturned;

      if (line.returnedQuantity > availableQuantity) {
        throw StateError('Returned quantity exceeds available quantity');
      }

      final maxAmount = line.returnedQuantity * invoiceLine.unitPrice;
      if (line.returnedAmount > maxAmount) {
        throw StateError('Returned amount exceeds maximum allowed');
      }
    }

    final totalReturnedAmount = lines.fold<int>(
      0,
      (sum, line) => sum + line.returnedAmount,
    );

    final existingReturnTotal = await getActiveReturnTotalForInvoice(invoiceId);
    if (existingReturnTotal + totalReturnedAmount > invoice.total) {
      throw StateError('Cumulative return total exceeds invoice total');
    }

    final returnId = _uuid.v4();
    final ref = await _nextReturnRef(deviceId);
    final now = DateTime.now();

    await _db.transaction(() async {
      await _db
          .into(_db.salesReturns)
          .insert(
            SalesReturnsCompanion(
              id: Value(returnId),
              localRef: Value(ref.localRef),
              invoiceId: Value(invoiceId),
              returnDate: Value(returnDate),
              totalReturnedAmount: Value(totalReturnedAmount),
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

      for (final line in lines) {
        final lineId = _uuid.v4();
        await _db
            .into(_db.salesReturnLines)
            .insert(
              SalesReturnLinesCompanion(
                id: Value(lineId),
                returnId: Value(returnId),
                invoiceLineId: Value(line.invoiceLineId),
                returnedQuantity: Value(line.returnedQuantity),
                returnedAmount: Value(line.returnedAmount),
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );

        final linePayload = jsonEncode({
          'id': lineId,
          'returnId': returnId,
          'invoiceLineId': line.invoiceLineId,
          'returnedQuantity': line.returnedQuantity,
          'returnedAmount': line.returnedAmount,
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        });

        await _db
            .into(_db.syncOutbox)
            .insert(
              SyncOutboxCompanion.insert(
                id: _uuid.v4(),
                entityType: ParentEntityType.SALES_RETURN_LINE,
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

      final headerPayload = jsonEncode({
        'id': returnId,
        'localRef': ref.localRef,
        'invoiceId': invoiceId,
        'returnDate': returnDate.toIso8601String(),
        'totalReturnedAmount': totalReturnedAmount,
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
              entityType: ParentEntityType.SALES_RETURN,
              entityId: returnId,
              operation: AuditOperation.CREATE,
              payload: headerPayload,
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
          nextReturnSequence: Value(ref.sequence + 1),
        ),
      );
    });

    return await getById(returnId);
  }

  Future<void> voidReturn(String id, String reason, String deviceId) async {
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      throw ArgumentError('Void reason is required');
    }

    final existing = await getById(id);

    if (existing.status != RecordStatus.ACTIVE) {
      throw StateError('Return is already voided');
    }

    final now = DateTime.now();
    final newVersion = existing.rowVersion + 1;

    final payload = jsonEncode({
      'id': id,
      'localRef': existing.localRef,
      'invoiceId': existing.invoiceId,
      'returnDate': existing.returnDate.toIso8601String(),
      'totalReturnedAmount': existing.totalReturnedAmount,
      'note': existing.note,
      'status': RecordStatus.VOIDED.index,
      'voidReason': trimmedReason,
      'createdAt': existing.createdAt.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'deviceId': existing.deviceId,
      'rowVersion': newVersion,
      'syncStatus': SyncStatus.PENDING.index,
    });

    await _db.transaction(() async {
      await (_db.update(_db.salesReturns)..where((t) => t.id.equals(id))).write(
        SalesReturnsCompanion(
          status: Value(RecordStatus.VOIDED),
          voidReason: Value(trimmedReason),
          updatedAt: Value(now),
          rowVersion: Value(newVersion),
          syncStatus: Value(SyncStatus.PENDING),
        ),
      );

      await _db
          .into(_db.syncOutbox)
          .insert(
            SyncOutboxCompanion.insert(
              id: _uuid.v4(),
              entityType: ParentEntityType.SALES_RETURN,
              entityId: id,
              operation: AuditOperation.UPDATE,
              payload: payload,
              rowVersion: existing.rowVersion,
              deviceId: deviceId,
              createdAt: now,
              status: Value(SyncOutboxStatus.PENDING),
            ),
          );
    });
  }

  Future<SalesReturn> getById(String id) async {
    final result = await (_db.select(
      _db.salesReturns,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    if (result == null) {
      throw StateError('Return not found: $id');
    }

    return result;
  }

  Stream<List<SalesReturn>> watchAll() {
    return (_db.select(_db.salesReturns)..orderBy([
          (t) => OrderingTerm.desc(t.returnDate),
          (t) => OrderingTerm.desc(t.createdAt),
        ]))
        .watch();
  }

  Stream<List<SalesReturn>> searchByText(String query) {
    final q = query.trim().toLowerCase();
    final returnStream =
        (_db.select(_db.salesReturns)..orderBy([
              (t) => OrderingTerm.desc(t.returnDate),
              (t) => OrderingTerm.desc(t.createdAt),
            ]))
            .watch();

    return returnStream.map((returns) {
      if (q.isEmpty) return returns;

      return returns.where((r) {
        if (r.note != null && r.note!.toLowerCase().contains(q)) return true;
        return false;
      }).toList();
    });
  }

  Future<List<SalesReturnLine>> getReturnLinesForReturn(String returnId) async {
    return await (_db.select(
      _db.salesReturnLines,
    )..where((t) => t.returnId.equals(returnId))).get();
  }

  Future<int> getActiveReturnTotalForInvoice(String invoiceId) async {
    final result =
        await (_db.selectOnly(_db.salesReturns)
              ..addColumns([_db.salesReturns.totalReturnedAmount.sum()])
              ..where(
                _db.salesReturns.invoiceId.equals(invoiceId) &
                    _db.salesReturns.status.equals(RecordStatus.ACTIVE.index),
              ))
            .getSingle();

    return result.read(_db.salesReturns.totalReturnedAmount.sum()) ?? 0;
  }

  Future<int> getReturnedQuantityForInvoiceLine(String invoiceLineId) async {
    final query = _db.selectOnly(_db.salesReturnLines)
      ..addColumns([_db.salesReturnLines.returnedQuantity.sum()])
      ..join([
        innerJoin(
          _db.salesReturns,
          _db.salesReturns.id.equalsExp(_db.salesReturnLines.returnId),
        ),
      ])
      ..where(
        _db.salesReturnLines.invoiceLineId.equals(invoiceLineId) &
            _db.salesReturns.status.equals(RecordStatus.ACTIVE.index),
      );

    final result = await query.getSingle();
    return result.read(_db.salesReturnLines.returnedQuantity.sum()) ?? 0;
  }

  Future<bool> hasActiveReturnsForInvoice(String invoiceId) async {
    final count =
        await (_db.select(_db.salesReturns)..where(
              (t) =>
                  t.invoiceId.equals(invoiceId) &
                  t.status.equals(RecordStatus.ACTIVE.index),
            ))
            .get()
            .then((list) => list.length);

    return count > 0;
  }
}
