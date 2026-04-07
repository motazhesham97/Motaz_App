# Research: Expenses & Monthly Profit Distribution

**Feature**: 006-expenses-profit  
**Date**: 2026-04-07

---

## 1. Schema Addition: MonthlyDistributions Table

**Decision**: Create a new Drift table `MonthlyDistributions` with a unique constraint on `(year, month)` to enforce one distribution per month. Include status (ACTIVE/VOIDED), voidReason, and standard audit fields.

**Rationale**: The Expenses table already exists from Phase 2, but no monthly distribution table exists. A dedicated table is needed to store immutable distribution records: the computed net profit and the three party shares. The unique constraint on year-month prevents duplicate distributions at the database level (FR-024).

**Alternatives considered**:
- Compute distributions on-the-fly from invoices/expenses without storing: Rejected — distributions must be immutable records that survive retroactive data changes. The spec explicitly states voided invoices/expenses do NOT auto-recalculate distributions.
- Store a single JSON blob per month: Rejected — violates the structured relational model and makes sync/conflict harder.

---

## 2. Profit Engine Design

**Decision**: Implement `ProfitEngine` as a stateless helper class that takes `AppDatabase` and provides `computeMonthlyProfit(int year, int month)` and `computeDistribution(int netProfit)` methods.

**Rationale**: The profit calculation is a pure computation — net sales minus OPERATIONAL/PRODUCTION expenses. Separating it from the repository makes it testable and reusable (dashboard queries reuse the same logic). The distribution formula (`trunc(n/3)` with remainder to Margin) is a pure function with no DB dependency.

**Alternatives considered**:
- Embed profit logic inside `DistributionRepository.create()`: Rejected — the dashboard cards also need net profit computation without creating a distribution.
- Create a Riverpod provider for profit logic: Rejected — profit logic is data-layer computation, not application-layer state. Providers will exist in the application layer and call the engine.

---

## 3. Monthly Net Sales Computation

**Decision**: Net sales = SUM of active invoice totals for the month MINUS SUM of active financial return amounts for the month. Use `invoiceDate` for invoices and `returnDate` for returns.

**Rationale**: Per constitution §10.1 and spec FR-017/FR-020. The SalesReturns table exists already (Phase 2 schema) but will be empty until Phase 7 — the query must still JOIN/reference it with a COALESCE so it returns 0 when no returns exist.

**Query pattern**:
```sql
SELECT COALESCE(SUM(total), 0) FROM sales_invoices
WHERE status = 0 AND invoiceDate BETWEEN ? AND ?

SELECT COALESCE(SUM(totalReturnedAmount), 0) FROM sales_returns
WHERE status = 0 AND returnDate BETWEEN ? AND ?

netSales = invoiceSum - returnSum
```

**Alternatives considered**:
- Single JOIN query combining invoices and returns: Rejected — produces a cross product. Two separate aggregate queries are correct and simpler.

---

## 4. Month Eligibility Validation

**Decision**: Distribution is allowed only for past completed months (year-month strictly less than current year-month). The current in-progress month is blocked.

**Rationale**: Per clarification session 2026-04-07 — distributing for the current month risks stale figures as new transactions arrive. The validation compares `(year, month)` to `DateTime.now()` at creation time. Reports may still show the current month as a live view.

**Implementation pattern**:
```dart
bool isPastMonth(int year, int month) {
  final now = DateTime.now();
  return year < now.year || (year == now.year && month < now.month);
}
```

---

## 5. Party Balance Computation

**Decision**: Compute-on-read using aggregate SQL queries. No stored projection.

**Rationale**: Per constitution §9 (Derived Data Strategy), party balances are computed on read. The formula: `balance = SUM(share from ACTIVE distributions) - SUM(amount from ACTIVE draw expenses)`. Each party has its own share column and draw category.

**Query pattern**:
```sql
-- Owner balance
SELECT
  COALESCE((SELECT SUM(ownerShare) FROM monthly_distributions WHERE status = 0), 0) -
  COALESCE((SELECT SUM(amount) FROM expenses WHERE category = 0 AND status = 0), 0)
  AS ownerBalance
```

Note: ExpenseCategory enum values — OWNER_DRAW=0, PARTNER_DRAW=1, MARGIN_DRAW=2, OPERATIONAL=3, PRODUCTION=4.

**Alternatives considered**:
- Materialized projection table updated on every distribution/draw: Rejected — adds complexity, risks drift, and the volume (monthly distributions + draws) is tiny enough for real-time aggregation.

---

## 6. Expense Repository Pattern

**Decision**: Follow the same repository + outbox pattern established in `ProductRepository` and `InvoiceRepository`. Methods: `create`, `update`, `voidExpense`, `getById`, `watchAll`, `searchByText`.

**Rationale**: Consistency with the existing codebase. The expense entity is simpler than invoices (no lines, no allocations, no edit constraints beyond status check). The ExpenseCategory enum and Expenses table already exist from Phase 2, so no schema modification is needed for expenses.

**Outbox entity type**: Use existing `ParentEntityType.EXPENSE` (already defined in the enum).

---

## 7. MonthlyDistribution Outbox Entity Type

**Decision**: Add `MONTHLY_DISTRIBUTION` to the `ParentEntityType` enum.

**Rationale**: The sync outbox requires an entity type for each syncable table. MonthlyDistributions is a new table not currently in the enum. Must be appended at the end to avoid breaking existing enum index mappings.

**Risk**: Adding a new enum value at the end preserves backward compatibility. Existing values: SALES_INVOICE=0, SALES_INVOICE_LINE=1, RECEIPT=2, RECEIPT_ALLOCATION=3, PRODUCT=4, CLIENT=5, EXPENSE=6, SALES_RETURN=7, SALES_RETURN_LINE=8, ATTACHMENT_METADATA=9. New: MONTHLY_DISTRIBUTION=10.

---

## 8. Dashboard Partial Implementation

**Decision**: Implement only 5 of the 9 dashboard cards in this phase: This Month Net Profit, Owner Balance, Partner Balance, Margin Balance, This Month Expense Summary by Type. The remaining 4 cards (Today Net Sales, This Month Net Sales, Outstanding Receivables, Recent Activity) are deferred to Phase 8 (Reports & Dashboard).

**Rationale**: The spec for Phase 6 explicitly scopes 5 cards. The full dashboard (all 9 cards) is Phase 8. The dashboard screen must be designed to accommodate future cards — use a grid/list layout that can be extended.

**Alternatives considered**:
- Implement all 9 cards now: Rejected — exceeds Phase 6 scope. Some cards (Outstanding Receivables, Recent Activity) depend on report queries not yet built.

---

## 9. Migration Strategy

**Decision**: Bump schema version from 3 to 4 in `app_database.dart`. Add an `onUpgrade` migration step that creates the `monthly_distributions` table for users upgrading from version 3.

**Rationale**: The Expenses table already exists since schema v2. Only MonthlyDistributions is new. The migration must use `m.createTable(monthlyDistributions)` inside the `onUpgrade` handler.

**Pattern** (from existing code):
```dart
onUpgrade: (Migrator m, int from, int to) async {
  if (from < 4) {
    await m.createTable(monthlyDistributions);
  }
}
```
