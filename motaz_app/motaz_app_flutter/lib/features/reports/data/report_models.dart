import '../../../core/database/enums/expense_category.dart';
import '../../../core/utils/date_range.dart';

enum StatementEntryType { invoice, receipt, returnItem }

class SalesReportRow {
  final String invoiceId;
  final String localRef;
  final String clientName;
  final DateTime invoiceDate;
  final int total;
  final int discount;

  SalesReportRow({
    required this.invoiceId,
    required this.localRef,
    required this.clientName,
    required this.invoiceDate,
    required this.total,
    required this.discount,
  });
}

class SalesReportSummary {
  final List<SalesReportRow> rows;
  final int grossSales;
  final int totalDiscounts;
  final int totalReturns;
  final int netSales;

  SalesReportSummary({
    required this.rows,
    required this.grossSales,
    required this.totalDiscounts,
    required this.totalReturns,
    required this.netSales,
  });
}

class ProductSalesRow {
  final String productName;
  final int totalQuantitySold;
  final int totalRevenue;
  final double percentageOfTotal;

  ProductSalesRow({
    required this.productName,
    required this.totalQuantitySold,
    required this.totalRevenue,
    required this.percentageOfTotal,
  });
}

class ExpenseByCategoryRow {
  final ExpenseCategory category;
  final String categoryLabel;
  final int totalAmount;
  final double percentageOfTotal;

  ExpenseByCategoryRow({
    required this.category,
    required this.categoryLabel,
    required this.totalAmount,
    required this.percentageOfTotal,
  });
}

class ProfitReportData {
  final int grossSales;
  final int discounts;
  final int returns;
  final int netSales;
  final int operationalExpenses;
  final int productionExpenses;
  final int netProfit;
  final ProfitDistribution? distribution;

  ProfitReportData({
    required this.grossSales,
    required this.discounts,
    required this.returns,
    required this.netSales,
    required this.operationalExpenses,
    required this.productionExpenses,
    required this.netProfit,
    this.distribution,
  });
}

class ProfitDistribution {
  final int ownerShare;
  final int partnerShare;
  final int marginShare;

  ProfitDistribution({
    required this.ownerShare,
    required this.partnerShare,
    required this.marginShare,
  });
}

class ClientStatementEntry {
  final StatementEntryType type;
  final DateTime date;
  final String reference;
  final String? note;
  final int amount;
  final int runningBalance;

  ClientStatementEntry({
    required this.type,
    required this.date,
    required this.reference,
    this.note,
    required this.amount,
    required this.runningBalance,
  });
}

class ClientStatementData {
  final String clientName;
  final DateRange dateRange;
  final int openingBalance;
  final List<ClientStatementEntry> entries;
  final int closingBalance;

  ClientStatementData({
    required this.clientName,
    required this.dateRange,
    required this.openingBalance,
    required this.entries,
    required this.closingBalance,
  });
}

class ReceivablesRow {
  final String clientId;
  final String clientName;
  final int totalInvoiced;
  final int totalPaid;
  final int totalReturned;
  final int remainingBalance;

  ReceivablesRow({
    required this.clientId,
    required this.clientName,
    required this.totalInvoiced,
    required this.totalPaid,
    required this.totalReturned,
    required this.remainingBalance,
  });
}

class AgingRow {
  final String clientName;
  final int current;
  final int days31to60;
  final int days61to90;
  final int over90;
  final int total;

  AgingRow({
    required this.clientName,
    required this.current,
    required this.days31to60,
    required this.days61to90,
    required this.over90,
    required this.total,
  });
}

class PartyBalanceRow {
  final String partyName;
  final int accumulatedShares;
  final int totalDraws;
  final int currentBalance;

  PartyBalanceRow({
    required this.partyName,
    required this.accumulatedShares,
    required this.totalDraws,
    required this.currentBalance,
  });
}