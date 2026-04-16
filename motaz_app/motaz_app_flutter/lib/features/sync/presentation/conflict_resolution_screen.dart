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
        title: const Text('Conflict Resolution'),
      ),
      body: conflictsAsync.when(
        data: (conflicts) {
          if (conflicts.isEmpty) {
            return const Center(child: Text('No pending conflicts'));
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
                  '${conflict.entityType.name} - ${conflict.entityId.substring(0, 8)}',
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
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildDetail(BuildContext context, ConflictLog conflict) {
    Map<String, dynamic>? localPayload;
    Map<String, dynamic>? remotePayload;
    try {
      localPayload = jsonDecode(conflict.localPayload) as Map<String, dynamic>;
    } catch (_) {}
    try {
      remotePayload = jsonDecode(conflict.remotePayload) as Map<String, dynamic>;
    } catch (_) {}

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
                  '${conflict.entityType.name} Conflict',
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
                'Local',
                localPayload,
                remotePayload,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPayloadCard(
                context,
                'Remote',
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
                label: const Text('Choose Local'),
                style: ElevatedButton.styleFrom(foregroundColor: Colors.blue),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _confirmAndResolve(context, conflict, 'remote'),
                icon: const Icon(Icons.cloud),
                label: const Text('Choose Remote'),
                style: ElevatedButton.styleFrom(foregroundColor: Colors.green),
              ),
            ),
          ],
        ),
        ],
      ),
    );
  }

  Widget _buildPayloadCard(
    BuildContext context,
    String title,
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
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
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
        title: Text('Confirm ${chosenVersion == 'local' ? 'Local' : 'Remote'} Version'),
        content: Text('Are you sure you want to choose the $chosenVersion version? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
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
                const SnackBar(content: Text('Conflict resolved successfully')),
              );
              setState(() { _selectedConflict = null; });
              ref.invalidate(syncStateProvider);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resolution failed: ${response.errorMessage ?? 'unknown'}')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) { setState(() { _resolving = false; }); }
    }
  }
}
