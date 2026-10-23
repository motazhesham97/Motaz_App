import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:motaz_app_flutter/features/profit_distribution/application/profit_providers.dart';
import 'package:motaz_app_flutter/features/profit_distribution/data/profit_engine.dart';
import 'package:motaz_app_flutter/features/profit_distribution/domain/monthly_profit.dart';
import 'package:motaz_app_flutter/features/profit_distribution/presentation/settlement_review_notice.dart';

MonthSettlement _review(int month, {int sales = 100000}) => (
  profit: MonthlyProfit(
    year: 2026,
    month: month,
    netSales: sales,
    operationalExpenses: 0,
    productionExpenses: 0,
    carriedLossIn: 0,
  ),
  recorded: null,
  needsReview: true,
);

const _notice = Key('settlement-review-notification');
const _page = Key('test-page');

void main() {
  Future<void> pumpNotice(
    WidgetTester tester, {
    VoidCallback? onRead,
    List<MonthSettlement> Function()? loadReviews,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settlementReviewProvider.overrideWith((ref) async {
            onRead?.call();
            return loadReviews?.call() ?? [_review(9)];
          }),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          supportedLocales: [Locale('ar')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: SettlementReviewNotice(
            child: Scaffold(body: SizedBox.expand(key: _page)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }

  testWidgets(
    'notice respects the safe area and closes without resizing the page',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 24);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      await pumpNotice(tester);
      expect(find.byKey(_notice), findsOneWidget);
      expect(find.textContaining('09/2026'), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(_notice)).dy,
        greaterThanOrEqualTo(24),
      );
      final originalPage = tester.getRect(find.byKey(_page));

      await tester.tap(find.byTooltip('إغلاق التنبيه'));
      await tester.pumpAndSettle();

      expect(find.byKey(_notice), findsNothing);
      expect(tester.getRect(find.byKey(_page)), originalPage);
      expect(tester.takeException(), isNull);
      await unmount(tester);
    },
  );

  testWidgets(
    'notice expires after eight seconds and reminds without repeating queries',
    (tester) async {
      var queries = 0;
      await pumpNotice(tester, onRead: () => queries++);
      await tester.pump(const Duration(seconds: 7));
      expect(find.byKey(_notice), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(_notice), findsNothing);

      await tester.pump(const Duration(minutes: 14, seconds: 52));
      expect(find.byKey(_notice), findsOneWidget);
      expect(queries, 1);
      await tester.pump(const Duration(seconds: 8));
      expect(find.byKey(_notice), findsNothing);
      expect(tester.takeException(), isNull);
      await unmount(tester);
    },
  );

  testWidgets(
    'new financial changes reshow the notice and approval cancels reminders',
    (tester) async {
      var reviews = [_review(9)];
      await pumpNotice(tester, loadReviews: () => reviews);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SettlementReviewNotice)),
      );
      await tester.tap(find.byTooltip('إغلاق التنبيه'));
      await tester.pumpAndSettle();

      container.invalidate(settlementReviewProvider);
      await tester.pumpAndSettle();
      expect(find.byKey(_notice), findsNothing);

      reviews = [_review(9, sales: 125000)];
      container.invalidate(settlementReviewProvider);
      await tester.pumpAndSettle();
      expect(find.byKey(_notice), findsOneWidget);

      reviews = [];
      container.invalidate(settlementReviewProvider);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(minutes: 15));
      expect(find.byKey(_notice), findsNothing);
      expect(tester.takeException(), isNull);
      await unmount(tester);
    },
  );

  testWidgets(
    'pending reviews remind on resume but remain hidden in the background',
    (tester) async {
      await pumpNotice(tester);
      await tester.tap(find.byTooltip('إغلاق التنبيه'));
      await tester.pumpAndSettle();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(minutes: 15));
      expect(find.byKey(_notice), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(find.byKey(_notice), findsOneWidget);
      expect(tester.takeException(), isNull);
      await unmount(tester);
    },
  );

  testWidgets(
    'review action opens the earliest affected month without repeating on navigation',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/invoices',
        routes: [
          ShellRoute(
            builder: (context, state, child) => SettlementReviewNotice(
              suppressed: state.uri.path == '/distributions',
              child: child,
            ),
            routes: [
              GoRoute(
                path: '/invoices',
                builder: (_, _) => const Scaffold(body: Text('الفواتير')),
              ),
              GoRoute(
                path: '/distributions',
                builder: (_, _) => const Scaffold(body: Text('التسويات')),
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settlementReviewProvider.overrideWith(
              (ref) async => [_review(10), _review(9)],
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('مراجعة التسويات'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/distributions');
      expect(router.routeInformationProvider.value.uri.queryParameters, {
        'year': '2026',
        'month': '9',
      });
      expect(find.byKey(_notice), findsNothing);

      router.go('/invoices');
      await tester.pumpAndSettle();
      expect(find.text('الفواتير'), findsOneWidget);
      expect(find.byKey(_notice), findsNothing);
      expect(tester.takeException(), isNull);
      await unmount(tester);
    },
  );
}
