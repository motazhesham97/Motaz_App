import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/core/connectivity/connectivity_provider.dart';
import 'package:motaz_app_flutter/core/database/enums/expense_category.dart';
import 'package:motaz_app_flutter/core/utils/money_formatter.dart';
import 'package:motaz_app_flutter/features/dashboard/application/dashboard_providers.dart';
import 'package:motaz_app_flutter/features/dashboard/data/dashboard_models.dart';
import 'package:motaz_app_flutter/features/dashboard/presentation/dashboard_screen.dart';
import 'package:motaz_app_flutter/features/sync/application/sync_providers.dart';
import 'package:motaz_app_flutter/features/sync/domain/sync_state.dart';
import 'package:motaz_app_flutter/features/profit_distribution/domain/monthly_profit.dart';

void main() {
  testWidgets('net profit starts obscured with five stars', (tester) async {
    const netProfit = 1250000;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardTodayNetSalesProvider.overrideWith((ref) async => 0),
          dashboardThisMonthNetSalesProvider.overrideWith((ref) async => 0),
          dashboardNetProfitProvider.overrideWith((ref) async => netProfit),
          dashboardMonthlySettlementProvider.overrideWith(
            (ref) async => (
              profit: MonthlyProfit(
                year: 2026,
                month: 1,
                netSales: netProfit,
                operationalExpenses: 0,
                productionExpenses: 0,
                carriedLossIn: 0,
              ),
              recorded: null,
              needsReview: false,
            ),
          ),
          dashboardReceivablesTotalProvider.overrideWith((ref) async => 0),
          dashboardPartyBalancesProvider.overrideWith(
            (ref) async => (
              ownerBalance: 0,
              partnerBalance: 0,
              marginBalance: 0,
            ),
          ),
          dashboardExpenseSummaryProvider.overrideWith(
            (ref) async => const <ExpenseCategory, int>{},
          ),
          dashboardActivityFeedProvider.overrideWith(
            (ref) async => const <ActivityFeedItem>[],
          ),
          syncStateProvider.overrideWith(
            (ref) => Stream.value(const SyncState(status: SyncPhase.idle)),
          ),
          pendingCountProvider.overrideWith((ref) => Stream.value(0)),
          failedOutboxCountProvider.overrideWith((ref) => Stream.value(0)),
          unresolvedConflictCountProvider.overrideWith(
            (ref) => Stream.value(0),
          ),
          connectivityProvider.overrideWith(
            (ref) => Stream.value(ConnectivityStatus.online),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: DashboardScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(dashboardObscuredMoneyText), findsNWidgets(3));
    expect(find.text('*'), findsNothing);
    expect(find.text(formatMoney(netProfit)), findsNothing);

    await tester.tap(find.byTooltip('إظهار الرصيد'));
    await tester.pumpAndSettle();

    expect(find.text(dashboardObscuredMoneyText), findsNothing);
    expect(find.text(formatMoney(netProfit)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
