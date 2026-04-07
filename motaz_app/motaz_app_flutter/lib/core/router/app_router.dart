import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/registration_screen.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/clients/presentation/client_list_screen.dart';
import '../../features/dashboard/presentation/placeholder_screen.dart';
import '../../features/expenses/presentation/placeholder_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/invoices/presentation/invoice_list_screen.dart';
import '../../features/party_balances/presentation/placeholder_screen.dart';
import '../../features/products/presentation/product_list_screen.dart';
import '../../features/receipts/presentation/receipt_list_screen.dart';
import '../../features/reports/presentation/placeholder_screen.dart';
import '../../features/returns/presentation/placeholder_screen.dart';
import '../../features/settings/presentation/placeholder_screen.dart';
import '../auth/auth_provider.dart';
import '../auth/auth_state.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authController = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authController,
    redirect: (context, state) {
      final authState = authController.state;
      final location = state.matchedLocation;

      if (authState is AuthInitial) {
        return location == '/splash' ? null : '/splash';
      }

      if (authState is AuthAuthenticated) {
        if (location == '/splash' || location == '/register' || location == '/sign-in') {
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
      GoRoute(path: '/splash', builder: (context, state) => const _SplashScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegistrationScreen()),
      GoRoute(path: '/sign-in', builder: (context, state) => const SignInScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/dashboard', builder: (context, state) => const DashboardPlaceholderScreen()),
      GoRoute(path: '/products', builder: (context, state) => const ProductListScreen()),
      GoRoute(path: '/clients', builder: (context, state) => const ClientListScreen()),
      GoRoute(path: '/invoices', builder: (context, state) => const InvoiceListScreen()),
      GoRoute(path: '/receipts', builder: (context, state) => const ReceiptListScreen()),
      GoRoute(path: '/expenses', builder: (context, state) => const ExpensesPlaceholderScreen()),
      GoRoute(path: '/returns', builder: (context, state) => const ReturnsPlaceholderScreen()),
      GoRoute(path: '/reports', builder: (context, state) => const ReportsPlaceholderScreen()),
      GoRoute(path: '/party-balances', builder: (context, state) => const PartyBalancesPlaceholderScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsPlaceholderScreen()),
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
