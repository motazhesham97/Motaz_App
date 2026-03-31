import 'package:serverpod/serverpod.dart';

class HealthEndpoint extends Endpoint {
  Future<String> ping(Session session) async => 'pong';

  Future<String> authenticatedPing(Session session) async {
    if (!session.isUserSignedIn) {
      throw NotAuthorizedException(
        reason: AuthenticationFailureReason.unauthenticated,
        message: 'Authentication required',
      );
    }

    return 'pong';
  }
}
