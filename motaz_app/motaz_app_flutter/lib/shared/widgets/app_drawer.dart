import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/auth/auth_state.dart';
import '../../features/follow_up/application/follow_up_providers.dart';
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
  AppDestination(
    label: 'لوحة التحكم',
    icon: Icons.dashboard_rounded,
    route: '/dashboard',
  ),
  AppDestination(
    label: 'مهام المتابعة',
    icon: Icons.task_alt_rounded,
    route: '/follow-up',
  ),
  AppDestination(
    label: 'المنتجات',
    icon: Icons.inventory_2_rounded,
    route: '/products',
  ),
  AppDestination(
    label: 'العملاء',
    icon: Icons.people_alt_rounded,
    route: '/clients',
  ),
  AppDestination(
    label: 'الفواتير',
    icon: Icons.receipt_long_rounded,
    route: '/invoices',
  ),
  AppDestination(
    label: 'المبالغ المستلمة',
    icon: Icons.payments_rounded,
    route: '/receipts',
  ),
  AppDestination(
    label: 'المصروفات',
    icon: Icons.account_balance_wallet_rounded,
    route: '/expenses',
  ),
  AppDestination(
    label: 'المرتجعات',
    icon: Icons.assignment_return_rounded,
    route: '/returns',
  ),
  AppDestination(
    label: 'العينات المجانية',
    icon: Icons.card_giftcard_rounded,
    route: '/free-samples',
  ),
  AppDestination(
    label: 'التقارير',
    icon: Icons.bar_chart_rounded,
    route: '/reports',
  ),
  AppDestination(
    label: 'أرصدة الأطراف',
    icon: Icons.balance_rounded,
    route: '/party-balances',
  ),
  AppDestination(
    label: 'توزيع الأرباح',
    icon: Icons.pie_chart_rounded,
    route: '/distributions',
  ),
  AppDestination(
    label: 'الإعدادات',
    icon: Icons.settings_rounded,
    route: '/settings',
  ),
];

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 840;
    final currentRoute = GoRouterState.of(context).uri.path;
    final drawer = _DrawerContent(currentRoute: currentRoute);

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            Container(
              width: 280,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  left: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    width: 1.5,
                  ),
                ),
              ),
              child: drawer,
            ),
            Expanded(
              child: ClipRRect(
                child: child,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      drawer: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
        ),
        child: drawer,
      ),
      body: child,
    );
  }
}

class AppDrawerScaffold extends StatelessWidget {
  const AppDrawerScaffold({
    super.key,
    required this.title,
    required this.currentRoute,
    required this.child,
    this.leading,
  });

  final String title;
  final String currentRoute;
  final Widget child;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 840;

    return Scaffold(
      appBar: AppBar(
        leading:
            leading ??
            (!isDesktop
                ? Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () {
                        context
                            .findRootAncestorStateOfType<ScaffoldState>()
                            ?.openDrawer();
                      },
                    ),
                  )
                : null),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
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
    final followUpTaskCount =
        ref.watch(followUpTasksProvider).asData?.value.length ?? 0;

    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.2),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/images/LOGO.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FASTIKA',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (authController.state case AuthAuthenticated(
                        :final email,
                      ))
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(
              color: Theme.of(context).colorScheme.outlineVariant,
              height: 1,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: appDestinations.length,
              itemBuilder: (context, index) {
                final destination = appDestinations[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _DrawerTile(
                    destination: destination,
                    selected:
                        currentRoute == destination.route ||
                        currentRoute.startsWith('${destination.route}/'),
                    badgeCount: destination.route == '/follow-up'
                        ? followUpTaskCount
                        : 0,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(
              color: Theme.of(context).colorScheme.outlineVariant,
              height: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              leading: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFEF4444),
              ),
              title: const Text(
                'تسجيل الخروج',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('تأكيد تسجيل الخروج'),
                    content: const Text('هل تريد تسجيل الخروج من التطبيق؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: const Text('إلغاء'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: const Text('تأكيد'),
                      ),
                    ],
                  ),
                );
                if (confirmed != true || !context.mounted) return;
                await ref.read(authControllerProvider).signOut();
                if (context.mounted) {
                  context.go('/sign-in');
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatefulWidget {
  const _DrawerTile({
    required this.destination,
    required this.selected,
    this.badgeCount = 0,
  });

  final AppDestination destination;
  final bool selected;
  final int badgeCount;

  @override
  State<_DrawerTile> createState() => _DrawerTileState();
}

class _DrawerTileState extends State<_DrawerTile> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // We use the secondary color for selected indicator (#F8B97E)
    // Primary color for background of selected item (#657F66)

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: () {
          context.go(widget.destination.route);
          if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
            Navigator.of(context).pop();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: widget.selected
                ? colorScheme.primary.withValues(alpha: 0.15)
                : (_isHovering
                      ? colorScheme.surfaceContainerHighest
                      : Colors.transparent),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.selected
                  ? colorScheme.primary.withValues(alpha: 0.5)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    widget.destination.icon,
                    color: widget.selected
                        ? colorScheme.secondary
                        : colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                  if (widget.badgeCount > 0)
                    PositionedDirectional(
                      top: -4,
                      end: -4,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.surface,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.destination.label,
                  style: TextStyle(
                    color: widget.selected
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                    fontWeight: widget.selected
                        ? FontWeight.w800
                        : FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              if (widget.selected)
                Icon(
                  Icons.chevron_left_rounded,
                  size: 20,
                  color: colorScheme.secondary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
