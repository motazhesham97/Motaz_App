# Feature Specification: Invoices & Receipts

**Feature Branch**: `005-invoices-receipts`  
**Created**: 2026-04-07  
**Status**: Draft  
**Input**: Phase 5 from `docs/implementation-plan.md` — Launch the core commercial transaction engine

---

## User Scenarios & Testing

### User Story 1 — Create a Sales Invoice (Priority: P1)

The owner opens the invoice screen, selects a client, adds one or more products from an autocomplete search, adjusts quantities and unit prices as needed, optionally enters an invoice-level discount, and saves the invoice. The invoice is saved locally, assigned a local reference number (`INV-<deviceCode>-<localSequence>`), its total is computed automatically, and a sync outbox entry is created.

**Why this priority**: Invoices are the atomic unit of revenue. Without invoice creation, no downstream feature (receipts, returns, reports) works.

**Independent Test**: With the device offline, create an invoice for an existing client with 2 products, verify the invoice appears in the invoice list with the correct total and local reference.

**Acceptance Scenarios**:

1. **Given** the owner has products and clients in the system, **When** the owner creates an invoice with client "أحمد", product "عصير مانجو" ×2 at 500.00 YER and product "شاي" ×1 at 200.00 YER with a 100.00 YER discount, **Then** the invoice total is (2×500.00 + 1×200.00) − 100.00 = 1100.00 YER, the invoice status is ACTIVE, and a local ref like `INV-D1-001` is assigned.
2. **Given** the owner is offline, **When** the owner creates and saves an invoice, **Then** the invoice is stored locally with a sync outbox entry and is visible in the invoice list immediately.
3. **Given** no clients exist, **When** the owner tries to create an invoice, **Then** the system prevents saving until a client is selected (mandatory client).
4. **Given** the owner is building an invoice, **When** the owner searches for a product, **Then** only active products appear in the autocomplete results.

---

### User Story 2 — Capture Payment at Invoice Creation (Priority: P1)

During invoice creation, the owner may enter a paid amount. If a paid amount greater than zero is entered, an invoice-linked receipt is created automatically in the same local transaction as the invoice. The paid amount must not exceed the invoice total.

**Why this priority**: Most small businesses collect payment at the point of sale. This flow is the primary commercial transaction and must be atomic.

**Independent Test**: Create an invoice for 1000.00 YER with a paid amount of 600.00 YER, verify both the invoice and a linked receipt appear, and the invoice's remaining balance is 400.00 YER.

**Acceptance Scenarios**:

1. **Given** the owner is creating an invoice with total 1000.00 YER, **When** the owner enters a paid amount of 600.00 YER and saves, **Then** both the invoice and an INVOICE_LINKED receipt for 600.00 YER are saved in the same local transaction, a receipt allocation of 600.00 YER against this invoice is created, and two outbox entries are created (one for the invoice, one for the receipt).
2. **Given** the owner is creating an invoice with total 500.00 YER, **When** the owner enters a paid amount of 500.00 YER, **Then** the invoice is fully paid and the remaining balance is 0.
3. **Given** the owner is creating an invoice with total 500.00 YER, **When** the owner enters a paid amount of 600.00 YER, **Then** the system rejects the amount with a validation error: the paid amount cannot exceed the invoice total.
4. **Given** the owner leaves the paid amount empty or enters 0, **When** saving the invoice, **Then** only the invoice is created — no receipt is generated.

---

### User Story 3 — Edit a Sales Invoice (Priority: P1)

The owner opens an existing active invoice and edits its fields. The editing rules depend on whether receipts or returns exist against the invoice:

- **No receipts and no returns**: All fields can be edited freely (client, lines, quantities, prices, discount, note).
- **Receipts exist but no returns**: All fields can be edited, but the new invoice total must not be lower than the total amount already collected through receipts.
- **Returns exist**: Only non-financial fields (note, attachment metadata) may be edited. Client, discount, lines, quantities, and prices are locked.

**Why this priority**: Invoices frequently need correction after creation. The editing rules protect financial integrity while remaining flexible.

**Independent Test**: Create an invoice with no payments, edit the quantity of a line item, verify the total recalculates and saves correctly.

**Acceptance Scenarios**:

