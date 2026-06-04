import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../features/returns/application/return_providers.dart';
import '../data/follow_up_repository.dart';
import '../data/follow_up_task.dart';

final followUpRepositoryProvider = Provider<FollowUpRepository>((ref) {
  return FollowUpRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(returnRepositoryProvider),
  );
});

final followUpTasksProvider = StreamProvider<List<FollowUpTask>>((ref) {
  return ref.watch(followUpRepositoryProvider).watchTasks();
});
