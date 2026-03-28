// ignore_for_file: implementation_imports

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motaz_app_client/src/protocol/client.dart' as app_client;

import '../logging/app_logger.dart';

enum ServerConnectionStatus {
  connected,
  disconnected,
  error,
}

class ServerConnectionState {
  final ServerConnectionStatus status;
  final String? errorMessage;
  final DateTime lastChecked;

  const ServerConnectionState({
    required this.status,
    this.errorMessage,
    required this.lastChecked,
  });

  factory ServerConnectionState.initial() => ServerConnectionState(
    status: ServerConnectionStatus.disconnected,
    lastChecked: DateTime.now(),
  );

  factory ServerConnectionState.connected() => ServerConnectionState(
    status: ServerConnectionStatus.connected,
    lastChecked: DateTime.now(),
  );

  factory ServerConnectionState.error(String message) => ServerConnectionState(
    status: ServerConnectionStatus.error,
    errorMessage: message,
    lastChecked: DateTime.now(),
  );

  bool get isConnected => status == ServerConnectionStatus.connected;
  bool get isDisconnected => status == ServerConnectionStatus.disconnected;
  bool get hasError => status == ServerConnectionStatus.error;
}

class ServerService {
  final app_client.Client _client;

  ServerService(this._client);

  Future<ServerConnectionState> checkConnection() async {
    try {
      AppLog.server('Checking server connection with health.ping()');
      final result = await _client.health
          .ping()
          .timeout(const Duration(seconds: 5));
      if (result == 'pong') {
        AppLog.server('Server health check succeeded');
        return ServerConnectionState.connected();
      }
      AppLog.warning(
        'Server health check returned unexpected response: $result',
      );
      return ServerConnectionState.error('استجابة غير متوقعة من الخادم');
    } on TimeoutException {
      AppLog.warning('Server health check timed out');
      return ServerConnectionState.error('انتهت مهلة الاتصال بالخادم');
    } catch (e) {
      AppLog.error('Server health check failed', e);
      return ServerConnectionState.error('فشل الاتصال بالخادم');
    }
  }

  Future<String?> ping() async {
    try {
      AppLog.server('Calling unauthenticated ping');
      return await _client.health.ping();
    } catch (e) {
      AppLog.error('Unauthenticated ping failed', e);
      return null;
    }
  }

  Future<String?> authenticatedPing() async {
    try {
      AppLog.server('Calling authenticated ping');
      return await _client.authenticatedHealth.authenticatedPing();
    } catch (e) {
      AppLog.error('Authenticated ping failed', e);
      return null;
    }
  }
}

final serverServiceProvider = Provider<ServerService>((ref) {
  throw UnimplementedError('serverServiceProvider must be overridden');
});

final serverConnectionStatusProvider = FutureProvider<ServerConnectionState>((
  ref,
) async {
  final serverService = ref.watch(serverServiceProvider);
  return await serverService.checkConnection();
});
