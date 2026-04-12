# Data Model: Expenses & Monthly Profit Distribution

**Feature**: 006-expenses-profit  
**Date**: 2026-04-07

---

## Entities

### 1. Expense (existing table — `expenses`)

The Expenses table already exists from Phase 2. No schema modification needed.

| Field | Type | Constraints | Notes |
|---|---|---|---|
| id | TEXT(36) | PK | UUID v4 |
| category | INTEGER | NOT NULL, enum | ExpenseCategory (0-4) |
| amount | INTEGER | NOT NULL | Minor-unit integer (positive) |
| expenseDate | DATETIME | NOT NULL | Date the expense occurred |
| note | TEXT | NULLABLE | Optional description |
| status | INTEGER | NOT NULL, default 0 | RecordStatus (0=ACTIVE, 1=VOIDED) |
| voidReason | TEXT | NULLABLE | Required when voiding |
| createdAt | DATETIME | NOT NULL | Creation timestamp |
| updatedAt | DATETIME | NOT NULL | Last modified timestamp |
| deviceId | TEXT(36) | NOT NULL, FK → devices.id | Source device |
| rowVersion | INTEGER | NOT NULL, default 1 | Optimistic concurrency |
| syncStatus | INTEGER | NOT NULL, default 0 | SyncStatus enum |

**Indexes** (already defined):
- `idx_expense_date` on `expenseDate`
- `idx_expense_category` on `category`
- `idx_expense_status` on `status`

**State transitions**:
```
ACTIVE → VOIDED (via voidExpense with reason)
VOIDED → ∅ (terminal state, no transitions out)
```

### 2. MonthlyDistribution (NEW table — `monthly_distributions`)

| Field | Type | Constraints | Notes |
|---|---|---|---|
| id | TEXT(36) | PK | UUID v4 |
| year | INTEGER | NOT NULL | Calendar year (e.g. 2026) |
| month | INTEGER | NOT NULL | Calendar month (1-12) |
| netProfit | INTEGER | NOT NULL | Computed net profit in minor units (can be negative) |
| ownerShare | INTEGER | NOT NULL | trunc(netProfit / 3) |
| partnerShare | INTEGER | NOT NULL | trunc(netProfit / 3) |
| marginShare | INTEGER | NOT NULL | netProfit - ownerShare - partnerShare |
| status | INTEGER | NOT NULL, default 0 | RecordStatus (0=ACTIVE, 1=VOIDED) |
| voidReason | TEXT | NULLABLE | Required when voiding |
| createdAt | DATETIME | NOT NULL | Creation timestamp |
| updatedAt | DATETIME | NOT NULL | Last modified timestamp |
| deviceId | TEXT(36) | NOT NULL, FK → devices.id | Source device |
| rowVersion | INTEGER | NOT NULL, default 1 | Optimistic concurrency |
| syncStatus | INTEGER | NOT NULL, default 0 | SyncStatus enum |

**Unique constraint**: `UNIQUE(year, month)` — enforces one distribution per month.

**Indexes**:
- `idx_distribution_year_month` on `(year, month)` — fast lookup and duplicate detection
- `idx_distribution_status` on `status` — filter ACTIVE distributions efficiently

**State transitions**:
```
ACTIVE → VOIDED (via voidDistribution with reason)
VOIDED → ∅ (terminal state)
```

**Validation rules**:
- `year >= 2020` and `year <= 2100` (reasonable bounds)
- `month >= 1` and `month <= 12`
- `(year, month)` must be strictly before current year-month (past months only)
- `ownerShare + partnerShare + marginShare == netProfit` (integrity invariant)

### 3. ExpenseCategory Enum (existing — no change)

| Index | Value | Arabic Label | In Net Profit? |
|---|---|---|---|
| 0 | OWNER_DRAW | سحب مالك | ❌ (draw) |
| 1 | PARTNER_DRAW | سحب شريك | ❌ (draw) |
| 2 | MARGIN_DRAW | سحب هامش | ❌ (draw) |
| 3 | OPERATIONAL | تشغيلي | ✅ |
| 4 | PRODUCTION | إنتاج | ✅ |

### 4. ParentEntityType Enum (existing — add 1 value)

| Index | Value | Status |
|---|---|---|
| 0 | SALES_INVOICE | existing |
| 1 | SALES_INVOICE_LINE | existing |
| 2 | RECEIPT | existing |
| 3 | RECEIPT_ALLOCATION | existing |
| 4 | PRODUCT | existing |
| 5 | CLIENT | existing |
| 6 | EXPENSE | existing |
| 7 | SALES_RETURN | existing |
| 8 | SALES_RETURN_LINE | existing |
| 9 | ATTACHMENT_METADATA | existing |
| 10 | MONTHLY_DISTRIBUTION | **NEW** |

---

## Computed Values (not stored)

### Party Balances

| Party | Formula |
|---|---|
| Owner | SUM(ownerShare) from ACTIVE distributions − SUM(amount) from ACTIVE OWNER_DRAW expenses |
| Partner | SUM(partnerShare) from ACTIVE distributions − SUM(amount) from ACTIVE PARTNER_DRAW expenses |
| Margin | SUM(marginShare) from ACTIVE distributions − SUM(amount) from ACTIVE MARGIN_DRAW expenses |

### Monthly Net Profit

```
Net Sales = SUM(total) from ACTIVE invoices in month − SUM(totalReturnedAmount) from ACTIVE returns in month
Net Profit = Net Sales − SUM(amount) from ACTIVE OPERATIONAL expenses in month − SUM(amount) from ACTIVE PRODUCTION expenses in month
```

---

## Relationships

```
Expense
  └── deviceId → Device.id

MonthlyDistribution
  └── deviceId → Device.id

Party Balance (computed)
  ├── reads MonthlyDistribution.ownerShare/partnerShare/marginShare
  └── reads Expense.amount WHERE category IN (OWNER_DRAW, PARTNER_DRAW, MARGIN_DRAW)

Net Profit (computed)
  ├── reads SalesInvoice.total WHERE status = ACTIVE
  ├── reads SalesReturn.totalReturnedAmount WHERE status = ACTIVE
  └── reads Expense.amount WHERE category IN (OPERATIONAL, PRODUCTION) AND status = ACTIVE
```
