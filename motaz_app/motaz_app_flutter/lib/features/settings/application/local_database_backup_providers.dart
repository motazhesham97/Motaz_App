import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../data/local_database_backup_service.dart';

final localDatabaseBackupServiceProvider = Provider<LocalDatabaseBackupService>(
  (ref) {
    return LocalDatabaseBackupService(ref.watch(appDatabaseProvider));
  },
);
