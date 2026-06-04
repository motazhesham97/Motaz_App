import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/app_logger.dart';
import 'app_config.dart';
import 'server_client_provider.dart';

final localServerLauncherProvider = Provider<LocalServerLauncher>((ref) {
  return LocalServerLauncher(ref.watch(appConfigProvider));
});

class LocalServerLauncher {
  LocalServerLauncher(this._config);

  final AppConfig _config;
  bool _starting = false;
  DateTime? _lastAttempt;

  bool get shouldAutoStart => _shouldAutoStart;

  Future<bool> ensureReady({
    Duration timeout = const Duration(seconds: 30),
    Duration pollInterval = const Duration(seconds: 1),
  }) async {
    if (await _isServerReachable()) return true;

    await ensureStarted();

    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (await _isServerReachable()) return true;
      await Future<void>.delayed(pollInterval);
    }

    return _isServerReachable();
  }

  Future<void> ensureStarted() async {
    if (!_shouldAutoStart) return;
    if (_starting) return;

    final lastAttempt = _lastAttempt;
    if (lastAttempt != null &&
        DateTime.now().difference(lastAttempt) < const Duration(seconds: 20)) {
      return;
    }

    if (await _isServerReachable()) return;

    final serverDir = await _findServerDirectory();
    if (serverDir == null) {
      AppLogger.server.info(
        'Local Serverpod autostart skipped: motaz_app_server was not found.',
      );
      return;
    }

    _starting = true;
    _lastAttempt = DateTime.now();
    try {
      await _startServerProcess(serverDir);
      AppLogger.server.info(
        'Local Serverpod autostart requested from ${serverDir.path}.',
      );
    } catch (error) {
      AppLogger.server.warning(
        'Local Serverpod autostart failed: $error',
      );
    } finally {
      _starting = false;
    }
  }

  Future<void> _startServerProcess(Directory serverDir) async {
    final dartExecutable = await _findDartExecutable();
    if (dartExecutable != null) {
      if (Platform.isWindows && !_isWindowsExe(dartExecutable)) {
        await Process.start(
          'cmd.exe',
          ['/c', dartExecutable, 'bin/main.dart'],
          workingDirectory: serverDir.path,
          mode: ProcessStartMode.detached,
        );
        return;
      }

      await Process.start(
        dartExecutable,
        ['bin/main.dart'],
        workingDirectory: serverDir.path,
        mode: ProcessStartMode.detached,
      );
      return;
    }

    if (Platform.isWindows) {
      await Process.start(
        'cmd.exe',
        ['/c', 'dart', 'bin/main.dart'],
        workingDirectory: serverDir.path,
        mode: ProcessStartMode.detached,
      );
      return;
    }

    await Process.start(
      'dart',
      ['bin/main.dart'],
      workingDirectory: serverDir.path,
      mode: ProcessStartMode.detached,
      runInShell: true,
    );
  }

  bool get _shouldAutoStart {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      return false;
    }
    if (_config.runMode != 'development') return false;

    final uri = Uri.tryParse(_config.effectiveApiUrl);
    if (uri == null) return false;
    return uri.host == 'localhost' || uri.host == '127.0.0.1';
  }

  Future<bool> _isServerReachable() async {
    final uri = Uri.tryParse(_config.effectiveApiUrl);
    if (uri == null) return false;

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
    try {
      final request = await client
          .getUrl(uri)
          .timeout(
            const Duration(seconds: 2),
          );
      final response = await request.close().timeout(
        const Duration(seconds: 3),
      );
      await response.drain<void>();
      return true;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  Future<Directory?> _findServerDirectory() async {
    final override = Platform.environment['MOTAZ_SERVER_DIR']?.trim();
    final candidates = <Directory>[
      if (override != null && override.isNotEmpty) Directory(override),
      Directory.current,
      Directory(
        '${Directory.current.path}${Platform.pathSeparator}motaz_app_server',
      ),
      Directory(
        '${Directory.current.parent.path}${Platform.pathSeparator}motaz_app_server',
      ),
      Directory(
        '${Directory.current.parent.parent.path}${Platform.pathSeparator}motaz_app_server',
      ),
    ];

    try {
      final executableDir = File(Platform.resolvedExecutable).parent;
      candidates.addAll([
        Directory(
          '${executableDir.path}${Platform.pathSeparator}motaz_app_server',
        ),
        Directory(
          '${executableDir.parent.path}${Platform.pathSeparator}motaz_app_server',
        ),
      ]);
    } catch (_) {}

    for (final dir in candidates) {
      final mainFile = File(
        '${dir.path}${Platform.pathSeparator}bin${Platform.pathSeparator}main.dart',
      );
      if (await mainFile.exists()) {
        return dir;
      }
    }

    return null;
  }

  Future<String?> _findDartExecutable() async {
    final executableNames = Platform.isWindows
        ? const ['dart.exe', 'dart.bat', 'dart']
        : const ['dart'];
    final explicit = Platform.environment['MOTAZ_DART_EXE']?.trim();
    final dartSdk = Platform.environment['DART_SDK']?.trim();
    final flutterRoot = Platform.environment['FLUTTER_ROOT']?.trim();
    final candidates = <File>[
      if (explicit != null && explicit.isNotEmpty) File(explicit),
      for (final executableName in executableNames) ...[
        if (dartSdk != null && dartSdk.isNotEmpty)
          File(
            '$dartSdk${Platform.pathSeparator}bin'
            '${Platform.pathSeparator}$executableName',
          ),
        if (flutterRoot != null && flutterRoot.isNotEmpty) ...[
          File(
            '$flutterRoot${Platform.pathSeparator}bin'
            '${Platform.pathSeparator}$executableName',
          ),
          File(
            '$flutterRoot${Platform.pathSeparator}bin'
            '${Platform.pathSeparator}cache${Platform.pathSeparator}dart-sdk'
            '${Platform.pathSeparator}bin${Platform.pathSeparator}$executableName',
          ),
        ],
        ..._pathDartCandidates(executableName),
      ],
    ];

    for (final candidate in candidates) {
      if (await candidate.exists()) {
        return candidate.path;
      }
    }

    if (Platform.isWindows) {
      try {
        final result = await Process.run(
          'where.exe',
          ['dart'],
          runInShell: true,
        ).timeout(const Duration(seconds: 3));
        if (result.exitCode == 0) {
          final paths = result.stdout
              .toString()
              .split(RegExp(r'\r?\n'))
              .map((line) => line.trim())
              .where((line) => line.isNotEmpty)
              .toList();
          final first = paths.isEmpty ? null : paths.first;
          if (first != null && await File(first).exists()) {
            return first;
          }
        }
      } catch (_) {}
    }

    return null;
  }

  bool _isWindowsExe(String path) {
    return path.toLowerCase().endsWith('.exe');
  }

  List<File> _pathDartCandidates(String executableName) {
    final path = Platform.environment[Platform.isWindows ? 'Path' : 'PATH'];
    if (path == null || path.trim().isEmpty) return const [];
    return path
        .split(Platform.isWindows ? ';' : ':')
        .where((entry) => entry.trim().isNotEmpty)
        .map(
          (entry) => File(
            '${entry.trim()}${Platform.pathSeparator}$executableName',
          ),
        )
        .toList();
  }
}
