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
        return _buildContent(context, syncState, pendingCount, conflictCount, ref);
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(8),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => const Icon(Icons.sync_problem, size: 20, color: Colors.grey),
    );
  }

  Widget _buildContent(
    BuildContext context,
    SyncState syncState,
    int pendingCount,
    int conflictCount,
    WidgetRef ref,
  ) {
    final lastSyncedStr = syncState.lastSyncedAt != null
        ? 'Last synced: ${syncState.lastSyncedAt!.toLocal().toString().substring(0, 19)}'
        : 'Not synced yet';
    switch (syncState.status) {
      case SyncPhase.idle:
        if (pendingCount == 0 && conflictCount == 0) {
          return Tooltip(
            message: 'Synced\n$lastSyncedStr',
            child: const Icon(Icons.check_circle, size: 20, color: Colors.green),
          );
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
        return GestureDetector(
          onTap: () {
            ref.read(syncCoordinatorProvider).retryAndSync();
          },
          child: Tooltip(
            message: 'Tap to retry\n${syncState.errorMessage ?? "Unknown error"}',
            child: const Icon(Icons.error_outline, size: 20, color: Colors.red),
          ),
        );
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
}