1. **Given** an active invoice with no receipts and no returns, **When** the owner changes a line quantity from 2 to 3, **Then** the total recalculates, the invoice is updated locally, row version increments, and an outbox entry is created.
2. **Given** an active invoice with total 1000.00 YER and 600.00 YER collected through receipts, **When** the owner tries to reduce the total to 500.00 YER, **Then** the system rejects the edit with a validation error: the new total cannot be less than the amount already collected (600.00 YER).
3. **Given** an active invoice with total 1000.00 YER and 600.00 YER collected, **When** the owner changes the total to 800.00 YER (which is ≥ 600.00 collected), **Then** the edit succeeds.
4. **Given** an active invoice that has a partial return, **When** the owner tries to edit lines, quantities, or prices, **Then** those fields are disabled and the owner can only edit the note.
5. **Given** a voided invoice, **When** the owner tries to open it for editing, **Then** the system prevents editing entirely and shows the invoice as read-only.

---

### User Story 4 — Void a Sales Invoice (Priority: P1)

The owner voids an active invoice by providing a reason. Voiding sets the invoice status to VOIDED and preserves audit history. Invoice attachments remain linked and are not deleted.

**Why this priority**: Voiding is the only way to cancel an invoice (no hard delete allowed). It's essential for correcting mistakes and maintaining audit integrity.

**Independent Test**: Create an invoice, void it with reason "خطأ في البيانات", verify the invoice shows as voided, the reason is stored, and it no longer appears in active invoice calculations.

**Acceptance Scenarios**:

1. **Given** an active invoice with no receipts and no returns, **When** the owner voids it with reason "خطأ في البيانات", **Then** the invoice status changes to VOIDED, the void reason is stored, an outbox entry is created, and the invoice no longer counts in sales or receivables calculations.
2. **Given** an active invoice with receipts, **When** the owner voids the invoice, **Then** the invoice is voided, all linked receipt allocations for this invoice are reversed (freed), and the freed receipt amounts are re-allocated via FIFO to the client's other oldest unpaid invoices. If the client has no other unpaid invoices, the freed amounts become unallocated client credit (the receipts remain active).
3. **Given** a voided invoice, **When** the owner views it, **Then** it is displayed with a clear "ملغية" (voided) indicator and the void reason is visible.
4. **Given** an invoice void is requested, **When** the owner does not provide a void reason, **Then** the system rejects the void and requires a reason.

---

### User Story 5 — Create an Invoice-Linked Receipt (Priority: P1)

After an invoice is created, the owner can create an additional receipt linked to that invoice. The receipt amount must not exceed the invoice's remaining unpaid balance.

**Why this priority**: Follow-up payments on existing invoices are a core daily operation.

**Independent Test**: Create an invoice for 1000.00 YER, pay 400.00 YER at creation, then create a second invoice-linked receipt for 300.00 YER, verify the remaining balance is 300.00 YER.

**Acceptance Scenarios**:

1. **Given** an active invoice with a remaining balance of 400.00 YER, **When** the owner creates an invoice-linked receipt for 300.00 YER, **Then** a receipt is saved with type INVOICE_LINKED, a receipt allocation of 300.00 YER against this invoice is created, and the remaining balance drops to 100.00 YER.
2. **Given** an active invoice with a remaining balance of 400.00 YER, **When** the owner creates a receipt for 400.00 YER, **Then** the invoice is fully paid (remaining balance = 0).
3. **Given** an active invoice with a remaining balance of 400.00 YER, **When** the owner tries to create a receipt for 500.00 YER, **Then** the system rejects the amount: it cannot exceed the remaining balance.
4. **Given** a voided invoice, **When** the owner tries to create a receipt for it, **Then** the system prevents receipt creation on a voided invoice.

---

### User Story 6 — Create a General Client Receipt with FIFO Allocation (Priority: P2)

The owner creates a general receipt (payment on account) for a client without linking it to a specific invoice. The system automatically allocates the receipt amount to the client's oldest unpaid invoices first, using FIFO order (by invoice date, then by creation date).

**Why this priority**: Some clients pay a lump sum covering multiple invoices. FIFO auto-allocation saves manual work while maintaining correct accounting.

**Independent Test**: Create 3 invoices for a client (1000, 800, 500 YER), create a general receipt for 1500 YER, verify allocations: 1000 to first invoice, 500 to second invoice, third invoice untouched.

**Acceptance Scenarios**:

