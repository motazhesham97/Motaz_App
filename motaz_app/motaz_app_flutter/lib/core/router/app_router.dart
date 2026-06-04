import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/registration_screen.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/clients/presentation/client_list_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/expenses/presentation/expense_list_screen.dart';
import '../../features/free_samples/presentation/free_sample_form_screen.dart';
import '../../features/free_samples/presentation/free_sample_list_screen.dart';
import '../../features/follow_up/presentation/follow_up_tasks_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/invoices/presentation/invoice_list_screen.dart';
import '../../features/party_balances/presentation/party_balance_detail_screen.dart';
import '../../features/party_balances/presentation/party_balances_screen.dart';
import '../../features/profit_distribution/presentation/distribution_screen.dart';
import '../../features/products/presentation/product_list_screen.dart';
import '../../features/receipts/presentation/receipt_list_screen.dart';
import '../../features/reports/presentation/client_statement_screen.dart';
import '../../features/reports/presentation/client_reports_home_screen.dart';
import '../../features/reports/presentation/client_product_sales_report_screen.dart';
import '../../features/reports/presentation/client_receivables_report_screen.dart';
import '../../features/reports/presentation/expense_report_screen.dart';
import '../../features/reports/presentation/final_monthly_report_screen.dart';
import '../../features/reports/presentation/free_sample_report_screen.dart';
import '../../features/reports/presentation/profit_report_screen.dart';
import '../../features/reports/presentation/reports_home_screen.dart';
import '../../features/reports/presentation/sales_report_screen.dart';
import '../../features/returns/presentation/return_form_screen.dart';
import '../../features/returns/presentation/return_list_screen.dart';
import '../../features/settings/presentation/log_viewer_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/sync/presentation/conflict_resolution_screen.dart';
import '../auth/auth_provider.dart';
import '../auth/auth_state.dart';
import '../../shared/widgets/app_drawer.dart';
import '../database/enums/party_account.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authController = ref.watch(authControllerProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: authController,
    redirect: (context, state) {
      final authState = authController.state;
      final location = state.matchedLocation;

      if (authState is AuthInitial) {
        return location == '/splash' ? null : '/splash';
      }

      if (authState is AuthAuthenticated) {
        if (location == '/splash' ||
            location == '/register' ||
            location == '/sign-in') {
          return '/home';
        }
        return null;
      }

      if (authState is AuthUnauthenticated) {
        final target = authState.hasAccount ? '/sign-in' : '/register';
        return location == target ? null : target;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const _SplashScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegistrationScreen(),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/products',
            builder: (context, state) => const ProductListScreen(),
          ),
          GoRoute(
            path: '/clients',
            builder: (context, state) => const ClientListScreen(),
          ),
          GoRoute(
            path: '/invoices',
            builder: (context, state) => const InvoiceListScreen(),
          ),
          GoRoute(
            path: '/receipts',
            builder: (context, state) => const ReceiptListScreen(),
          ),
          GoRoute(
            path: '/expenses',
            builder: (context, state) => const ExpenseListScreen(),
          ),
          GoRoute(
            path: '/returns',
            builder: (context, state) => const ReturnListScreen(),
          ),
          GoRoute(
            path: '/free-samples',
            builder: (context, state) => const FreeSampleListScreen(),
          ),
          GoRoute(
            path: '/follow-up',
            builder: (context, state) => const FollowUpTasksScreen(),
          ),
          GoRoute(
            path: '/free-samples/create',
            builder: (context, state) => const FreeSampleFormScreen(),
          ),
          GoRoute(
            path: '/free-samples/:id/edit',
            builder: (context, state) => FreeSampleFormScreen(
              sampleId: state.pathParameters['id'],
            ),
          ),
          GoRoute(
            path: '/returns/create',
            builder: (context, state) {
              final invoiceId = state.uri.queryParameters['invoiceId'];
              return ReturnFormScreen(invoiceId: invoiceId);
            },
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsHomeScreen(),
          ),
          GoRoute(
            path: '/reports/sales',
            builder: (context, state) => const SalesReportScreen(),
          ),
          GoRoute(
            path: '/reports/profit',
            builder: (context, state) => const ProfitReportScreen(),
          ),
          GoRoute(
            path: '/reports/final',
            builder: (context, state) => const FinalMonthlyReportScreen(),
          ),
          GoRoute(
            path: '/reports/clients',
            builder: (context, state) => const ClientReportsHomeScreen(),
          ),
          GoRoute(
            path: '/reports/client-statement',
            builder: (context, state) => const ClientStatementScreen(),
          ),
          GoRoute(
            path: '/reports/client-receivables',
            builder: (context, state) => const ClientReceivablesReportScreen(),
          ),
          GoRoute(
            path: '/reports/client-products',
            builder: (context, state) => const ClientProductSalesReportScreen(),
          ),
          GoRoute(
            path: '/reports/expenses',
            builder: (context, state) => const ExpenseReportScreen(),
          ),
          GoRoute(
            path: '/reports/free-samples',
            builder: (context, state) => const FreeSampleReportScreen(),
          ),
          GoRoute(
            path: '/party-balances',
            builder: (context, state) => const PartyBalancesScreen(),
          ),
          GoRoute(
            path: '/party-balances/:party',
            builder: (context, state) => PartyBalanceDetailScreen(
              party: partyAccountFromRouteKey(
                state.pathParameters['party'] ?? 'owner',
              ),
            ),
          ),
          GoRoute(
            path: '/distributions',
            builder: (context, state) => const DistributionScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/settings/logs',
            builder: (context, state) => const LogViewerScreen(),
          ),
          GoRoute(
            path: '/sync/conflicts',
            builder: (context, state) => const ConflictResolutionScreen(),
          ),
        ],
      ),
    ],
  );
});

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
