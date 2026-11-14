import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:motaz_app_flutter/core/router/app_back_button_dispatcher.dart';
import 'package:motaz_app_flutter/core/auth/auth_provider.dart';
import 'package:motaz_app_flutter/core/auth/auth_state.dart';
import 'package:motaz_app_flutter/features/follow_up/application/follow_up_providers.dart';
import 'package:motaz_app_flutter/features/profit_distribution/application/profit_providers.dart';
import 'package:motaz_app_flutter/shared/widgets/app_drawer.dart';

void main() {
  testWidgets('back from a replaced section returns home without exiting', (
    tester,
  ) async {
    final navigation = await _pumpNavigation(tester);

    navigation.router.go('/invoices');
    await tester.pumpAndSettle();
    expect(find.text('invoices page'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('home page'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(navigation.platformCalls, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('one back at home shows a brief hint without exiting', (
    tester,
  ) async {
    final navigation = await _pumpNavigation(tester);

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(find.text('اضغط رجوع مرة أخرى لطلب الخروج'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('home page'), findsOneWidget);
    expect(navigation.platformCalls, isEmpty);
    await tester.pump(AppBackButtonDispatcher.exitWindow);
    expect(find.text('اضغط رجوع مرة أخرى لطلب الخروج'), findsNothing);
  });

  testWidgets('two consecutive backs show a centered dialog and cancel stays', (
    tester,
  ) async {
    final navigation = await _pumpNavigation(tester);
    await tester.binding.handlePopRoute();
    await tester.pump();
    navigation.now = navigation.now.add(const Duration(milliseconds: 500));

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('هل تريد الخروج من التطبيق؟'), findsOneWidget);
    expect(
      tester.getCenter(find.byType(AlertDialog)),
      tester.getCenter(find.byType(Overlay).first),
    );
    expect(navigation.platformCalls, isEmpty);
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('home page'), findsOneWidget);
    expect(navigation.platformCalls, isEmpty);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(AlertDialog), findsNothing);
    await tester.pump(AppBackButtonDispatcher.exitWindow);
    expect(find.text('اضغط رجوع مرة أخرى لطلب الخروج'), findsNothing);
  });

  testWidgets('only explicit exit confirmation invokes SystemNavigator pop', (
    tester,
  ) async {
    final navigation = await _pumpNavigation(tester);
    await tester.binding.handlePopRoute();
    await tester.pump();
    navigation.now = navigation.now.add(const Duration(seconds: 1));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(navigation.platformCalls, isEmpty);

    await tester.tap(find.text('خروج'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(navigation.platformCalls.map((call) => call.method), [
      'SystemNavigator.pop',
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an expired back window requires two fresh presses', (
    tester,
  ) async {
    final navigation = await _pumpNavigation(tester);
    await tester.binding.handlePopRoute();
    await tester.pump();

    navigation.now = navigation.now.add(
      AppBackButtonDispatcher.exitWindow + const Duration(milliseconds: 1),
    );
    await tester.pump(
      AppBackButtonDispatcher.exitWindow + const Duration(milliseconds: 300),
    );
    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(find.byType(AlertDialog), findsNothing);
    expect(navigation.platformCalls, isEmpty);
    navigation.now = navigation.now.add(const Duration(milliseconds: 200));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(navigation.platformCalls, isEmpty);
  });

  testWidgets(
    'back from a pushed subflow returns to its section with null result',
    (
      tester,
    ) async {
      final navigation = await _pumpNavigation(tester);
      navigation.router.go('/invoices');
      await tester.pumpAndSettle();
      final result = navigation.router.push<bool>('/invoices/edit');
      await tester.pumpAndSettle();
      expect(find.text('invoice form'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(await result, isNull);
      expect(find.text('invoices page'), findsOneWidget);
      expect(find.text('home page'), findsNothing);
      expect(navigation.platformCalls, isEmpty);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('home page'), findsOneWidget);
    },
  );

  testWidgets('a form guard on a section root can block returning home', (
    tester,
  ) async {
    final navigation = await _pumpNavigation(tester);
    navigation.formCanPop.value = false;
    navigation.router.go('/invoices/edit');
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('invoice form'), findsOneWidget);
    expect(find.text('home page'), findsNothing);
    expect(navigation.formPopResults, [false]);
    expect(navigation.platformCalls, isEmpty);
  });

  testWidgets('a pushed form can veto back then return normally when allowed', (
    tester,
  ) async {
    final navigation = await _pumpNavigation(tester);
    navigation.router.go('/invoices');
    await tester.pumpAndSettle();
    navigation.formCanPop.value = false;
    final result = navigation.router.push<bool>('/invoices/edit');
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('invoice form'), findsOneWidget);
    expect(navigation.formPopResults, [false]);

    navigation.formCanPop.value = true;
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(await result, isNull);
    expect(find.text('invoices page'), findsOneWidget);
    expect(navigation.formPopResults, [false, true]);
    expect(navigation.platformCalls, isEmpty);
  });

  testWidgets(
    'Android root back remains routed through Flutter until confirmation',
    (
      tester,
    ) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      final navigation = await _pumpNavigation(tester);

      expect(navigation.frameworkBackRequests, isNotEmpty);
      expect(navigation.frameworkBackRequests.last, isTrue);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(navigation.platformCalls, isEmpty);

      navigation.router.go('/sign-in');
      await tester.pumpAndSettle();
      expect(navigation.frameworkBackRequests.last, isFalse);
    },
  );

  testWidgets('back closes an open drawer before popping a pushed form', (
    tester,
  ) async {
    final navigation = await _pumpNavigation(tester, useAppShell: true);
    navigation.router.go('/invoices');
    await tester.pumpAndSettle();
    navigation.router.push<bool>('/invoices/edit');
    await tester.pumpAndSettle();
    final shellScaffold = tester.state<ScaffoldState>(
      find
          .descendant(
            of: find.byType(AppShell),
            matching: find.byType(Scaffold),
          )
          .first,
    );
    shellScaffold.openDrawer();
    await tester.pumpAndSettle();
    expect(shellScaffold.isDrawerOpen, isTrue);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(shellScaffold.isDrawerOpen, isFalse);
    expect(find.text('invoice form'), findsOneWidget);
    expect(navigation.formPopResults, isEmpty);
    expect(navigation.platformCalls, isEmpty);
  });

  testWidgets('every top level destination returns home on Android back', (
    tester,
  ) async {
    final navigation = await _pumpNavigation(tester, useAppShell: true);

    for (final destination in appDestinations) {
      if (destination.route == '/home') {
        continue;
      }
      navigation.router.go(destination.route);
      await tester.pumpAndSettle();
      expect(
        navigation.router.routerDelegate.currentConfiguration.uri.path,
        destination.route,
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('home page'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(navigation.platformCalls, isEmpty);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'choosing a drawer destination does not pop the new destination',
    (
      tester,
    ) async {
      final navigation = await _pumpNavigation(tester, useAppShell: true);
      final shellScaffold = tester.state<ScaffoldState>(
        find
            .descendant(
              of: find.byType(AppShell),
              matching: find.byType(Scaffold),
            )
            .first,
      );
      shellScaffold.openDrawer();
      await tester.pumpAndSettle();

      await tester.tap(find.text('الفواتير'));
      await tester.pumpAndSettle();

      expect(shellScaffold.isDrawerOpen, isFalse);
      expect(find.text('invoices page'), findsOneWidget);
      expect(navigation.platformCalls, isEmpty);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('home page'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('an explicit form result is preserved without a home redirect', (
    tester,
  ) async {
    final navigation = await _pumpNavigation(tester);
    navigation.router.go('/invoices');
    await tester.pumpAndSettle();
    final result = navigation.router.push<bool>('/invoices/edit');
    await tester.pumpAndSettle();

    navigation.router.pop(true);
    await tester.pumpAndSettle();

    expect(await result, isTrue);
    expect(find.text('invoices page'), findsOneWidget);
    expect(navigation.formPopResults, [true]);
    expect(navigation.platformCalls, isEmpty);
  });

  testWidgets('back dismisses the exit dialog without confirming exit', (
    tester,
  ) async {
    final navigation = await _pumpNavigation(tester, useAppShell: true);
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('home page'), findsOneWidget);
    expect(navigation.platformCalls, isEmpty);
  });
}

class _NavigationHarness {
  _NavigationHarness({
    required this.router,
    required this.platformCalls,
    required this.formCanPop,
    required this.formPopResults,
    required this.frameworkBackRequests,
  });

  final GoRouter router;
  final List<MethodCall> platformCalls;
  final ValueNotifier<bool> formCanPop;
  final List<bool> formPopResults;
  final List<bool> frameworkBackRequests;
  DateTime now = DateTime(2026, 11, 14, 12);
}

Future<_NavigationHarness> _pumpNavigation(
  WidgetTester tester, {
  bool useAppShell = false,
}) async {
  final rootKey = GlobalKey<NavigatorState>();
  final shellKey = GlobalKey<NavigatorState>();
  final formCanPop = ValueNotifier(true);
  final formPopResults = <bool>[];
  final router = GoRouter(
    navigatorKey: rootKey,
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const Scaffold(body: Text('sign in')),
      ),
      ShellRoute(
        navigatorKey: shellKey,
        builder: (context, state, child) =>
            useAppShell ? AppShell(child: child) : child,
        routes: [
          for (final section in appDestinations.map(
            (destination) => destination.route.substring(1),
          ))
            GoRoute(
              path: '/$section',
              builder: (context, state) => Scaffold(
                body: Center(child: Text('$section page')),
              ),
            ),
          GoRoute(
            path: '/invoices/edit',
            builder: (context, state) => ValueListenableBuilder<bool>(
              valueListenable: formCanPop,
              builder: (context, canPop, child) => Form(
                canPop: canPop,
                onPopInvokedWithResult: (didPop, result) {
                  formPopResults.add(didPop);
                },
                child: const Scaffold(
                  body: Center(child: Text('invoice form')),
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );
  final calls = <MethodCall>[];
  final frameworkBackRequests = <bool>[];
  final navigation = _NavigationHarness(
    router: router,
    platformCalls: calls,
    formCanPop: formCanPop,
    formPopResults: formPopResults,
    frameworkBackRequests: frameworkBackRequests,
  );
  final dispatcher = AppBackButtonDispatcher(
    router: router,
    rootNavigatorKey: rootKey,
    shellNavigatorKey: shellKey,
    now: () => navigation.now,
  );
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'SystemNavigator.pop') {
        calls.add(call);
      } else if (call.method == 'SystemNavigator.setFrameworkHandlesBack') {
        frameworkBackRequests.add(call.arguments as bool);
      }
      return null;
    },
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    dispatcher.dispose();
    router.dispose();
    formCanPop.dispose();
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith((ref) => _TestAuthController()),
        followUpTasksProvider.overrideWith((ref) => Stream.value(const [])),
        settlementReviewProvider.overrideWith((ref) async => const []),
      ],
      child: MaterialApp.router(
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        ),
        routeInformationProvider: router.routeInformationProvider,
        routeInformationParser: router.routeInformationParser,
        routerDelegate: router.routerDelegate,
        backButtonDispatcher: dispatcher,
        onNavigationNotification: dispatcher.onNavigationNotification,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return navigation;
}

class _TestAuthController extends AuthController {
  _TestAuthController() : super(client: Object(), sessionManager: Object());

  @override
  AuthState get state => const AuthAuthenticated('test@example.com');
}
