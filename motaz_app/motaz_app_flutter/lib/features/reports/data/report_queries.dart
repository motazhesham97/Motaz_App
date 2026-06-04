import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/enums/expense_category.dart';
import '../../../core/database/enums/party_account.dart';
import '../../../core/database/enums/record_status.dart';
import '../../../core/utils/date_range.dart';
import 'report_models.dart';

class ReportQueries {
  ReportQueries(this._db);

  final AppDatabase _db;

  Future<SalesReportSummary> getSalesReport(DateRange range) async {
    final invoiceRows = await _db
        .customSelect(
          'SELECT si.id, COALESCE(si.official_no, si.local_ref) AS local_ref, c.display_name AS client_name, si.invoice_date, si.total, si.discount '
          'FROM sales_invoices si '
          'JOIN clients c ON c.id = si.client_id '
          'WHERE si.status = ? AND si.invoice_date >= ? AND si.invoice_date < ? '
          'ORDER BY si.invoice_date DESC',
          variables: [
            Variable(RecordStatus.ACTIVE.index),
            Variable<DateTime>(range.start),
            Variable<DateTime>(range.end),
          ],
        )
        .get();

    final returnRow = await _db
        .customSelect(
          'SELECT COALESCE(SUM(total_returned_amount), 0) AS total_returns '
          'FROM sales_returns '
          'WHERE status = ? AND return_date >= ? AND return_date < ?',
          variables: [
            Variable(RecordStatus.ACTIVE.index),
            Variable<DateTime>(range.start),
            Variable<DateTime>(range.end),
          ],
        )
        .getSingle();

    final totalReturns = returnRow.read<int>('total_returns');

    final rows = invoiceRows
        .map(
          (row) => SalesReportRow(
            invoiceId: row.read<String>('id'),
            localRef: row.read<String>('local_ref'),
            clientName: row.read<String>('client_name'),
            invoiceDate: row.read<DateTime>('invoice_date'),
            total: row.read<int>('total'),
            discount: row.read<int>('discount'),
          ),
        )
        .toList();

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
    final grossRow = await _db
        .customSelect(
          'SELECT COALESCE(SUM(total), 0) AS gross, COALESCE(SUM(discount), 0) AS disc '
          'FROM sales_invoices '
          'WHERE status = ? AND invoice_date >= ? AND invoice_date < ?',
          variables: [
            Variable(RecordStatus.ACTIVE.index),
            Variable<DateTime>(range.start),
            Variable<DateTime>(range.end),
          ],
        )
        .getSingle();

    final returnRow = await _db
        .customSelect(
          'SELECT COALESCE(SUM(total_returned_amount), 0) AS ret '
          'FROM sales_returns '
          'WHERE status = ? AND return_date >= ? AND return_date < ?',
          variables: [
            Variable(RecordStatus.ACTIVE.index),
            Variable<DateTime>(range.start),
            Variable<DateTime>(range.end),
          ],
        )
        .getSingle();

    final opRow = await _db
        .customSelect(
          'SELECT COALESCE(SUM(amount), 0) AS total FROM expenses '
          'WHERE category = ? AND status = ? AND expense_date >= ? AND expense_date < ?',
          variables: [
            Variable(ExpenseCategory.OPERATIONAL.index),
            Variable(RecordStatus.ACTIVE.index),
            Variable<DateTime>(range.start),
            Variable<DateTime>(range.end),
          ],
        )
        .getSingle();

    final prodRow = await _db
        .customSelect(
          'SELECT COALESCE(SUM(amount), 0) AS total FROM expenses '
          'WHERE category = ? AND status = ? AND expense_date >= ? AND expense_date < ?',
          variables: [
            Variable(ExpenseCategory.PRODUCTION.index),
            Variable(RecordStatus.ACTIVE.index),
            Variable<DateTime>(range.start),
            Variable<DateTime>(range.end),
          ],
        )
        .getSingle();

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
    final isMonthly =
        start.year == end.year &&
        start.month == end.month &&
        start.day == 1 &&
        end.day >= 28;

    if (isMonthly) {
      final distRows = await _db
          .customSelect(
            'SELECT owner_share, partner_share, margin_share '
            'FROM monthly_distributions '
            'WHERE year = ? AND month = ? AND status = ?',
            variables: [
              Variable(start.year),
              Variable(start.month),
              Variable(RecordStatus.ACTIVE.index),
            ],
          )
          .get();

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

  Future<FinalMonthlyReportData> getFinalMonthlyReport({
    required int year,
    required int month,
  }) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);

    final operationalExpenses = await _sumExpenses(
      ExpenseCategory.OPERATIONAL,
      start,
      end,
    );
    final productionExpenses = await _sumExpenses(
      ExpenseCategory.PRODUCTION,
      start,
      end,
    );
    final totalCost = operationalExpenses + productionExpenses;

    final productRows = await _db
        .customSelect(
          'SELECT p.name AS product_name, '
          'COALESCE(SUM(sil.quantity), 0) AS total_quantity, '
          'COALESCE(SUM(sil.line_total), 0) AS total_sales '
          'FROM sales_invoice_lines sil '
          'JOIN sales_invoices si ON si.id = sil.invoice_id '
          'JOIN products p ON p.id = sil.product_id '
          'WHERE si.status = ? AND si.invoice_date >= ? AND si.invoice_date < ? '
          'GROUP BY p.id, p.name '
          'ORDER BY total_sales DESC, p.name ASC',
          variables: [
            Variable(RecordStatus.ACTIVE.index),
            Variable<DateTime>(start),
            Variable<DateTime>(end),
          ],
        )
        .get();

    final productSales = productRows
        .map(
          (row) => FinalReportProductSale(
            productName: row.read<String>('product_name'),
            quantity: row.read<int>('total_quantity'),
            totalSales: row.read<int>('total_sales'),
          ),
        )
        .toList();

    final totalSales = productSales.fold<int>(
      0,
      (sum, row) => sum + row.totalSales,
    );
    final profit = totalSales - totalCost;

    final partyRows = <FinalReportPartyRow>[
      await _getPartyFinalRow(PartyAccount.PARTNER, year, month, start, end),
      await _getPartyFinalRow(PartyAccount.OWNER, year, month, start, end),
      await _getPartyFinalRow(PartyAccount.MARGIN, year, month, start, end),
    ];

    return FinalMonthlyReportData(
      year: year,
      month: month,
      operationalExpenses: operationalExpenses,
      productionExpenses: productionExpenses,
      totalCost: totalCost,
      productSales: productSales,
      totalSales: totalSales,
      profit: profit,
      partyRows: partyRows,
    );
  }

