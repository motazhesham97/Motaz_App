import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/app_logger.dart';
import '../server/server_client_provider.dart';

class ServerService {
  ServerService(this._client);

  final dynamic _client;

  Future<bool> ping() async {
    try {
      return await _client.health.ping() == 'pong';
    } catch (error) {
      AppLogger.server.warning('Public ping failed: $error');
      return false;
    }
  }

  Future<bool> authenticatedPing() async {
    try {
      return await _client.health.authenticatedPing() == 'pong';
    } catch (error) {
      AppLogger.server.warning('Authenticated ping failed: $error');
      return false;
    }
  }
}

final serverServiceProvider = Provider<ServerService>((ref) {
  return ServerService(ref.watch(serverpodClientProvider));
});
