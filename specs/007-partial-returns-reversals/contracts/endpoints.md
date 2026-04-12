# Repository Contracts: Partial Returns & Reversals

**Feature**: 007-partial-returns-reversals  
**Date**: 2026-04-12

---

## ReturnRepository

**File**: `features/returns/data/return_repository.dart`  
**Constructor**: `ReturnRepository(AppDatabase db)`

### create()

```
Future<SalesReturn> create({
  required String invoiceId,
  required DateTime returnDate,
  String? note,
  required List<({String invoiceLineId, int returnedQuantity, int returnedAmount})> lines,
  required String deviceId,
})
```

**Preconditions**:
- Invoice with `invoiceId` must exist and be ACTIVE
- `lines` must not be empty
- For each line:
  - `returnedQuantity > 0`
  - `returnedAmount > 0`
  - `returnedQuantity ≤ availableQuantity` for that invoice line
  - `returnedAmount ≤ returnedQuantity × invoiceLine.unitPrice`
- Cumulative active return totals + new return total ≤ invoice.total

**Postconditions**:
- SalesReturn record created with `status = ACTIVE`, `totalReturnedAmount = SUM(line amounts)`
- SalesReturnLine records created for each line
- Sync outbox entries created for return header (`SALES_RETURN`) and each line (`SALES_RETURN_LINE`)
- All saved in a single atomic transaction

**Errors**:
- `ArgumentError` if lines empty, quantity ≤ 0, or amount ≤ 0
- `StateError` if invoice is voided
- `StateError` if quantity exceeds available
- `StateError` if amount exceeds max per line
- `StateError` if cumulative return total exceeds invoice total

---

### voidReturn()

```
Future<void> voidReturn(String id, String reason, String deviceId)
```

**Preconditions**:
- Return with `id` must exist
- Return must be ACTIVE (not already VOIDED)
- `reason` must not be empty after trimming

**Postconditions**:
- Return status set to VOIDED
- voidReason stored
- updatedAt updated
- rowVersion incremented
- syncStatus set to PENDING
- Sync outbox entry created (`SALES_RETURN`, UPDATE operation)

**Errors**:
- `ArgumentError` if reason is empty
- `StateError` if already voided

---

### getById()

```
Future<SalesReturn> getById(String id)
```

Returns a single return by primary key. Throws if not found.

---

### watchAll()

```
Stream<List<SalesReturn>> watchAll()
```

Returns a reactive stream of all returns, ordered by `returnDate DESC`, then `createdAt DESC`.

---

### searchByText()

```
Stream<List<SalesReturn>> searchByText(String query)
```

Filters returns by matching note text or linked invoice `localRef`. Uses client-side filtering with 300ms debounce (applied at UI layer).

---

### getReturnLinesForReturn()

```
Future<List<SalesReturnLine>> getReturnLinesForReturn(String returnId)
```

Returns all return lines for a given return header.

---

### getActiveReturnTotalForInvoice()

```
Future<int> getActiveReturnTotalForInvoice(String invoiceId)
```

Returns the sum of `totalReturnedAmount` for all ACTIVE returns linked to the given invoice. Used for cumulative validation.

---

### getReturnedQuantityForInvoiceLine()

```
Future<int> getReturnedQuantityForInvoiceLine(String invoiceLineId)
```

Returns the sum of `returnedQuantity` across all ACTIVE return lines referencing this invoice line. Used for per-line quantity validation.

---

### hasActiveReturnsForInvoice()

```
Future<bool> hasActiveReturnsForInvoice(String invoiceId)
```

Returns `true` if any ACTIVE return exists for the given invoice. Used by invoice edit restriction logic.

---

## InvoiceRepository (modifications)

**File**: `features/invoices/data/invoice_repository.dart`  
**Changes**: Add edit restriction check

### Modified: edit flow

The invoice edit method must check `hasActiveReturnsForInvoice(invoiceId)` before allowing financial field changes. If returns exist:
- **Allowed**: note, attachment metadata
- **Blocked**: clientId, discount, lines (add/remove/modify), quantities, prices

The check queries `SalesReturns` for `invoiceId = ? AND status = ACTIVE.index` and returns `true` if count > 0.

---

## Computed Queries (used by existing code, no new files)

### Invoice Remaining Balance

```sql
SELECT invoice.total
  - COALESCE((SELECT SUM(ra.allocated_amount) FROM receipt_allocations ra
      JOIN receipts r ON r.id = ra.receipt_id
      WHERE ra.invoice_id = ? AND r.status = 0), 0)
  - COALESCE((SELECT SUM(sr.total_returned_amount) FROM sales_returns sr
      WHERE sr.invoice_id = ? AND sr.status = 0), 0)
  AS remaining_balance
FROM sales_invoices invoice
WHERE invoice.id = ?
```

### Client Balance

```sql
SELECT
  COALESCE((SELECT SUM(total) FROM sales_invoices WHERE client_id = ? AND status = 0), 0)
  - COALESCE((SELECT SUM(ra.allocated_amount) FROM receipt_allocations ra
      JOIN receipts r ON r.id = ra.receipt_id
      JOIN sales_invoices si ON si.id = ra.invoice_id
      WHERE si.client_id = ? AND r.status = 0), 0)
  - COALESCE((SELECT SUM(sr.total_returned_amount) FROM sales_returns sr
      JOIN sales_invoices si ON si.id = sr.invoice_id
      WHERE si.client_id = ? AND sr.status = 0), 0)
  AS client_balance
```
