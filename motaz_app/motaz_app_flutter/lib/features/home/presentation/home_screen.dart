import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/device_provider.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../dashboard/application/dashboard_providers.dart';
import '../../sync/application/sync_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref.watch(currentDeviceProvider);
    final headerDeviceName = device.when(
      data: (value) {
        final name = value?.deviceName.trim() ?? '';
        return name.isEmpty ? 'جهاز غير معروف' : name;
      },
      loading: () => 'جاري قراءة اسم الجهاز...',
      error: (_, _) => 'جهاز غير معروف',
    );
    final todaySales = ref.watch(dashboardTodayNetSalesProvider);
    final monthSales = ref.watch(dashboardThisMonthNetSalesProvider);
    final receivables = ref.watch(dashboardReceivablesTotalProvider);
    final pending = ref.watch(pendingCountProvider);
    final failed = ref.watch(failedOutboxCountProvider);
    final conflicts = ref.watch(unresolvedConflictCountProvider);

    return AppDrawerScaffold(
      title: 'الرئيسية',
      currentRoute: '/home',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeaderCard(deviceName: headerDeviceName),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900 ? 3 : 1;
              return _ResponsiveGrid(
                columns: columns,
                spacing: 12,
                children: [
                  _MetricCard(
                    title: 'مبيعات اليوم',
                    icon: Icons.point_of_sale_rounded,
                    asyncValue: todaySales,
                  ),
                  _MetricCard(
                    title: 'مبيعات الشهر',
                    icon: Icons.calendar_month_rounded,
                    asyncValue: monthSales,
                  ),
                  _MetricCard(
                    title: 'المستحقات',
                    icon: Icons.account_balance_wallet_rounded,
                    asyncValue: receivables,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          _SyncOverviewCard(
            pending: pending.asData?.value ?? 0,
            failed: failed.asData?.value ?? 0,
            conflicts: conflicts.asData?.value ?? 0,
          ),
          const SizedBox(height: 16),
          Text('إجراءات سريعة', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 980
                  ? 4
                  : constraints.maxWidth >= 640
                  ? 2
                  : 1;
              return _ResponsiveGrid(
                columns: columns,
                spacing: 12,
                children: const [
                  _QuickActionCard(
                    title: 'منتج جديد',
                    subtitle: 'إضافة صنف للبيع',
                    icon: Icons.add_box_rounded,
                    route: '/products',
                  ),
                  _QuickActionCard(
                    title: 'فاتورة',
                    subtitle: 'فتح قسم الفواتير',
                    icon: Icons.receipt_long_rounded,
                    route: '/invoices',
                  ),
                  _QuickActionCard(
                    title: 'مبلغ مستلم',
                    subtitle: 'تسجيل دفعة عميل',
                    icon: Icons.payments_rounded,
                    route: '/receipts',
                  ),
                  _QuickActionCard(
                    title: 'التقارير',
                    subtitle: 'مبيعات وأرباح وكشوفات',
                    icon: Icons.bar_chart_rounded,
                    route: '/reports',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.deviceName});

  final String? deviceName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final cleanDeviceName = deviceName?.trim();

    Widget iconBox() {
      return Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.store_mall_directory_rounded,
          color: colorScheme.onSecondaryContainer,
        ),
      );
    }

    Widget textBlock({required bool compact}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'مرحباً بك',
            maxLines: compact ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ابدأ من الإجراءات السريعة أو راجع مؤشرات اليوم قبل العمل.',
            maxLines: compact ? 3 : 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    Widget? deviceChip() {
      if (cleanDeviceName == null || cleanDeviceName.isEmpty) return null;
      return Tooltip(
        message: cleanDeviceName,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Chip(
            avatar: const Icon(Icons.devices_rounded, size: 18),
            label: Text(
              cleanDeviceName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 560;
            final chip = deviceChip();

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  textBlock(compact: true),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (chip != null)
                        Expanded(
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: chip,
                          ),
                        )
                      else
                        const Spacer(),
                      const SizedBox(width: 12),
                      iconBox(),
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                iconBox(),
                const SizedBox(width: 16),
                Expanded(child: textBlock(compact: false)),
                if (chip != null) ...[
                  const SizedBox(width: 12),
                  chip,
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.icon,
    required this.asyncValue,
  });

  final String title;
  final IconData icon;
  final AsyncValue<int> asyncValue;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  asyncValue.when(
                    data: (value) => Text(
                      formatMoney(value),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: value < 0
                            ? colorScheme.error
                            : colorScheme.onSurface,
                      ),
                    ),
                    loading: () => const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (_, _) => Text(
                      'غير متاح',
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncOverviewCard extends StatelessWidget {
  const _SyncOverviewCard({
    required this.pending,
    required this.failed,
    required this.conflicts,
  });

  final int pending;
  final int failed;
  final int conflicts;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final needsAttention = pending > 0 || failed > 0 || conflicts > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              needsAttention
                  ? Icons.sync_problem_rounded
                  : Icons.cloud_done_rounded,
              color: needsAttention
                  ? colorScheme.tertiary
                  : colorScheme.secondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    needsAttention
                        ? 'المزامنة تحتاج متابعة'
                        : 'المزامنة مستقرة',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatusChip(label: 'معلقة', value: pending),
                      _StatusChip(label: 'فاشلة', value: failed),
                      _StatusChip(label: 'تعارضات', value: conflicts),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.go(route),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({
    required this.columns,
    required this.spacing,
    required this.children,
  });

  final int columns;
  final double spacing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        for (final child in children)
          SizedBox(
            width: _itemWidth(context),
            child: child,
          ),
      ],
    );
  }

  double _itemWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final drawerAdjustedWidth = width >= 840 ? width - 332 : width - 32;
    return (drawerAdjustedWidth - (spacing * (columns - 1))) / columns;
  }
}
