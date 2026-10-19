import 'package:motaz_app_server/src/services/monthly_settlement_rules.dart';
import 'package:test/test.dart';

Map<String, dynamic> loss() => {
  'year': 2026,
  'month': 1,
  'netSales': 100000,
  'operationalExpenses': 200000,
  'productionExpenses': 0,
  'profitBeforeCarry': -100000,
  'currentMonthLoss': -100000,
  'carriedLossIn': -50000,
  'carriedLossOut': -150000,
  'netProfit': -150000,
  'ownerShare': 0,
  'partnerShare': 0,
  'marginShare': 0,
  'status': 'ACTIVE',
};

void main() {
  test(
    'validates recovered positive surplus and rejects an unfinished month',
    () {
      final payload = {
        ...loss(),
        'netSales': 1000000,
        'operationalExpenses': 200000,
        'profitBeforeCarry': 800000,
        'currentMonthLoss': 0,
        'carriedLossIn': -300000,
        'carriedLossOut': 0,
        'netProfit': 500000,
        'ownerShare': 166000,
        'partnerShare': 166000,
        'marginShare': 168000,
      };
      expect(
        () => MonthlySettlementRules.validate(payload, now: DateTime(2026, 2)),
        returnsNormally,
      );
      expect(
        () => MonthlySettlementRules.validate(
          payload,
          now: DateTime(2026, 1, 20),
        ),
        throwsFormatException,
      );
    },
  );
  test(
    'accepts signed loss with zero shares and rejects invalid settlement arithmetic',
    () {
      final valid = loss();
      expect(() => MonthlySettlementRules.validate(valid), returnsNormally);
      for (final field in [
        'netProfit',
        'currentMonthLoss',
        'carriedLossOut',
        'ownerShare',
        'carriedLossIn',
        'operationalExpenses',
      ]) {
        final invalid = {...valid, field: 1};
        expect(
          () => MonthlySettlementRules.validate(invalid),
          throwsFormatException,
          reason: field,
        );
      }
      expect(
        MonthlySettlementRules.sameFinancials(valid, {
          ...valid,
          'deviceId': 'other',
        }),
        isTrue,
      );
      expect(
        MonthlySettlementRules.sameFinancials(valid, {
          ...valid,
          'carriedLossOut': -1,
        }),
        isFalse,
      );
    },
  );
}
