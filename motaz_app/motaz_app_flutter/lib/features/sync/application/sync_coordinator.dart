import 'dart:async';
import 'dart:io';

import 'package:motaz_app_client/motaz_app_client.dart' as server;

import '../../../core/connectivity/connectivity_provider.dart';
import '../../../core/database/app_database.dart' hide Client;
import '../../../core/database/device_service.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/server/local_server_launcher.dart';
import '../../profit_distribution/data/distribution_repository.dart';
import '../domain/sync_state.dart';
import 'attachment_uploader.dart';
import 'outbox_processor.dart';
import 'pull_processor.dart';
import 'server_database_binding_service.dart';

class SyncCoordinator {
  SyncCoordinator({
    required AppDatabase db,
    required server.Client serverClient,
    required DeviceService deviceService,
    required DistributionRepository distributionRepository,
    required Stream<ConnectivityStatus> connectivityStream,
    required LocalServerLauncher localServerLauncher,
    required dynamic sessionManager,
  }) : _serverClient = serverClient,
       _deviceService = deviceService,
       _distributionRepository = distributionRepository,
       _connectivityStream = connectivityStream,
       _localServerLauncher = localServerLauncher,
       _sessionManager = sessionManager,
       _serverDatabaseBinding = ServerDatabaseBindingService(
         db: db,
         serverClient: serverClient,
       ),
       _outboxProcessor = OutboxProcessor(db: db, serverClient: serverClient),
       _pullProcessor = PullProcessor(db: db, serverClient: serverClient),
       _attachmentUploader = AttachmentUploader(
         db: db,
         serverClient: serverClient,
         deviceService: deviceService,
       ) {
    _connectivitySubscription = _connectivityStream.listen(
      _onConnectivityChanged,
    );
  }

  final server.Client _serverClient;
  final DeviceService _deviceService;
  final DistributionRepository _distributionRepository;
  final Stream<ConnectivityStatus> _connectivityStream;
  final LocalServerLauncher _localServerLauncher;
  final dynamic _sessionManager;
  final ServerDatabaseBindingService _serverDatabaseBinding;
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
  bool _authSessionReady = false;
  ConnectivityStatus _lastConnectivity = ConnectivityStatus.offline;
  DateTime? _lastSyncAttempt;
  DateTime? _lastFullReconcile;

  Stream<SyncState> get stateStream => _stateController.stream;
  SyncState get currentState => _state;
  bool get isOnline => _lastConnectivity == ConnectivityStatus.online;

