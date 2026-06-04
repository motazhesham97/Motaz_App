import 'dart:typed_data';

import '../../../core/database/enums/parent_entity_type.dart';
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
  final List<Uint8List> attachmentImages;

  SalesReportRow({
    required this.invoiceId,
    required this.localRef,
    required this.clientName,
    required this.invoiceDate,
    required this.total,
    required this.discount,
    this.attachmentImages = const [],
  });

  SalesReportRow copyWith({List<Uint8List>? attachmentImages}) {
    return SalesReportRow(
      invoiceId: invoiceId,
      localRef: localRef,
      clientName: clientName,
      invoiceDate: invoiceDate,
      total: total,
      discount: discount,
      attachmentImages: attachmentImages ?? this.attachmentImages,
    );
  }
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

class ExpenseReportRow {
  final String id;
  final ExpenseCategory category;
  final String categoryLabel;
  final DateTime expenseDate;
  final int amount;
  final String? note;

  ExpenseReportRow({
    required this.id,
    required this.category,
    required this.categoryLabel,
    required this.expenseDate,
    required this.amount,
    this.note,
  });
}

class ExpenseReportData {
  final List<ExpenseReportRow> rows;
  final int totalAmount;
  final String filterLabel;

  ExpenseReportData({
    required this.rows,
    required this.totalAmount,
    required this.filterLabel,
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

class FinalReportProductSale {
  final String productName;
  final int quantity;
  final int totalSales;

  FinalReportProductSale({
    required this.productName,
    required this.quantity,
    required this.totalSales,
  });
}

class FinalReportPartyRow {
  final String partyName;
  final int profitShare;
  final int withdrawals;
  final int afterWithdrawals;
  final int repayments;
  final int openingBalance;
  final int closingBalance;

  FinalReportPartyRow({
    required this.partyName,
    required this.profitShare,
    required this.withdrawals,
    required this.afterWithdrawals,
    required this.repayments,
    required this.openingBalance,
    required this.closingBalance,
  });
}

class FinalMonthlyReportData {
  final int year;
  final int month;
  final int operationalExpenses;
  final int productionExpenses;
  final int totalCost;
  final List<FinalReportProductSale> productSales;
  final int totalSales;
  final int profit;
  final List<FinalReportPartyRow> partyRows;

  FinalMonthlyReportData({
    required this.year,
    required this.month,
    required this.operationalExpenses,
    required this.productionExpenses,
    required this.totalCost,
    required this.productSales,
    required this.totalSales,
    required this.profit,
    required this.partyRows,
  });
}

class ClientStatementEntry {
  final String entityId;
  final ParentEntityType parentEntityType;
  final StatementEntryType type;
  final DateTime date;
  final String reference;
  final String? note;
  final int amount;
  final int runningBalance;
  final List<Uint8List> attachmentImages;

  ClientStatementEntry({
    required this.entityId,
    required this.parentEntityType,
    required this.type,
    required this.date,
    required this.reference,
    this.note,
    required this.amount,
    required this.runningBalance,
    this.attachmentImages = const [],
  });

  ClientStatementEntry copyWith({
    List<Uint8List>? attachmentImages,
  }) {
    return ClientStatementEntry(
      entityId: entityId,
      parentEntityType: parentEntityType,
      type: type,
      date: date,
      reference: reference,
      note: note,
      amount: amount,
      runningBalance: runningBalance,
      attachmentImages: attachmentImages ?? this.attachmentImages,
    );
  }
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

class ClientReceivablesReportData {
  final DateRange dateRange;
  final String filterLabel;
  final List<ReceivablesRow> rows;
  final int totalInvoiced;
  final int totalPaid;
  final int totalReturned;
  final int totalRemaining;

  ClientReceivablesReportData({
    required this.dateRange,
    required this.filterLabel,
    required this.rows,
    required this.totalInvoiced,
    required this.totalPaid,
    required this.totalReturned,
    required this.totalRemaining,
  });
}

class ClientProductSalesRow {
  final String productId;
  final String productName;
  final int totalQuantitySold;
  final int totalQuantityReturned;
  final int netQuantity;
  final int totalSales;
  final int totalReturns;
  final int netSales;

  ClientProductSalesRow({
    required this.productId,
    required this.productName,
    required this.totalQuantitySold,
    required this.totalQuantityReturned,
    required this.netQuantity,
    required this.totalSales,
    required this.totalReturns,
    required this.netSales,
  });
}

class ClientProductSalesReportData {
  final String clientId;
  final String clientName;
  final DateRange dateRange;
  final String filterLabel;
  final List<ClientProductSalesRow> rows;
  final int totalQuantitySold;
  final int totalQuantityReturned;
  final int netQuantity;
  final int totalSales;
  final int totalReturns;
  final int netSales;

  ClientProductSalesReportData({
    required this.clientId,
    required this.clientName,
    required this.dateRange,
    required this.filterLabel,
    required this.rows,
    required this.totalQuantitySold,
    required this.totalQuantityReturned,
    required this.netQuantity,
    required this.totalSales,
    required this.totalReturns,
    required this.netSales,
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
