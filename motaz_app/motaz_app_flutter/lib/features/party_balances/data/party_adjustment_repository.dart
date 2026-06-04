import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/enums/audit_operation.dart';
import '../../../core/database/enums/parent_entity_type.dart';
import '../../../core/database/enums/party_account.dart';
import '../../../core/database/enums/record_status.dart';
import '../../../core/database/enums/sync_outbox_status.dart';
import '../../../core/database/enums/sync_status.dart';

class PartyAdjustmentRepository {
  PartyAdjustmentRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  Future<PartyAdjustment> getById(String id) {
    return (_db.select(
      _db.partyAdjustments,
    )..where((tbl) => tbl.id.equals(id))).getSingle();
  }

  Future<PartyAdjustment> create({
    required PartyAccount party,
    required int amount,
    required DateTime adjustmentDate,
    String? note,
    required String deviceId,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Amount must be positive');
    }

    final id = _uuid.v4();
    final now = DateTime.now();
    final cleanNote = note?.trim();

    final payload = jsonEncode({
      'id': id,
      'party': party.index,
      'amount': amount,
      'adjustmentDate': adjustmentDate.toIso8601String(),
      'note': cleanNote == null || cleanNote.isEmpty ? null : cleanNote,
      'status': RecordStatus.ACTIVE.index,
      'voidReason': null,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'deviceId': deviceId,
      'rowVersion': 1,
      'syncStatus': SyncStatus.PENDING.index,
    });

    await _db.transaction(() async {
      await _db
          .into(_db.partyAdjustments)
          .insert(
            PartyAdjustmentsCompanion(
              id: Value(id),
              party: Value(party),
              amount: Value(amount),
              adjustmentDate: Value(adjustmentDate),
              note: Value(
                cleanNote == null || cleanNote.isEmpty ? null : cleanNote,
              ),
              status: Value(RecordStatus.ACTIVE),
              voidReason: const Value.absent(),
              createdAt: Value(now),
              updatedAt: Value(now),
              deviceId: Value(deviceId),
              rowVersion: const Value(1),
              syncStatus: Value(SyncStatus.PENDING),
            ),
          );

      await _db
          .into(_db.syncOutbox)
          .insert(
            SyncOutboxCompanion.insert(
              id: _uuid.v4(),
              entityType: ParentEntityType.PARTY_ADJUSTMENT,
              entityId: id,
              operation: AuditOperation.CREATE,
              payload: payload,
              rowVersion: 1,
              deviceId: deviceId,
              createdAt: now,
              status: Value(SyncOutboxStatus.PENDING),
            ),
          );
    });

    return (_db.select(
      _db.partyAdjustments,
    )..where((tbl) => tbl.id.equals(id))).getSingle();
  }

  Future<void> update({
    required String id,
    required int amount,
    required DateTime adjustmentDate,
    String? note,
    required String deviceId,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Amount must be positive');
    }

    final existing = await getById(id);
    if (existing.status == RecordStatus.VOIDED) {
      throw StateError('Cannot update a deleted party adjustment');
    }

    final now = DateTime.now();
    final cleanNote = note?.trim();
    final newRowVersion = existing.rowVersion + 1;

    final payload = jsonEncode({
      'id': existing.id,
      'party': existing.party.index,
      'amount': amount,
      'adjustmentDate': adjustmentDate.toIso8601String(),
      'note': cleanNote == null || cleanNote.isEmpty ? null : cleanNote,
      'status': RecordStatus.ACTIVE.index,
      'voidReason': null,
      'createdAt': existing.createdAt.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'deviceId': existing.deviceId,
      'rowVersion': newRowVersion,
      'syncStatus': SyncStatus.PENDING.index,
    });

    await _db.transaction(() async {
      await (_db.update(
        _db.partyAdjustments,
      )..where((tbl) => tbl.id.equals(id))).write(
        PartyAdjustmentsCompanion(
          amount: Value(amount),
          adjustmentDate: Value(adjustmentDate),
          note: Value(
            cleanNote == null || cleanNote.isEmpty ? null : cleanNote,
          ),
          status: Value(RecordStatus.ACTIVE),
          voidReason: const Value<String?>(null),
          updatedAt: Value(now),
          rowVersion: Value(newRowVersion),
          syncStatus: Value(SyncStatus.PENDING),
        ),
      );

      await _db
          .into(_db.syncOutbox)
          .insert(
            SyncOutboxCompanion.insert(
              id: _uuid.v4(),
              entityType: ParentEntityType.PARTY_ADJUSTMENT,
              entityId: existing.id,
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

  Future<void> delete(String id, String deviceId) async {
    final existing = await getById(id);
    if (existing.status == RecordStatus.VOIDED) {
      return;
    }

    final now = DateTime.now();
    final newRowVersion = existing.rowVersion + 1;
    const voidReason = 'حذف يدوي';

    final payload = jsonEncode({
      'id': existing.id,
      'party': existing.party.index,
      'amount': existing.amount,
      'adjustmentDate': existing.adjustmentDate.toIso8601String(),
      'note': existing.note,
      'status': RecordStatus.VOIDED.index,
      'voidReason': voidReason,
      'createdAt': existing.createdAt.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'deviceId': existing.deviceId,
      'rowVersion': newRowVersion,
      'syncStatus': SyncStatus.PENDING.index,
    });

    await _db.transaction(() async {
      await (_db.update(
        _db.partyAdjustments,
      )..where((tbl) => tbl.id.equals(id))).write(
        PartyAdjustmentsCompanion(
          status: Value(RecordStatus.VOIDED),
          voidReason: const Value(voidReason),
          updatedAt: Value(now),
          rowVersion: Value(newRowVersion),
          syncStatus: Value(SyncStatus.PENDING),
        ),
      );

      await _db
          .into(_db.syncOutbox)
          .insert(
            SyncOutboxCompanion.insert(
              id: _uuid.v4(),
              entityType: ParentEntityType.PARTY_ADJUSTMENT,
              entityId: existing.id,
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
}
