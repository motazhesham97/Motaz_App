import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart' hide Client;
import '../../../core/database/device_service.dart';
import '../../sync/application/sync_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('1.0.0'),
            subtitle: const Text('إصدار'),
          ),
          const Divider(),
          FutureBuilder<Device?>(
            future: ref.read(deviceServiceProvider).currentDevice(),
            builder: (context, snapshot) {
              final device = snapshot.data;
              if (device == null) {
                return const ListTile(
                  leading: Icon(Icons.devices),
                  title: Text('معلومات الجهاز'),
                  subtitle: Text('جاري التحميل...'),
                );
              }
              return ListTile(
                leading: const Icon(Icons.devices),
                title: const Text('معلومات الجهاز'),
                subtitle: Text('${device.id.substring(0, 8)} • ${device.deviceCode}'),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text('سجل الأخطاء'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () {
              context.push('/settings/logs');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('مزامنة يدوية'),
            onTap: () {
              ref.read(syncCoordinatorProvider).syncNow();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('جاري المزامنة...')),
              );
            },
          ),
        ],
      ),
    );
  }
}
