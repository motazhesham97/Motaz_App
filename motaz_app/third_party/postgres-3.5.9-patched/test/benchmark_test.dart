import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import 'docker.dart';

void main() {
  withPostgresServer('Benchmarking queries', (server) {
    late Connection connection;

    setUp(() async {
      connection = await server.newConnection();
    });

    tearDown(() async {
      await connection.close();
    });

    test('simple query', () async {
      final sw = Stopwatch()..start();
      for (var i = 10000; i > 0; i--) {
        await connection.execute('SELECT 1');
      }
      sw.stop();
      print(sw.elapsedMicroseconds);
    });
  });
}