  void _emitState(SyncState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  Future<bool> ensureDeviceRegistered() async {
    if (_deviceRegistered) return true;
    final authReady = await _ensureAuthSessionInitialized();
    if (!authReady) {
      AppLogger.sync.warning(
        'Device registration skipped: Authentication required',
      );
      return false;
    }

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
        AppLogger.sync.info('Device registered: ${device.id}');
        return true;
      }
      AppLogger.sync.warning(
        'Device registration failed: ${response.errorMessage}',
      );
      final errorMessage = response.errorMessage?.toLowerCase() ?? '';
      if (errorMessage.contains('authentication')) {
        _authSessionReady = false;
      }
      return false;
    } catch (e) {
      AppLogger.sync.warning('Device registration error: $e');
      return false;
    }
  }

  Future<bool> _ensureAuthSessionInitialized() async {
    if (_authSessionReady) return true;

    try {
      final result = _sessionManager.initialize(
        timeout: const Duration(seconds: 12),
      );
      if (result is Future) {
        final value = await result.timeout(const Duration(seconds: 14));
        _authSessionReady = value != false;
      } else if (result is bool) {
        _authSessionReady = result;
      } else {
        _authSessionReady = true;
      }
      if (!_hasStoredAuthSession()) {
        _authSessionReady = false;
      }
      if (_authSessionReady) {
        final serverValidated = await _validateServerAuthentication();
        if (serverValidated != null) {
          _authSessionReady = serverValidated;
        }
      }
      return _authSessionReady;
    } on NoSuchMethodError {
      _authSessionReady = true;
      return true;
    } catch (e) {
      AppLogger.sync.warning(
        'Auth session initialization before sync failed: $e',
      );
      _authSessionReady = false;
      return false;
    }
  }

  Future<bool?> _validateServerAuthentication() async {
    try {
      final result = _sessionManager.validateAuthentication();
      if (result is Future) {
        final value = await result.timeout(const Duration(seconds: 20));
        if (value is bool) return value;
        return true;
      }
      if (result is bool) return result;
      return true;
    } on NoSuchMethodError {
      return null;
    } on TimeoutException catch (e) {
      AppLogger.sync.warning(
        'Server auth validation timed out; continuing with stored session: $e',
      );
      return null;
    } catch (e) {
      AppLogger.sync.warning(
        'Sync skipped: could not verify server auth session: $e',
      );
      return false;
    }
  }

  bool _hasStoredAuthSession() {
    try {
      final isAuthenticated = _sessionManager.isAuthenticated;
      if (isAuthenticated is bool) {
        return isAuthenticated;
      }
      return true;
    } on NoSuchMethodError {
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<void> runSyncCycle() async {
    if (_isRunning) return;
    if (_lastSyncAttempt != null &&
        DateTime.now().difference(_lastSyncAttempt!) <
            const Duration(seconds: 10)) {
      return;
    }
    _isRunning = true;
    try {
      final bindingResult = await _serverDatabaseBinding.validate();
      if (!bindingResult.allowed) {
        _emitState(
          _state.copyWith(
            status: SyncPhase.error,
            errorMessage: bindingResult.message,
          ),
        );
        return;
      }

      final isDeviceRegistered = await ensureDeviceRegistered();
      if (!isDeviceRegistered) {
        AppLogger.sync.info(
          'Sync delayed: authentication session is not ready yet.',
        );
        _emitState(
          _state.copyWith(
            status: SyncPhase.error,
            errorMessage: 'Authentication required',
          ),
        );
        return;
      }
      _lastSyncAttempt = DateTime.now();
      final device = await _deviceService.ensureCurrentDevice();
      _emitState(_state.copyWith(status: SyncPhase.pushing));
      await _outboxProcessor.processPending();
      _emitState(_state.copyWith(status: SyncPhase.pulling));
      await _pullProcessor.pullAllEntityTypes();
      await _pullProcessor.pullPendingConflicts();
      await _reconcileFromServerIfNeeded();
      await _distributionRepository.ensurePreviousMonthDistributed(
        deviceId: device.id,
      );
      _emitState(_state.copyWith(status: SyncPhase.pushing));
      await _outboxProcessor.processPending();
      await _attachmentUploader.processPending();
      await _pullProcessor.pullPendingConflicts();
      _emitState(
        _state.copyWith(
          status: SyncPhase.idle,
          lastSyncedAt: DateTime.now(),
          clearError: true,
        ),
      );
    } on SocketException catch (e) {
      AppLogger.sync.info('Transient network error: $e');
      _emitState(_state.copyWith(status: SyncPhase.idle));
    } on TimeoutException catch (e) {
      AppLogger.sync.info('Transient timeout error: $e');
      _emitState(_state.copyWith(status: SyncPhase.idle));
    } catch (e) {
      AppLogger.sync.warning('Sync cycle error: $e');
      _emitState(
        _state.copyWith(
          status: SyncPhase.error,
          errorMessage: e.toString(),
        ),
      );
    } finally {
      _isRunning = false;
    }
  }

  Future<void> syncNow() async {
    if (!isOnline) {
      _emitState(
        _state.copyWith(
          status: SyncPhase.error,
          errorMessage: 'No internet connection',
        ),
      );
      return;
    }
    final serverReady = await _localServerLauncher.ensureReady();
    if (!serverReady) {
      AppLogger.sync.info('Sync delayed: local Serverpod is not ready yet.');
      _emitState(
        _state.copyWith(
          status: SyncPhase.error,
          errorMessage: 'Local Serverpod is not ready yet',
        ),
      );
      return;
    }
    await runSyncCycle();
  }

  Future<void> retryAndSync() async {
    await _outboxProcessor.retryFailed();
    await syncNow();
  }

  Future<void> resetLocalDataForCurrentServerAndSync() async {
    if (_isRunning) return;

    _isRunning = true;
    try {
      _emitState(
        _state.copyWith(
          status: SyncPhase.pulling,
          clearError: true,
          pendingCount: 0,
          failedCount: 0,
          unresolvedConflictCount: 0,
        ),
      );
      await _serverDatabaseBinding.resetLocalDataAndBindToCurrentServer();
      _deviceRegistered = false;
      _lastSyncAttempt = null;
      _lastFullReconcile = null;
      _emitState(
        _state.copyWith(
          status: SyncPhase.idle,
          clearError: true,
          pendingCount: 0,
          failedCount: 0,
          unresolvedConflictCount: 0,
        ),
      );
    } catch (e) {
      AppLogger.sync.warning('Local reset for current server failed: $e');
      _emitState(
        _state.copyWith(
          status: SyncPhase.error,
          errorMessage: e.toString(),
        ),
      );
      return;
    } finally {
      _isRunning = false;
    }

    await syncNow();
  }

  Future<void> _reconcileFromServerIfNeeded() async {
    final now = DateTime.now();
    final shouldReconcile =
        _lastFullReconcile == null ||
        now.difference(_lastFullReconcile!) > const Duration(minutes: 15);
    if (!shouldReconcile) return;

    await _pullProcessor.reconcileAllEntityTypes();
    _lastFullReconcile = DateTime.now();
  }

  void _onConnectivityChanged(ConnectivityStatus status) {
    _lastConnectivity = status;
    if (status == ConnectivityStatus.online) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(seconds: 5), () {
        unawaited(_startServerAndSync());
      });
      _periodicTimer?.cancel();
      _periodicTimer = Timer.periodic(const Duration(minutes: 5), (_) {
        unawaited(_startServerAndSync());
      });
    } else {
      _debounceTimer?.cancel();
      _periodicTimer?.cancel();
    }
  }

  Future<void> _startServerAndSync() async {
    final serverReady = await _localServerLauncher.ensureReady();
    if (!serverReady) {
      AppLogger.sync.info('Sync delayed: local Serverpod is not ready yet.');
      _emitState(
        _state.copyWith(
          status: SyncPhase.error,
          errorMessage: 'Local Serverpod is not ready yet',
        ),
      );
      return;
    }
    await runSyncCycle();
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _debounceTimer?.cancel();
    _periodicTimer?.cancel();
    _stateController.close();
  }
}
