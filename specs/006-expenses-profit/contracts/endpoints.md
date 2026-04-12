# Contracts: Expenses & Monthly Profit Distribution

**Feature**: 006-expenses-profit  
**Date**: 2026-04-07

---

## ExpenseRepository

**File**: `lib/features/expenses/data/expense_repository.dart`  
**Constructor**: `ExpenseRepository(AppDatabase _db)`

### Mutations

```dart
/// Create a new expense. Inserts expense + outbox entry in single transaction.
/// Validates: amount > 0.
/// Returns the inserted Expense row.
Future<Expense> create({
  required ExpenseCategory category,
  required int amount,
  required DateTime expenseDate,
  String? note,
  required String deviceId,
});

/// Update an active expense. Validates: status == ACTIVE.
/// Throws if expense is voided.
/// Updates all fields + rowVersion + syncStatus + outbox entry in single transaction.
Future<void> update({
  required String id,
  required ExpenseCategory category,
  required int amount,
  required DateTime expenseDate,
  String? note,
  required String deviceId,
});

/// Void an active expense. Validates: status == ACTIVE, reason not empty.
/// Sets status=VOIDED, voidReason=reason + outbox entry in single transaction.
Future<void> voidExpense(String id, String reason, String deviceId);
```

### Queries

```dart
/// Get a single expense by ID.
Future<Expense> getById(String id);

/// Watch all expenses ordered by expenseDate DESC, createdAt DESC.
Stream<List<Expense>> watchAll();

/// Search expenses by category Arabic label or note text.
/// Returns stream for reactive UI updates.
Stream<List<Expense>> searchByText(String query);

/// Get sum of active expenses by category for a month.
/// Used by profit engine and dashboard.
Future<int> getMonthlyTotalByCategory(ExpenseCategory category, int year, int month);
```

---

## ProfitEngine

**File**: `lib/features/profit_distribution/data/profit_engine.dart`  
**Constructor**: `ProfitEngine(AppDatabase _db)`

### Computation Methods

```dart
/// Compute net sales for a given month.
/// Formula: SUM(active invoice totals) - SUM(active return amounts)
/// Uses invoiceDate for invoices, returnDate for returns.
Future<int> computeMonthlyNetSales(int year, int month);

/// Compute net profit for a given month.
/// Formula: netSales - SUM(ACTIVE OPERATIONAL expenses) - SUM(ACTIVE PRODUCTION expenses)
/// Uses expenseDate for expenses.
Future<int> computeMonthlyNetProfit(int year, int month);

/// Compute the three-way distribution from a net profit value.
/// Pure function, no DB access.
/// Returns: {ownerShare, partnerShare, marginShare}
/// Invariant: ownerShare + partnerShare + marginShare == netProfit
({int ownerShare, int partnerShare, int marginShare}) computeDistribution(int netProfit);

/// Validate that a year-month is eligible for distribution.
/// Must be strictly before the current year-month.
bool isPastMonth(int year, int month);
```

---

## DistributionRepository

**File**: `lib/features/profit_distribution/data/distribution_repository.dart`  
**Constructor**: `DistributionRepository(AppDatabase _db, ProfitEngine _engine)`

### Mutations

```dart
/// Create a distribution for a given month.
/// Validates: isPastMonth, no existing ACTIVE distribution for (year, month).
/// Computes net profit via ProfitEngine, computes shares, inserts row + outbox entry.
/// Returns the inserted MonthlyDistribution row.
Future<MonthlyDistribution> distribute({
  required int year,
  required int month,
  required String deviceId,
});

/// Void an existing distribution.
/// Validates: status == ACTIVE, reason not empty.
/// Sets status=VOIDED, voidReason=reason + outbox entry in single transaction.
Future<void> voidDistribution(String id, String reason, String deviceId);
```

### Queries

```dart
/// Get a single distribution by ID.
Future<MonthlyDistribution> getById(String id);

/// Watch all distributions ordered by year DESC, month DESC.
Stream<List<MonthlyDistribution>> watchAll();

/// Get the active distribution for a given year-month, or null if none exists.
Future<MonthlyDistribution?> getForMonth(int year, int month);
```

---

## PartyBalanceCalculator

**File**: `lib/features/party_balances/data/party_balance_calculator.dart`  
**Constructor**: `PartyBalanceCalculator(AppDatabase _db)`

### Computation Methods

```dart
/// Compute current balances for all three parties.
/// Formula per party: SUM(share from ACTIVE distributions) - SUM(draw amount from ACTIVE draw expenses)
/// Returns a record with three int fields.
Future<({int ownerBalance, int partnerBalance, int marginBalance})> computeAllBalances();
```

---

## DashboardQueries

**File**: `lib/features/dashboard/data/dashboard_queries.dart`  
**Constructor**: `DashboardQueries(AppDatabase _db, ProfitEngine _engine, PartyBalanceCalculator _balanceCalc)`

### Query Methods

```dart
/// Get this month's net profit (computed, live).
Future<int> getThisMonthNetProfit();

/// Get all three party balances (computed, live).
Future<({int ownerBalance, int partnerBalance, int marginBalance})> getPartyBalances();

/// Get this month's expense breakdown by category.
/// Returns a map: {ExpenseCategory: int totalAmount}
Future<Map<ExpenseCategory, int>> getThisMonthExpensesByCategory();
```
