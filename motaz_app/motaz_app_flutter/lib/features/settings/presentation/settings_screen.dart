import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart' hide Client;
import '../../../core/database/database_provider.dart';
import '../../../core/database/device_service.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../sync/application/sync_providers.dart';
import '../application/local_database_backup_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _databaseFileBusy = false;

  @override
  Widget build(BuildContext context) {
    return AppDrawerScaffold(
      title: 'الإعدادات',
      currentRoute: '/settings',
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SettingsHeader(onHomePressed: () => context.go('/home')),
              const SizedBox(height: 16),
              _SettingsSection(
                children: [
                  const _SettingsTile(
                    icon: Icons.info_outline_rounded,
                    title: 'الإصدار',
                    subtitle: '1.0.0',
                  ),
                  FutureBuilder<Device?>(
                    future: ref.read(deviceServiceProvider).currentDevice(),
                    builder: (context, snapshot) {
                      final device = snapshot.data;
                      return _SettingsTile(
                        icon: Icons.devices_rounded,
                        title: 'معلومات الجهاز',
                        subtitle: device == null
                            ? 'جاري التحميل...'
                            : '${device.id.substring(0, 8)} • ${device.deviceCode}',
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SettingsSection(
                children: [
                  _SettingsTile(
                    icon: Icons.file_upload_rounded,
                    title: 'تصدير قاعدة البيانات المحلية',
                    subtitle: 'حفظ نسخة احتياطية من بيانات هذا الجهاز',
                    trailing: FilledButton.icon(
                      onPressed: _databaseFileBusy
                          ? null
                          : _exportLocalDatabase,
                      icon: const Icon(Icons.save_alt_rounded),
                      label: const Text('تصدير'),
                    ),
                  ),
                  _SettingsTile(
                    icon: Icons.file_download_rounded,
                    title: 'استيراد قاعدة بيانات محلية',
                    subtitle: 'استبدال بيانات هذا الجهاز بملف نسخة احتياطية',
                    trailing: OutlinedButton.icon(
                      onPressed: _databaseFileBusy
                          ? null
                          : _importLocalDatabase,
                      icon: const Icon(Icons.restore_rounded),
                      label: const Text('استيراد'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SettingsSection(
                children: [
                  _SettingsTile(
                    icon: Icons.article_outlined,
                    title: 'سجل الأخطاء',
                    subtitle: 'عرض السجل المحلي للتطبيق',
                    trailing: const Icon(Icons.chevron_left_rounded),
                    onTap: () => context.push('/settings/logs'),
                  ),
                  _SettingsTile(
                    icon: Icons.sync_rounded,
                    title: 'مزامنة يدوية',
                    subtitle: 'إرسال واستقبال التغييرات الآن',
                    trailing: FilledButton.icon(
                      onPressed: () {
                        ref.read(syncCoordinatorProvider).syncNow();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('جاري المزامنة...')),
                        );
                      },
                      icon: const Icon(Icons.sync_rounded),
                      label: const Text('تشغيل'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportLocalDatabase() async {
    setState(() => _databaseFileBusy = true);
    try {
      final savedPath = await ref
          .read(localDatabaseBackupServiceProvider)
          .exportDatabase();
      if (!mounted) return;

      final _ = savedPath == null
          ? 'تم إلغاء تصدير قاعدة البيانات'
          : 'تم تصدير قاعدة البيانات بنجاح';
      final displayMessage = savedPath == null
          ? 'تم إلغاء تصدير قاعدة البيانات'
          : 'تم حفظ نسخة قاعدة البيانات:\n$savedPath';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(displayMessage)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تصدير قاعدة البيانات: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _databaseFileBusy = false);
      }
    }
  }

  Future<void> _importLocalDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('استيراد قاعدة بيانات محلية'),
        content: const Text(
          'سيتم استبدال قاعدة البيانات المحلية الحالية بملف النسخة الاحتياطية. '
          'يفضل تصدير نسخة من البيانات الحالية قبل المتابعة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('متابعة الاستيراد'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _databaseFileBusy = true);
    try {
      final result = await ref
          .read(localDatabaseBackupServiceProvider)
          .importDatabase();
      if (!mounted) return;

      if (!result.imported) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إلغاء استيراد قاعدة البيانات')),
        );
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('تم الاستيراد'),
          content: Text(
            'تم استيراد ${result.importedName ?? 'ملف قاعدة البيانات'} بنجاح. '
            'أغلق التطبيق وافتحه من جديد حتى تقرأ كل الشاشات البيانات الجديدة.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('حسنًا'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ref.invalidate(appDatabaseProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر استيراد قاعدة البيانات: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _databaseFileBusy = false);
      }
    }
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.onHomePressed});

  final VoidCallback onHomePressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.settings_rounded,
              color: colorScheme.onPrimaryContainer,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الإعدادات',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'إدارة الجهاز والمزامنة وسجل التطبيق',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: onHomePressed,
              tooltip: 'العودة للرئيسية',
              icon: const Icon(Icons.home_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
