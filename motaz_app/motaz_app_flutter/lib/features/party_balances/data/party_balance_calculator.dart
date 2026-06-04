import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/enums/expense_category.dart';
import '../../../core/database/enums/party_account.dart';
import '../../../core/database/enums/record_status.dart';
import 'party_balance_transaction.dart';

class PartyBalanceCalculator {
  PartyBalanceCalculator(this._db);

  final AppDatabase _db;

  Future<({int ownerBalance, int partnerBalance, int marginBalance})>
  computeAllBalances() async {
    return (
      ownerBalance: await computeBalance(PartyAccount.OWNER),
      partnerBalance: await computeBalance(PartyAccount.PARTNER),
      marginBalance: await computeBalance(PartyAccount.MARGIN),
    );
  }

  Future<int> computeBalance(PartyAccount party) async {
    final shareColumn = _shareColumnFor(party);
    final drawCategory = _drawCategoryFor(party);

    final shareRow = await _db
        .customSelect(
          'SELECT COALESCE(SUM($shareColumn), 0) AS total '
          'FROM monthly_distributions WHERE status = ?',
          variables: [Variable(RecordStatus.ACTIVE.index)],
        )
        .getSingle();
    final drawRow = await _db
        .customSelect(
          'SELECT COALESCE(SUM(amount), 0) AS total '
          'FROM expenses WHERE category = ? AND status = ?',
          variables: [
            Variable(drawCategory.index),
            Variable(RecordStatus.ACTIVE.index),
          ],
        )
        .getSingle();
    final manualRow = await _db
        .customSelect(
          'SELECT COALESCE(SUM(amount), 0) AS total '
          'FROM party_adjustments WHERE party = ? AND status = ?',
          variables: [
            Variable(party.index),
            Variable(RecordStatus.ACTIVE.index),
          ],
        )
        .getSingle();

    return shareRow.read<int>('total') +
        manualRow.read<int>('total') -
        drawRow.read<int>('total');
  }

  Future<List<PartyBalanceTransaction>> getTransactions(
    PartyAccount party,
  ) async {
    final transactions = <PartyBalanceTransaction>[];
    final shareColumn = _shareColumnFor(party);
    final drawCategory = _drawCategoryFor(party);

    final distributionRows = await _db
        .customSelect(
          'SELECT id, year, month, $shareColumn AS amount, created_at '
          'FROM monthly_distributions '
          'WHERE status = ? AND $shareColumn > 0',
          variables: [Variable(RecordStatus.ACTIVE.index)],
        )
        .get();
    for (final row in distributionRows) {
      final year = row.read<int>('year');
      final month = row.read<int>('month');
      transactions.add(
        PartyBalanceTransaction(
          id: row.read<String>('id'),
          party: party,
          type: PartyBalanceTransactionType.distribution,
          title: 'توزيع أرباح $year-${month.toString().padLeft(2, '0')}',
          amount: row.read<int>('amount'),
          date: row.read<DateTime>('created_at'),
        ),
      );
    }

    final expenseRows =
        await (_db.select(_db.expenses)..where(
              (tbl) =>
                  tbl.category.equals(drawCategory.index) &
                  tbl.status.equals(RecordStatus.ACTIVE.index),
            ))
            .get();
    for (final expense in expenseRows) {
      transactions.add(
        PartyBalanceTransaction(
          id: expense.id,
          party: party,
          type: PartyBalanceTransactionType.withdrawal,
          title: 'سحب',
          amount: -expense.amount,
          date: expense.expenseDate,
          note: expense.note,
        ),
      );
    }

    final adjustmentRows =
        await (_db.select(_db.partyAdjustments)..where(
              (tbl) =>
                  tbl.party.equals(party.index) &
                  tbl.status.equals(RecordStatus.ACTIVE.index),
            ))
            .get();
    for (final adjustment in adjustmentRows) {
      transactions.add(
        PartyBalanceTransaction(
          id: adjustment.id,
          party: party,
          type: PartyBalanceTransactionType.manualAddition,
          title: 'إضافة مبلغ',
          amount: adjustment.amount,
          date: adjustment.adjustmentDate,
          note: adjustment.note,
        ),
      );
    }

    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
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