1. **Given** client "أحمد" has 3 unpaid invoices: #001 (1000 YER, oldest), #002 (800 YER), #003 (500 YER), **When** the owner creates a general receipt for 1500 YER, **Then** FIFO allocation creates: 1000 YER → #001 (fully paid), 500 YER → #002 (partially paid), #003 untouched.
2. **Given** a client has no outstanding invoices, **When** the owner creates a general receipt for 500 YER, **Then** the receipt is saved with no allocations — the amount becomes a client credit balance.
3. **Given** a client has one unpaid invoice of 300 YER, **When** the owner creates a general receipt for 500 YER, **Then** 300 YER is allocated to the invoice (fully paid), 200 YER remains unallocated (client credit).
4. **Given** a general receipt is created, **When** the system allocates it, **Then** each allocation record is a separate `ReceiptAllocation` row (receiptId, invoiceId, allocatedAmount).

---

### User Story 7 — Void a Receipt (Priority: P2)

The owner voids an existing receipt by providing a reason. Voiding reverses the receipt's allocations and re-allocates any remaining receipts against the affected invoices via FIFO.

**Why this priority**: Receipt mistakes must be correctable while maintaining correct allocation state. This is critical for accurate client balances.

**Independent Test**: Create an invoice for 1000 YER, pay 600 YER, void the receipt, verify the invoice remaining balance returns to 1000 YER.

**Acceptance Scenarios**:

1. **Given** an invoice-linked receipt of 600 YER with allocations, **When** the owner voids the receipt with reason "مبلغ خاطئ", **Then** the receipt status becomes VOIDED, all allocations for this receipt are removed, the invoice's remaining balance increases by 600 YER, and an outbox entry is created.
2. **Given** a general receipt with multiple allocations spread across 3 invoices, **When** the owner voids the receipt, **Then** all allocations are reversed, and each of the 3 invoices' remaining balances increase by the respective allocated amounts.
3. **Given** a voided receipt, **When** the owner tries to void it again, **Then** the system prevents double-voiding.
4. **Given** a receipt void without a reason, **When** the void request is submitted, **Then** the system rejects it and requires a reason.

---

### User Story 8 — View Invoice List and Details (Priority: P1)

The owner can view a list of all invoices, filtered by status (active/voided) and searchable by client name or local reference. Tapping an invoice shows full details including lines, payment summary, and remaining balance.

**Why this priority**: Viewing and navigating invoices is the primary daily task for managing sales activity.

**Independent Test**: Create 5 invoices for different clients, open the invoice list, search by client name, verify matching invoices appear with correct totals and status.

**Acceptance Scenarios**:

1. **Given** the owner has 50 invoices, **When** the owner opens the invoice list, **Then** invoices are displayed ordered by date (newest first), showing: local ref, client name, total, status (active/voided), and remaining balance.
2. **Given** the owner searches "أحمد" in the invoice list, **When** results load, **Then** only invoices belonging to client "أحمد" are shown.
3. **Given** the owner taps an invoice, **When** the invoice detail screen opens, **Then** the screen shows: local ref, client name, invoice date, all line items (product name, quantity, unit price, line total), invoice-level discount, invoice total, list of receipts and their amounts, remaining balance, status, and void reason (if voided).

---

### User Story 9 — View Receipt List (Priority: P2)

The owner can view a list of all receipts, searchable by client name. Each receipt shows its type (invoice-linked or general), amount, date, and status.

**Why this priority**: Viewing receipts allows the owner to track collection activity.

**Independent Test**: Create several receipts (both types), open the receipt list, verify all receipts appear with correct type labels and amounts.

**Acceptance Scenarios**:

1. **Given** the owner has receipts of both types, **When** the receipt list opens, **Then** receipts are ordered by date (newest first) showing: client name, amount, type ("مرتبط بفاتورة" or "دفعة عامة"), date, and status.
2. **Given** the owner searches by client name, **When** results load, **Then** only receipts for matching clients appear.

---

### Edge Cases

- What happens if the owner creates an invoice with zero line items? → The system must require at least one line item.
- What happens if the owner sets a line quantity to zero? → The system must require a positive quantity (≥ 1).
- What happens if the invoice-level discount exceeds the sum of line totals? → The system must reject: discount cannot exceed the pre-discount subtotal.
- What happens if a product used in a past invoice is later disabled? → The invoice remains valid. The line references the product by ID. The disabled product simply won't appear in autocomplete for new invoices.
- What happens if the owner tries to create a general receipt for a negative amount? → The system must reject negative receipt amounts.
- What happens if FIFO allocation encounters rounding issues? → All amounts are minor-unit integers. No rounding is needed — allocation is exact integer arithmetic.
- What happens if the owner edits an invoice and the new total exactly equals the collected amount? → The edit succeeds. Remaining balance becomes 0.

