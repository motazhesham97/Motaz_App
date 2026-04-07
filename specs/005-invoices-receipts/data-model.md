# Data Model: Invoices & Receipts

**Feature**: 005-invoices-receipts  
**Date**: 2026-04-07

---

## Schema Gap Analysis

All 4 required tables already exist from Phase 2. **No schema migration needed** for this phase.

| Table | Status | Notes |
|---|---|---|
| `SalesInvoices` | ✅ Exists | All columns present (id, localRef, officialNo, clientId, invoiceDate, discount, total, note, status, voidReason, timestamps, deviceId, rowVersion, syncStatus) |
| `SalesInvoiceLines` | ✅ Exists | All columns present (id, invoiceId, productId, quantity, unitPrice, lineTotal, timestamps) |
| `Receipts` | ✅ Exists | All columns present (id, receiptType, clientId, invoiceId, amount, receiptDate, note, status, voidReason, timestamps, deviceId, rowVersion, syncStatus) |
| `ReceiptAllocations` | ✅ Exists | All columns present (id, receiptId, invoiceId, allocatedAmount, timestamps) |
| `Devices` | ✅ Exists | Has `nextInvoiceSequence` column (integer, default 1) |

---

## Entity Definitions

### SalesInvoice

| Field | Type | Constraints | Description |
|---|---|---|---|
| id | TEXT(36) | PK | UUID primary key |
| localRef | TEXT(50) | UNIQUE, NOT NULL | Human-readable ref: `INV-<deviceCode>-<seq>` |
| officialNo | TEXT | nullable | Reserved for future use (null in MVP) |
| clientId | TEXT(36) | FK → Clients.id, NOT NULL | Owning client |
| invoiceDate | DATETIME | NOT NULL | Date of the invoice |
| discount | INTEGER | default 0 | Invoice-level discount (minor units) |
| total | INTEGER | NOT NULL | Computed total after discount (minor units) |
| note | TEXT | nullable | Free-text note |
| status | INTEGER | default 0 (ACTIVE) | RecordStatus enum: 0=ACTIVE, 1=VOIDED |
| voidReason | TEXT | nullable | Required when voiding |
| createdAt | DATETIME | NOT NULL | Creation timestamp |
| updatedAt | DATETIME | NOT NULL | Last update timestamp |
| deviceId | TEXT(36) | FK → Devices.id, NOT NULL | Originating device |
| rowVersion | INTEGER | default 1 | Incremented on each update |
| syncStatus | INTEGER | default 0 (PENDING) | SyncStatus enum |

**Indexes**: `idx_invoice_date` (invoiceDate), `idx_invoice_client` (clientId), `idx_invoice_status` (status)

**Business rules**:
- `total = Σ(line.lineTotal) - discount`
- `discount` ≤ `Σ(line.lineTotal)`
- Editing constrained by receipt/return presence
- Void requires reason, sets status=VOIDED

---

### SalesInvoiceLine

| Field | Type | Constraints | Description |
|---|---|---|---|
| id | TEXT(36) | PK | UUID primary key |
| invoiceId | TEXT(36) | FK → SalesInvoices.id, NOT NULL | Parent invoice |
| productId | TEXT(36) | FK → Products.id, NOT NULL | Referenced product |
| quantity | INTEGER | NOT NULL, ≥ 1 | Line quantity (app-level validation) |
| unitPrice | INTEGER | NOT NULL, ≥ 0 | Unit price (minor units) |
| lineTotal | INTEGER | NOT NULL | quantity × unitPrice (minor units) |
| createdAt | DATETIME | NOT NULL | Creation timestamp |
| updatedAt | DATETIME | NOT NULL | Last update timestamp |

**Index**: `idx_invoice_line_invoice` (invoiceId)

**Business rules**:
- `lineTotal = quantity × unitPrice`
- At least 1 line per invoice
- `unitPrice` defaults to `product.defaultSalePrice` but can be overridden

