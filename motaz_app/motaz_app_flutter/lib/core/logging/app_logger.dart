import 'dart:io';

import 'package:logging/logging.dart';

class AppLogger {
  static final Logger auth = Logger('motaz.auth');
  static final Logger connectivity = Logger('motaz.connectivity');
  static final Logger database = Logger('motaz.database');
  static final Logger server = Logger('motaz.server');

  static IOSink? _fileSink;

  static void initialize() {
    Logger.root.level = Level.INFO;
    _fileSink ??= _createLogSink();
    Logger.root.onRecord.listen((record) {
      final line =
          '[${record.level.name}] ${record.loggerName}: ${record.message}';
      // ignore: avoid_print
      print(line);
      _fileSink?.writeln(line);
    });
  }

  static File? logFile() {
    try {
      final executable = File(Platform.resolvedExecutable);
      return File(
        '${executable.parent.path}${Platform.pathSeparator}motaz_app.log',
      );
    } catch (_) {
      return null;
    }
  }

  static IOSink? _createLogSink() {
    try {
      final file = logFile();
      if (file == null) {
        return null;
      }
      return file.openWrite(mode: FileMode.append);
    } catch (_) {
      return null;
    }
  }
}
