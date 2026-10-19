class MonthlyProfit {
  MonthlyProfit({
    required this.year,
    required this.month,
    required this.netSales,
    required this.operationalExpenses,
    required this.productionExpenses,
    required this.carriedLossIn,
  }) {
    if (month < 1 || month > 12 || year < 1 || carriedLossIn > 0) {
      throw ArgumentError('Invalid month or signed opening loss');
    }
  }

  final int year;
  final int month;
  final int netSales;
  final int operationalExpenses;
  final int productionExpenses;
  final int carriedLossIn;

  int get profitBeforeCarry =>
      netSales - operationalExpenses - productionExpenses;
  int get currentMonthLoss => switch (profitBeforeCarry) {
    < 0 => profitBeforeCarry,
    _ => 0,
  };
  int get netProfit => profitBeforeCarry + carriedLossIn;
  int get carriedLossOut => switch (netProfit) {
    < 0 => netProfit,
    _ => 0,
  };
  int get distributableProfit => netProfit > 0 ? netProfit : 0;
  ({int ownerShare, int partnerShare, int marginShare}) get shares =>
      split(netProfit);

  static ({int ownerShare, int partnerShare, int marginShare}) split(
    int netProfit,
  ) {
    final amount = netProfit > 0 ? netProfit : 0;
    final share = (amount ~/ 3 ~/ 1000) * 1000;
    return (
      ownerShare: share,
      partnerShare: share,
      marginShare: amount - share * 2,
    );
  }
}
