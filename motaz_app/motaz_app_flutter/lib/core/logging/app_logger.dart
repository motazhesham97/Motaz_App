import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

import '../app_identity.dart';

class AppLogger {
  static final Logger auth = Logger('fastika.auth');
  static final Logger connectivity = Logger('fastika.connectivity');
  static final Logger database = Logger('fastika.database');
  static final Logger server = Logger('fastika.server');
  static final Logger sync = Logger('fastika.sync');

  static IOSink? _fileSink;

  static Future<void> initialize() async {
    Logger.root.level = Level.INFO;
    _fileSink ??= await _createLogSink();
    Logger.root.onRecord.listen((record) {
      final line =
          '[${record.time.toIso8601String()}] [${record.level.name}] [${record.loggerName}]: ${record.message}';
      // ignore: avoid_print
      print(line);
      _fileSink?.writeln(line);
    });
  }

  static Future<File> logFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(
      '${dir.path}${Platform.pathSeparator}${AppIdentity.logFileName}',
    );
  }

  static Future<IOSink?> _createLogSink() async {
    try {
      final file = await logFile();
      if (file.existsSync() && file.lengthSync() > 1048576) {
        final rotated = File('${file.path}.1');
        if (rotated.existsSync()) {
          await rotated.delete();
        }
        await file.rename(rotated.path);
        final fresh = await logFile();
        return fresh.openWrite(mode: FileMode.append);
      }
      return file.openWrite(mode: FileMode.append);
    } catch (_) {
      return null;
    }
  }

  static Future<String> getLogContents() async {
    try {
      final file = await logFile();
      if (!file.existsSync()) return '';
      return await file.readAsString();
    } catch (_) {
      return '';
    }
  }

  static Future<void> clearLog() async {
    try {
      await _fileSink?.close();
      _fileSink = null;
      final file = await logFile();
      if (file.existsSync()) {
        await file.writeAsString('');
      }
      _fileSink = await _createLogSink();
    } catch (_) {}
  }
}
