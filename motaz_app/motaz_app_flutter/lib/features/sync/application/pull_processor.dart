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
