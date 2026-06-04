import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/enums/expense_category.dart';
import '../../../core/database/enums/record_status.dart';
import '../../../core/utils/document_reference_formatter.dart';
import '../../../core/utils/money_formatter.dart';
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
      final row = await _db
          .customSelect(
            'SELECT COALESCE(SUM(amount), 0) AS total FROM expenses '
            'WHERE category = ? AND status = ? AND expense_date >= ? AND expense_date < ?',
            variables: [
              Variable(cat.index),
              Variable(RecordStatus.ACTIVE.index),
              Variable<DateTime>(monthStart),
              Variable<DateTime>(monthEnd),
            ],
          )
          .getSingle();
      result[cat] = row.read<int>('total');
    }

    return result;
  }

  Future<int> getTodayNetSales() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    final invoiceRow = await _db
        .customSelect(
          'SELECT COALESCE(SUM(total), 0) - COALESCE(SUM(discount), 0) AS net '
          'FROM sales_invoices '
          'WHERE status = ? AND invoice_date >= ? AND invoice_date < ?',
          variables: [
            Variable(RecordStatus.ACTIVE.index),
            Variable<DateTime>(todayStart),
            Variable<DateTime>(tomorrowStart),
          ],
        )
        .getSingle();
    final invoiceNet = invoiceRow.read<int>('net');

    final returnRow = await _db
        .customSelect(
          'SELECT COALESCE(SUM(total_returned_amount), 0) AS ret '
          'FROM sales_returns '
          'WHERE status = ? AND return_date >= ? AND return_date < ?',
          variables: [
            Variable(RecordStatus.ACTIVE.index),
            Variable<DateTime>(todayStart),
            Variable<DateTime>(tomorrowStart),
          ],
        )
        .getSingle();
    final returnTotal = returnRow.read<int>('ret');

    return invoiceNet - returnTotal;
  }

  Future<int> getThisMonthNetSales() {
    final now = DateTime.now();
    return _engine.computeMonthlyNetSales(now.year, now.month);
  }

  Future<int> getOutstandingReceivablesTotal() async {
    final result = await _db
        .customSelect(
          'SELECT COALESCE(SUM(CASE WHEN remaining > 0 THEN remaining ELSE 0 END), 0) AS total '
          'FROM ('
          '  SELECT i.client_id,'
          '    COALESCE(SUM(i.total), 0)'
          '    - COALESCE(('
          '        SELECT SUM(r.amount) FROM receipts r'
          '        WHERE r.client_id = i.client_id AND r.status = ?'
          '      ), 0)'
          '    - COALESCE(('
          '        SELECT SUM(sr.total_returned_amount)'
          '        FROM sales_returns sr'
          '        JOIN sales_invoices ri ON ri.id = sr.invoice_id'
          '        WHERE ri.client_id = i.client_id AND sr.status = ?'
          '      ), 0) AS remaining'
          '  FROM sales_invoices i'
          '  WHERE i.status = ?'
          '  GROUP BY i.client_id'
          ')',
          variables: [
            Variable(RecordStatus.ACTIVE.index),
            Variable(RecordStatus.ACTIVE.index),
            Variable(RecordStatus.ACTIVE.index),
          ],
        )
        .getSingle();
    return result.read<int>('total');
  }

  Future<List<ActivityFeedItem>> getRecentActivityFeed() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));

    final rows = await _db
        .customSelect(
          "SELECT 'INVOICE' AS type, si.id, si.local_ref, si.official_no, "
          "COALESCE(c.display_name, 'عميل غير معروف') AS client_name, "
          'si.total AS amount, NULL AS note, NULL AS category, '
          'si.created_at, si.status '
          'FROM sales_invoices si '
          'LEFT JOIN clients c ON c.id = si.client_id '
          'WHERE si.created_at >= ? '
          'UNION ALL '
          "SELECT 'RECEIPT', r.id, r.local_ref, r.official_no, "
          "COALESCE(c.display_name, 'عميل غير معروف'), "
          'r.amount, NULL, NULL, r.created_at, r.status '
          'FROM receipts r '
          'LEFT JOIN clients c ON c.id = r.client_id '
          'WHERE r.created_at >= ? '
          'UNION ALL '
          "SELECT 'EXPENSE', e.id, NULL, NULL, NULL, e.amount, e.note, "
          'e.category, e.created_at, e.status '
          'FROM expenses e '
          'WHERE e.created_at >= ? '
          'UNION ALL '
          "SELECT 'RETURN', sr.id, sr.local_ref, sr.official_no, "
          "COALESCE(c.display_name, 'عميل غير معروف'), "
          'sr.total_returned_amount, NULL, NULL, sr.created_at, sr.status '
          'FROM sales_returns sr '
          'LEFT JOIN sales_invoices si ON si.id = sr.invoice_id '
          'LEFT JOIN clients c ON c.id = si.client_id '
          'WHERE sr.created_at >= ? '
          'ORDER BY created_at DESC LIMIT 10',
          variables: [
            Variable<DateTime>(cutoff),
            Variable<DateTime>(cutoff),
            Variable<DateTime>(cutoff),
            Variable<DateTime>(cutoff),
          ],
        )
        .get();

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
        reference: _activityReference(row),
        timestamp: row.read<DateTime>('created_at'),
      );
    }).toList();
  }

  String _activityReference(QueryRow row) {
    final type = row.read<String>('type');
    final localRef = row.data['local_ref'] as String?;
    final officialNo = row.data['official_no'] as String?;
    final clientName = (row.data['client_name'] as String?) ?? 'عميل غير معروف';
    final amount = (row.data['amount'] as num?)?.toInt() ?? 0;
    final note = (row.data['note'] as String?)?.trim();
    final categoryValue = row.data['category'];
    final category = categoryValue is num ? categoryValue.toInt() : null;

    return switch (type) {
      'INVOICE' =>
        '${invoiceDisplayRef(localRef ?? '', officialNo: officialNo)} - $clientName - ${formatMoney(amount)}',
      'RECEIPT' =>
        '${receiptDisplayRef(localRef ?? '', officialNo: officialNo)} - $clientName - ${formatMoney(amount)}',
      'RETURN' =>
        '${returnDisplayRef(localRef ?? '', officialNo: officialNo)} - $clientName - ${formatMoney(amount)}',
      'EXPENSE' =>
        'مصروف - ${(note == null || note.isEmpty) ? _expenseCategoryLabel(category) : note} - ${formatMoney(amount)}',
      _ => formatMoney(amount),
    };
  }

  String _expenseCategoryLabel(int? category) {
    if (category == null ||
        category < 0 ||
        category >= ExpenseCategory.values.length) {
      return 'تصنيف غير معروف';
    }

    return switch (ExpenseCategory.values[category]) {
      ExpenseCategory.OWNER_DRAW => 'امي',
      ExpenseCategory.PARTNER_DRAW => 'معتز',
      ExpenseCategory.MARGIN_DRAW => 'الهامش',
      ExpenseCategory.OPERATIONAL => 'تشغيلي',
      ExpenseCategory.PRODUCTION => 'إنتاجي',
    };
  }
}
