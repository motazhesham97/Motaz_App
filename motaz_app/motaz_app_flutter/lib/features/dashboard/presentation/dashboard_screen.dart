import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/enums/expense_category.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../expenses/presentation/expense_form_screen.dart'
    show categoryLabel;
import '../application/dashboard_providers.dart';
import '../data/dashboard_models.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _showNetProfit = false;

  @override
  Widget build(BuildContext context) {
    final todayNetSalesAsync = ref.watch(dashboardTodayNetSalesProvider);
    final thisMonthNetSalesAsync = ref.watch(
      dashboardThisMonthNetSalesProvider,
    );
    final netProfitAsync = ref.watch(dashboardNetProfitProvider);
    final receivablesAsync = ref.watch(dashboardReceivablesTotalProvider);
    final balancesAsync = ref.watch(dashboardPartyBalancesProvider);
    final expensesAsync = ref.watch(dashboardExpenseSummaryProvider);
    final activityAsync = ref.watch(dashboardActivityFeedProvider);

    return AppDrawerScaffold(
      title: 'لوحة التحكم',
      currentRoute: '/dashboard',
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 800;
            final crossAxisCount = isDesktop
                ? 4
                : (constraints.maxWidth > 600 ? 2 : 1);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'نظرة عامة',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Top KPIs
                  GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: isDesktop ? 1.8 : 2.5,
                    children: [
                      _buildKpiCard(
                        context,
                        'مبيعات اليوم',
                        todayNetSalesAsync,
                        Icons.point_of_sale_rounded,
                      ),
                      _buildKpiCard(
                        context,
                        'مبيعات الشهر',
                        thisMonthNetSalesAsync,
                        Icons.insert_chart_rounded,
                      ),
                      _buildKpiCard(
                        context,
                        'صافي ربح الشهر',
                        netProfitAsync,
                        Icons.trending_up_rounded,
                        highlight: true,
                        obscured: !_showNetProfit,
                        onToggleVisibility: () {
                          setState(() => _showNetProfit = !_showNetProfit);
                        },
                      ),
                      _buildKpiCard(
                        context,
                        'إجمالي المستحقات',
                        receivablesAsync,
                        Icons.account_balance_wallet_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Balances Row
                  const Text(
                    'أرصدة الأطراف',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildBalanceCard(
                        context,
                        'رصيد امي',
                        balancesAsync,
                        (b) => b.ownerBalance,
                        isDesktop,
                      ),
                      _buildBalanceCard(
                        context,
                        'رصيد معتز',
                        balancesAsync,
                        (b) => b.partnerBalance,
                        isDesktop,
                      ),
                      _buildBalanceCard(
                        context,
                        'رصيد الهامش',
                        balancesAsync,
                        (b) => b.marginBalance,
                        isDesktop,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Bottom section (Expenses and Activity)
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildExpenseSummaryCard(
                            context,
                            expensesAsync,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 4,
                          child: _buildActivityFeedCard(context, activityAsync),
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildExpenseSummaryCard(context, expensesAsync),
                        const SizedBox(height: 16),
                        _buildActivityFeedCard(context, activityAsync),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildKpiCard(
    BuildContext context,
    String label,
    AsyncValue<int> async,
    IconData icon, {
    bool highlight = false,
    bool obscured = false,
    VoidCallback? onToggleVisibility,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: highlight ? colorScheme.primary : colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: highlight
                          ? colorScheme.onPrimary.withValues(alpha: 0.9)
                          : colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onToggleVisibility != null) ...[
                  IconButton(
                    tooltip: obscured ? 'إظهار الرصيد' : 'إخفاء الرصيد',
                    onPressed: onToggleVisibility,
                    icon: Icon(
                      obscured
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                    ),
                    color: highlight
                        ? colorScheme.onPrimary
                        : colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                ],
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: highlight
                        ? Colors.white.withValues(alpha: 0.2)
                        : colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: highlight
                        ? colorScheme.onPrimary
                        : colorScheme.primary,
                  ),
                ),
              ],
            ),
            async.when(
              data: (value) => FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  obscured ? '*' : formatMoney(value),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: highlight
                        ? colorScheme.onPrimary
                        : (value < 0
                              ? const Color(0xFFEF4444)
                              : colorScheme.onSurface),
                  ),
                ),
              ),
              loading: () => const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (e, _) => Text(
                'خطأ',
                style: TextStyle(color: highlight ? Colors.white : Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(
    BuildContext context,
    String label,
    AsyncValue<({int ownerBalance, int partnerBalance, int marginBalance})>
    async,
    int Function(({int ownerBalance, int partnerBalance, int marginBalance}))
    selector,
    bool isDesktop,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: isDesktop ? 280 : double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.secondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.account_balance_rounded,
                    size: 20,
                    color: colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: async.when(
              data: (balances) {
                final amount = selector(balances);
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerEnd,
                  child: Text(
                    formatMoney(amount),
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: amount < 0
                          ? const Color(0xFFEF4444)
                          : colorScheme.onSurface,
                    ),
                  ),
                );
              },
              loading: () => const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (e, _) =>
                  const Text('خطأ', style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseSummaryCard(
    BuildContext context,
    AsyncValue<Map<ExpenseCategory, int>> async,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'مصروفات الشهر',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            async.when(
              data: (expenses) {
                final entries = expenses.entries.toList();
                int total = 0;
                for (final e in entries) {
                  total += e.value;
                }
                if (entries.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'لا توجد مصروفات',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    ...entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF8B97E),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  categoryLabel(e.key),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              formatMoney(e.value),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'الإجمالي',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          formatMoney(total),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Text('خطأ: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityFeedCard(
    BuildContext context,
    AsyncValue<List<ActivityFeedItem>> async,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الأنشطة الحديثة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            async.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'لا توجد أنشطة حديثة',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }
                final visibleItems = items.take(5).toList();
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visibleItems.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = visibleItems[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _activityIcon(item.type),
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        item.reference,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFFFFFF),
                        ),
                      ),
                      subtitle: Text(
                        '${item.timestamp.year}-${item.timestamp.month.toString().padLeft(2, '0')}-${item.timestamp.day.toString().padLeft(2, '0')} '
                        '${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFFFFFFF),
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.grey,
                        size: 20,
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Text('خطأ: $e'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _activityIcon(ActivityType type) {
    return switch (type) {
      ActivityType.invoice => Icons.receipt_long_rounded,
      ActivityType.receipt => Icons.payments_rounded,
      ActivityType.expense => Icons.money_off_rounded,
      ActivityType.returnItem => Icons.keyboard_return_rounded,
      ActivityType.voidAction => Icons.block_rounded,
    };
  }
}
