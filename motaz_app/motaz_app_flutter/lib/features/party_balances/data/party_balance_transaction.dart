import '../../../core/database/enums/party_account.dart';

enum PartyBalanceTransactionType {
  distribution,
  manualAddition,
  withdrawal,
}

class PartyBalanceTransaction {
  const PartyBalanceTransaction({
    required this.id,
    required this.party,
    required this.type,
    required this.title,
    required this.amount,
    required this.date,
    this.note,
  });

  final String id;
  final PartyAccount party;
  final PartyBalanceTransactionType type;
  final String title;
  final int amount;
  final DateTime date;
  final String? note;
}
