import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_drawer.dart';

class ClientReportsHomeScreen extends StatelessWidget {
  const ClientReportsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppDrawerScaffold(
      title: 'تقارير العملاء',
      currentRoute: '/reports',
      leading: IconButton(
        tooltip: 'الرجوع للتقارير',
        icon: const BackButtonIcon(),
        onPressed: () => context.go('/reports'),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _ClientReportTile(
            title: 'كشف حساب عميل',
            subtitle: 'حركات العميل ورصيده الافتتاحي والختامي خلال فترة محددة.',
            icon: Icons.account_balance_wallet_rounded,
            route: '/reports/client-statement',
          ),
          SizedBox(height: 12),
          _ClientReportTile(
            title: 'المبالغ المتبقية عند العملاء',
            subtitle: 'عرض أرصدة العملاء حسب الفترة مع بحث وتصدير PDF.',
            icon: Icons.pending_actions_rounded,
            route: '/reports/client-receivables',
          ),
          SizedBox(height: 12),
          _ClientReportTile(
            title: 'المنتجات المباعة لعميل',
            subtitle: 'إجمالي المنتجات والكميات والمبيعات لعميل محدد.',
            icon: Icons.inventory_2_rounded,
            route: '/reports/client-products',
          ),
        ],
      ),
    );
  }
}

class _ClientReportTile extends StatelessWidget {
  const _ClientReportTile({
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
