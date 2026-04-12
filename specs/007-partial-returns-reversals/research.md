# Research: Partial Returns & Reversals

**Feature**: 007-partial-returns-reversals  
**Date**: 2026-04-12

---

## Decision 1: Schema Readiness

**Decision**: No schema migration needed. Existing tables are sufficient.

**Rationale**: The `SalesReturns` and `SalesReturnLines` tables were created in Phase 2 (schema v2). Both tables already contain all required columns:
- `SalesReturns`: id, invoiceId (FK), returnDate, totalReturnedAmount, note, status (RecordStatus), voidReason, createdAt, updatedAt, deviceId (FK), rowVersion, syncStatus
- `SalesReturnLines`: id, returnId (FK), invoiceLineId (FK), returnedQuantity (CHECK > 0), returnedAmount (CHECK > 0), createdAt, updatedAt

The `ParentEntityType` enum already includes `SALES_RETURN` (index 7) and `SALES_RETURN_LINE` (index 8).

**Alternatives considered**: Adding a `returnedTotal` computed column — rejected because `totalReturnedAmount` on the parent record serves this purpose and is computed at save time.

---

## Decision 2: Balance Computation Strategy

**Decision**: Compute-on-read via queries. No materialized balance columns.

**Rationale**: The constitution mandates compute-on-read for derived data (§9). The invoice remaining balance formula is:
```
remainingBalance = invoice.total − SUM(active allocations) − SUM(active return totals)
```
This is computed dynamically from the raw tables. The existing `ProfitEngine.computeMonthlyNetSales` already subtracts active return totals, so no modification is needed for profit/dashboard calculations.

**Alternatives considered**: Adding a `remainingBalance` column to SalesInvoices — rejected per constitution (no materialized projections in MVP).

---

## Decision 3: Return Amount Auto-fill Strategy

**Decision**: Auto-fill `returnedAmount = returnedQuantity × invoiceLine.unitPrice`, with manual override downward.

**Rationale**: Per clarification session (2026-04-12), the return form auto-fills the amount when the user enters a quantity. The user may reduce the amount (e.g., for damaged goods at a discount) but cannot increase it above `returnedQuantity × unitPrice`. This prevents overcharging and simplifies the common case.

**Alternatives considered**: 
- Fully auto-calculated (no override) — rejected because it doesn't support partial-price returns.
- Fully manual (no auto-fill) — rejected because it's error-prone for the common case.

---

## Decision 4: Quantity Validation (Cumulative Per Line)

**Decision**: Validate per-invoice-line returned quantity against `lineQuantity − SUM(active return line quantities for that line)`.

**Rationale**: Multiple returns can exist against the same invoice and even the same invoice line (e.g., returning 3 of 10, then later 2 more). The total returned quantity per invoice line must never exceed the original line quantity. Voided return lines are excluded from this sum.

**Alternatives considered**: Single-return-per-line model — rejected because it arbitrarily limits partial returns over time.

---

## Decision 5: Invoice Edit Restriction Enforcement

**Decision**: Add a `hasActiveReturns(invoiceId)` query to the invoice repository. The invoice edit flow checks this before allowing financial field changes.

**Rationale**: Per constitution §IV, if returns exist, only non-financial fields (notes, attachment metadata) may be edited. The check queries `SalesReturns` for any active (non-voided) records linked to the invoice. If found, financial edits are blocked. Voided returns do not restrict.

**Alternatives considered**: 
- Enforcing via a `locked` column on invoice — rejected because it requires migration and state management.
- Checking only at UI level — rejected because it must be enforced at the repository level.

---

## Decision 6: Void Reversal Mechanism

**Decision**: No explicit reversal records. Voiding a return simply sets its status to VOIDED. All balance computations exclude voided returns automatically because queries filter by `status = ACTIVE`.

**Rationale**: Since balances are computed on read, voiding a return inherently reverses its effects without needing explicit reversal journal entries. The voided return record is preserved for audit but has no financial impact on any computed value.

**Alternatives considered**: Creating explicit reversal journal entries — rejected because compute-on-read makes them unnecessary and they would add complexity without benefit.

---

## Decision 7: Return Amount Cap (Invoice-Level)

**Decision**: Cumulative active return amounts must not exceed `invoice.total`. Validation occurs at save time.

**Rationale**: The spec (FR-005) requires that the total returned amount across all active returns for an invoice cannot exceed the invoice total. This is a server-enforceable invariant that prevents over-crediting.

**Alternatives considered**: Capping at `invoice.total − totalReceipts` — rejected because returns can create client credits (§IV: "If the invoice is already fully paid, the return creates a client credit balance").

---

## Decision 8: Client Balance Computation

**Decision**: Client balance = `SUM(active invoice totals) − SUM(active receipt amounts) − SUM(active return totals)`. Positive = debtor, negative = creditor.

**Rationale**: Returns reduce the client's obligation. When returns exceed unpaid balance, the client has a credit. This is computed on-read from the three source tables. No separate credit table is needed.

**Alternatives considered**: Separate ClientCredit entity — rejected per constitution (compute-on-read; no materialized projections).