  Future<FinalReportPartyRow> _getPartyFinalRow(
    PartyAccount party,
    int year,
    int month,
    DateTime start,
    DateTime end,
  ) async {
    final shareColumn = _shareColumnFor(party);
    final drawCategory = _drawCategoryFor(party);
    final profitShare = await _monthlyShare(shareColumn, year, month);
    final withdrawals = await _sumExpenses(drawCategory, start, end);
    final repayments = await _sumPartyAdjustments(party, start, end);
    final openingBalance = await _partyOpeningBalance(
      party,
      shareColumn,
      drawCategory,
      year,
      month,
      start,
    );
    final afterWithdrawals = profitShare - withdrawals;
    final closingBalance = afterWithdrawals + repayments + openingBalance;

    return FinalReportPartyRow(
      partyName: party.displayName,
      profitShare: profitShare,
      withdrawals: withdrawals,
      afterWithdrawals: afterWithdrawals,
      repayments: repayments,
      openingBalance: openingBalance,
      closingBalance: closingBalance,
    );
  }

  Future<int> _monthlyShare(String shareColumn, int year, int month) async {
    final row = await _db
        .customSelect(
          'SELECT COALESCE(SUM($shareColumn), 0) AS total '
          'FROM monthly_distributions '
          'WHERE year = ? AND month = ? AND status = ?',
          variables: [
            Variable(year),
            Variable(month),
            Variable(RecordStatus.ACTIVE.index),
          ],
        )
        .getSingle();
    return row.read<int>('total');
  }

