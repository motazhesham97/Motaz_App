import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/enums/expense_category.dart';
import '../../../core/database/enums/record_status.dart';
import '../../profit_distribution/data/profit_engine.dart';
import '../../party_balances/data/party_balance_calculator.dart';

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
}
