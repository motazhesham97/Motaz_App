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

class SyncCoordinator {
  SyncCoordinator({
    required AppDatabase db,
    required server.Client serverClient,
    required DeviceService deviceService,
    required Stream<ConnectivityStatus> connectivityStream,
  })  : _db = db,
        _serverClient = serverClient,
        _deviceService = deviceService,
        _connectivityStream = connectivityStream {
    _connectivitySubscription = _connectivityStream.listen(_onConnectivityChanged);
  }

  final AppDatabase _db;
  final server.Client _serverClient;
  final DeviceService _deviceService;
  final Stream<ConnectivityStatus> _connectivityStream;
  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;
  Timer? _debounceTimer;
  Timer? _periodicTimer;

  final _stateController = StreamController<SyncState>.broadcast();
  SyncState _state = const SyncState();
  bool _isRunning = false;
  bool _deviceRegistered = false;

  Stream<SyncState> get stateStream => _stateController.stream;
  SyncState get currentState => _state;

  void _emitState(SyncState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  Future<bool> ensureDeviceRegistered() async {
    if (_deviceRegistered) return true;

    final device = await _deviceService.ensureCurrentDevice();
    try {
      final request = server.DeviceRegistrationRequest(
        deviceId: device.id,
        deviceCode: device.deviceCode,
        platform: device.platform.name,
        deviceName: device.deviceName,
      );
      final response = await _serverClient.device.registerDevice(request);

      if (response.success) {
        _deviceRegistered = true;
        AppLogger.database.info('Device registered: ${device.id}');
        return true;
      }
      AppLogger.database.warning('Device registration failed: ${response.errorMessage}');
      return false;
    } catch (e) {
      AppLogger.database.warning('Device registration error: $e');
      return false;
    }
  }

  Future<void> runSyncCycle() async {
    if (_isRunning) return;
    _isRunning = true;

    try {
      await ensureDeviceRegistered();

      _emitState(_state.copyWith(status: SyncPhase.pushing));

      _emitState(_state.copyWith(status: SyncPhase.pulling));

      _emitState(_state.copyWith(
        status: SyncPhase.idle,
        lastSyncedAt: DateTime.now(),
        errorMessage: null,
      ));
    } catch (e) {
      AppLogger.database.warning('Sync cycle error: $e');
      _emitState(_state.copyWith(
        status: SyncPhase.error,
        errorMessage: e.toString(),
      ));
    } finally {
      _isRunning = false;
    }
  }

  Future<void> syncNow() async {
    await runSyncCycle();
  }

  void _onConnectivityChanged(ConnectivityStatus status) {
    if (status == ConnectivityStatus.online) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(seconds: 5), () {
        runSyncCycle();
      });

      _periodicTimer?.cancel();
      _periodicTimer = Timer.periodic(const Duration(minutes: 5), (_) {
        runSyncCycle();
      });
    } else {
      _debounceTimer?.cancel();
      _periodicTimer?.cancel();
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _debounceTimer?.cancel();
    _periodicTimer?.cancel();
    _stateController.close();
  }
}

final syncCoordinatorProvider = Provider<SyncCoordinator>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final serverClient = ref.watch(serverpodClientProvider);
  final deviceService = ref.watch(deviceServiceProvider);

  final controller = StreamController<ConnectivityStatus>.broadcast();
  ref.listen(connectivityProvider, (_, next) {
    if (next.hasValue) controller.add(next.value!);
  });
  ref.onDispose(controller.close);

  final coordinator = SyncCoordinator(
    db: db,
    serverClient: serverClient,
    deviceService: deviceService,
    connectivityStream: controller.stream,
  );

  ref.onDispose(coordinator.dispose);
  return coordinator;
});
