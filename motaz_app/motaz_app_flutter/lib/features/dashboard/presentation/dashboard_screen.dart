import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/enums/expense_category.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../expenses/presentation/expense_form_screen.dart' show categoryLabel;
import '../application/dashboard_providers.dart';
import '../data/dashboard_models.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayNetSalesAsync = ref.watch(dashboardTodayNetSalesProvider);
    final thisMonthNetSalesAsync = ref.watch(dashboardThisMonthNetSalesProvider);
    final netProfitAsync = ref.watch(dashboardNetProfitProvider);
    final receivablesAsync = ref.watch(dashboardReceivablesTotalProvider);
    final balancesAsync = ref.watch(dashboardPartyBalancesProvider);
    final expensesAsync = ref.watch(dashboardExpenseSummaryProvider);
    final activityAsync = ref.watch(dashboardActivityFeedProvider);

    return AppDrawerScaffold(
      title: 'لوحة التحكم',
      currentRoute: '/dashboard',
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMonetaryCard('مبيعات اليوم', todayNetSalesAsync),
              const SizedBox(height: 12),
              _buildMonetaryCard('مبيعات الشهر', thisMonthNetSalesAsync),
              const SizedBox(height: 12),
              _buildMonetaryCard('صافي ربح الشهر الحالي', netProfitAsync),
              const SizedBox(height: 12),
              _buildMonetaryCard('إجمالي المستحقات', receivablesAsync),
              const SizedBox(height: 12),
              _buildBalanceCard(
                context,
                'رصيد المالك',
                balancesAsync,
                (b) => b.ownerBalance,
              ),
              const SizedBox(height: 12),
              _buildBalanceCard(
                context,
                'رصيد الشريك',
                balancesAsync,
                (b) => b.partnerBalance,
              ),
              const SizedBox(height: 12),
              _buildBalanceCard(
                context,
                'رصيد الهامش',
                balancesAsync,
                (b) => b.marginBalance,
              ),
              const SizedBox(height: 12),
              _buildExpenseSummaryCard(context, expensesAsync),
              const SizedBox(height: 12),
              _buildActivityFeedCard(context, activityAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonetaryCard(String label, AsyncValue<int> async) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            async.when(
              data: (value) => Text(
                formatMoney(value),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: value < 0 ? Colors.red : Colors.green,
                ),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('خطأ: $e'),
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
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            async.when(
              data: (balances) {
                final amount = selector(balances);
                return Text(
                  formatMoney(amount),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: amount < 0 ? Colors.red : Colors.green,
                  ),
                );
              },
              loading: () => const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (e, _) => Text('خطأ'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseSummaryCard(
    BuildContext context,
    AsyncValue<Map<ExpenseCategory, int>> async,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ملخص مصروفات الشهر',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            async.when(
              data: (expenses) {
                final entries = expenses.entries.toList();
                int total = 0;
                for (final e in entries) {
                  total += e.value;
                }
                return Column(
                  children: [
                    ...entries.map((e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(categoryLabel(e.key)),
                              Text(formatMoney(e.value)),
                            ],
                          ),
                        )),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'الإجمالي',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          formatMoney(total),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الأنشطة الحديثة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            async.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Text(
                    'لا توجد أنشطة حديثة',
                    style: TextStyle(color: Colors.grey),
                  );
                }
                return Column(
                  children: items.map((item) {
                    return ListTile(
                      leading: Icon(_activityIcon(item.type)),
                      title: Text(item.reference),
                      subtitle: Text(
                        '${item.timestamp.year}-${item.timestamp.month.toString().padLeft(2, '0')}-${item.timestamp.day.toString().padLeft(2, '0')} '
                        '${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')}',
                      ),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('خطأ: $e'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _activityIcon(ActivityType type) {
    return switch (type) {
      ActivityType.invoice => Icons.receipt_long,
      ActivityType.receipt => Icons.payment,
      ActivityType.expense => Icons.money_off,
      ActivityType.returnItem => Icons.keyboard_return,
      ActivityType.voidAction => Icons.block,
    };
  }
}