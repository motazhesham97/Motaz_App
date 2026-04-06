import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/enums/audit_operation.dart';
import '../../../core/database/enums/parent_entity_type.dart';
import '../../../core/database/enums/sync_outbox_status.dart';
import '../../../core/database/enums/sync_status.dart';

class ClientRepository {
  ClientRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  Future<void> create(ClientsCompanion client) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final row = client.copyWith(
      id: Value(id),
      createdAt: Value(now),
      updatedAt: Value(now),
      rowVersion: const Value(1),
      syncStatus: Value(SyncStatus.PENDING),
    );

    final payload = jsonEncode({
      'id': id,
      'displayName': row.displayName.value,
      'phone': row.phone.present ? row.phone.value : null,
      'email': row.email.present ? row.email.value : null,
      'address': row.address.present ? row.address.value : null,
      'note': row.note.present ? row.note.value : null,
      'clientCode': row.clientCode.present ? row.clientCode.value : null,
      'isActive': row.isActive.present ? row.isActive.value : true,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'deviceId': row.deviceId.value,
      'rowVersion': 1,
      'syncStatus': 0,
    });

    await _db.transaction(() async {
      await _db.into(_db.clients).insert(row);
      await _db.into(_db.syncOutbox).insert(
        SyncOutboxCompanion.insert(
          id: _uuid.v4(),
          entityType: ParentEntityType.CLIENT,
          entityId: id,
          operation: AuditOperation.CREATE,
          payload: payload,
          rowVersion: 1,
          deviceId: row.deviceId.value,
          createdAt: now,
          status: Value(SyncOutboxStatus.PENDING),
        ),
      );
    });
  }

  Future<Client> getById(String id) async {
    return (_db.select(_db.clients)..where((t) => t.id.equals(id)))
        .getSingle();
  }

  Stream<List<Client>> watchAll() {
    return (_db.select(_db.clients)
          ..orderBy([(t) => OrderingTerm.asc(t.displayName)]))
        .watch();
  }

  Future<void> update(String id, ClientsCompanion updated) async {
    final existing = await getById(id);
    final now = DateTime.now();
    final newVersion = existing.rowVersion + 1;

    final displayName = updated.displayName.present ? updated.displayName.value : existing.displayName;
    final phone = updated.phone.present ? updated.phone.value : existing.phone;
    final email = updated.email.present ? updated.email.value : existing.email;
    final address = updated.address.present ? updated.address.value : existing.address;
    final note = updated.note.present ? updated.note.value : existing.note;
    final clientCode = updated.clientCode.present ? updated.clientCode.value : existing.clientCode;
    final isActive = updated.isActive.present ? updated.isActive.value : existing.isActive;
    final deviceId = updated.deviceId.present ? updated.deviceId.value : existing.deviceId;

    final payload = jsonEncode({
      'id': id,
      'displayName': displayName,
      'phone': phone,
      'email': email,
      'address': address,
      'note': note,
      'clientCode': clientCode,
      'isActive': isActive,
      'deviceId': deviceId,
      'rowVersion': newVersion,
      'updatedAt': now.toIso8601String(),
    });

    await _db.transaction(() async {
      await (_db.update(_db.clients)..where((t) => t.id.equals(id))).write(
        ClientsCompanion(
          displayName: Value(displayName),
          phone: Value(phone),
          email: Value(email),
          address: Value(address),
          note: Value(note),
          clientCode: Value(clientCode),
          isActive: Value(isActive),
          deviceId: Value(deviceId),
          updatedAt: Value(now),
          rowVersion: Value(newVersion),
          syncStatus: Value(SyncStatus.PENDING),
        ),
      );
      await _db.into(_db.syncOutbox).insert(
        SyncOutboxCompanion.insert(
          id: _uuid.v4(),
          entityType: ParentEntityType.CLIENT,
          entityId: id,
          operation: AuditOperation.UPDATE,
          payload: payload,
          rowVersion: newVersion,
          deviceId: deviceId,
          createdAt: now,
          status: Value(SyncOutboxStatus.PENDING),
        ),
      );
    });
  }

  Future<int> getOutstandingBalance(String clientId) async {
    try {
      final invoiceSum = await _db.customSelect(
        'SELECT COALESCE(SUM(total), 0) AS total FROM sales_invoices WHERE clientId = ? AND status != 2',
        variables: [Variable(clientId)],
      ).getSingle();

      final receiptSum = await _db.customSelect(
        'SELECT COALESCE(SUM(amount), 0) AS total FROM receipts WHERE clientId = ? AND status != 2',
        variables: [Variable(clientId)],
      ).getSingle();

      return invoiceSum.read<int>('total') - receiptSum.read<int>('total');
    } catch (e) {
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getRecentTransactions(
    String clientId, {
    int limit = 20,
  }) async {
    try {
      final transactions = <Map<String, dynamic>>[];

      final invoices = await (_db.select(_db.salesInvoices)
            ..where((t) => t.clientId.equals(clientId) & t.status.equals(0))
            ..orderBy([(t) => OrderingTerm.desc(t.invoiceDate)]))
          .get();

      for (final invoice in invoices) {
        transactions.add({
          'type': 'INVOICE',
          'date': invoice.invoiceDate,
          'amount': invoice.total,
          'status': invoice.status,
        });
      }

      final receipts = await (_db.select(_db.receipts)
            ..where((t) => t.clientId.equals(clientId) & t.status.equals(0))
            ..orderBy([(t) => OrderingTerm.desc(t.receiptDate)]))
          .get();

      for (final receipt in receipts) {
        transactions.add({
          'type': 'RECEIPT',
          'date': receipt.receiptDate,
          'amount': receipt.amount,
          'status': receipt.status,
        });
      }

      transactions.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

      return transactions.take(limit).toList();
    } catch (e) {
      return [];
    }
  }
}
