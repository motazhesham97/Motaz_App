import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/enums/audit_operation.dart';
import '../../../core/database/enums/parent_entity_type.dart';
import '../../../core/database/enums/sync_outbox_status.dart';
import '../../../core/database/enums/sync_status.dart';

class ProductRepository {
  ProductRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  Future<void> create(ProductsCompanion product) async {
    await createAndReturn(product);
  }

  Future<Product> createAndReturn(ProductsCompanion product) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final row = product.copyWith(
      id: Value(id),
      createdAt: Value(now),
      updatedAt: Value(now),
      rowVersion: const Value(1),
      syncStatus: Value(SyncStatus.PENDING),
    );

    final payload = jsonEncode({
      'id': id,
      'name': row.name.value,
      'description': row.description.present ? row.description.value : null,
      'defaultSalePrice': row.defaultSalePrice.value,
      'unit': row.unit.present ? row.unit.value : null,
      'sku': row.sku.present ? row.sku.value : null,
      'shelfLifeDays': row.shelfLifeDays.present
          ? row.shelfLifeDays.value
          : null,
      'isActive': row.isActive.present ? row.isActive.value : true,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'deviceId': row.deviceId.value,
      'rowVersion': 1,
      'syncStatus': 0,
    });

    await _db.transaction(() async {
      await _db.into(_db.products).insert(row);
      await _db
          .into(_db.syncOutbox)
          .insert(
            SyncOutboxCompanion.insert(
              id: _uuid.v4(),
              entityType: ParentEntityType.PRODUCT,
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

    return await getById(id);
  }

  Future<Product> getById(String id) async {
    return (_db.select(
      _db.products,
    )..where((t) => t.id.equals(id))).getSingle();
  }

  Future<bool> isNameTaken(String name, {String? excludeId}) async {
    final lowerName = name.toLowerCase();
    var sql = 'SELECT COUNT(*) AS cnt FROM products WHERE LOWER(name) = ?';
    final vars = <Variable>[Variable(lowerName)];
    if (excludeId != null) {
      sql += ' AND id != ?';
      vars.add(Variable(excludeId));
    }
    final row = await _db.customSelect(sql, variables: vars).getSingle();
    return row.read<int>('cnt') > 0;
  }

  Future<void> update(String id, ProductsCompanion updated) async {
    final existing = await getById(id);
    final now = DateTime.now();
    final newVersion = existing.rowVersion + 1;

    updated = updated.copyWith(
      updatedAt: Value(now),
      rowVersion: Value(newVersion),
      syncStatus: Value(SyncStatus.PENDING),
    );

    final name = updated.name.present ? updated.name.value : existing.name;
    final description = updated.description.present
        ? updated.description.value
        : existing.description;
    final defaultSalePrice = updated.defaultSalePrice.present
        ? updated.defaultSalePrice.value
        : existing.defaultSalePrice;
    final unit = updated.unit.present ? updated.unit.value : existing.unit;
    final sku = updated.sku.present ? updated.sku.value : existing.sku;
    final shelfLifeDays = updated.shelfLifeDays.present
        ? updated.shelfLifeDays.value
        : existing.shelfLifeDays;
    final isActive = updated.isActive.present
        ? updated.isActive.value
        : existing.isActive;
    final deviceId = updated.deviceId.present
        ? updated.deviceId.value
        : existing.deviceId;

    final payload = jsonEncode({
      'id': id,
      'name': name,
      'description': description,
      'defaultSalePrice': defaultSalePrice,
      'unit': unit,
      'sku': sku,
      'shelfLifeDays': shelfLifeDays,
      'isActive': isActive,
      'deviceId': deviceId,
      'rowVersion': newVersion,
      'updatedAt': now.toIso8601String(),
    });

    await _db.transaction(() async {
      await (_db.update(
        _db.products,
      )..where((t) => t.id.equals(id))).write(updated);
      await _db
          .into(_db.syncOutbox)
          .insert(
            SyncOutboxCompanion.insert(
              id: _uuid.v4(),
              entityType: ParentEntityType.PRODUCT,
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

  Future<void> toggleActive(String id, bool isActive) async {
    final existing = await getById(id);
    final now = DateTime.now();
    final newVersion = existing.rowVersion + 1;

    final payload = jsonEncode({
      'id': id,
      'name': existing.name,
      'description': existing.description,
      'defaultSalePrice': existing.defaultSalePrice,
      'unit': existing.unit,
      'sku': existing.sku,
      'shelfLifeDays': existing.shelfLifeDays,
      'isActive': isActive,
      'deviceId': existing.deviceId,
      'rowVersion': newVersion,
      'updatedAt': now.toIso8601String(),
    });

    await _db.transaction(() async {
      await (_db.update(_db.products)..where((t) => t.id.equals(id))).write(
        ProductsCompanion(
          isActive: Value(isActive),
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
              entityType: ParentEntityType.PRODUCT,
              entityId: id,
              operation: AuditOperation.UPDATE,
              payload: payload,
              rowVersion: existing.rowVersion,
              deviceId: existing.deviceId,
              createdAt: now,
              status: Value(SyncOutboxStatus.PENDING),
            ),
          );
    });
  }
}
