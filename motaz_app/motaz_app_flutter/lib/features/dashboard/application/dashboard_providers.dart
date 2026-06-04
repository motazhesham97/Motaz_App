import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/database/enums/expense_category.dart';
import '../../party_balances/application/party_balance_providers.dart';
import '../../profit_distribution/application/profit_providers.dart';
import '../data/dashboard_models.dart';
import '../data/dashboard_queries.dart';

final dashboardQueriesProvider = Provider<DashboardQueries>((ref) {
  return DashboardQueries(
    ref.watch(appDatabaseProvider),
    ref.watch(profitEngineProvider),
    ref.watch(partyBalanceCalculatorProvider),
  );
});

final dashboardRefreshProvider = StreamProvider<int>((ref) {
  final db = ref.watch(appDatabaseProvider);
  var tick = 0;
  return db
      .customSelect(
        'SELECT 1 AS tick',
        readsFrom: {
          db.salesInvoices,
          db.salesInvoiceLines,
          db.receipts,
          db.receiptAllocations,
          db.salesReturns,
          db.expenses,
          db.monthlyDistributions,
        },
      )
      .watch()
      .map((_) => tick++);
});

final dashboardNetProfitProvider = FutureProvider<int>((ref) {
  ref.watch(dashboardRefreshProvider);
  return ref.watch(dashboardQueriesProvider).getThisMonthNetProfit();
});

final dashboardPartyBalancesProvider =
    FutureProvider<({int ownerBalance, int partnerBalance, int marginBalance})>(
      (ref) {
        ref.watch(dashboardRefreshProvider);
        return ref.watch(dashboardQueriesProvider).getPartyBalances();
      },
    );

final dashboardExpenseSummaryProvider =
    FutureProvider<Map<ExpenseCategory, int>>((ref) {
      ref.watch(dashboardRefreshProvider);
      return ref
          .watch(dashboardQueriesProvider)
          .getThisMonthExpensesByCategory();
    });

final dashboardTodayNetSalesProvider = FutureProvider<int>((ref) {
  ref.watch(dashboardRefreshProvider);
  return ref.watch(dashboardQueriesProvider).getTodayNetSales();
});

final dashboardThisMonthNetSalesProvider = FutureProvider<int>((ref) {
  ref.watch(dashboardRefreshProvider);
  return ref.watch(dashboardQueriesProvider).getThisMonthNetSales();
});

final dashboardReceivablesTotalProvider = FutureProvider<int>((ref) {
  ref.watch(dashboardRefreshProvider);
  return ref.watch(dashboardQueriesProvider).getOutstandingReceivablesTotal();
});

final dashboardActivityFeedProvider = FutureProvider<List<ActivityFeedItem>>((
  ref,
) {
  ref.watch(dashboardRefreshProvider);
  return ref.watch(dashboardQueriesProvider).getRecentActivityFeed();
});
