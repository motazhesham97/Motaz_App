# Feature Specification: Partial Returns & Reversals

**Feature Branch**: `007-partial-returns-reversals`  
**Created**: 2026-04-12  
**Status**: Draft  
**Input**: Phase 7 from docs/implementation-plan.md — Partial Returns & Reversals

---

## Clarifications

### Session 2026-04-12

- Q: Is the return amount per line auto-calculated or manually entered? → A: Auto-fills from `returned_quantity × original_unit_price`, but the owner can manually override downward. The entered amount must not exceed `returned_quantity × original_unit_price`.

## User Scenarios & Testing

### User Story 1 — Create Partial Return from Invoice (Priority: P1)

The business owner opens a previously created sales invoice and initiates a partial return. They select one or more invoice lines to return, specifying the quantity returned and the return amount for each line. The system validates the entries against the original invoice, computes the total returned amount, and saves the return record with its lines.

**Why this priority**: Without the ability to record returns, the accounting system overstates revenue. This is the foundational feature upon which all other return-related functionality depends.

**Independent Test**: Can be fully tested by creating an invoice, then creating a return against it. The return record and lines are saved to the local database with correct financial values.

**Acceptance Scenarios**:

1. **Given** an active invoice with 3 lines, **When** the owner selects 2 lines and enters valid returned quantities and amounts, **Then** a SalesReturn record is created with the correct `totalReturnedAmount` and 2 SalesReturnLine records are created.
2. **Given** an active invoice line with quantity 10 and unit price 5000, **When** the owner enters returned quantity 3, **Then** the return amount auto-fills to 15000. The owner may reduce it (e.g., to 12000 for damaged goods) but cannot increase it above 15000.
3. **Given** a voided invoice, **When** the owner attempts to create a return, **Then** the system blocks the action and displays an error message.
4. **Given** an invoice line where a previous return already consumed 5 of 10 units, **When** the owner attempts to return 6 more, **Then** the system blocks the action (would exceed original line quantity).

---

### User Story 2 — Financial Effect on Invoice Balance (Priority: P1)

When a return is created against an invoice that has an outstanding (unpaid) balance, the return reduces the invoice's outstanding balance. The business owner sees the updated remaining balance on the invoice and in the client statement immediately.

**Why this priority**: Returns must correctly affect accounting balances to maintain financial integrity. This is a core accounting rule, not optional.

**Independent Test**: Create an invoice for 100,000, pay 50,000 via receipt, create a return for 20,000. The remaining balance should be 30,000 (100,000 − 50,000 paid − 20,000 returned).

**Acceptance Scenarios**:

1. **Given** an invoice with total 100,000 and no receipts, **When** a return of 20,000 is created, **Then** the computed remaining balance is 80,000.
2. **Given** an invoice with total 100,000 and receipts totaling 60,000, **When** a return of 25,000 is created, **Then** the remaining balance is 15,000 (100,000 − 60,000 − 25,000).
3. **Given** an invoice with total 100,000 and receipts totaling 100,000 (fully paid), **When** a return of 30,000 is created, **Then** the client has a credit balance of 30,000.

---

### User Story 3 — Client Credit from Fully Paid Return (Priority: P2)

When a return is created against a fully paid invoice, the return amount creates a client credit balance. The business owner sees the client's balance shift from zero (or debtor) to creditor status. Cash refund workflows are out of scope — the credit is simply tracked.

**Why this priority**: Common business scenario when goods are returned after full payment. The system must handle this correctly to avoid phantom receivables.

**Independent Test**: Create a fully paid invoice, issue a return, verify the client balance reflects the credit.

**Acceptance Scenarios**:

1. **Given** an invoice fully paid (total = receipts), **When** a return of 15,000 is created, **Then** the client balance becomes −15,000 (credit/creditor).
2. **Given** a client with existing credit of −10,000, **When** a new invoice of 25,000 is created, **Then** the net client balance is 15,000 (debtor).

---

### User Story 4 — View Returns List (Priority: P2)

The business owner views a list of all sales returns, sorted by date (newest first). Each entry shows the linked invoice reference, return date, total returned amount, and status. Voided returns are visually distinguished.

**Why this priority**: Essential for the owner to review and manage return history.

**Independent Test**: Create several returns (some active, some voided), navigate to the returns list, and verify all appear correctly sorted and labeled.

