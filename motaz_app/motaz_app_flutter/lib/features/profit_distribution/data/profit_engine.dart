import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/enums/expense_category.dart';
import '../../../core/database/enums/record_status.dart';
import '../domain/monthly_profit.dart';

typedef MonthSettlement = ({
  MonthlyProfit profit,
  MonthlyDistribution? recorded,
  bool needsReview,
});

class ProfitEngine {
  ProfitEngine(this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;
  DateTime get today => _now();

  Future<int> computeMonthlyNetSales(int year, int month) async =>
      (await timeline(year, month)).last.profit.netSales;

  Future<int> computeMonthlyNetProfit(int year, int month) async =>
      (await timeline(year, month)).last.profit.netProfit;

  ({int ownerShare, int partnerShare, int marginShare}) computeDistribution(
    int netProfit,
  ) => MonthlyProfit.split(netProfit);

  bool isPastMonth(int year, int month, {DateTime? now}) {
    final today = now ?? _now();
    return DateTime(year, month).isBefore(DateTime(today.year, today.month));
  }

  // One local aggregate covers the whole chain, including empty intervening months.
  Future<List<MonthSettlement>> timeline(int year, int month) async {
    if (year < 1 || month < 1 || month > 12) {
      throw ArgumentError('Invalid settlement month');
    }
    final end = DateTime(year, month + 1);
    final rows = await _db
        .customSelect(
          """
SELECT event_date,
       SUM(sales) AS sales, SUM(operational) AS operational,
       SUM(production) AS production
FROM (
  SELECT invoice_date AS event_date, total AS sales, 0 AS operational,
         0 AS production FROM sales_invoices WHERE status = ?
  UNION ALL
  SELECT return_date, -total_returned_amount, 0, 0
         FROM sales_returns WHERE status = ?
  UNION ALL
  SELECT expense_date, 0,
         CASE WHEN category = ? THEN amount ELSE 0 END,
         CASE WHEN category = ? THEN amount ELSE 0 END
         FROM expenses WHERE status = ? AND category IN (?, ?)
) WHERE event_date < ?
GROUP BY event_date ORDER BY event_date
""",
          variables: [
            Variable(RecordStatus.ACTIVE.index),
            Variable(RecordStatus.ACTIVE.index),
            Variable(ExpenseCategory.OPERATIONAL.index),
            Variable(ExpenseCategory.PRODUCTION.index),
            Variable(RecordStatus.ACTIVE.index),
            Variable(ExpenseCategory.OPERATIONAL.index),
            Variable(ExpenseCategory.PRODUCTION.index),
            Variable<DateTime>(end),
          ],
        )
        .get();
    final recorded =
        await (_db.select(_db.monthlyDistributions)..where(
              (t) =>
                  t.year.isSmallerThanValue(year) |
                  (t.year.equals(year) & t.month.isSmallerOrEqualValue(month)),
            ))
            .get();
    final byMonth = {
      for (final row in recorded) _key(row.year, row.month): row,
    };
    final totals = <String, ({int sales, int operational, int production})>{};
    for (final row in rows) {
      final date = row.read<DateTime>('event_date');
      final key = _key(date.year, date.month);
      final previous = totals[key];
      totals[key] = (
        sales: (previous?.sales ?? 0) + row.read<int>('sales'),
        operational:
            (previous?.operational ?? 0) + row.read<int>('operational'),
        production: (previous?.production ?? 0) + row.read<int>('production'),
      );
    }
    var first = DateTime(year, month);
    for (final key in [...totals.keys, ...byMonth.keys]) {
      final date = DateTime.parse('$key-01');
      if (date.isBefore(first)) first = date;
    }
    var carry = 0;
    var earlierUnapproved = false;
    final result = <MonthSettlement>[];
    for (
      var date = first;
      date.isBefore(end);
      date = DateTime(date.year, date.month + 1)
    ) {
      final key = _key(date.year, date.month);
      final row = totals[key];
      final profit = MonthlyProfit(
        year: date.year,
        month: date.month,
        netSales: row?.sales ?? 0,
        operationalExpenses: row?.operational ?? 0,
        productionExpenses: row?.production ?? 0,
        carriedLossIn: carry,
      );
      final saved = byMonth[key];
      final valid =
          saved != null &&
          saved.status == RecordStatus.ACTIVE &&
          matches(saved, profit) &&
          !earlierUnapproved;
      result.add((
        profit: profit,
        recorded: saved,
        needsReview: saved != null && !valid,
      ));
      earlierUnapproved = earlierUnapproved || !valid;
      carry = profit.carriedLossOut;
    }
    return result;
  }

  static bool matches(MonthlyDistribution saved, MonthlyProfit profit) {
    final shares = profit.shares;
    return saved.netSales == profit.netSales &&
        saved.operationalExpenses == profit.operationalExpenses &&
        saved.productionExpenses == profit.productionExpenses &&
        saved.profitBeforeCarry == profit.profitBeforeCarry &&
        saved.currentMonthLoss == profit.currentMonthLoss &&
        saved.carriedLossIn == profit.carriedLossIn &&
        saved.carriedLossOut == profit.carriedLossOut &&
        saved.netProfit == profit.netProfit &&
        saved.ownerShare == shares.ownerShare &&
        saved.partnerShare == shares.partnerShare &&
        saved.marginShare == shares.marginShare;
  }

  String _key(int year, int month) =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
}
