import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/enums/expense_category.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../expenses/presentation/expense_form_screen.dart' show categoryLabel;
import '../application/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _formatMoney(int minorUnits) {
    return '\${(minorUnits / 100).toStringAsFixed(2)} ر.ي.';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final netProfitAsync = ref.watch(dashboardNetProfitProvider);
    final balancesAsync = ref.watch(dashboardPartyBalancesProvider);
    final expensesAsync = ref.watch(dashboardExpenseSummaryProvider);

    return AppDrawerScaffold(
      title: 'لوحة التحكم',
      currentRoute: '/dashboard',
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildNetProfitCard(context, netProfitAsync),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNetProfitCard(BuildContext context, AsyncValue<int> async) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'صافي ربح الشهر الحالي',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            async.when(
              data: (profit) => Text(
                _formatMoney(profit),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: profit < 0 ? Colors.red : Colors.green,
                ),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('خطأ: \$e'),
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
                  _formatMoney(amount),
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
                              Text(_formatMoney(e.value)),
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
                          _formatMoney(total),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('خطأ: \$e'),
            ),
          ],
        ),
      ),
    );
  }
}
