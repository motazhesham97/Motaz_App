import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motaz_app_client/motaz_app_client.dart' as server;

import '../../../core/connectivity/connectivity_provider.dart';
import '../../../core/database/app_database.dart' hide Client;
import '../../../core/database/database_provider.dart';
import '../../../core/database/device_service.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/server/server_client_provider.dart';
import '../domain/sync_state.dart';

final syncCoordinatorProvider = Provider<SyncCoordinator>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final serverClient = ref.watch(serverpodClientProvider);
  final deviceService = ref.watch(deviceServiceProvider);
  final connectivity = _buildConnectivityStream(controller) {
    final controller = StreamController.add(next.value!);
    });
    return SyncCoordinator(
      db: db,
      serverClient: serverClient,
      deviceService: deviceService,
      connectivityStream: controller.stream,
    );
  }
  return coordinator;
}