---

## Requirements

### Functional Requirements — Invoices

- **FR-001**: The system MUST allow the owner to create a sales invoice with a mandatory client selection, at least one line item, an optional invoice-level discount, and an optional note.
- **FR-002**: Each invoice line MUST specify a product (via autocomplete), a quantity (positive integer ≥ 1), and a unit price (minor-unit integer ≥ 0). The unit price MUST default to the product's `defaultSalePrice` but may be overridden.
- **FR-003**: The system MUST compute the invoice total automatically as: `Σ(line quantity × unit price) − invoice-level discount`. All arithmetic MUST use minor-unit integers. No `double` anywhere in the money path.
- **FR-004**: The invoice-level discount MUST NOT exceed the pre-discount subtotal (sum of all line totals).
- **FR-005**: Each invoice MUST be assigned a unique local reference in the format `INV-<deviceCode>-<localSequence>`, generated locally per device without requiring network access.
- **FR-006**: Invoice creation MUST save the invoice, all its lines, and an optional payment receipt (if `paidAmount > 0`) in a single atomic local transaction with corresponding sync outbox entries.
- **FR-007**: Product autocomplete during invoice creation MUST show only active products.
- **FR-008**: The system MUST support editing an active invoice under these rules:
  - No receipts and no returns: all fields editable (client, lines, discount, note).
  - Receipts exist, no returns: all fields editable, but new total MUST NOT be less than total amount already collected.
  - Returns exist: only note and attachment metadata are editable.
- **FR-009**: The system MUST NOT allow editing a voided invoice.
- **FR-010**: The system MUST allow voiding an active invoice, requiring a text reason. When an invoice with receipts is voided, all allocations for that invoice MUST be reversed and freed receipt amounts MUST be re-allocated via FIFO to the client's other oldest unpaid invoices. If no other unpaid invoices exist for the client, the freed receipt amounts become unallocated client credit — the receipts themselves remain ACTIVE.
- **FR-011**: Invoice attachments MUST remain linked when an invoice is voided.
- **FR-012**: All invoice monetary values (discount, total, line totals, unit prices) MUST be stored as minor-unit integers.

### Functional Requirements — Receipts

- **FR-013**: The system MUST support two receipt types: INVOICE_LINKED and GENERAL.
- **FR-014**: An invoice-linked receipt MUST reference a specific active invoice, and its amount MUST NOT exceed the invoice's remaining unpaid balance.
- **FR-015**: A general client receipt MUST auto-allocate to the client's oldest unpaid invoices first (FIFO by invoice date, then by creation date). If the receipt exceeds all outstanding invoices, the unallocated amount becomes a client credit balance.
- **FR-016**: Each FIFO allocation MUST be stored as an explicit `ReceiptAllocation` record with receiptId, invoiceId, and allocatedAmount.
- **FR-017**: The system MUST allow voiding a receipt, requiring a text reason. When a receipt is voided, all its allocations MUST be reversed.
- **FR-018**: After voiding a receipt that had allocations against an invoice (which still has other receipts), the remaining receipts for that invoice MUST NOT be re-allocated — only the voided receipt's allocations are removed.
- **FR-019**: All receipt amounts and allocation amounts MUST be stored as minor-unit integers.
- **FR-020**: The system MUST NOT allow creating a receipt for a voided invoice.
- **FR-021**: The system MUST NOT allow voiding an already-voided receipt.

### Functional Requirements — Invoice List & Navigation

- **FR-022**: The invoice list MUST display invoices ordered by date (newest first) showing: local ref, client name, total, remaining balance, and status.
- **FR-023**: The invoice list MUST support searching by client name or local reference with live filtering and 300ms debounce.
- **FR-024**: The invoice detail screen MUST show: local ref, client name, invoice date, all line items, discount, total, list of receipts with amounts, remaining balance, status, and void reason (if voided).

### Functional Requirements — Receipt List & Navigation

- **FR-025**: The receipt list MUST display receipts ordered by date (newest first) showing: client name, amount, receipt type label, date, and status.
- **FR-026**: The receipt list MUST support searching by client name with live filtering and 300ms debounce.

