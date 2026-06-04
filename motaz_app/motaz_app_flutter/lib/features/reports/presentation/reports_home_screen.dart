import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_drawer.dart';

class ReportsHomeScreen extends StatelessWidget {
  const ReportsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppDrawerScaffold(
      title: 'التقارير',
      currentRoute: '/reports',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _ReportTile(
            title: 'العملاء',
            subtitle: 'كشف حساب، مبالغ متبقية، ومنتجات مباعة لكل عميل.',
            icon: Icons.groups_rounded,
            route: '/reports/clients',
          ),
          SizedBox(height: 12),
          _ReportTile(
            title: 'تقرير المبيعات',
            subtitle: 'إجمالي المبيعات والخصومات والمرتجعات وصافي المبيعات.',
            icon: Icons.receipt_long_rounded,
            route: '/reports/sales',
          ),
          SizedBox(height: 12),
          _ReportTile(
            title: 'تقرير الأرباح',
            subtitle: 'صافي الربح مع المصروفات وتوزيع الأرباح عند توفره.',
            icon: Icons.trending_up_rounded,
            route: '/reports/profit',
          ),
          SizedBox(height: 12),
          _ReportTile(
            title: 'التقرير النهائي',
            subtitle:
                'حصر شهري للتكلفة والمبيعات والأرباح والسلف والسحبيات مع تصدير PDF مباشر.',
            icon: Icons.summarize_rounded,
            route: '/reports/final',
          ),
          SizedBox(height: 12),
          _ReportTile(
            title: 'كشف المصروفات',
            subtitle: 'فلترة المصروفات حسب الفترة والتصنيف مع تصدير PDF.',
            icon: Icons.account_balance_wallet_rounded,
            route: '/reports/expenses',
          ),
          SizedBox(height: 12),
          _ReportTile(
            title: 'تقرير العينات المجانية',
            subtitle: 'فلترة العينات حسب المستفيد أو الفترة مع تصدير PDF.',
            icon: Icons.card_giftcard_rounded,
            route: '/reports/free-samples',
          ),
        ],
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({
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
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.go(route),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