  Future<int> _partyOpeningBalance(
    PartyAccount party,
    String shareColumn,
    ExpenseCategory drawCategory,
    int year,
    int month,
    DateTime start,
  ) async {
    final shareRow = await _db
        .customSelect(
          'SELECT COALESCE(SUM($shareColumn), 0) AS total '
          'FROM monthly_distributions '
          'WHERE status = ? AND (year < ? OR (year = ? AND month < ?))',
          variables: [
            Variable(RecordStatus.ACTIVE.index),
            Variable(year),
            Variable(year),
            Variable(month),
          ],
        )
        .getSingle();
    final draws = await _sumExpensesBefore(drawCategory, start);
    final repayments = await _sumPartyAdjustmentsBefore(party, start);
    return shareRow.read<int>('total') + repayments - draws;
  }

  Future<int> _sumExpenses(
    ExpenseCategory category,
    DateTime start,
    DateTime end,
  ) async {
    final row = await _db
        .customSelect(
          'SELECT COALESCE(SUM(amount), 0) AS total FROM expenses '
          'WHERE category = ? AND status = ? AND expense_date >= ? AND expense_date < ?',
          variables: [
            Variable(category.index),
            Variable(RecordStatus.ACTIVE.index),
            Variable<DateTime>(start),
            Variable<DateTime>(end),
          ],
        )
        .getSingle();
    return row.read<int>('total');
  }

  Future<int> _sumExpensesBefore(
    ExpenseCategory category,
    DateTime before,
  ) async {
    final row = await _db
        .customSelect(
          'SELECT COALESCE(SUM(amount), 0) AS total FROM expenses '
          'WHERE category = ? AND status = ? AND expense_date < ?',
          variables: [
            Variable(category.index),
            Variable(RecordStatus.ACTIVE.index),
            Variable<DateTime>(before),
          ],
        )
        .getSingle();
    return row.read<int>('total');
  }

  Future<int> _sumPartyAdjustments(
    PartyAccount party,
    DateTime start,
    DateTime end,
  ) async {
    final row = await _db
        .customSelect(
          'SELECT COALESCE(SUM(amount), 0) AS total FROM party_adjustments '
          'WHERE party = ? AND status = ? AND adjustment_date >= ? AND adjustment_date < ?',
          variables: [
            Variable(party.index),
            Variable(RecordStatus.ACTIVE.index),
            Variable<DateTime>(start),
            Variable<DateTime>(end),
          ],
        )
        .getSingle();
    return row.read<int>('total');
  }

  Future<int> _sumPartyAdjustmentsBefore(
    PartyAccount party,
    DateTime before,
  ) async {
    final row = await _db
        .customSelect(
          'SELECT COALESCE(SUM(amount), 0) AS total FROM party_adjustments '
          'WHERE party = ? AND status = ? AND adjustment_date < ?',
          variables: [
            Variable(party.index),
            Variable(RecordStatus.ACTIVE.index),
            Variable<DateTime>(before),
          ],
        )
        .getSingle();
    return row.read<int>('total');
  }

  ExpenseCategory _drawCategoryFor(PartyAccount party) {
    return switch (party) {
      PartyAccount.OWNER => ExpenseCategory.OWNER_DRAW,
      PartyAccount.PARTNER => ExpenseCategory.PARTNER_DRAW,
      PartyAccount.MARGIN => ExpenseCategory.MARGIN_DRAW,
    };
  }

  String _shareColumnFor(PartyAccount party) {
    return switch (party) {
      PartyAccount.OWNER => 'owner_share',
      PartyAccount.PARTNER => 'partner_share',
      PartyAccount.MARGIN => 'margin_share',
    };
  }
}
