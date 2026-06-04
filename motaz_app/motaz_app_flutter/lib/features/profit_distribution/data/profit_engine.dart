import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/enums/expense_category.dart';
import '../../../core/database/enums/record_status.dart';

class ProfitEngine {
  ProfitEngine(this._db);

  final AppDatabase _db;
  static const _shareRoundingStep = 1000;

  Future<int> computeMonthlyNetSales(int year, int month) async {
    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTime(year, month + 1, 1);

    final invoiceRow = await _db
        .customSelect(
          'SELECT COALESCE(SUM(total), 0) AS total FROM sales_invoices '
          'WHERE status = ? AND invoice_date >= ? AND invoice_date < ?',
          variables: [
            Variable(RecordStatus.ACTIVE.index),
            Variable<DateTime>(monthStart),
            Variable<DateTime>(monthEnd),
          ],
        )
        .getSingle();
    final invoiceSum = invoiceRow.read<int>('total');

    final returnRow = await _db
        .customSelect(
          'SELECT COALESCE(SUM(total_returned_amount), 0) AS total FROM sales_returns '
          'WHERE status = ? AND return_date >= ? AND return_date < ?',
          variables: [
            Variable(RecordStatus.ACTIVE.index),
            Variable<DateTime>(monthStart),
            Variable<DateTime>(monthEnd),
          ],
        )
        .getSingle();
    final returnSum = returnRow.read<int>('total');

    return invoiceSum - returnSum;
  }

  Future<int> computeMonthlyNetProfit(int year, int month) async {
    final netSales = await computeMonthlyNetSales(year, month);

    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTime(year, month + 1, 1);

    final operationalRow = await _db
        .customSelect(
          'SELECT COALESCE(SUM(amount), 0) AS total FROM expenses '
          'WHERE category = ? AND status = ? AND expense_date >= ? AND expense_date < ?',
          variables: [
            Variable(ExpenseCategory.OPERATIONAL.index),
            Variable(RecordStatus.ACTIVE.index),
            Variable<DateTime>(monthStart),
            Variable<DateTime>(monthEnd),
          ],
        )
        .getSingle();
    final operationalTotal = operationalRow.read<int>('total');

    final productionRow = await _db
        .customSelect(
          'SELECT COALESCE(SUM(amount), 0) AS total FROM expenses '
          'WHERE category = ? AND status = ? AND expense_date >= ? AND expense_date < ?',
          variables: [
            Variable(ExpenseCategory.PRODUCTION.index),
            Variable(RecordStatus.ACTIVE.index),
            Variable<DateTime>(monthStart),
            Variable<DateTime>(monthEnd),
          ],
        )
        .getSingle();
    final productionTotal = productionRow.read<int>('total');

    return netSales - operationalTotal - productionTotal;
  }

  ({int ownerShare, int partnerShare, int marginShare}) computeDistribution(
    int netProfit,
  ) {
    final baseShare = netProfit ~/ 3;
    final roundedShare = _roundTowardZeroToStep(
      baseShare,
      _shareRoundingStep,
    );
    final ownerShare = roundedShare;
    final partnerShare = roundedShare;
    final marginShare = netProfit - ownerShare - partnerShare;
    return (
      ownerShare: ownerShare,
      partnerShare: partnerShare,
      marginShare: marginShare,
    );
  }

  bool isPastMonth(int year, int month) {
    final now = DateTime.now();
    return year < now.year || (year == now.year && month < now.month);
  }

  int _roundTowardZeroToStep(int value, int step) {
    final rounded = (value.abs() ~/ step) * step;
    return value.isNegative ? -rounded : rounded;
  }
}
