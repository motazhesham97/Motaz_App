import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/database/enums/party_account.dart';
import '../data/party_adjustment_repository.dart';
import '../data/party_balance_calculator.dart';
import '../data/party_balance_transaction.dart';

final partyBalanceCalculatorProvider = Provider<PartyBalanceCalculator>((ref) {
  return PartyBalanceCalculator(ref.watch(appDatabaseProvider));
});

final partyAdjustmentRepositoryProvider = Provider<PartyAdjustmentRepository>((
  ref,
) {
  return PartyAdjustmentRepository(ref.watch(appDatabaseProvider));
});

final partyBalancesProvider =
    FutureProvider<({int ownerBalance, int partnerBalance, int marginBalance})>(
      (ref) {
        return ref.watch(partyBalanceCalculatorProvider).computeAllBalances();
      },
    );

final partyBalanceProvider = FutureProvider.family<int, PartyAccount>((
  ref,
  party,
) {
  return ref.watch(partyBalanceCalculatorProvider).computeBalance(party);
});

final partyBalanceTransactionsProvider =
    FutureProvider.family<List<PartyBalanceTransaction>, PartyAccount>((
      ref,
      party,
    ) {
      return ref.watch(partyBalanceCalculatorProvider).getTransactions(party);
    });
