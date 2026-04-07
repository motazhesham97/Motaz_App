# Research: Invoices & Receipts

**Feature**: 005-invoices-receipts  
**Date**: 2026-04-07  
**Status**: Complete

---

## 1. Invoice Local Reference Generation

**Decision**: Use `INV-<deviceCode>-<localSequence>` format with `nextInvoiceSequence` from the `Devices` table.

**Rationale**: The `Devices` table already has a `nextInvoiceSequence` column (integer, default 1). Each invoice creation reads the current value, formats the local ref, and atomically increments the sequence within the same transaction. This guarantees uniqueness per device without network access. The `deviceCode` is a 4-character uppercase string derived from the device UUID.

**Alternatives considered**:
- UUID-only reference: Rejected — not human-readable for daily business use.
- Central server sequence: Rejected — violates offline-first requirement.
- Timestamp-based: Rejected — collisions possible if two invoices created in the same second.

---

## 2. Atomic Invoice + Receipt Creation

**Decision**: Use a single Drift `_db.transaction()` to insert the invoice, all its lines, the optional receipt, the optional receipt allocation, and all sync outbox entries atomically.

**Rationale**: This is the established pattern from Phase 4 (ProductRepository, ClientRepository). A single transaction ensures that either all records are saved or none are — no orphaned receipts or missing outbox entries. The transaction also atomically increments the invoice sequence on the device record.

**Alternatives considered**:
- Separate transactions: Rejected — risks orphaned receipts or invoices without matching outbox entries.
- Event sourcing: Rejected — over-engineering for MVP; outbox pattern is sufficient.

---

## 3. FIFO Allocation Engine

**Decision**: Implement as a pure function in the repository that queries unpaid invoices ordered by `invoiceDate ASC, createdAt ASC`, iterates through them, and generates `ReceiptAllocation` records until the receipt amount is exhausted or all invoices are covered.

**Rationale**: All amounts are minor-unit integers, so allocation is exact — no rounding. The function produces a list of `ReceiptAllocationCompanion` objects which are inserted inside the transaction. Remaining unallocated amount (if any) is simply not allocated — it becomes implicit client credit.

**Alternatives considered**:
- Stored procedure in SQLite: Rejected — Drift doesn't support SQLite stored procedures; logic belongs in Dart.
- Materialized balance column: Rejected — constitution mandates compute-on-read for balances.

---

## 4. Invoice Remaining Balance Computation

**Decision**: Compute on-read via a repository method: `remaining = invoice.total - SUM(allocations WHERE receipt.status = ACTIVE)`.

**Rationale**: Consistent with Phase 4's `getOutstandingBalance` approach. No stored balance column — the `ReceiptAllocations` table is the source of truth for payments. Only allocations whose parent receipt is ACTIVE count.

**Alternatives considered**:
- Cached `paidAmount` column on invoice: Rejected — risks stale data after receipt voids; constitution demands compute-on-read.
- Trigger-based update: Rejected — SQLite triggers are fragile with Drift.

---

## 5. Invoice Edit State Detection

**Decision**: Three-state detection via two queries at form load time:
1. `hasReceipts`: `SELECT COUNT(*) FROM receipts WHERE invoiceId = ? AND status = 0` (ACTIVE)
2. `hasReturns`: `SELECT COUNT(*) FROM sales_returns WHERE invoiceId = ? AND status = 0` (ACTIVE)

The edit form uses these flags to determine the constraint level.

**Rationale**: Simple, fast, and deterministic. No need for a separate state machine — the two boolean flags map directly to the three editing modes.

**Alternatives considered**:
- Stored enum on invoice: Rejected — would require synchronization between invoice and receipt/return lifecycle events.
- Check at save time only: Rejected — poor UX; user should see disabled fields before attempting to save.

---

## 6. Invoice Void with Receipt Reallocation

**Decision**: When an invoice is voided and has active receipt allocations:
1. Delete all `ReceiptAllocation` rows for this invoice.
2. For each affected receipt, re-run the FIFO allocator against the client's remaining unpaid invoices (excluding the voided one).
3. If no other unpaid invoices exist, the freed receipt amounts become unallocated client credit (receipts stay ACTIVE).
4. All operations happen inside a single transaction.

**Rationale**: Reuses the same FIFO allocation function used for general receipts. Client credit is consistent with US6 spec behavior. Receipts are never auto-voided by an invoice void — they represent real money received.

**Alternatives considered**:
- Auto-void receipts on invoice void: Rejected — receipts represent actual payments; voiding them would lose record of money received.
- Manual reallocation by user: Rejected — unnecessarily complex UX for MVP.

---

## 7. Receipt Void Behavior

**Decision**: When a receipt is voided, only its allocations are removed. No re-allocation of other receipts is triggered.

**Rationale**: Per FR-018, voiding a receipt simply removes its contribution. This is intentionally different from invoice void (which triggers re-allocation) because receipt void is a simpler operation — the invoices' remaining balances simply increase.

**Alternatives considered**:
- Re-allocate remaining receipts after void: Rejected — would create unexpected side effects and complexity.

---

## 8. Sync Outbox Pattern for Multi-Entity Transactions

**Decision**: For invoice creation with payment, create separate outbox entries for each entity type (SALES_INVOICE, SALES_INVOICE_LINE ×N, RECEIPT, RECEIPT_ALLOCATION). All within the same transaction.

**Rationale**: The sync engine processes outbox entries individually by entity type. Separate entries ensure each entity can be pushed and reconciled independently. The existing `SyncOutbox` schema supports this with its `entityType` + `entityId` design.

**Alternatives considered**:
- Single aggregate outbox entry: Rejected — doesn't match existing sync infrastructure.

---

## 9. Product Autocomplete for Invoice Builder

**Decision**: Reuse the existing `activeProductSearchProvider` from Phase 4 which queries `WHERE name LIKE '%query%' AND isActive = 1`.

**Rationale**: Already implemented and tested. No changes needed. The invoice form will consume this provider directly.

**Alternatives considered**:
- New provider: Rejected — existing provider exactly matches the requirement.
