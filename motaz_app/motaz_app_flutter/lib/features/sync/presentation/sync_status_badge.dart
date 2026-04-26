import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../sync/application/sync_providers.dart';
import '../../sync/domain/sync_state.dart';

class SyncStatusBadge extends ConsumerWidget {
  const SyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStateAsync = ref.watch(syncStateProvider);
    final pendingAsync = ref.watch(pendingCountProvider);
    final conflictAsync = ref.watch(unresolvedConflictCountProvider);

    return syncStateAsync.when(
      data: (syncState) {
    final pendingCount = pendingAsync.value ?? 0;
    final conflictCount = conflictAsync.value ?? 0;
        return GestureDetector(
          onTap: () => _showSyncInfoSheet(context, syncState, pendingCount, conflictCount, ref),
          child: _buildContent(context, syncState, pendingCount, conflictCount, ref),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(8),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, _) => const Icon(Icons.sync_problem, size: 20, color: Colors.grey),
    );
  }

  Widget _buildContent(
    BuildContext context,
    SyncState syncState,
    int pendingCount,
    int conflictCount,
    WidgetRef ref,
  ) {
    switch (syncState.status) {
      case SyncPhase.idle:
        if (pendingCount == 0 && conflictCount == 0) {
          return const Icon(Icons.check_circle, size: 20, color: Colors.green);
        }
        if (conflictCount > 0) {
          return _buildConflictBadge(context, conflictCount);
        }
        return _buildPendingBadge(pendingCount);
      case SyncPhase.pushing:
      case SyncPhase.pulling:
        return const Padding(
          padding: EdgeInsets.all(4),
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case SyncPhase.error:
        return const Icon(Icons.error_outline, size: 20, color: Colors.red);
    }
  }

  Widget _buildPendingBadge(int count) {
    return Badge(
      label: Text(count.toString()),
      child: const Icon(Icons.cloud_upload_outlined, size: 20),
    );
  }

  Widget _buildConflictBadge(BuildContext context, int count) {
    return Badge(
      label: Text(count.toString()),
      backgroundColor: Colors.orange,
      child: const Icon(Icons.warning_amber_rounded, size: 20, color: Colors.orange),
    );
  }

  void _showSyncInfoSheet(
    BuildContext context,
    SyncState syncState,
    int pendingCount,
    int conflictCount,
    WidgetRef ref,
  ) {
    final String statusLabel;
    switch (syncState.status) {
      case SyncPhase.idle:
        statusLabel = 'متزامن';
      case SyncPhase.pushing:
      case SyncPhase.pulling:
        statusLabel = 'قيد المزامنة';
      case SyncPhase.error:
        statusLabel = 'خطأ في المزامنة';
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(
                  syncState.status == SyncPhase.error
                      ? Icons.error_outline
                      : syncState.status == SyncPhase.idle
                          ? Icons.check_circle
                          : Icons.sync,
                  color: syncState.status == SyncPhase.error
                      ? Colors.red
                      : syncState.status == SyncPhase.idle
                          ? Colors.green
                          : Colors.blue,
                ),
                title: Text(statusLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.cloud_upload_outlined),
                title: Text('التغييرات المعلقة: $pendingCount'),
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(
                  syncState.lastSyncedAt != null
                      ? 'آخر مزامنة: ${syncState.lastSyncedAt!.toLocal().toString().substring(0, 16)}'
                      : 'لم تتم المزامنة بعد',
                ),
              ),
              if (conflictCount > 0)
                ListTile(
                  leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  title: Text('التعارضات: $conflictCount'),
                ),
              if (syncState.failedCount > 0)
                ListTile(
                  leading: const Icon(Icons.error_outline, color: Colors.red),
                  title: Text('فشل المزامنة: ${syncState.failedCount}'),
                ),
              if (syncState.status == SyncPhase.error)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(syncCoordinatorProvider).retryAndSync();
                        Navigator.pop(context);
                      },
                      child: const Text('إعادة المحاولة'),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
