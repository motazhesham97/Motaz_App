import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/enums/audit_operation.dart';
import '../../../core/database/enums/parent_entity_type.dart';
import '../../../core/database/enums/sync_outbox_status.dart';
import '../../../core/database/enums/sync_status.dart';

class BeneficiaryRepository {
  BeneficiaryRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  Stream<List<Beneficiary>> watchAll() {
    return (_db.select(_db.beneficiaries)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.displayName)]))
        .watch();
  }

  Future<List<Beneficiary>> search(String query) async {
    final text = query.trim().toLowerCase();
    if (text.isEmpty) return const [];
    final rows =
        await (_db.select(_db.beneficiaries)
              ..where((t) => t.isActive.equals(true))
              ..orderBy([(t) => OrderingTerm.asc(t.displayName)]))
            .get();
    return rows
        .where((row) => _matchesWordPrefix(row.displayName, text))
        .take(12)
        .toList();
  }

  Future<Beneficiary> createAndReturn({
    required String displayName,
    required String deviceId,
    String? phone,
  }) async {
    final existing = await findByName(displayName);
    if (existing != null) return existing;

    final id = _uuid.v4();
    final now = DateTime.now();
    final companion = BeneficiariesCompanion.insert(
      id: id,
      displayName: displayName.trim(),
      phone: Value(phone?.trim().isEmpty == true ? null : phone?.trim()),
      sourceClientId: const Value(null),
      isActive: const Value(true),
      createdAt: now,
      updatedAt: now,
      deviceId: deviceId,
      rowVersion: const Value(1),
      syncStatus: SyncStatus.PENDING,
    );

    await _db.transaction(() async {
      await _db.into(_db.beneficiaries).insert(companion);
      await _enqueue(
        id: id,
        operation: AuditOperation.CREATE,
        payload: _payload(
          id: id,
          displayName: displayName.trim(),
          phone: phone,
          sourceClientId: null,
          isActive: true,
          createdAt: now,
          updatedAt: now,
          deviceId: deviceId,
          rowVersion: 1,
          syncStatus: SyncStatus.PENDING,
        ),
        rowVersion: 1,
        deviceId: deviceId,
        createdAt: now,
      );
    });

    return getById(id);
  }

  Future<Beneficiary?> findByName(String displayName) {
    final normalized = displayName.trim().toLowerCase();
    return (_db.select(
      _db.beneficiaries,
    )..where((t) => t.isActive.equals(true))).get().then(
      (rows) => rows.cast<Beneficiary?>().firstWhere(
        (row) => row?.displayName.trim().toLowerCase() == normalized,
        orElse: () => null,
      ),
    );
  }

  Future<Beneficiary> getById(String id) {
    return (_db.select(
      _db.beneficiaries,
    )..where((t) => t.id.equals(id))).getSingle();
  }

  Future<void> ensureClientsMirrored(String deviceId) async {
    final clients = await (_db.select(
      _db.clients,
    )..where((t) => t.isActive.equals(true))).get();
    final now = DateTime.now();

    for (final client in clients) {
      final existing =
          await (_db.select(_db.beneficiaries)
                ..where((t) => t.sourceClientId.equals(client.id))
                ..limit(1))
              .getSingleOrNull();
      if (existing == null) {
        await _db.transaction(() async {
          await _db
              .into(_db.beneficiaries)
              .insert(
                BeneficiariesCompanion.insert(
                  id: client.id,
                  displayName: client.displayName,
                  phone: Value(client.phone),
                  sourceClientId: Value(client.id),
                  isActive: Value(client.isActive),
                  createdAt: client.createdAt,
                  updatedAt: now,
                  deviceId: deviceId,
                  rowVersion: const Value(1),
                  syncStatus: SyncStatus.PENDING,
                ),
              );
          await _enqueue(
            id: client.id,
            operation: AuditOperation.CREATE,
            payload: _payload(
              id: client.id,
              displayName: client.displayName,
              phone: client.phone,
              sourceClientId: client.id,
              isActive: client.isActive,
              createdAt: client.createdAt,
              updatedAt: now,
              deviceId: deviceId,
              rowVersion: 1,
              syncStatus: SyncStatus.PENDING,
            ),
            rowVersion: 1,
            deviceId: deviceId,
            createdAt: now,
          );
        });
      }
    }
  }

  bool _matchesWordPrefix(String value, String query) {
    return value
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .any((word) => word.startsWith(query));
  }

  Future<void> _enqueue({
    required String id,
    required AuditOperation operation,
    required String payload,
    required int rowVersion,
    required String deviceId,
    required DateTime createdAt,
  }) async {
    await _db
        .into(_db.syncOutbox)
        .insert(
          SyncOutboxCompanion.insert(
            id: _uuid.v4(),
            entityType: ParentEntityType.BENEFICIARY,
            entityId: id,
            operation: operation,
            payload: payload,
            rowVersion: rowVersion,
            deviceId: deviceId,
            createdAt: createdAt,
            status: Value(SyncOutboxStatus.PENDING),
          ),
        );
  }

  String _payload({
    required String id,
    required String displayName,
    required String? phone,
    required String? sourceClientId,
    required bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String deviceId,
    required int rowVersion,
    required SyncStatus syncStatus,
  }) {
    return jsonEncode({
      'id': id,
      'displayName': displayName,
      'phone': phone,
      'sourceClientId': sourceClientId,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deviceId': deviceId,
      'rowVersion': rowVersion,
      'syncStatus': syncStatus.index,
    });
  }
}
