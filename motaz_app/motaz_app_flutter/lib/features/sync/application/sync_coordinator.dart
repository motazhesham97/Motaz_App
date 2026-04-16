import 'dart:async';

import 'package:motaz_app_client/motaz_app_client.dart' as server;

import '../../../core/connectivity/connectivity_provider.dart';
import '../../../core/database/app_database.dart' hide Client;
import '../../../core/database/device_service.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/sync_state.dart';
import 'attachment_uploader.dart';
import 'outbox_processor.dart';
import 'pull_processor.dart';

class SyncCoordinator {
  SyncCoordinator({
    required AppDatabase db,
    required server.Client serverClient,
    required DeviceService deviceService,
    required Stream<ConnectivityStatus> connectivityStream,
  }) : _serverClient = serverClient, _deviceService = deviceService, _connectivityStream = connectivityStream, _outboxProcessor = OutboxProcessor(db: db, serverClient: serverClient), _pullProcessor = PullProcessor(db: db, serverClient: serverClient), _attachmentUploader = AttachmentUploader(db: db, serverClient: serverClient, deviceService: deviceService) {
    _connectivitySubscription = _connectivityStream.listen(_onConnectivityChanged);
  }


  final server.Client _serverClient;
  final DeviceService _deviceService;
  final Stream<ConnectivityStatus> _connectivityStream;
  final OutboxProcessor _outboxProcessor;
  final PullProcessor _pullProcessor;
  final AttachmentUploader _attachmentUploader;
  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;
  Timer? _debounceTimer;
  Timer? _periodicTimer;

  final _stateController = StreamController<SyncState>.broadcast();
  SyncState _state = const SyncState();
  bool _isRunning = false;
  bool _deviceRegistered = false;
  ConnectivityStatus _lastConnectivity = ConnectivityStatus.offline;

  Stream<SyncState> get stateStream => _stateController.stream;
  SyncState get currentState => _state;
  bool get isOnline => _lastConnectivity == ConnectivityStatus.online;

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
      AppLogger.database.warning('Device registration failed');
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
      await _outboxProcessor.processPending();
    _emitState(_state.copyWith(status: SyncPhase.pulling));
    await _pullProcessor.pullAllEntityTypes();
    await _attachmentUploader.processPending();
    _emitState(_state.copyWith(
        status: SyncPhase.idle,
        lastSyncedAt: DateTime.now(),
        clearError: true,
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
    if (!isOnline) {
      _emitState(_state.copyWith(
        status: SyncPhase.error,
        errorMessage: 'No internet connection',
      ));
      return;
    }
    await runSyncCycle();
  }

  Future<void> retryAndSync() async {
    await _outboxProcessor.retryFailed();
    await syncNow();
  }

  void _onConnectivityChanged(ConnectivityStatus status) {
    _lastConnectivity = status;
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
