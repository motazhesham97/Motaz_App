import 'dart:convert';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motaz_app_client/motaz_app_client.dart' as server;
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart' hide Client;
import '../../../core/database/database_provider.dart';
import '../../../core/database/enums/enums.dart';
import '../../../core/server/server_client_provider.dart';
import '../application/sync_providers.dart';

final _pendingConflictsProvider = StreamProvider<List<ConflictLog>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final query = db.select(db.conflictLogs)
    ..where((t) => t.resolutionStatus.equals(ConflictStatus.PENDING.index))
    ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
  return query.watch();
});

class ConflictResolutionScreen extends ConsumerStatefulWidget {
  const ConflictResolutionScreen({super.key});

  @override
  ConsumerState<ConflictResolutionScreen> createState() =>
      _ConflictResolutionScreenState();
}

class _ConflictResolutionScreenState
    extends ConsumerState<ConflictResolutionScreen> {
  ConflictLog? _selectedConflict;
  bool _resolving = false;
  bool _refreshing = false;

  @override
  Widget build(BuildContext context) {
    final conflictsAsync = ref.watch(_pendingConflictsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('حل التعارضات'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: _refreshing ? null : _refreshFromServer,
            icon: _refreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: conflictsAsync.when(
        data: (conflicts) {
          if (_selectedConflict != null) {
            ConflictLog? stillPending;
            for (final conflict in conflicts) {
              if (conflict.id == _selectedConflict!.id) {
                stillPending = conflict;
                break;
              }
            }
            if (stillPending != null) {
              return _buildDetail(context, stillPending);
            }
            _selectedConflict = null;
          }

          if (conflicts.isEmpty) {
            return const Center(
              child: Text('لا توجد تعارضات معلقة'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: conflicts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final conflict = conflicts[index];
              final localPayload = _decodePayload(conflict.localPayload);
              final remotePayload = _decodePayload(conflict.remotePayload);
              final titlePayload = localPayload['_missingLocally'] == true
                  ? remotePayload
                  : localPayload;
              return Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                  ),
                  title: Text(
                    _documentTitle(conflict.entityType, titlePayload),
                  ),
                  subtitle: Text(
                    '${_entityTypeLabel(conflict.entityType)} - ${_formatDateTime(conflict.createdAt)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    setState(() => _selectedConflict = conflict);
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('خطأ: $error')),
      ),
    );
  }

  Future<void> _refreshFromServer() async {
    setState(() => _refreshing = true);
    try {
      await ref.read(syncCoordinatorProvider).syncNow();
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  Widget _buildDetail(BuildContext context, ConflictLog conflict) {
    final db = ref.read(appDatabaseProvider);
    final localPayload = _decodePayload(conflict.localPayload);
    final remotePayload = _decodePayload(conflict.remotePayload);
    final titlePayload = localPayload['_missingLocally'] == true
        ? remotePayload
        : localPayload;
    final isMissingLocally = localPayload['_missingLocally'] == true;
    final differences = _diffRows(localPayload, remotePayload);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'رجوع',
              onPressed: () => setState(() => _selectedConflict = null),
              icon: const Icon(Icons.arrow_back),
            ),
            Expanded(
              child: Text(
                _documentTitle(conflict.entityType, titlePayload),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'تم تعديل نفس ${_entityTypeLabel(conflict.entityType)} من أكثر من جهاز. اختر النسخة التي تريد اعتمادها، وسيتم نشر القرار على باقي الأجهزة في المزامنة التالية.',
        ),
        if (isMissingLocally) ...[
          const SizedBox(height: 8),
          const Text(
            'هذا السجل موجود في نيون وغير موجود في النسخة المستوردة. يمكنك اعتماد نسخة السيرفر لإرجاعه محليا. اعتماد الحذف المحلي يحتاج نظام حذف أو أرشفة مستقل.',
          ),
        ],
        const SizedBox(height: 16),
        FutureBuilder<_VersionInfo>(
          future: _versionInfo(db, localPayload, 'التعديل الجديد'),
          builder: (context, snapshot) {
            return _buildVersionCard(
              context,
              title: 'التعديل الجديد',
              info: snapshot.data,
              payload: localPayload,
              differences: differences,
              color: Colors.blue,
            );
          },
        ),
        const SizedBox(height: 12),
        FutureBuilder<_VersionInfo>(
          future: _versionInfo(db, remotePayload, 'نسخة السيرفر الحالية'),
          builder: (context, snapshot) {
            return _buildVersionCard(
              context,
              title: 'نسخة السيرفر الحالية',
              info: snapshot.data,
              payload: remotePayload,
              differences: differences,
              color: Colors.green,
            );
          },
        ),
        const SizedBox(height: 18),
        if (differences.isNotEmpty) _buildDifferenceList(differences),
        const SizedBox(height: 24),
        if (_resolving)
          const Center(child: CircularProgressIndicator())
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: isMissingLocally
                    ? null
                    : () => _confirmAndResolve(
                        context,
                        conflict,
                        chosenVersion: 'local',
                        label: 'التعديل الجديد',
                      ),
                icon: const Icon(Icons.edit_note),
                label: const Text('اعتماد التعديل الجديد'),
              ),
              OutlinedButton.icon(
                onPressed: () => _confirmAndResolve(
                  context,
                  conflict,
                  chosenVersion: 'remote',
                  label: 'نسخة السيرفر الحالية',
                ),
                icon: const Icon(Icons.cloud_done_outlined),
                label: const Text('اعتماد نسخة السيرفر الحالية'),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildVersionCard(
    BuildContext context, {
    required String title,
    required _VersionInfo? info,
    required Map<String, dynamic> payload,
    required List<_FieldDifference> differences,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.devices, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$title - ${info?.deviceName ?? 'جهاز غير معروف'}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (info?.timestamp != null) ...[
              const SizedBox(height: 4),
              Text('وقت التعديل: ${_formatDateTime(info!.timestamp!)}'),
            ],
            const Divider(height: 20),
            if (differences.isEmpty)
              const Text('لا توجد فروقات واضحة في الحقول المعروضة.')
            else
              ...differences.map((difference) {
                final value = payload[difference.key];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _fieldLabel(difference.key),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: SelectableText(_displayValue(value)),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildDifferenceList(List<_FieldDifference> differences) {
    return Card(
      color: Colors.orange.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الفروقات',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...differences.map(
              (difference) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${_fieldLabel(difference.key)}: ${_displayValue(difference.localValue)} ↔ ${_displayValue(difference.remoteValue)}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<_VersionInfo> _versionInfo(
    AppDatabase db,
    Map<String, dynamic> payload,
    String fallbackDeviceName,
  ) async {
    final deviceId = payload['deviceId'] ?? payload['device_id'];
    Device? device;
    if (deviceId is String) {
      device = await (db.select(
        db.devices,
      )..where((tbl) => tbl.id.equals(deviceId))).getSingleOrNull();
    }
    return _VersionInfo(
      deviceName: device?.deviceName ?? fallbackDeviceName,
      timestamp: _payloadTimestamp(payload),
    );
  }

  Future<void> _confirmAndResolve(
    BuildContext context,
    ConflictLog conflict, {
    required String chosenVersion,
    required String label,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد حل التعارض'),
        content: Text('هل تريد اعتماد "$label"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('اعتماد'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await _resolveConflict(context, conflict, chosenVersion);
    }
  }

  Future<void> _resolveConflict(
    BuildContext context,
    ConflictLog conflict,
    String chosenVersion,
  ) async {
    setState(() => _resolving = true);
    try {
      if (_isRestorePullConflict(conflict)) {
        await _resolveRestorePullConflict(conflict, chosenVersion);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حل التعارض بنجاح')),
        );
        setState(() => _selectedConflict = null);
        return;
      }

      final serverClient = ref.read(serverpodClientProvider);
      final response = await serverClient.sync.resolveConflict(
        server.ConflictResolutionRequest(
          conflictId: conflict.id,
          chosenVersion: chosenVersion,
        ),
      );

      if (!context.mounted) return;

      if (!response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'فشل حل التعارض: ${response.errorMessage ?? 'خطأ غير معروف'}',
            ),
          ),
        );
        return;
      }

      final db = ref.read(appDatabaseProvider);
      await _applyResolvedPayloadLocally(
        db,
        conflict,
        chosenVersion,
        response.newRowVersion,
      );
      await (db.update(
        db.conflictLogs,
      )..where((tbl) => tbl.id.equals(conflict.id))).write(
        ConflictLogsCompanion(
          resolutionStatus: Value(ConflictStatus.RESOLVED),
          resolvedAt: Value(DateTime.now()),
          resolutionData: Value(chosenVersion),
        ),
      );
      ref.invalidate(_pendingConflictsProvider);
      ref.invalidate(syncStateProvider);
      await ref.read(syncCoordinatorProvider).syncNow();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حل التعارض بنجاح')),
      );
      setState(() => _selectedConflict = null);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _resolving = false);
      }
    }
  }

  bool _isRestorePullConflict(ConflictLog conflict) {
    return conflict.conflictType == 'RESTORE_PULL_CONFLICT';
  }

  Future<void> _resolveRestorePullConflict(
    ConflictLog conflict,
    String chosenVersion,
  ) async {
    final db = ref.read(appDatabaseProvider);
    if (chosenVersion == 'remote') {
      await _applyResolvedPayloadLocally(
        db,
        conflict,
        chosenVersion,
        _rowVersionFromPayload(_decodePayload(conflict.remotePayload)),
      );
    } else {
      final localPayload = _decodePayload(conflict.localPayload);
      if (localPayload['_missingLocally'] == true) {
        throw StateError(
          'لا يمكن اعتماد الحذف المحلي قبل إضافة نظام حذف أو أرشفة متزامن.',
        );
      }
      await _enqueueLocalRestoreChoice(db, conflict, localPayload);
    }

    await (db.update(
      db.conflictLogs,
    )..where((tbl) => tbl.id.equals(conflict.id))).write(
      ConflictLogsCompanion(
        resolutionStatus: Value(ConflictStatus.RESOLVED),
        resolvedAt: Value(DateTime.now()),
        resolutionData: Value(chosenVersion),
      ),
    );

    ref.invalidate(_pendingConflictsProvider);
    ref.invalidate(syncStateProvider);
    if (chosenVersion == 'local') {
      await ref.read(syncCoordinatorProvider).syncNow();
    }
  }

  Future<void> _enqueueLocalRestoreChoice(
    AppDatabase db,
    ConflictLog conflict,
    Map<String, dynamic> localPayload,
  ) async {
    final tableName = _entityTableName[conflict.entityType];
    if (tableName == null) return;
    final remotePayload = _decodePayload(conflict.remotePayload);
    final rowVersion = _rowVersionFromPayload(remotePayload) ?? 1;
    final now = DateTime.now();
    await db
        .into(db.syncOutbox)
        .insert(
          SyncOutboxCompanion.insert(
            id: const Uuid().v4(),
            entityType: conflict.entityType,
            entityId: conflict.entityId,
            operation: AuditOperation.UPDATE,
            payload: jsonEncode(localPayload),
            rowVersion: rowVersion,
            deviceId: conflict.deviceId,
            createdAt: now,
            status: Value(SyncOutboxStatus.PENDING),
          ),
        );
    await db.customStatement(
      'UPDATE "$tableName" SET sync_status = ? WHERE id = ?',
      [SyncStatus.PENDING.index, conflict.entityId],
    );
    db.notifyUpdates({TableUpdate(tableName, kind: UpdateKind.update)});
  }

  int? _rowVersionFromPayload(Map<String, dynamic> payload) {
    final value = payload['rowVersion'] ?? payload['row_version'];
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> _decodePayload(String payload) {
    try {
      return jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      return const {};
    }
  }

  Future<void> _applyResolvedPayloadLocally(
    AppDatabase db,
    ConflictLog conflict,
    String chosenVersion,
    int? newRowVersion,
  ) async {
    final tableName = _entityTableName[conflict.entityType];
    if (tableName == null) return;

    final payload = _decodePayload(
      chosenVersion == 'local' ? conflict.localPayload : conflict.remotePayload,
    );
    if (payload.isEmpty) return;

    final id = payload['id']?.toString() ?? conflict.entityId;
    final sqlValues = <String, Object?>{};
    for (final entry in payload.entries) {
      final snakeKey = _camelToSnake(entry.key);
      var value = entry.value;
      if (snakeKey == 'sync_status') continue;
      if (snakeKey == 'row_version') continue;
      if (value is bool) {
        value = value ? 1 : 0;
      } else if (value is String && _isDateTimeColumn(snakeKey)) {
        final parsedDate = DateTime.tryParse(value);
        value = parsedDate == null
            ? value
            : parsedDate.millisecondsSinceEpoch ~/ 1000;
      } else if (value is String) {
        value = _enumIndexValue(snakeKey, value) ?? value;
      }
      sqlValues[snakeKey] = value;
    }

    sqlValues['sync_status'] = SyncStatus.SYNCED.index;
    if (newRowVersion != null) {
      sqlValues['row_version'] = newRowVersion;
    }

    final existing = await db
        .customSelect(
          'SELECT id FROM "$tableName" WHERE id = ?',
          variables: [Variable.withString(id)],
        )
        .getSingleOrNull();

    if (existing == null) {
      final columns = sqlValues.keys.map((column) => '"$column"').join(', ');
      final placeholders = List.filled(sqlValues.length, '?').join(', ');
      await db.customStatement(
        'INSERT INTO "$tableName" ($columns) VALUES ($placeholders)',
        sqlValues.values.toList(),
      );
      db.notifyUpdates({TableUpdate(tableName, kind: UpdateKind.insert)});
      return;
    }

    final setClauses = sqlValues.entries
        .where((entry) => entry.key != 'id')
        .map((entry) => '"${entry.key}" = ?')
        .join(', ');
    final values = sqlValues.entries
        .where((entry) => entry.key != 'id')
        .map((entry) => entry.value)
        .toList();
    await db.customStatement(
      'UPDATE "$tableName" SET $setClauses WHERE id = ?',
      [...values, id],
    );
    db.notifyUpdates({TableUpdate(tableName, kind: UpdateKind.update)});
  }

  List<_FieldDifference> _diffRows(
    Map<String, dynamic> localPayload,
    Map<String, dynamic> remotePayload,
  ) {
    final ignored = {
      'id',
      'rowVersion',
      'row_version',
      'syncStatus',
      'sync_status',
      'createdAt',
      'created_at',
      'updatedAt',
      'updated_at',
      'deviceId',
      'device_id',
    };
    final keys = {
      ...localPayload.keys,
      ...remotePayload.keys,
    }.where((key) => !ignored.contains(key)).toList()..sort();

    return keys
        .where(
          (key) =>
              _normalize(localPayload[key]) != _normalize(remotePayload[key]),
        )
        .map(
          (key) => _FieldDifference(
            key,
            localPayload[key],
            remotePayload[key],
          ),
        )
        .toList();
  }

  String _normalize(Object? value) {
    if (value == null) return '';
    return value.toString();
  }

  DateTime? _payloadTimestamp(Map<String, dynamic> payload) {
    final value =
        payload['updatedAt'] ??
        payload['updated_at'] ??
        payload['createdAt'] ??
        payload['created_at'];
    if (value is String) {
      return DateTime.tryParse(value)?.toLocal();
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value * 1000).toLocal();
    }
    return null;
  }

  String _documentTitle(
    ParentEntityType entityType,
    Map<String, dynamic> payload,
  ) {
    return switch (entityType) {
      ParentEntityType.SALES_INVOICE => _friendlyReference(
        payload['localRef'] ?? payload['local_ref'],
        'الفاتورة',
      ),
      ParentEntityType.RECEIPT => _friendlyReference(
        payload['localRef'] ?? payload['local_ref'],
        'سند القبض',
      ),
      ParentEntityType.SALES_RETURN => _friendlyReference(
        payload['localRef'] ?? payload['local_ref'],
        'المرتجع',
      ),
      ParentEntityType.CLIENT =>
        (payload['displayName'] ?? payload['display_name'] ?? 'عميل')
            .toString(),
      ParentEntityType.PRODUCT => (payload['name'] ?? 'منتج').toString(),
      ParentEntityType.EXPENSE =>
        (payload['note'] ?? payload['description'] ?? 'مصروف').toString(),
      ParentEntityType.MONTHLY_DISTRIBUTION =>
        'توزيع ${payload['year'] ?? ''}-${payload['month'] ?? ''}',
      ParentEntityType.PARTY_ADJUSTMENT =>
        'إضافة مبلغ ${payload['amount'] ?? ''}',
      _ => '${_entityTypeLabel(entityType)} ${payload['id'] ?? ''}',
    };
  }

  String _friendlyReference(Object? reference, String label) {
    final raw = reference?.toString() ?? '';
    final match = RegExp(r'(\d+)$').firstMatch(raw);
    if (match == null) return label;
    final number = int.tryParse(match.group(1) ?? '') ?? 0;
    return '$label رقم $number';
  }

  String _entityTypeLabel(ParentEntityType type) => switch (type) {
    ParentEntityType.SALES_INVOICE => 'فاتورة',
    ParentEntityType.SALES_INVOICE_LINE => 'بند فاتورة',
    ParentEntityType.RECEIPT => 'سند قبض',
    ParentEntityType.RECEIPT_ALLOCATION => 'تخصيص سند',
    ParentEntityType.PRODUCT => 'منتج',
    ParentEntityType.CLIENT => 'عميل',
    ParentEntityType.EXPENSE => 'مصروف',
    ParentEntityType.SALES_RETURN => 'مرتجع',
    ParentEntityType.SALES_RETURN_LINE => 'بند مرتجع',
    ParentEntityType.ATTACHMENT_METADATA => 'مرفق',
    ParentEntityType.MONTHLY_DISTRIBUTION => 'توزيع شهري',
    ParentEntityType.PARTY_ADJUSTMENT => 'إضافة رصيد طرف',
    ParentEntityType.BENEFICIARY => 'مستفيد',
    ParentEntityType.FREE_SAMPLE => 'عينة مجانية',
    ParentEntityType.FREE_SAMPLE_LINE => 'بند عينة مجانية',
  };

  String _fieldLabel(String key) => switch (key) {
    'amount' => 'المبلغ',
    'allocatedAmount' || 'allocated_amount' => 'المبلغ المخصص',
    'total' => 'الإجمالي',
    'subtotal' => 'الإجمالي الفرعي',
    'discount' => 'الخصم',
    'paidAmount' || 'paid_amount' => 'المبلغ المدفوع',
    'remainingAmount' || 'remaining_amount' => 'المتبقي',
    'clientId' || 'client_id' => 'العميل',
    'invoiceId' || 'invoice_id' => 'الفاتورة',
    'invoiceDate' || 'invoice_date' => 'تاريخ الفاتورة',
    'receiptDate' || 'receipt_date' => 'تاريخ السند',
    'returnDate' || 'return_date' => 'تاريخ المرتجع',
    'expenseDate' || 'expense_date' => 'تاريخ المصروف',
    'adjustmentDate' || 'adjustment_date' => 'تاريخ الإضافة',
    'party' => 'الطرف',
    'name' => 'الاسم',
    'displayName' || 'display_name' => 'اسم العميل',
    'description' => 'الوصف',
    'note' => 'الملاحظة',
    'status' => 'الحالة',
    'voidReason' || 'void_reason' => 'سبب الإلغاء',
    'localRef' || 'local_ref' => 'الرقم المحلي',
    'unitPrice' || 'unit_price' => 'سعر الوحدة',
    'quantity' => 'الكمية',
    _ => key,
  };

  String _displayValue(Object? value) {
    if (value == null) return 'فارغ';
    return value.toString();
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String _camelToSnake(String input) {
    return input.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
  }

  bool _isDateTimeColumn(String columnName) {
    return columnName == 'created_at' ||
        columnName == 'updated_at' ||
        columnName.endsWith('_date');
  }

  int? _enumIndexValue(String columnName, String value) {
    final values = _enumValues[columnName];
    if (values == null) return null;
    final index = values.indexOf(value);
    return index < 0 ? null : index;
  }

  static const Map<ParentEntityType, String> _entityTableName = {
    ParentEntityType.PRODUCT: 'products',
    ParentEntityType.CLIENT: 'clients',
    ParentEntityType.SALES_INVOICE: 'sales_invoices',
    ParentEntityType.RECEIPT: 'receipts',
    ParentEntityType.EXPENSE: 'expenses',
    ParentEntityType.SALES_RETURN: 'sales_returns',
    ParentEntityType.ATTACHMENT_METADATA: 'attachment_metadata',
    ParentEntityType.MONTHLY_DISTRIBUTION: 'monthly_distributions',
    ParentEntityType.PARTY_ADJUSTMENT: 'party_adjustments',
    ParentEntityType.BENEFICIARY: 'beneficiaries',
    ParentEntityType.FREE_SAMPLE: 'free_samples',
    ParentEntityType.FREE_SAMPLE_LINE: 'free_sample_lines',
  };

  static const Map<String, List<String>> _enumValues = {
    'category': [
      'OWNER_DRAW',
      'PARTNER_DRAW',
      'MARGIN_DRAW',
      'OPERATIONAL',
      'PRODUCTION',
    ],
    'parent_entity_type': [
      'SALES_INVOICE',
      'SALES_INVOICE_LINE',
      'RECEIPT',
      'RECEIPT_ALLOCATION',
      'PRODUCT',
      'CLIENT',
      'EXPENSE',
      'SALES_RETURN',
      'SALES_RETURN_LINE',
      'ATTACHMENT_METADATA',
      'MONTHLY_DISTRIBUTION',
      'PARTY_ADJUSTMENT',
      'BENEFICIARY',
      'FREE_SAMPLE',
      'FREE_SAMPLE_LINE',
    ],
    'party': ['OWNER', 'PARTNER', 'MARGIN'],
    'receipt_type': ['INVOICE_LINKED', 'GENERAL'],
    'status': ['ACTIVE', 'VOIDED'],
  };
}

class _VersionInfo {
  const _VersionInfo({
    required this.deviceName,
    required this.timestamp,
  });

  final String deviceName;
  final DateTime? timestamp;
}

class _FieldDifference {
  const _FieldDifference(this.key, this.localValue, this.remoteValue);

  final String key;
  final Object? localValue;
  final Object? remoteValue;
}
