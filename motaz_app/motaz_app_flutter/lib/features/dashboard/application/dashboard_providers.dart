import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/database/enums/expense_category.dart';
import '../../party_balances/application/party_balance_providers.dart';
import '../../profit_distribution/application/profit_providers.dart';
import '../data/dashboard_queries.dart';

final dashboardQueriesProvider = Provider<DashboardQueries>((ref) {
  return DashboardQueries(
    ref.watch(appDatabaseProvider),
    ref.watch(profitEngineProvider),
    ref.watch(partyBalanceCalculatorProvider),
  );
});

final dashboardNetProfitProvider = FutureProvider<int>((ref) {
  return ref.watch(dashboardQueriesProvider).getThisMonthNetProfit();
});

final dashboardPartyBalancesProvider =
    FutureProvider<({int ownerBalance, int partnerBalance, int marginBalance})>(
        (ref) {
  return ref.watch(dashboardQueriesProvider).getPartyBalances();
});

final dashboardExpenseSummaryProvider =
    FutureProvider<Map<ExpenseCategory, int>>((ref) {
  return ref.watch(dashboardQueriesProvider).getThisMonthExpensesByCategory();
});