**Acceptance Scenarios**:

1. **Given** 5 returns in the system, **When** the owner opens the returns list, **Then** all 5 appear ordered by return date descending.
2. **Given** a voided return, **When** it appears in the list, **Then** it is rendered with reduced visual emphasis and a "ملغى" badge.
3. **Given** no returns exist, **When** the owner opens the returns list, **Then** an empty state message is displayed.

---

### User Story 5 — Void Return with Reversal (Priority: P1)

The business owner voids a previously created return. The system requires a reason, reverses all accounting effects (restores the invoice outstanding balance and removes any client credit created by the return), and preserves the voided return for audit history.

**Why this priority**: Without voiding, there is no way to correct a return created in error. The reversal of accounting effects is critical for financial integrity.

**Independent Test**: Create a return, void it, verify the invoice remaining balance returns to pre-return value.

**Acceptance Scenarios**:

1. **Given** an active return reducing invoice balance by 20,000, **When** the owner voids it with reason "خطأ في الإدخال", **Then** the return status becomes VOIDED, the void reason is stored, and the invoice remaining balance increases by 20,000.
2. **Given** a return that created a client credit of 15,000, **When** it is voided, **Then** the client credit is removed (balance returns to 0 or debtor).
3. **Given** an already voided return, **When** the owner attempts to void it again, **Then** the system blocks the action.

---

### User Story 6 — Invoice Edit Restrictions After Return (Priority: P2)

Once a return exists against an invoice, the invoice is locked for financial editing. The business owner can still edit non-financial fields (notes, attachment metadata) but cannot change the client, discount, line items, quantities, or prices.

**Why this priority**: Allowing financial edits after a return would create accounting inconsistencies. This is a constitution-mandated constraint.

**Independent Test**: Create an invoice, create a return against it, attempt to edit a financial field on the invoice — verify it is blocked.

**Acceptance Scenarios**:

1. **Given** an invoice with an active return, **When** the owner tries to edit the invoice discount, **Then** the system blocks the edit with a message explaining why.
2. **Given** an invoice with an active return, **When** the owner edits the invoice note, **Then** the edit is accepted and saved.
3. **Given** an invoice with only a voided return (no active returns), **When** the owner tries to edit a financial field, **Then** the edit is allowed (voided returns do not restrict).

---

### User Story 7 — Return from Invoice Detail Screen (Priority: P3)

From the invoice detail or list screen, the business owner can tap a "إنشاء مرتجع" (Create Return) action to navigate to the return form pre-filled with the invoice context. This streamlines the return creation workflow.

**Why this priority**: UX convenience — a natural entry point for creating a return. Lower priority because functionally the return can also be created from a standalone returns screen.

**Independent Test**: Navigate to an invoice, tap the create return action, verify the return form opens with the invoice pre-selected.

**Acceptance Scenarios**:

1. **Given** an active invoice, **When** the owner taps "إنشاء مرتجع", **Then** the return form opens with the invoice already linked and its lines displayed for selection.
2. **Given** a voided invoice, **When** looking at the invoice detail, **Then** no "إنشاء مرتجع" action is available.

---

### Edge Cases

- What happens when a return amount exceeds the remaining returnable amount for a line? → System blocks with validation error.
- What happens when trying to return from a voided invoice? → System blocks; only active invoices allow returns.
- What happens when a return is voided and then a new return is created for the same lines? → Allowed; voided returns do not count toward returned-quantity limits.
- What happens when total returned amount for an invoice exceeds the invoice total? → System blocks; cumulative returns must not exceed invoice total.
- What happens when a return is created while offline? → Saved locally, synced later via outbox.
- What happens when one device creates a return and another device voids the same invoice before sync? → Void wins (constitution rule). The return references a voided invoice.

---

## Requirements

### Functional Requirements

