import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/enums/expense_category.dart';
import '../../../core/database/enums/record_status.dart';
import '../../party_balances/data/party_balance_calculator.dart';
import '../../profit_distribution/data/profit_engine.dart';
import 'dashboard_models.dart';

class DashboardQueries {
  DashboardQueries(this._db, this._engine, this._balanceCalc);

  final AppDatabase _db;
  final ProfitEngine _engine;
  final PartyBalanceCalculator _balanceCalc;

  Future<int> getThisMonthNetProfit() {
    final now = DateTime.now();
    return _engine.computeMonthlyNetProfit(now.year, now.month);
  }

  Future<({int ownerBalance, int partnerBalance, int marginBalance})>
      getPartyBalances() {
    return _balanceCalc.computeAllBalances();
  }

  Future<Map<ExpenseCategory, int>> getThisMonthExpensesByCategory() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);

    final result = <ExpenseCategory, int>{};

    for (final cat in ExpenseCategory.values) {
      final row = await _db.customSelect(
        'SELECT COALESCE(SUM(amount), 0) AS total FROM expenses '
        'WHERE category = ? AND status = ? AND expense_date >= ? AND expense_date < ?',
        variables: [
          Variable(cat.index),
          Variable(RecordStatus.ACTIVE.index),
          Variable<DateTime>(monthStart),
          Variable<DateTime>(monthEnd),
        ],
      ).getSingle();
      result[cat] = row.read<int>('total');
    }

    return result;
  }

  Future<int> getTodayNetSales() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    final invoiceRow = await _db.customSelect(
      'SELECT COALESCE(SUM(total), 0) - COALESCE(SUM(discount), 0) AS net '
      'FROM sales_invoices '
      'WHERE status = ? AND invoice_date >= ? AND invoice_date < ?',
      variables: [
        Variable(RecordStatus.ACTIVE.index),
        Variable<DateTime>(todayStart),
        Variable<DateTime>(tomorrowStart),
      ],
    ).getSingle();
    final invoiceNet = invoiceRow.read<int>('net');

    final returnRow = await _db.customSelect(
      'SELECT COALESCE(SUM(total_returned_amount), 0) AS ret '
      'FROM sales_returns '
      'WHERE status = ? AND return_date >= ? AND return_date < ?',
      variables: [
        Variable(RecordStatus.ACTIVE.index),
        Variable<DateTime>(todayStart),
        Variable<DateTime>(tomorrowStart),
      ],
    ).getSingle();
    final returnTotal = returnRow.read<int>('ret');

    return invoiceNet - returnTotal;
  }

  Future<int> getThisMonthNetSales() {
    final now = DateTime.now();
    return _engine.computeMonthlyNetSales(now.year, now.month);
  }

  Future<int> getOutstandingReceivablesTotal() async {
    final result = await _db.customSelect(
      'SELECT COALESCE(SUM(remaining), 0) AS total FROM ('
      '  SELECT i.total'
      '    - COALESCE((SELECT SUM(allocated_amount) FROM receipt_allocations ra'
      '                JOIN receipts r ON r.id = ra.receipt_id'
      '                WHERE ra.invoice_id = i.id AND r.status = 0), 0)'
      '    - COALESCE((SELECT SUM(total_returned_amount) FROM sales_returns sr'
      '                WHERE sr.invoice_id = i.id AND sr.status = 0), 0)'
      '    AS remaining'
      '  FROM sales_invoices i WHERE i.status = 0'
      ') WHERE remaining > 0',
      variables: [],
    ).getSingle();
    return result.read<int>('total');
  }

  Future<List<ActivityFeedItem>> getRecentActivityFeed() async {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 30));

    final rows = await _db.customSelect(
      "SELECT 'INVOICE' AS type, id, local_ref AS ref, created_at, status FROM sales_invoices WHERE created_at >= ? "
      "UNION ALL "
      "SELECT 'RECEIPT', id, id, created_at, status FROM receipts WHERE created_at >= ? "
      "UNION ALL "
      "SELECT 'EXPENSE', id, id, created_at, status FROM expenses WHERE created_at >= ? "
      "UNION ALL "
      "SELECT 'RETURN', id, id, created_at, status FROM sales_returns WHERE created_at >= ? "
      "ORDER BY created_at DESC LIMIT 10",
      variables: [
        Variable<DateTime>(cutoff),
        Variable<DateTime>(cutoff),
        Variable<DateTime>(cutoff),
        Variable<DateTime>(cutoff),
      ],
    ).get();

    return rows.map((row) {
      final typeStr = row.read<String>('type');
      final status = row.read<int>('status');
      final isActive = status == RecordStatus.ACTIVE.index;

      final type = switch (typeStr) {
        'INVOICE' when isActive => ActivityType.invoice,
        'RECEIPT' when isActive => ActivityType.receipt,
        'EXPENSE' when isActive => ActivityType.expense,
        'RETURN' when isActive => ActivityType.returnItem,
        _ => ActivityType.voidAction,
      };

      return ActivityFeedItem(
        type: type,
        entityId: row.read<String>('id'),
        reference: row.read<String>('ref'),
        timestamp: row.read<DateTime>('created_at'),
      );
    }).toList();
  }
}