### Functional Requirements — Cross-Cutting

- **FR-027**: Every mutation (create, update, void) MUST save the entity and a sync outbox entry in a single local transaction.
- **FR-028**: All screens MUST display text in Arabic and render correctly in RTL layout.
- **FR-029**: Financial conflicts (amounts, prices, discounts, quantities, dates, clientId, lines, allocations) MUST NOT be silently auto-merged during sync. They MUST be surfaced as conflict records.
- **FR-030**: If one device voids an invoice/receipt and another device edits the same record before sync, void MUST win.

### Key Entities

- **SalesInvoice**: Core revenue document. Contains client reference, invoice date, invoice-level discount, computed total, local reference, status (ACTIVE/VOIDED), void reason, note.
- **SalesInvoiceLine**: Individual line item within an invoice. Contains product reference, quantity, unit price, computed line total.
- **Receipt**: Payment record. Two types: INVOICE_LINKED (tied to a specific invoice) and GENERAL (payment on account). Contains client reference, optional invoice reference, amount, date, type, status, void reason, note.
- **ReceiptAllocation**: Explicit FIFO allocation record. Links a receipt to an invoice with the allocated amount. A business record, not a derived cache.

---

## Success Criteria

### Measurable Outcomes

- **SC-001**: The owner can create an invoice with up to 20 line items and save it locally in under 2 seconds, including payment capture, while fully offline.
- **SC-002**: Invoice total computation is always correct for any combination of line items and discount, verified via: `total = Σ(qty × unitPrice) − discount`, with all arithmetic in minor-unit integers.
- **SC-003**: FIFO allocation distributes a general receipt across multiple invoices correctly, verified by: oldest invoice filled first, each allocation is an explicit record, allocated amounts sum to the receipt amount (or the total of all outstanding balances, whichever is smaller).
- **SC-004**: Voiding an invoice with receipts correctly re-allocates freed amounts to other unpaid invoices via FIFO, verified by checking allocation records before and after the void.
- **SC-005**: Invoice editing rules enforce the correct constraint for each state: unrestricted, receipt-constrained (total ≥ collected), or return-locked (note-only), with no bypass path.
- **SC-006**: All 9 user stories (create, pay-at-creation, edit, void invoice, linked receipt, general receipt, void receipt, invoice list, receipt list) work fully offline with sync outbox entries created for every mutation.
- **SC-007**: Client remaining balance (computed on-read as: invoice totals − receipt amounts for active records) is accurate to the minor unit after any sequence of creates, edits, voids, and allocations.
- **SC-008**: The owner can navigate and search through 500+ invoices with results appearing within 1 second.
- **SC-009**: Receipt creation screen prevents the owner from entering an amount exceeding the remaining balance (invoice-linked) or a negative amount (both types) — 100% enforcement with no bypass.
- **SC-010**: Every voided record retains its void reason, audit timestamps, and linked attachments — no data loss on void.

---

## Assumptions

- Products and clients already exist in the system (Phase 4 complete).
- The sync engine (Phase 3) is operational and handles outbox entries for SALES_INVOICE, SALES_INVOICE_LINE, RECEIPT, and RECEIPT_ALLOCATION entity types.
- The existing schema for `SalesInvoices`, `SalesInvoiceLines`, `Receipts`, and `ReceiptAllocations` tables is sufficient — no schema migration is needed for this phase.
- `RecordStatus` enum (ACTIVE, VOIDED) and `ReceiptType` enum (INVOICE_LINKED, GENERAL) already exist.
- Invoice local reference sequence (`localSequence`) is stored per-device and incremented locally. Offline creation never requires network access.
- The `description` field on `SalesInvoiceLines` is not used — each line references a product by ID. No free-text line descriptions in MVP.
- Attachment upload/management is handled in a separate feature. This phase creates the attachment metadata association structure but does not implement the upload UI.
- Client balance is computed on-read (per Phase 4's existing `getOutstandingBalance` method), not cached.

---

## Clarifications

### Session 2026-04-07

- Q: When an invoice with receipts is voided and the client has no other unpaid invoices, what happens to the freed receipt amounts? → A: Freed receipt amounts become unallocated client credit. The receipts remain ACTIVE. This is consistent with general receipt behavior (US6 scenario 2), avoids forced cash refund workflows (out of scope per constitution §IV), and preserves accounting correctness without inventing phantom invoices.
