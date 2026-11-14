import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/core/auth/auth_provider.dart';
import 'package:motaz_app_flutter/core/auth/auth_state.dart';
import 'package:motaz_app_flutter/core/router/app_router.dart';

void main() {
  testWidgets('auth background refresh keeps the router and current route', (
    tester,
  ) async {
    final auth = _TestAuthController();
    final container = ProviderContainer(
      overrides: [authControllerProvider.overrideWith((ref) => auth)],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    final dispatcher = container.read(appBackButtonDispatcherProvider);
    final uri = Uri.parse('/reports/final?year=2026&month=8');
    await router.routerDelegate.setNewRoutePath(
      router.configuration.findMatch(uri),
    );

    auth.refresh();
    await container.pump();

    expect(container.read(appRouterProvider), same(router));
    expect(container.read(appBackButtonDispatcherProvider), same(dispatcher));
    expect(router.routerDelegate.currentConfiguration.uri, uri);
  });
}

class _TestAuthController extends AuthController {
  _TestAuthController() : super(client: Object(), sessionManager: Object());

  @override
  AuthState get state => const AuthAuthenticated('test@example.com');

  void refresh() => notifyListeners();
}
