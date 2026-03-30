import 'package:serverpod/serverpod.dart';

class HealthEndpoint extends Endpoint {
  Future<String> ping(Session session) async => 'pong';

  Future<String> authenticatedPing(Session session) async {
    if (session.authenticated == null) {
      throw StateError('AUTHENTICATION_REQUIRED');
    }

    return 'pong';
  }
}