- **FR-001**: System MUST allow creation of a partial return only against an active (non-voided) invoice.
- **FR-002**: System MUST require at least one return line per return.
- **FR-003**: Each return line MUST reference an existing invoice line and specify a returned quantity > 0 and a returned amount > 0. The return amount MUST auto-fill as `returned_quantity × original_unit_price` and the owner MAY override it downward. The entered amount MUST NOT exceed `returned_quantity × original_unit_price`.
- **FR-004**: System MUST validate that the returned quantity for any invoice line does not exceed the original line quantity minus previously returned (active) quantities for that line.
- **FR-005**: System MUST validate that the cumulative returned amount across all active returns for an invoice does not exceed the invoice total.
- **FR-006**: System MUST compute `totalReturnedAmount` on the SalesReturn header as the sum of all its return line `returnedAmount` values.
- **FR-007**: System MUST store the return date as a user-selectable date (not necessarily today).
- **FR-008**: System MUST save the return and its lines atomically in a single local transaction, with a sync outbox entry.
- **FR-009**: System MUST allow an optional note on the return header.
- **FR-010**: System MUST compute the invoice remaining balance as: `invoiceTotal − totalAllocatedReceipts − totalActiveReturns`.
- **FR-011**: When the invoice is fully paid and a return is created, the system MUST reflect the returned amount as a client credit (negative balance contribution).
- **FR-012**: System MUST allow voiding a return with a mandatory reason.
- **FR-013**: When a return is voided, the system MUST reverse all accounting effects: restore the invoice outstanding balance and remove the client credit if any was created.
- **FR-014**: System MUST prevent voiding an already voided return.
- **FR-015**: System MUST restrict invoice editing to non-financial fields when active returns exist (notes, attachment metadata only). Financial fields (client, discount, lines, quantities, prices) MUST be blocked.
- **FR-016**: System MUST NOT count voided returns toward quantity limits or financial restrictions.
- **FR-017**: System MUST display the returns list sorted by return date descending, with voided returns visually distinguished.
- **FR-018**: System MUST update the Net Sales calculation to subtract active return totals: `Net Sales = Active Invoice Totals − Invoice Discounts − Active Return Totals`.
- **FR-019**: System MUST store all return records using minor-unit integers. No double/float allowed.
- **FR-020**: System MUST preserve voided return records and never hard-delete them.
- **FR-021**: System MUST apply a 300ms debounce to search within the returns list.
- **FR-022**: System MUST create the return and return line sync outbox entries using the existing `SALES_RETURN` and `SALES_RETURN_LINE` entity types from the ParentEntityType enum.
- **FR-023**: System MUST wrap the returns list screen with `AppDrawerScaffold` for consistent navigation.
- **FR-024**: System MUST provide a "إنشاء مرتجع" action from the invoice detail/list when the invoice is active.

### Key Entities

- **SalesReturn**: A partial financial return against a specific invoice. Contains: invoice reference, return date, total returned amount, optional note, status (ACTIVE/VOIDED), void reason, audit fields (timestamps, device, row version, sync status).
- **SalesReturnLine**: An individual line within a return. Contains: reference to return header, reference to original invoice line, returned quantity, returned amount, timestamps.
- **SalesInvoice** (existing): Outstanding balance computation affected by returns.
- **ReceiptAllocation** (existing): Used in balance computation alongside returns.
- **Client** (existing): Balance affected by return credits.

---

## Success Criteria

### Measurable Outcomes

- **SC-001**: Owner can create a return in under 1 minute from an existing invoice.
- **SC-002**: Invoice remaining balance updates correctly within 1 second after a return is created or voided.
- **SC-003**: 100% of return creation attempts against voided invoices are blocked with a clear error message.
- **SC-004**: 100% of attempts to exceed line quantity limits are blocked with a clear validation error.
- **SC-005**: Voided returns have zero effect on invoice balances, client balances, and net sales calculations.
- **SC-006**: All return records survive app restart and sync correctly when connectivity returns.
- **SC-007**: Net Sales in all profit and dashboard calculations correctly subtract active return totals.
- **SC-008**: Invoice edit restrictions are enforced 100% of the time when active returns exist, and relaxed 100% of the time when only voided returns exist.

---

## Assumptions

- The SalesReturns and SalesReturnLines tables already exist in the database schema (created in Phase 2).
- The `SALES_RETURN` and `SALES_RETURN_LINE` values already exist in the ParentEntityType enum.
- No new schema migration is required for this phase — existing tables are sufficient.
- Receipt reallocation after return is handled via compute-on-read balance queries, not by physically rearranging allocation records. The remaining balance formula already factors in returns.
- Cash refund workflows are explicitly out of scope (constitution §IV).
- The existing `ProfitEngine.computeMonthlyNetSales` already subtracts `sales_returns.total_returned_amount` from invoice totals (verified in Phase 6 implementation).
