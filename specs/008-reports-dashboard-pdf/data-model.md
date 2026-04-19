# Data Model: Reports, Statements, Dashboard & PDF

**Branch**: `008-reports-dashboard-pdf`
**Date**: 2026-04-19

## Overview

This phase introduces **no new database tables**. All reporting data is computed on-read from existing transactional tables. This document describes the derived data models (Dart value objects) used to represent query results in the application layer.

## Existing Tables Used (Read-Only)

| Table | Report Usage |
|-------|-------------|
| `sales_invoices` | Sales Report, Profit Report, Client Statement, Receivables, Aging, Dashboard |
| `sales_invoice_lines` | Sales by Product Report |
| `receipts` | Client Statement, Receivables, Dashboard activity feed |
| `receipt_allocations` | Receivables, Aging (allocated amounts) |
| `expenses` | Expenses by Type, Profit Report, Dashboard |
| `sales_returns` | Sales Report (net sales), Profit, Client Statement, Receivables, Dashboard |
| `sales_return_lines` | Sales by Product (returned quantities) |
| `monthly_distributions` | Profit Report (distribution rows), Party Balances |
| `clients` | Client Statement, Receivables, Aging |
| `products` | Sales by Product Report |

## Derived Data Models (Dart Value Objects)

### DateRange

```
DateRange
├── start: DateTime
├── end: DateTime
├── label: String (display label, e.g., "هذا الشهر")
```
- Factory constructors: today, thisWeek, thisMonth, thisYear, allTime, custom
- `thisWeek` uses Monday as week start (ISO 8601)
- `allTime` uses DateTime(2000) to DateTime(2100) as practical bounds

### SalesReportRow

```
SalesReportRow
├── invoiceId: String
├── localRef: String
├── clientName: String
├── invoiceDate: DateTime
├── total: int (minor units)
├── discount: int (minor units)
```

### SalesReportSummary

```
SalesReportSummary
├── rows: List<SalesReportRow>
├── grossSales: int (minor units)
├── totalDiscounts: int (minor units)
├── totalReturns: int (minor units)
├── netSales: int (minor units, = grossSales - totalDiscounts - totalReturns)
```

### ProductSalesRow

```
ProductSalesRow
├── productName: String
├── totalQuantitySold: int
├── totalRevenue: int (minor units, after returns)
├── percentageOfTotal: double
```

### ExpenseByCategoryRow

```
ExpenseByCategoryRow
├── category: ExpenseCategory
├── categoryLabel: String
├── totalAmount: int (minor units)
├── percentageOfTotal: double
```

### ProfitReportData

```
ProfitReportData
├── grossSales: int (minor units)
├── discounts: int (minor units)
├── returns: int (minor units)
├── netSales: int (minor units)
├── operationalExpenses: int (minor units)
├── productionExpenses: int (minor units)
├── netProfit: int (minor units)
├── distribution: ProfitDistribution? (null if non-monthly or undistributed)
```

### ProfitDistribution

```
ProfitDistribution
├── ownerShare: int (minor units)
├── partnerShare: int (minor units)
├── marginShare: int (minor units)
```

### ClientStatementEntry

```
ClientStatementEntry
├── type: StatementEntryType (INVOICE | RECEIPT | RETURN)
├── date: DateTime
├── reference: String
├── note: String?
├── amount: int (minor units)
├── runningBalance: int (minor units, computed in Dart)
```

### ClientStatementData

```
ClientStatementData
├── clientName: String
├── dateRange: DateRange
├── openingBalance: int (minor units)
├── entries: List<ClientStatementEntry>
├── closingBalance: int (minor units)
```

### ReceivablesRow

```
ReceivablesRow
├── clientId: String
├── clientName: String
├── totalInvoiced: int (minor units)
├── totalPaid: int (minor units)
├── totalReturned: int (minor units)
├── remainingBalance: int (minor units)
```

### AgingRow

```
AgingRow
├── clientName: String
├── current: int (minor units, 0-30 days)
├── days31to60: int (minor units)
├── days61to90: int (minor units)
├── over90: int (minor units)
├── total: int (minor units)
```

### PartyBalanceRow

```
PartyBalanceRow
├── partyName: String (المالك | الشريك | الهامش)
├── accumulatedShares: int (minor units)
├── totalDraws: int (minor units)
├── currentBalance: int (minor units)
```

### ActivityFeedItem

```
ActivityFeedItem
├── type: ActivityType (INVOICE | RECEIPT | EXPENSE | RETURN | VOID)
├── entityId: String
├── reference: String
├── timestamp: DateTime
```

### DashboardData

```
DashboardData
├── todayNetSales: int (minor units)
├── thisMonthNetSales: int (minor units)
├── thisMonthNetProfit: int (minor units)
├── outstandingReceivablesTotal: int (minor units)
├── ownerBalance: int (minor units)
├── partnerBalance: int (minor units)
├── marginBalance: int (minor units)
├── expensesByCategory: Map<ExpenseCategory, int>
├── recentActivity: List<ActivityFeedItem>
```

## Enums (New)

### StatementEntryType
```
INVOICE, RECEIPT, RETURN
```

### ActivityType
```
INVOICE, RECEIPT, EXPENSE, RETURN, VOID
```

## Relationships

```
DateRange ──used by──> All report queries
DateRange ──used by──> PDF templates

DashboardData ──aggregates──> sales_invoices, receipts, expenses, returns, distributions
SalesReportSummary ──reads──> sales_invoices, sales_returns
ProductSalesRow ──reads──> sales_invoice_lines, products, sales_return_lines
ExpenseByCategoryRow ──reads──> expenses
ProfitReportData ──reads──> sales_invoices, expenses, sales_returns, monthly_distributions
ClientStatementData ──reads──> sales_invoices, receipts, sales_returns (scoped to single client)
ReceivablesRow ──reads──> sales_invoices, receipt_allocations, receipts, sales_returns
AgingRow ──reads──> sales_invoices, receipt_allocations, receipts, sales_returns
PartyBalanceRow ──reads──> monthly_distributions, expenses (draw categories)
```

## Validation Rules

- All monetary fields are `int` (minor-unit integers). No `double` in the money path.
- `DateRange.start` must be ≤ `DateRange.end`. Enforced by constructor.
- `percentageOfTotal` computed as `(rowAmount / grandTotal * 100)`. Returns 0.0 if grandTotal is 0.
- `runningBalance` in client statements is computed sequentially: `previousBalance + invoice - receipt - return`.
- Aging `ageDays` uses `DateTime.now().difference(invoiceDate).inDays`. Bucket assignment: 0-30 = Current, 31-60, 61-90, >90.
