enum SyncPhase {
  idle,
  pushing,
  pulling,
  error,
}

class SyncState {
  final SyncPhase status;
  final int pendingCount;
  final DateTime? lastSyncedAt;
  final String? errorMessage;
  final int unresolvedConflictCount;

  const SyncState({
    this.status = SyncPhase.idle,
    this.pendingCount = 0,
    this.lastSyncedAt,
    this.errorMessage,
    this.unresolvedConflictCount = 0,
  });

  SyncState copyWith({
    SyncPhase? status,
    int? pendingCount,
    DateTime? lastSyncedAt,
    String? errorMessage,
    int? unresolvedConflictCount,
  }) {
    return SyncState(
      status: status ?? this.status,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      unresolvedConflictCount:
          unresolvedConflictCount ?? this.unresolvedConflictCount,
    );
  }
}
