import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motaz_app_flutter/features/sync/application/sync_providers.dart';
import 'package:motaz_app_flutter/features/sync/domain/sync_state.dart';
import 'package:motaz_app_flutter/features/sync/presentation/sync_status_badge.dart';

Widget _buildBadge({
  required SyncState state,
  int pendingCount = 0,
  int failedCount = 0,
  int conflictCount = 0,
  Future<void> Function(WidgetRef ref)? retryOverride,
}) {
  return ProviderScope(
    overrides: [
      syncStateProvider.overrideWith((ref) => Stream.value(state)),
      pendingCountProvider.overrideWith((ref) => Stream.value(pendingCount)),
      failedOutboxCountProvider.overrideWith(
        (ref) => Stream.value(failedCount),
      ),
      unresolvedConflictCountProvider.overrideWith(
        (ref) => Stream.value(conflictCount),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Center(
          child: SyncStatusBadge(retryOverride: retryOverride),
        ),
      ),
    ),
  );
}

void main() {
  group('SyncStatusBadge', () {
    testWidgets('shows lastSyncedAt in sync information sheet', (tester) async {
      await tester.pumpWidget(
        _buildBadge(
          state: SyncState(
            status: SyncPhase.idle,
            lastSyncedAt: DateTime(2026, 6, 14, 8, 30),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(SyncStatusBadge));
      await tester.pumpAndSettle();

      expect(find.textContaining('2026-06-14 08:30'), findsOneWidget);
    });

    testWidgets('calls retry action from error sheet', (tester) async {
      var retryCalled = false;

      await tester.pumpWidget(
        _buildBadge(
          state: const SyncState(
            status: SyncPhase.error,
            errorMessage: 'Authentication required',
          ),
          retryOverride: (_) async {
            retryCalled = true;
          },
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(SyncStatusBadge));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(retryCalled, isTrue);
    });
  });
}
