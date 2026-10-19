import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/features/profit_distribution/domain/monthly_profit.dart';

void main() {
  test(
    'keeps shares zero at break-even and carries loss through an empty month',
    () {
      final empty = MonthlyProfit(
        year: 2027,
        month: 1,
        netSales: 0,
        operationalExpenses: 0,
        productionExpenses: 0,
        carriedLossIn: -100001,
      );
      expect(empty.currentMonthLoss, 0);
      expect(empty.carriedLossOut, -100001);
      final recovered = MonthlyProfit(
        year: 2027,
        month: 2,
        netSales: 100001,
        operationalExpenses: 0,
        productionExpenses: 0,
        carriedLossIn: empty.carriedLossOut,
      );
      expect(recovered.netProfit, 0);
      expect(recovered.carriedLossOut, 0);
      expect(recovered.shares, (
        ownerShare: 0,
        partnerShare: 0,
        marginShare: 0,
      ));
      expect(MonthlyProfit.split(1), (
        ownerShare: 0,
        partnerShare: 0,
        marginShare: 1,
      ));
      expect(
        () => MonthlyProfit(
          year: 2026,
          month: 1,
          netSales: 0,
          operationalExpenses: 0,
          productionExpenses: 0,
          carriedLossIn: 1,
        ),
        throwsArgumentError,
      );
    },
  );
  test(
    'recovers consecutive losses before distributing the positive surplus',
    () {
      var carry = 0;
      final results = <MonthlyProfit>[];
      for (final (index, operating) in [
        -500000,
        -200000,
        400000,
        800000,
      ].indexed) {
        final result = MonthlyProfit(
          year: 2026,
          month: index + 1,
          netSales: operating,
          operationalExpenses: 0,
          productionExpenses: 0,
          carriedLossIn: carry,
        );
        results.add(result);
        carry = result.carriedLossOut;
      }
      expect(results.map((r) => r.currentMonthLoss), [-500000, -200000, 0, 0]);
      expect(results.map((r) => r.carriedLossOut), [
        -500000,
        -700000,
        -300000,
        0,
      ]);
      expect(results.map((r) => r.distributableProfit), [0, 0, 0, 500000]);
      expect(results.first.shares, (
        ownerShare: 0,
        partnerShare: 0,
        marginShare: 0,
      ));
      expect(results.last.shares, (
        ownerShare: 166000,
        partnerShare: 166000,
        marginShare: 168000,
      ));
    },
  );
}
