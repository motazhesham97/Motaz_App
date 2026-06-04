import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../sync/application/sync_providers.dart';
import '../../sync/domain/sync_state.dart';

class SyncStatusBadge extends ConsumerWidget {
  const SyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStateAsync = ref.watch(syncStateProvider);
    final pendingAsync = ref.watch(pendingCountProvider);
    final failedAsync = ref.watch(failedOutboxCountProvider);
    final conflictAsync = ref.watch(unresolvedConflictCountProvider);

    return syncStateAsync.when(
      data: (syncState) {
        final pendingCount = pendingAsync.value ?? 0;
        final failedCount = failedAsync.value ?? 0;
        final conflictCount = conflictAsync.value ?? 0;
        return GestureDetector(
          onTap: () => _showSyncInfoSheet(
            context,
            syncState,
            pendingCount,
            failedCount,
            conflictCount,
            ref,
          ),
          child: _buildContent(
            syncState,
            pendingCount,
            failedCount,
            conflictCount,
          ),
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
      error: (_, _) =>
          const Icon(Icons.sync_problem, size: 20, color: Colors.grey),
    );
  }

  Widget _buildContent(
    SyncState syncState,
    int pendingCount,
    int failedCount,
    int conflictCount,
  ) {
    switch (syncState.status) {
      case SyncPhase.idle:
        if (failedCount > 0) return _buildFailedBadge(failedCount);
        if (conflictCount > 0) return _buildConflictBadge(conflictCount);
        if (pendingCount > 0) return _buildPendingBadge(pendingCount);
        if (syncState.errorMessage != null) {
          return const Icon(Icons.error_outline, size: 20, color: Colors.red);
        }
        if (syncState.lastSyncedAt == null) {
          return const Icon(
            Icons.sync_problem,
            size: 20,
            color: Colors.orange,
          );
        }
        return const Icon(Icons.check_circle, size: 20, color: Colors.green);
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
        if (failedCount > 0) return _buildFailedBadge(failedCount);
        if (conflictCount > 0) return _buildConflictBadge(conflictCount);
        return const Icon(Icons.error_outline, size: 20, color: Colors.red);
    }
  }

  Widget _buildPendingBadge(int count) {
    return Badge(
      label: Text(count.toString()),
      child: const Icon(Icons.cloud_upload_outlined, size: 20),
    );
  }

  Widget _buildConflictBadge(int count) {
    return Badge(
      label: Text(count.toString()),
      backgroundColor: Colors.orange,
      child: const Icon(
        Icons.warning_amber_rounded,
        size: 20,
        color: Colors.orange,
      ),
    );
  }

  Widget _buildFailedBadge(int count) {
    return Badge(
      label: Text(count.toString()),
      backgroundColor: Colors.red,
      child: const Icon(Icons.error_outline, size: 20, color: Colors.red),
    );
  }

  void _showSyncInfoSheet(
    BuildContext context,
    SyncState syncState,
    int pendingCount,
    int failedCount,
    int conflictCount,
    WidgetRef ref,
  ) {
    final statusLabel = switch (syncState.status) {
      SyncPhase.idle =>
        syncState.lastSyncedAt == null ? 'لم تتم المزامنة بعد' : 'متزامن',
      SyncPhase.pushing || SyncPhase.pulling => 'قيد المزامنة',
      SyncPhase.error => 'خطأ في المزامنة',
    };

    final hasCompletedSync =
        syncState.status == SyncPhase.idle &&
        syncState.lastSyncedAt != null &&
        syncState.errorMessage == null;
    final statusIcon = switch (syncState.status) {
      SyncPhase.error => Icons.error_outline,
      SyncPhase.idle =>
        hasCompletedSync ? Icons.check_circle : Icons.sync_problem,
      SyncPhase.pushing || SyncPhase.pulling => Icons.sync,
    };
    final statusColor = switch (syncState.status) {
      SyncPhase.error => Colors.red,
      SyncPhase.idle => hasCompletedSync ? Colors.green : Colors.orange,
      SyncPhase.pushing || SyncPhase.pulling => Colors.blue,
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        final maxHeight = MediaQuery.of(sheetContext).size.height * 0.86;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    leading: Icon(statusIcon, color: statusColor),
                    title: Text(
                      statusLabel,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.cloud_upload_outlined),
                    title: Text(
                      'التغييرات المعلقة: $pendingCount',
                      textAlign: TextAlign.right,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: Text(
                      syncState.lastSyncedAt != null
                          ? 'آخر مزامنة: ${syncState.lastSyncedAt!.toLocal().toString().substring(0, 16)}'
                          : 'لم تتم المزامنة بعد',
                      textAlign: TextAlign.right,
                    ),
                  ),
                  if (conflictCount > 0)
                    ListTile(
                      leading: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                      ),
                      title: Text(
                        'التعارضات: $conflictCount',
                        textAlign: TextAlign.right,
                      ),
                      subtitle: const Text(
                        'افتحها لاختيار النسخة المعتمدة',
                        textAlign: TextAlign.right,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        context.push('/sync/conflicts');
                      },
                    ),
                  if (failedCount > 0)
                    ListTile(
                      leading: const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                      ),
                      title: Text(
                        'فشل المزامنة: $failedCount',
                        textAlign: TextAlign.right,
                      ),
                    ),
                  if (syncState.errorMessage != null)
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: Text(
                        syncState.errorMessage!,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  if (syncState.status == SyncPhase.error || failedCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            ref.read(syncCoordinatorProvider).retryAndSync();
                            Navigator.pop(sheetContext);
                          },
                          child: const Text('إعادة المحاولة'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
