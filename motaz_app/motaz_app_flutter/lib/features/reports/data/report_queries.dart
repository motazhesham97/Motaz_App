import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/enums/expense_category.dart';
import '../../../core/database/enums/record_status.dart';
import '../../../core/utils/date_range.dart';
import 'report_models.dart';

class ReportQueries {
  ReportQueries(this._db);

  final AppDatabase _db;

  Future<SalesReportSummary> getSalesReport(DateRange range) async {
    final invoiceRows = await _db.customSelect(
      'SELECT si.id, si.local_ref, c.display_name AS client_name, si.invoice_date, si.total, si.discount '
      'FROM sales_invoices si '
      'JOIN clients c ON c.id = si.client_id '
      'WHERE si.status = ? AND si.invoice_date >= ? AND si.invoice_date < ? '
      'ORDER BY si.invoice_date DESC',
      variables: [
        Variable(RecordStatus.ACTIVE.index),
        Variable<DateTime>(range.start),
        Variable<DateTime>(range.end),
      ],
    ).get();

    final returnRow = await _db.customSelect(
      'SELECT COALESCE(SUM(total_returned_amount), 0) AS total_returns '
      'FROM sales_returns '
      'WHERE status = ? AND return_date >= ? AND return_date < ?',
      variables: [
        Variable(RecordStatus.ACTIVE.index),
        Variable<DateTime>(range.start),
        Variable<DateTime>(range.end),
      ],
    ).getSingle();

    final totalReturns = returnRow.read<int>('total_returns');

    final rows = invoiceRows.map((row) => SalesReportRow(
          invoiceId: row.read<String>('id'),
          localRef: row.read<String>('local_ref'),
          clientName: row.read<String>('client_name'),
          invoiceDate: row.read<DateTime>('invoice_date'),
          total: row.read<int>('total'),
          discount: row.read<int>('discount'),
        )).toList();

    int grossSales = 0;
    int totalDiscounts = 0;
    for (final row in rows) {
      grossSales += row.total;
      totalDiscounts += row.discount;
    }

    return SalesReportSummary(
      rows: rows,
      grossSales: grossSales,
      totalDiscounts: totalDiscounts,
      totalReturns: totalReturns,
      netSales: grossSales - totalDiscounts - totalReturns,
    );
  }

  Future<ProfitReportData> getProfitReport(DateRange range) async {
    final grossRow = await _db.customSelect(
      'SELECT COALESCE(SUM(total), 0) AS gross, COALESCE(SUM(discount), 0) AS disc '
      'FROM sales_invoices '
      'WHERE status = ? AND invoice_date >= ? AND invoice_date < ?',
      variables: [
        Variable(RecordStatus.ACTIVE.index),
        Variable<DateTime>(range.start),
        Variable<DateTime>(range.end),
      ],
    ).getSingle();

    final returnRow = await _db.customSelect(
      'SELECT COALESCE(SUM(total_returned_amount), 0) AS ret '
      'FROM sales_returns '
      'WHERE status = ? AND return_date >= ? AND return_date < ?',
      variables: [
        Variable(RecordStatus.ACTIVE.index),
        Variable<DateTime>(range.start),
        Variable<DateTime>(range.end),
      ],
    ).getSingle();

    final opRow = await _db.customSelect(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM expenses '
      'WHERE category = ? AND status = ? AND expense_date >= ? AND expense_date < ?',
      variables: [
        Variable(ExpenseCategory.OPERATIONAL.index),
        Variable(RecordStatus.ACTIVE.index),
        Variable<DateTime>(range.start),
        Variable<DateTime>(range.end),
      ],
    ).getSingle();

    final prodRow = await _db.customSelect(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM expenses '
      'WHERE category = ? AND status = ? AND expense_date >= ? AND expense_date < ?',
      variables: [
        Variable(ExpenseCategory.PRODUCTION.index),
        Variable(RecordStatus.ACTIVE.index),
        Variable<DateTime>(range.start),
        Variable<DateTime>(range.end),
      ],
    ).getSingle();

    final grossSales = grossRow.read<int>('gross');
    final discounts = grossRow.read<int>('disc');
    final returns = returnRow.read<int>('ret');
    final netSales = grossSales - discounts - returns;
    final operationalExpenses = opRow.read<int>('total');
    final productionExpenses = prodRow.read<int>('total');
    final netProfit = netSales - operationalExpenses - productionExpenses;

    ProfitDistribution? distribution;
    final start = range.start;
    final end = range.end;
    final isMonthly = start.year == end.year && start.month == end.month
        && start.day == 1
        && end.day >= 28;

    if (isMonthly) {
      final distRows = await _db.customSelect(
        'SELECT owner_share, partner_share, margin_share '
        'FROM monthly_distributions '
        'WHERE year = ? AND month = ? AND status = ?',
        variables: [
          Variable(start.year),
          Variable(start.month),
          Variable(RecordStatus.ACTIVE.index),
        ],
      ).get();

      if (distRows.isNotEmpty) {
        final d = distRows.first;
        distribution = ProfitDistribution(
          ownerShare: d.read<int>('owner_share'),
          partnerShare: d.read<int>('partner_share'),
          marginShare: d.read<int>('margin_share'),
        );
      }
    }

    return ProfitReportData(
      grossSales: grossSales,
      discounts: discounts,
      returns: returns,
      netSales: netSales,
      operationalExpenses: operationalExpenses,
      productionExpenses: productionExpenses,
      netProfit: netProfit,
      distribution: distribution,
    );
  }
}