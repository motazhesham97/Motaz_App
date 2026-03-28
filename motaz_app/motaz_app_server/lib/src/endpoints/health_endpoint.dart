import 'package:serverpod/serverpod.dart';

/// Public health check endpoint — no authentication required.
class HealthEndpoint extends Endpoint {
  Future<String> ping(Session session) async {
    return 'pong';
  }
}

/// Authenticated health check endpoint — requires a valid session.
class AuthenticatedHealthEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  Future<String> authenticatedPing(Session session) async {
    return 'pong';
  }
}
