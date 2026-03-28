import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/auth/auth_state.dart';
import '../widgets/connectivity_badge.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key, this.isDesktop = false});

  final bool isDesktop;

  static const _sections = [
    (icon: Icons.dashboard, label: 'لوحة التحكم', route: '/dashboard'),
    (icon: Icons.inventory_2, label: 'المنتجات', route: '/products'),
    (icon: Icons.people, label: 'العملاء', route: '/clients'),
    (icon: Icons.receipt_long, label: 'الفواتير', route: '/invoices'),
    (icon: Icons.receipt, label: 'الإيصالات', route: '/receipts'),
    (icon: Icons.money_off, label: 'المصروفات', route: '/expenses'),
    (icon: Icons.assignment_return, label: 'المرتجعات', route: '/returns'),
    (icon: Icons.assessment, label: 'التقارير', route: '/reports'),
    (icon: Icons.balance, label: 'أرصدة الأطراف', route: '/party-balances'),
    (icon: Icons.settings, label: 'الإعدادات', route: '/settings'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState is Authenticated ? authState : null;
    final theme = Theme.of(context);
    final currentRoute = GoRouterState.of(context).matchedLocation;

    final drawerContent = Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تطبيق معتز',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'مرحباً بك',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                const ConnectivityBadge(),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              for (final section in _sections)
                ListTile(
                  leading: Icon(section.icon),
                  title: Text(section.label),
                  subtitle: const Text('قريباً'),
                  selected: currentRoute == section.route,
                  onTap: () {
                    if (!isDesktop) {
                      Navigator.of(context).pop();
                    }
                    context.go(section.route);
                  },
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('تسجيل الخروج'),
                onTap: () async {
                  if (!isDesktop) {
                    Navigator.of(context).pop();
                  }
                  await ref.read(authProvider.notifier).signOut();
                },
              ),
            ],
          ),
        ),
      ],
    );

    if (isDesktop) {
      return Material(
        color: theme.drawerTheme.backgroundColor ?? theme.colorScheme.surface,
        child: drawerContent,
      );
    }

    return Drawer(
      child: drawerContent,
    );
  }
}
