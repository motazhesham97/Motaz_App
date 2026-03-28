import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';

import '../logging/app_logger.dart';

enum ConnectionStatus {
  online,
  offline,
}

class ConnectivityState {
  final ConnectionStatus status;
  final DateTime lastChanged;

  const ConnectivityState({
    required this.status,
    required this.lastChanged,
  });

  factory ConnectivityState.initial() => ConnectivityState(
    status: ConnectionStatus.offline,
    lastChanged: DateTime.now(),
  );

  bool get isOnline => status == ConnectionStatus.online;
  bool get isOffline => status == ConnectionStatus.offline;
}

class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 500);

  ConnectivityNotifier(this._connectivity)
    : super(ConnectivityState.initial()) {
    _init();
  }

  Future<void> _init() async {
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);
    AppLog.connectivity('Initial connectivity results: $result');

    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      _debouncedUpdate(result);
    });
  }

  void _debouncedUpdate(List<ConnectivityResult> result) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      _updateStatus(result);
    });
  }

  void _updateStatus(List<ConnectivityResult> result) {
    final isOnline = result.any((r) => r != ConnectivityResult.none);
    final newStatus = isOnline
        ? ConnectionStatus.online
        : ConnectionStatus.offline;

    if (state.status != newStatus) {
      AppLog.connectivity('Connectivity changed to ${newStatus.name}');
      state = ConnectivityState(
        status: newStatus,
        lastChanged: DateTime.now(),
      );
    }
  }

  Future<void> checkNow() async {
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}

final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, ConnectivityState>((ref) {
      return ConnectivityNotifier(Connectivity());
    });

final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).isOnline;
});

final isOfflineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).isOffline;
});
