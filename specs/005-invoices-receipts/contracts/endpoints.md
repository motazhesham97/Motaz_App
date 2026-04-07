# Endpoint Contracts: Invoices & Receipts

**Feature**: 005-invoices-receipts  
**Date**: 2026-04-07

---

## Overview

Phase 5 is primarily a **local-first Flutter feature**. No new Serverpod endpoints are needed — the sync engine (Phase 3) already handles pushing and pulling all entity types via generic outbox/pull mechanisms.

The existing sync infrastructure handles:
- `SALES_INVOICE` push/pull/conflict detection
- `SALES_INVOICE_LINE` push/pull
- `RECEIPT` push/pull/conflict detection
- `RECEIPT_ALLOCATION` push/pull/conflict detection

---

## Local Repository Contracts

### InvoiceRepository

| Method | Input | Output | Transaction | Outbox Entries |
|---|---|---|---|---|
| `create(invoice, lines, paidAmount?)` | InvoiceData + lines + optional payment | `SalesInvoice` | Single atomic | SALES_INVOICE + N×SALES_INVOICE_LINE + optional RECEIPT + optional RECEIPT_ALLOCATION |
| `update(id, invoice, lines)` | ID + updated data + updated lines | void | Single atomic | SALES_INVOICE (UPDATE) + N×SALES_INVOICE_LINE |
| `voidInvoice(id, reason)` | ID + reason text | void | Single atomic | SALES_INVOICE (UPDATE) + reallocation entries |
| `getById(id)` | ID | `SalesInvoice` | — | — |
| `watchAll()` | — | `Stream<List<SalesInvoice>>` | — | — |
| `getRemainingBalance(id)` | ID | `int` (minor units) | — | — |
| `hasActiveReceipts(id)` | ID | `bool` | — | — |
| `hasActiveReturns(id)` | ID | `bool` | — | — |
| `getCollectedAmount(id)` | ID | `int` (minor units) | — | — |
| `getLinesForInvoice(id)` | ID | `List<SalesInvoiceLine>` | — | — |
| `getReceiptsForInvoice(id)` | ID | `List<Receipt>` | — | — |

### ReceiptRepository

| Method | Input | Output | Transaction | Outbox Entries |
|---|---|---|---|---|
| `createInvoiceLinked(receipt)` | Receipt data with invoiceId | `Receipt` | Single atomic | RECEIPT + RECEIPT_ALLOCATION |
| `createGeneral(receipt)` | Receipt data (no invoiceId) | `Receipt` | Single atomic | RECEIPT + N×RECEIPT_ALLOCATION (FIFO) |
| `voidReceipt(id, reason)` | ID + reason text | void | Single atomic | RECEIPT (UPDATE) + delete allocations |
| `getById(id)` | ID | `Receipt` | — | — |
| `watchAll()` | — | `Stream<List<Receipt>>` | — | — |
| `getAllocationsForReceipt(id)` | ID | `List<ReceiptAllocation>` | — | — |

### ReceiptAllocator (Pure Function / Helper)

| Method | Input | Output |
|---|---|---|
| `allocateFifo(clientId, amount)` | Client ID + amount to allocate | `List<ReceiptAllocationCompanion>` |

Queries unpaid invoices for the client ordered by `invoiceDate ASC, createdAt ASC`, generates allocation records until the amount is exhausted.

---

## Sync Field Classification (existing — no changes needed)

### Auto-merge (last-write-wins)

| Entity | Fields |
|---|---|
| SALES_INVOICE | note |
| RECEIPT | note |

### Conflict-required (server raises conflict)

| Entity | Fields |
|---|---|
| SALES_INVOICE | clientId, invoiceDate, discount, total, status, voidReason |
| SALES_INVOICE_LINE | invoiceId, productId, quantity, unitPrice, lineTotal |
| RECEIPT | receiptType, clientId, invoiceId, amount, receiptDate, status, voidReason |
| RECEIPT_ALLOCATION | receiptId, invoiceId, allocatedAmount |

All already configured in `FieldClassifier`.
