import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/enums/party_account.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../application/party_balance_providers.dart';

class PartyBalancesScreen extends ConsumerWidget {
  const PartyBalancesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balancesAsync = ref.watch(partyBalancesProvider);

    return AppDrawerScaffold(
      title: 'أرصدة الأطراف',
      currentRoute: '/party-balances',
      child: Scaffold(
        body: balancesAsync.when(
          data: (balances) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildBalanceCard(
                  context,
                  PartyAccount.OWNER,
                  balances.ownerBalance,
                  Icons.person_rounded,
                ),
                const SizedBox(height: 12),
                _buildBalanceCard(
                  context,
                  PartyAccount.PARTNER,
                  balances.partnerBalance,
                  Icons.handshake_rounded,
                ),
                const SizedBox(height: 12),
                _buildBalanceCard(
                  context,
                  PartyAccount.MARGIN,
                  balances.marginBalance,
                  Icons.percent_rounded,
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('خطأ: $e')),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(
    BuildContext context,
    PartyAccount party,
    int amount,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isNegative = amount < 0;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.go('/party-balances/${party.routeKey}'),
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
                child: Text(
                  party.balanceTitle,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFFFFFFFF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                formatMoney(amount),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: isNegative ? colorScheme.error : colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
