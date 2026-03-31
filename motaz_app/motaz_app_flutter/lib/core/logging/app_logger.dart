import 'package:logging/logging.dart';

class AppLogger {
  static final Logger auth = Logger('motaz.auth');
  static final Logger connectivity = Logger('motaz.connectivity');
  static final Logger database = Logger('motaz.database');
  static final Logger server = Logger('motaz.server');

  static void initialize() {
    Logger.root.level = Level.INFO;
    Logger.root.onRecord.listen((record) {
      // ignore: avoid_print
      print('[${record.level.name}] ${record.loggerName}: ${record.message}');
    });
  }
}
