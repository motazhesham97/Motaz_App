import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../data/party_balance_calculator.dart';

final partyBalanceCalculatorProvider = Provider<PartyBalanceCalculator>((ref) {
  return PartyBalanceCalculator(ref.watch(appDatabaseProvider));
});

final partyBalancesProvider =
    FutureProvider<({int ownerBalance, int partnerBalance, int marginBalance})>(
        (ref) {
  return ref.watch(partyBalanceCalculatorProvider).computeAllBalances();
});
