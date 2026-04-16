import 'dart:convert';
import 'dart:io' show Directory, File, Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;

class AppConfig {
  const AppConfig({
    required this.apiUrl,
    required this.apiUrlAndroid,
    required this.runMode,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      apiUrl: json['apiUrl'] as String? ?? 'http://localhost:8080',
      apiUrlAndroid: json['apiUrlAndroid'] as String? ?? 'http://10.0.2.2:8080',
      runMode: json['runMode'] as String? ?? 'development',
    );
  }

  static Future<AppConfig> load() async {
    final bundledJson =
        jsonDecode(await rootBundle.loadString('assets/config.json'))
            as Map<String, dynamic>;
    var mergedJson = Map<String, dynamic>.from(bundledJson);

    if (!kIsWeb) {
      final apiUrl = _envOrNull('MOTAZ_API_URL');
      final apiUrlAndroid = _envOrNull('MOTAZ_API_URL_ANDROID');
      final runMode = _envOrNull('MOTAZ_RUN_MODE');
      final envOverrides = <String, String?>{
        'apiUrl': apiUrl,
        'apiUrlAndroid': apiUrlAndroid,
        'runMode': runMode,
      }..removeWhere((_, value) => value == null);

      for (final file in _overrideFiles()) {
        if (!await file.exists()) {
          continue;
        }

        final decoded = jsonDecode(await file.readAsString());
        if (decoded is Map<String, dynamic>) {
          mergedJson = {
            ...mergedJson,
            ...decoded,
          };
        }
      }

      mergedJson = {
        ...mergedJson,
        ...envOverrides,
      };
    }

    return AppConfig.fromJson(mergedJson);
  }

  final String apiUrl;
  final String apiUrlAndroid;
  final String runMode;

  /// Returns the appropriate API URL based on the current platform.
  /// - Windows/Linux/macOS desktop: uses apiUrl (localhost)
  /// - Android emulator: uses apiUrlAndroid (10.0.2.2)
  /// - Android physical device: uses apiUrlAndroid (should be LAN IP)
  /// - iOS: uses apiUrl (localhost for simulator, requires config change for physical device)
  /// - Web: uses apiUrl
  String get effectiveApiUrl {
    if (kIsWeb) {
      return apiUrl;
    }

    // Check if running on Android
    try {
      if (Platform.isAndroid) {
        return apiUrlAndroid;
      }
    } catch (_) {
      // Platform check may fail on web
    }

    // Default to desktop/MacOS/iOS simulator URL
    return apiUrl;
  }

  static List<File> _overrideFiles() {
    final files = <File>[];

    try {
      files.add(
        File('${Directory.current.path}${Platform.pathSeparator}config.json'),
      );
    } catch (_) {}

    try {
      final executableDir = File(Platform.resolvedExecutable).parent.path;
      files.add(File('$executableDir${Platform.pathSeparator}config.json'));
    } catch (_) {}

    return files;
  }

  static String? _envOrNull(String key) {
    final value = Platform.environment[key]?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }
}
