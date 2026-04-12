import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/enums/expense_category.dart';
import '../../../core/database/enums/record_status.dart';

class PartyBalanceCalculator {
  PartyBalanceCalculator(this._db);

  final AppDatabase _db;

  Future<({int ownerBalance, int partnerBalance, int marginBalance})>
      computeAllBalances() async {
    final ownerShares = await _db.customSelect(
      'SELECT COALESCE(SUM(owner_share), 0) AS total FROM monthly_distributions WHERE status = ?',
      variables: [Variable(RecordStatus.ACTIVE.index)],
    ).getSingle();
    final ownerDraws = await _db.customSelect(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM expenses WHERE category = ? AND status = ?',
      variables: [
        Variable(ExpenseCategory.OWNER_DRAW.index),
        Variable(RecordStatus.ACTIVE.index),
      ],
    ).getSingle();

    final partnerShares = await _db.customSelect(
      'SELECT COALESCE(SUM(partner_share), 0) AS total FROM monthly_distributions WHERE status = ?',
      variables: [Variable(RecordStatus.ACTIVE.index)],
    ).getSingle();
    final partnerDraws = await _db.customSelect(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM expenses WHERE category = ? AND status = ?',
      variables: [
        Variable(ExpenseCategory.PARTNER_DRAW.index),
        Variable(RecordStatus.ACTIVE.index),
      ],
    ).getSingle();

    final marginShares = await _db.customSelect(
      'SELECT COALESCE(SUM(margin_share), 0) AS total FROM monthly_distributions WHERE status = ?',
      variables: [Variable(RecordStatus.ACTIVE.index)],
    ).getSingle();
    final marginDraws = await _db.customSelect(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM expenses WHERE category = ? AND status = ?',
      variables: [
        Variable(ExpenseCategory.MARGIN_DRAW.index),
        Variable(RecordStatus.ACTIVE.index),
      ],
    ).getSingle();

    return (
      ownerBalance: ownerShares.read<int>('total') - ownerDraws.read<int>('total'),
      partnerBalance: partnerShares.read<int>('total') - partnerDraws.read<int>('total'),
      marginBalance: marginShares.read<int>('total') - marginDraws.read<int>('total'),
    );
  }
}
