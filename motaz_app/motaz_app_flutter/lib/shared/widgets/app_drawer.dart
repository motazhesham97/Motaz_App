import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/auth/auth_state.dart';
import '../../features/sync/presentation/sync_status_badge.dart';
import 'connectivity_badge.dart';

class AppDestination {
  const AppDestination({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

const appDestinations = [
  AppDestination(label: 'الرئيسية', icon: Icons.home_rounded, route: '/home'),
  AppDestination(label: 'لوحة التحكم', icon: Icons.dashboard_rounded, route: '/dashboard'),
  AppDestination(label: 'المنتجات', icon: Icons.inventory_2_rounded, route: '/products'),
  AppDestination(label: 'العملاء', icon: Icons.people_alt_rounded, route: '/clients'),
  AppDestination(label: 'الفواتير', icon: Icons.receipt_long_rounded, route: '/invoices'),
  AppDestination(label: 'المبالغ المستلمة', icon: Icons.payments_rounded, route: '/receipts'),
  AppDestination(label: 'المصروفات', icon: Icons.account_balance_wallet_rounded, route: '/expenses'),
  AppDestination(label: 'المرتجعات', icon: Icons.assignment_return_rounded, route: '/returns'),
  AppDestination(label: 'التقارير', icon: Icons.bar_chart_rounded, route: '/reports'),
  AppDestination(label: 'أرصدة الأطراف', icon: Icons.balance_rounded, route: '/party-balances'),
  AppDestination(label: 'توزيع الأرباح', icon: Icons.pie_chart_rounded, route: '/distributions'),
  AppDestination(label: 'الإعدادات', icon: Icons.settings_rounded, route: '/settings'),
];

class AppDrawerScaffold extends ConsumerWidget {
  const AppDrawerScaffold({
    super.key,
    required this.title,
    required this.currentRoute,
    required this.child,
  });

  final String title;
  final String currentRoute;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 840;
    final drawer = _DrawerContent(currentRoute: currentRoute);

    if (isDesktop) {
      return Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: const [
            Padding(
              padding: EdgeInsetsDirectional.only(end: 8),
              child: Center(child: SyncStatusBadge()),
            ),
            Padding(
              padding: EdgeInsetsDirectional.only(end: 16),
              child: Center(child: ConnectivityBadge()),
            ),
          ],
        ),
        body: Row(
          children: [
            SizedBox(width: 280, child: Material(color: Theme.of(context).colorScheme.surfaceContainerHighest, child: drawer)),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: const [
          Padding(
            padding: EdgeInsetsDirectional.only(end: 16),
            child: Center(child: ConnectivityBadge()),
          ),
        ],
      ),
      drawer: Drawer(child: drawer),
      body: child,
    );
  }
}

class _DrawerContent extends ConsumerWidget {
  const _DrawerContent({required this.currentRoute});

  final String currentRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authController = ref.watch(authControllerProvider);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('تطبيق معتز', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                if (authController.state case AuthAuthenticated(:final email))
                  Text(email, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final destination in appDestinations)
                  ListTile(
                    leading: Icon(destination.icon),
                    title: Text(destination.label),
                    selected: currentRoute == destination.route,
                    onTap: () {
                      context.go(destination.route);
                      if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: const Text('تسجيل الخروج'),
            onTap: () async {
              await ref.read(authControllerProvider).signOut();
              if (context.mounted) {
                context.go('/sign-in');
              }
            },
          ),
        ],
      ),
    );
  }
}
