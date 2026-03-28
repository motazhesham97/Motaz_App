import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_provider.dart';
import '../auth/auth_state.dart';
import '../../features/auth/presentation/registration_screen.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/products/presentation/products_screen.dart';
import '../../features/clients/presentation/clients_screen.dart';
import '../../features/invoices/presentation/invoices_screen.dart';
import '../../features/receipts/presentation/receipts_screen.dart';
import '../../features/expenses/presentation/expenses_screen.dart';
import '../../features/returns/presentation/returns_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/party_balances/presentation/party_balances_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  const authRoutes = {'/registration', '/sign-in'};

  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const _AuthLoadingScreen(),
      ),
      GoRoute(
        path: '/registration',
        builder: (context, state) => const RegistrationScreen(),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
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
        builder: (context, state) => const ProductsScreen(),
      ),
      GoRoute(
        path: '/clients',
        builder: (context, state) => const ClientsScreen(),
      ),
      GoRoute(
        path: '/invoices',
        builder: (context, state) => const InvoicesScreen(),
      ),
      GoRoute(
        path: '/receipts',
        builder: (context, state) => const ReceiptsScreen(),
      ),
      GoRoute(
        path: '/expenses',
        builder: (context, state) => const ExpensesScreen(),
      ),
      GoRoute(
        path: '/returns',
        builder: (context, state) => const ReturnsScreen(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/party-balances',
        builder: (context, state) => const PartyBalancesScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    redirect: (context, state) {
      if (authState is AuthInitial) {
        return null;
      }

      if (authState is Authenticated) {
        if (!authRoutes.contains(state.matchedLocation) &&
            state.matchedLocation != '/') {
          return null;
        }
        return '/home';
      }

      final unauthenticatedState = authState as Unauthenticated;
      final targetRoute = unauthenticatedState.hasAccount
          ? '/sign-in'
          : '/registration';

      if (state.matchedLocation == targetRoute) {
        return null;
      }

      return targetRoute;
    },
  );
});

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
