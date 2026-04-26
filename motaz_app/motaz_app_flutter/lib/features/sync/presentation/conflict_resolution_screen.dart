import 'dart:convert';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motaz_app_client/motaz_app_client.dart' as server;

import '../../../core/database/app_database.dart' hide Client;
import '../../../core/database/database_provider.dart';
import '../../../core/database/enums/enums.dart';
import '../../../core/server/server_client_provider.dart';
import '../../sync/application/sync_providers.dart';

final _pendingConflictsProvider = FutureProvider.family<List<ConflictLog>, AppDatabase>((ref, db) async {
  return (db.select(db.conflictLogs)
    ..where((t) => t.resolutionStatus.equals(ConflictStatus.PENDING.index))
    ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
    .get();
});

class ConflictResolutionScreen extends ConsumerStatefulWidget {
  const ConflictResolutionScreen({super.key});

  @override
  ConsumerState<ConflictResolutionScreen> createState() => _ConflictResolutionScreenState();
}

class _ConflictResolutionScreenState extends ConsumerState<ConflictResolutionScreen> {
  ConflictLog? _selectedConflict;
  bool _resolving = false;

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(appDatabaseProvider);
    final conflictsAsync = ref.watch(_pendingConflictsProvider(db));

    return Scaffold(
      appBar: AppBar(
        title: const Text('حل التعارضات'),
      ),
      body: conflictsAsync.when(
        data: (conflicts) {
          if (conflicts.isEmpty) {
            return const Center(child: Text('لا توجد تعارضات معلقة'));
          }
          if (_selectedConflict != null) {
            return _buildDetail(context, _selectedConflict!);
          }
          return ListView.builder(
            itemCount: conflicts.length,
            itemBuilder: (context, index) {
              final conflict = conflicts[index];
              return ListTile(
                leading: const Icon(Icons.warning_amber, color: Colors.orange),
                title: Text(
                  '${_entityTypeLabel(conflict.entityType)} - ${conflict.entityId.substring(0, 8)}',
                ),
                subtitle: Text(
                  '${conflict.conflictType}  |  ${conflict.createdAt.toString().substring(0, 19)}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  setState(() { _selectedConflict = conflict; });
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
      ),
    );
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
      };

  Widget _buildDetail(BuildContext context, ConflictLog conflict) {
    Map<String, dynamic>? localPayload;
    Map<String, dynamic>? remotePayload;
    try {
      localPayload = jsonDecode(conflict.localPayload) as Map<String, dynamic>;
    } catch (_) {}
    try {
      remotePayload = jsonDecode(conflict.remotePayload) as Map<String, dynamic>;
    } catch (_) {}

    final db = ref.read(appDatabaseProvider);
    final localDeviceId = localPayload?['deviceId'] as String?;
    final remoteDeviceId = remotePayload?['deviceId'] as String?;
    final localDeviceFuture = _resolveDeviceName(db, localDeviceId);
    final remoteDeviceFuture = _resolveDeviceName(db, remoteDeviceId);
    final localTimestamp = _extractTimestamp(localPayload);
    final remoteTimestamp = _extractTimestamp(remotePayload);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () { setState(() { _selectedConflict = null; }); },
              ),
              Expanded(
                child: Text(
                  'تعارض ${_entityTypeLabel(conflict.entityType)}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildPayloadCard(
                context,
                localDeviceFuture,
                localTimestamp,
                localPayload,
                remotePayload,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPayloadCard(
                context,
                remoteDeviceFuture,
                remoteTimestamp,
                remotePayload,
                localPayload,
                Colors.green,
              ),
            ),
          ],
        ),
          const SizedBox(height: 24),
          if (_resolving)
            const Center(child: CircularProgressIndicator())
          else
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _confirmAndResolve(context, conflict, 'local'),
                icon: const Icon(Icons.phone_android),
                label: const Text('اختيار نسخة هذا الجهاز'),
                style: ElevatedButton.styleFrom(foregroundColor: Colors.blue),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _confirmAndResolve(context, conflict, 'remote'),
                icon: const Icon(Icons.cloud),
                label: const Text('اختيار النسخة الأخرى'),
                style: ElevatedButton.styleFrom(foregroundColor: Colors.green),
              ),
            ),
          ],
        ),
        ],
      ),
    );
  }

  Future<String> _resolveDeviceName(AppDatabase db, String? deviceId) async {
    if (deviceId == null) return 'جهاز غير معروف';
    try {
      final device = await (db.select(db.devices)
            ..where((t) => t.id.equals(deviceId)))
          .getSingleOrNull();
      return device?.deviceName ?? 'جهاز غير معروف';
    } catch (_) {
      return 'جهاز غير معروف';
    }
  }

  String? _extractTimestamp(Map<String, dynamic>? payload) {
    final ts = payload?['createdAt'] ?? payload?['created_at'];
    if (ts == null) return null;
    try {
      final dt = ts is String ? DateTime.parse(ts) : ts is DateTime ? ts : null;
      if (dt == null) return null;
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return null;
    }
  }

  Widget _buildPayloadCard(
    BuildContext context,
    Future<String> deviceNameFuture,
    String? timestamp,
    Map<String, dynamic>? payload,
    Map<String, dynamic>? otherPayload,
    Color color,
  ) {
    final differences = <String>{};
    if (payload != null && otherPayload != null) {
      for (final key in {...payload.keys, ...otherPayload.keys}) {
        if (payload[key].toString() != otherPayload[key].toString()) {
          differences.add(key);
        }
      }
    }
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<String>(
              future: deviceNameFuture,
              builder: (context, snapshot) {
                final name = snapshot.data ?? 'جهاز غير معروف';
                return Text(
                  timestamp != null ? '$name  ($timestamp)' : name,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14),
                );
              },
            ),
            const SizedBox(height: 8),
            if (payload == null)
              const SelectableText('Unable to parse payload', style: TextStyle(fontFamily: 'monospace', fontSize: 11))
            else
              ...payload.entries.map((e) {
                final isDiff = differences.contains(e.key);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black),
                      children: [
                        TextSpan(
                          text: '${e.key}: ',
                          style: TextStyle(
                            backgroundColor: isDiff ? Colors.orange.withValues(alpha: 0.3) : null,
                            fontWeight: isDiff ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        TextSpan(
                          text: e.value.toString(),
                          style: TextStyle(
                            backgroundColor: isDiff ? Colors.orange.withValues(alpha: 0.3) : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndResolve(
    BuildContext context,
    ConflictLog conflict,
    String chosenVersion,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد اختيار النسخة'),
        content: const Text('هل أنت متأكد من اختيار هذه النسخة؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('تأكيد')),
        ],
      ),
    );
    if (confirmed == true) {
      if (!context.mounted) return;
      await _resolveConflict(context, conflict, chosenVersion);
    }
  }

  Future<void> _resolveConflict(
  BuildContext context,
  ConflictLog conflict,
  String chosenVersion,
  ) async {
    setState(() { _resolving = true; });
    try {
      final serverClient = ref.read(serverpodClientProvider);
      final request = server.ConflictResolutionRequest(
        conflictId: conflict.id,
        chosenVersion: chosenVersion,
      );
      final response = await serverClient.sync.resolveConflict(request);

      if (!context.mounted) return;

            if (response.success) {
              final db = ref.read(appDatabaseProvider);
              await (db.update(db.conflictLogs)
                ..where((t) => t.id.equals(conflict.id)))
        .write(ConflictLogsCompanion(
          resolutionStatus: Value(ConflictStatus.RESOLVED),
          resolvedAt: Value(DateTime.now()),
        ));
              ref.invalidate(_pendingConflictsProvider);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حل التعارض بنجاح')),
              );
              setState(() { _selectedConflict = null; });
              ref.invalidate(syncStateProvider);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل حل التعارض: ${response.errorMessage ?? 'unknown'}')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e')),
      );
    } finally {
      if (mounted) { setState(() { _resolving = false; }); }
    }
  }
}
