import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:motaz_app_client/motaz_app_client.dart' as server;
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart' hide Client;
import '../../../core/database/enums/enums.dart';

class PullProcessor {
  PullProcessor({
    required AppDatabase db,
    required server.Client serverClient,
  })  : _db = db,
        _serverClient = serverClient;
  final AppDatabase _db;
  final server.Client _serverClient;
  static const int _defaultLimit = 100;
  static final _uuid = const Uuid();

  Future<void> pullAllEntityTypes() async {
    for (final entityType in ParentEntityType.values) {
      await _pullForEntityType(entityType);
    }
  }

  Future<void> _pullForEntityType(ParentEntityType entityType) async {
    final device = await _db.select(_db.devices).getSingleOrNull();
    if (device == null) return;
    final currentCursor = await (_db.select(_db.syncCursor)
          ..where((t) => t.entityType.equals(entityType.index)))
        .getSingleOrNull();
    var sinceRowVersion = 0;
    if (currentCursor != null) {
      sinceRowVersion = currentCursor.lastRowVersion;
    }
    var hasMore = true;
    while (hasMore) {
      final request = server.PullRequest(
        entityType: entityType.name,
        sinceRowVersion: sinceRowVersion,
        deviceId: device.id,
        limit: _defaultLimit,
      );
      final response = await _serverClient.sync.pull(request);
      if (response.rows.isEmpty) {
        hasMore = false;
        break;
      }
      for (final rowJson in response.rows) {
        final row = jsonDecode(rowJson) as Map<String, dynamic>;
        await _upsertRow(entityType, row);
      }
      sinceRowVersion = response.latestRowVersion;
      hasMore = response.hasMore;
      await _upsertCursor(entityType, sinceRowVersion, currentCursor);
    }
  }

  Future<void> _upsertCursor(
    ParentEntityType entityType,
    int lastRowVersion,
    SyncCursorData? existingCursor,
  ) async {
    final now = DateTime.now();
    if (existingCursor == null) {
      await _db.into(_db.syncCursor).insert(
            SyncCursorCompanion.insert(
              id: _uuid.v4(),
              entityType: entityType,
              lastRowVersion: Value(lastRowVersion),
              lastPulledAt: Value(now),
              updatedAt: now,
            ),
          );
    } else {
      await (_db.update(_db.syncCursor)
            ..where((t) => t.id.equals(existingCursor.id)))
          .write(SyncCursorCompanion(
        lastRowVersion: Value(lastRowVersion),
        lastPulledAt: Value(now),
        updatedAt: Value(now),
      ));
    }
  }

  Future<void> _upsertRow(
    ParentEntityType entityType,
    Map<String, dynamic> row,
  ) async {
    final tableName = _entityTableName[entityType];
    if (tableName == null) return;
    final id = row['id'];
    if (id == null) return;
    final sqlValues = <String, dynamic>{};
    for (final entry in row.entries) {
      final snakeKey = _camelToSnake(entry.key);
      var value = entry.value;
      if (value is bool) {
        value = value ? 1 : 0;
      }
      sqlValues[snakeKey] = value;
    }
    sqlValues['sync_status'] = SyncStatus.SYNCED.index;
    final existing = await _db.customSelect(
      'SELECT id FROM "$tableName" WHERE id = ?',
      variables: [Variable.withString(id)],
    ).getSingleOrNull();
    if (existing == null) {
      final columns = sqlValues.keys.map((c) => '"$c"').join(', ');
      final placeholders = List.filled(sqlValues.length, '?').join(', ');
      await _db.customStatement(
        'INSERT INTO "$tableName" ($columns) VALUES ($placeholders)',
        sqlValues.values.toList(),
      );
    } else {
      final setClauses = sqlValues.entries
          .where((e) => e.key != 'id')
          .map((e) => '"${e.key}" = ?')
          .join(', ');
      final updateValues = sqlValues.entries
          .where((e) => e.key != 'id')
          .map((e) => e.value)
          .toList();
      await _db.customStatement(
        'UPDATE "$tableName" SET $setClauses WHERE "id" = ?',
        [...updateValues, id],
      );
    }
  }

  String _camelToSnake(String input) {
    return input.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
  }

  static const Map<ParentEntityType, String> _entityTableName = {
    ParentEntityType.PRODUCT: 'products',
    ParentEntityType.CLIENT: 'clients',
    ParentEntityType.SALES_INVOICE: 'sales_invoices',
    ParentEntityType.SALES_INVOICE_LINE: 'sales_invoice_lines',
    ParentEntityType.RECEIPT: 'receipts',
    ParentEntityType.RECEIPT_ALLOCATION: 'receipt_allocations',
    ParentEntityType.EXPENSE: 'expenses',
    ParentEntityType.SALES_RETURN: 'sales_returns',
    ParentEntityType.SALES_RETURN_LINE: 'sales_return_lines',
    ParentEntityType.ATTACHMENT_METADATA: 'attachment_metadata',
  };
}
