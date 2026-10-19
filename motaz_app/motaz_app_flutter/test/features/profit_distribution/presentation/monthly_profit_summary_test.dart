import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/core/utils/money_formatter.dart';
import 'package:motaz_app_flutter/features/profit_distribution/domain/monthly_profit.dart';
import 'package:motaz_app_flutter/features/profit_distribution/presentation/monthly_profit_summary.dart';

void main() {
  testWidgets(
    'shows current and carried losses with zero shares on a narrow RTL screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final profit = MonthlyProfit(
        year: 2026,
        month: 1,
        netSales: 100000,
        operationalExpenses: 200000,
        productionExpenses: 0,
        carriedLossIn: -50000,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: MonthlyProfitSummary(profit: profit),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('خسارة الشهر الحالي'), findsOneWidget);
      expect(find.text('الخسارة المرحلة للشهر التالي'), findsOneWidget);
      expect(find.text(formatMoney(-150000)), findsNWidgets(2));
      expect(find.text(formatMoney(0)), findsNWidgets(5));
      expect(tester.takeException(), isNull);
    },
  );
}
