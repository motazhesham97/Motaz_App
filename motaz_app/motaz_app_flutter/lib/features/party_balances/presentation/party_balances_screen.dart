import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_drawer.dart';
import '../application/party_balance_providers.dart';

class PartyBalancesScreen extends ConsumerWidget {
  const PartyBalancesScreen({super.key});

  String _formatMoney(int minorUnits) {
    return '\${(minorUnits / 100).toStringAsFixed(2)} ر.ي.';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balancesAsync = ref.watch(partyBalancesProvider);

    return AppDrawerScaffold(
      title: 'أرصدة الأطراف',
      currentRoute: '/party-balances',
      child: Scaffold(
        body: balancesAsync.when(
          data: (balances) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildBalanceCard(
                    context,
                    'رصيد المالك',
                    balances.ownerBalance,
                  ),
                  const SizedBox(height: 12),
                  _buildBalanceCard(
                    context,
                    'رصيد الشريك',
                    balances.partnerBalance,
                  ),
                  const SizedBox(height: 12),
                  _buildBalanceCard(
                    context,
                    'رصيد الهامش',
                    balances.marginBalance,
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('خطأ: \$e')),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(
    BuildContext context,
    String label,
    int amount,
  ) {
    final isNegative = amount < 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              _formatMoney(amount),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isNegative ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
