import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motaz_app_client/motaz_app_client.dart';
import 'package:serverpod_auth_shared_flutter/serverpod_auth_shared_flutter.dart';

import 'app_config.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  throw StateError('appConfigProvider must be overridden during startup.');
});

final serverpodClientProvider = Provider<Client>((ref) {
  throw StateError(
    'serverpodClientProvider must be overridden during startup.',
  );
});

final sessionManagerProvider = Provider<SessionManager>((ref) {
  throw StateError('sessionManagerProvider must be overridden during startup.');
});
