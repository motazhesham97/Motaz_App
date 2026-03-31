import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/device_provider.dart';
import '../../../shared/widgets/app_drawer.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref.watch(currentDeviceProvider);

    return AppDrawerScaffold(
      title: 'مرحباً',
      currentRoute: '/home',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('مرحباً بك في تطبيق معتز', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              const Text('الأساس جاهز ويمكنك الآن الانتقال بين أقسام التطبيق.'),
              const SizedBox(height: 12),
              Text('معرّف الجهاز: ${device.asData?.value?.id ?? '...' }'),
            ],
          ),
        ),
      ),
    );
  }
}
