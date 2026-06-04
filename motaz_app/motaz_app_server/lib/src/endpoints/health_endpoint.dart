import 'package:serverpod/serverpod.dart';

class HealthEndpoint extends Endpoint {
  Future<String> ping(Session session) async => 'pong';

  Future<String> serverFingerprint(Session session) async {
    await session.db.unsafeExecute('''
CREATE TABLE IF NOT EXISTS motaz_app_server_metadata (
  "key" text PRIMARY KEY,
  "value" text NOT NULL,
  "updatedAt" timestamp without time zone NOT NULL DEFAULT now()
);
''');
    await session.db.unsafeExecute('''
INSERT INTO motaz_app_server_metadata ("key", "value", "updatedAt")
SELECT
  'sync_namespace',
  md5(random()::text || clock_timestamp()::text || txid_current()::text),
  now()
WHERE NOT EXISTS (
  SELECT 1
  FROM motaz_app_server_metadata
  WHERE "key" = 'sync_namespace'
);
''');
    final rows = await session.db.unsafeQuery(
      '''
SELECT "value"
FROM motaz_app_server_metadata
WHERE "key" = 'sync_namespace'
LIMIT 1
''',
    );
    final namespace = rows.first.first as String;
    return 'motaz-sync-v1:$namespace';
  }

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