---

### Receipt

| Field | Type | Constraints | Description |
|---|---|---|---|
| id | TEXT(36) | PK | UUID primary key |
| receiptType | INTEGER | NOT NULL | ReceiptType enum: 0=INVOICE_LINKED, 1=GENERAL |
| clientId | TEXT(36) | FK → Clients.id, NOT NULL | Paying client |
| invoiceId | TEXT(36) | FK → SalesInvoices.id, nullable | Required for INVOICE_LINKED; null for GENERAL |
| amount | INTEGER | NOT NULL, > 0 | Payment amount (minor units) |
| receiptDate | DATETIME | NOT NULL | Date of payment |
| note | TEXT | nullable | Free-text note |
| status | INTEGER | default 0 (ACTIVE) | RecordStatus enum: 0=ACTIVE, 1=VOIDED |
| voidReason | TEXT | nullable | Required when voiding |
| createdAt | DATETIME | NOT NULL | Creation timestamp |
| updatedAt | DATETIME | NOT NULL | Last update timestamp |
| deviceId | TEXT(36) | FK → Devices.id, NOT NULL | Originating device |
| rowVersion | INTEGER | default 1 | Incremented on each update |
| syncStatus | INTEGER | default 0 (PENDING) | SyncStatus enum |

**Indexes**: `idx_receipt_client` (clientId), `idx_receipt_date` (receiptDate), `idx_receipt_status` (status)

**Business rules**:
- INVOICE_LINKED: `amount` ≤ invoice remaining balance; `invoiceId` required
- GENERAL: `invoiceId` null; auto-allocated via FIFO
- Void requires reason

---

### ReceiptAllocation

| Field | Type | Constraints | Description |
|---|---|---|---|
| id | TEXT(36) | PK | UUID primary key |
| receiptId | TEXT(36) | FK → Receipts.id, NOT NULL | Source receipt |
| invoiceId | TEXT(36) | FK → SalesInvoices.id, NOT NULL | Target invoice |
| allocatedAmount | INTEGER | NOT NULL, > 0 | Allocated portion (minor units) |
| createdAt | DATETIME | NOT NULL | Creation timestamp |
| updatedAt | DATETIME | NOT NULL | Last update timestamp |

**Indexes**: `idx_allocation_receipt` (receiptId), `idx_allocation_invoice` (invoiceId)

**Business rules**:
- Each receipt can have multiple allocations across different invoices
- `SUM(allocations.allocatedAmount WHERE receipt.status=ACTIVE)` ≤ invoice.total
- Allocations are deleted when a receipt is voided

---

## State Transitions

### Invoice Lifecycle

```
ACTIVE → VOIDED (requires reason)
```

- No transition from VOIDED → ACTIVE (no un-void)
- Editing allowed only in ACTIVE state
- Editing rules further constrained by receipt/return presence

### Receipt Lifecycle

```
ACTIVE → VOIDED (requires reason)
```

- No transition from VOIDED → ACTIVE (no un-void)
- No editing of receipts — only create and void

### Allocation Lifecycle

- Created when receipt is created (INVOICE_LINKED → single allocation; GENERAL → FIFO allocations)
- Deleted when receipt is voided
- Deleted and re-created when invoice is voided (reallocation to other invoices)

---

## Computed Values (not stored)

| Value | Formula | Usage |
|---|---|---|
| Invoice remaining balance | `invoice.total - SUM(alloc.allocatedAmount WHERE receipt.status=ACTIVE)` | Invoice detail, receipt validation |
| Client outstanding balance | `SUM(invoice.total WHERE status=ACTIVE) - SUM(receipt.amount WHERE status=ACTIVE)` | Client summary |
| Client credit balance | Excess receipt amounts not allocated to any invoice | Client summary |
| Invoice subtotal | `SUM(line.lineTotal)` | Invoice form, discount validation |
