import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/connectivity/connectivity_provider.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/device_service.dart';
import '../../../core/server/server_client_provider.dart';
import '../../../core/database/enums/enums.dart';
import '../../../core/server/local_server_launcher.dart';
import '../../profit_distribution/application/profit_providers.dart';
import '../domain/sync_state.dart';
import 'sync_coordinator.dart';

final syncCoordinatorProvider = Provider<SyncCoordinator>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final serverClient = ref.watch(serverpodClientProvider);
  final deviceService = ref.watch(deviceServiceProvider);
  final distributionRepository = ref.watch(distributionRepositoryProvider);
  final localServerLauncher = ref.watch(localServerLauncherProvider);
  final sessionManager = ref.watch(sessionManagerProvider);

  final connectivityController = StreamController<ConnectivityStatus>();
  ref.listen<AsyncValue<ConnectivityStatus>>(connectivityProvider, (_, next) {
    next.whenData((status) {
      connectivityController.add(status);
    });
  });

  final coordinator = SyncCoordinator(
    db: db,
    serverClient: serverClient,
    deviceService: deviceService,
    distributionRepository: distributionRepository,
    connectivityStream: connectivityController.stream,
    localServerLauncher: localServerLauncher,
    sessionManager: sessionManager,
  );

  ref.onDispose(() {
    connectivityController.close();
    coordinator.dispose();
  });
  return coordinator;
});

final syncStateProvider = StreamProvider<SyncState>((ref) {
  final coordinator = ref.watch(syncCoordinatorProvider);
  return coordinator.stateStream;
});

final pendingCountProvider = StreamProvider<int>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final query = db.select(db.syncOutbox)
    ..where((t) => t.status.equals(SyncOutboxStatus.PENDING.index));
  return query.watch().map((rows) => rows.length);
});

final failedOutboxCountProvider = StreamProvider<int>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final query = db.select(db.syncOutbox)
    ..where((t) => t.status.equals(SyncOutboxStatus.FAILED.index));
  return query.watch().map((rows) => rows.length);
});

final unresolvedConflictCountProvider = StreamProvider<int>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final query = db.select(db.conflictLogs)
    ..where((t) => t.resolutionStatus.equals(ConflictStatus.PENDING.index));
  return query.watch().map((rows) => rows.length);
});
