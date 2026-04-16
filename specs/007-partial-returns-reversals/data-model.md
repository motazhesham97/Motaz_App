# Data Model: Partial Returns & Reversals

**Feature**: 007-partial-returns-reversals  
**Date**: 2026-04-12

---

## Entities

### SalesReturn (existing table — no migration needed)

| Field | Type | Constraints | Notes |
|---|---|---|---|
| id | TEXT(36) | PK | UUID |
| invoiceId | TEXT(36) | FK → SalesInvoices.id, NOT NULL | Parent invoice |
| returnDate | DATETIME | NOT NULL | User-selectable date |
| totalReturnedAmount | INTEGER | NOT NULL | Sum of return line amounts (minor units) |
| note | TEXT | NULLABLE | Optional note |
| status | INTEGER | NOT NULL, DEFAULT 0 | RecordStatus enum (0=ACTIVE, 1=VOIDED) |
| voidReason | TEXT | NULLABLE | Required when voiding |
| createdAt | DATETIME | NOT NULL | |
| updatedAt | DATETIME | NOT NULL | |
| deviceId | TEXT(36) | FK → Devices.id, NOT NULL | |
| rowVersion | INTEGER | NOT NULL, DEFAULT 1 | Optimistic concurrency |
| syncStatus | INTEGER | NOT NULL, DEFAULT 0 | SyncStatus enum |

**Indexes** (existing):
- `idx_return_invoice` on `invoiceId`
- `idx_return_date` on `returnDate`
- `idx_return_status` on `status`

---

### SalesReturnLine (existing table — no migration needed)

| Field | Type | Constraints | Notes |
|---|---|---|---|
| id | TEXT(36) | PK | UUID |
| returnId | TEXT(36) | FK → SalesReturns.id, NOT NULL | Parent return |
| invoiceLineId | TEXT(36) | FK → SalesInvoiceLines.id, NOT NULL | Original invoice line |
| returnedQuantity | INTEGER | NOT NULL, CHECK > 0 | Quantity returned |
| returnedAmount | INTEGER | NOT NULL, CHECK > 0 | Amount returned (minor units) |
| createdAt | DATETIME | NOT NULL | |
| updatedAt | DATETIME | NOT NULL | |

**Indexes** (existing):
- `idx_return_line_return` on `returnId`

---

## Relationships

```
SalesInvoice (1) ──── (0..*) SalesReturn
SalesReturn (1) ──── (1..*) SalesReturnLine
SalesInvoiceLine (1) ──── (0..*) SalesReturnLine
```

- A SalesReturn must belong to exactly one SalesInvoice.
- A SalesReturn must have at least one SalesReturnLine.
- A SalesReturnLine references exactly one SalesInvoiceLine.
- Multiple SalesReturnLines across different returns can reference the same SalesInvoiceLine (subject to quantity limits).

---

## State Transitions

### SalesReturn Lifecycle

```
ACTIVE ──[void with reason]──→ VOIDED
```

- Only ACTIVE → VOIDED is allowed.
- VOIDED is a terminal state (no un-void).
- Voided returns are excluded from all balance computations.

---

## Computed Values (on-read, not stored)

### Invoice Remaining Balance

```
remainingBalance = invoice.total
  − SUM(receiptAllocation.allocatedAmount WHERE receipt.status = ACTIVE)
  − SUM(salesReturn.totalReturnedAmount WHERE salesReturn.status = ACTIVE)
```

### Previously Returned Quantity (per invoice line)

```
alreadyReturned = SUM(salesReturnLine.returnedQuantity
  WHERE salesReturnLine.invoiceLineId = <lineId>
  AND salesReturn.status = ACTIVE)
```

### Available to Return (per invoice line)

```
availableQuantity = invoiceLine.quantity − alreadyReturned
```

### Max Return Amount (per return line)

```
maxAmount = returnedQuantity × invoiceLine.unitPrice
```

### Client Balance

```
clientBalance = SUM(invoice.total WHERE status = ACTIVE)
  − SUM(receiptAllocation.allocatedAmount WHERE receipt.status = ACTIVE)
  − SUM(salesReturn.totalReturnedAmount WHERE salesReturn.status = ACTIVE AND invoice.clientId = <clientId>)
```

Positive = debtor, negative = creditor (credit).

---

## Validation Rules

| Rule | Scope | Formula |
|---|---|---|
| V-001 | Return creation | Invoice must be ACTIVE (not VOIDED) |
| V-002 | Return creation | At least 1 return line required |
| V-003 | Return line | returnedQuantity > 0 |
| V-004 | Return line | returnedAmount > 0 |
| V-005 | Return line | returnedQuantity ≤ availableQuantity for that invoice line |
| V-006 | Return line | returnedAmount ≤ returnedQuantity × invoiceLine.unitPrice |
| V-007 | Return header | totalReturnedAmount = SUM(returnLine.returnedAmount) |
| V-008 | Return header | cumulative active return totals for invoice ≤ invoice.total |
| V-009 | Void | Return must be ACTIVE |
| V-010 | Void | Void reason must not be empty |
| V-011 | Invoice edit | If hasActiveReturns(invoiceId), block financial field changes |
