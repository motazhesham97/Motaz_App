# Data Model: Hardening & Release Readiness

**Branch**: `009-hardening-release` | **Date**: 2026-04-20

## No New Entities

Phase 9 introduces **no new database tables**. All work concerns existing entities from Phases 1–8.

## Existing Entities Under Hardening

### Financial Transaction Entities

| Entity | Table | Hardening Focus |
|--------|-------|-----------------|
| SalesInvoice | `sales_invoices` | Lifecycle integrity, sync round-trip, audit coverage |
| SalesInvoiceLine | `sales_invoice_lines` | Cascading void/edit consistency |
| Receipt | `receipts` | FIFO allocation integrity across sync |
| ReceiptAllocation | `receipt_allocations` | Reallocation correctness after void/resync |
| Expense | `expenses` | Category integrity, distribution period matching |
| SalesReturn | `sales_returns` | Reversal arithmetic, credit creation accuracy |
| SalesReturnLine | `sales_return_lines` | Quantity/amount bounds after partial return |
| MonthlyDistribution | `monthly_distributions` | Integer split remainder correctness |

### Sync & Audit Entities

| Entity | Table | Hardening Focus |
|--------|-------|-----------------|
| SyncOutbox | `sync_outbox` | Persistence during network failures, retry fidelity |
| SyncCursor | `sync_cursors` | Correct incremental pull after interruption |
| ConflictLog | `conflict_logs` | Complete detection, resolution UX, void-wins enforcement |
| AuditEvent | `audit_events` | 100% coverage of financial mutations |
| Device | `devices` | Device label display in conflict UI |

### Reference Entities

| Entity | Table | Hardening Focus |
|--------|-------|-----------------|
| Product | `products` | Search performance, unique name validation |
| Client | `clients` | Display name handling in long-name PDF scenarios |

## Index Additions (Performance Hardening)

The following indexes should be verified or added if missing:

| Table | Column(s) | Purpose |
|-------|-----------|---------|
| `sales_invoices` | `invoice_date` | Dashboard today/month filters, report date ranges |
| `sales_invoices` | `client_id` | Client statement query performance |
| `receipts` | `receipt_date` | Collection report date ranges |
| `expenses` | `expense_date` | Expense report date ranges |
| `audit_events` | `entity_type, entity_id` | Per-entity audit history lookup (exists ✅) |
| `audit_events` | `created_at` | Time-ordered audit feed (exists ✅) |
| `sync_outbox` | `status` | Pending outbox queries during push |
| `conflict_logs` | `resolution_status` | Pending conflict list queries |

## State Transitions Under Validation

### SyncOutbox Status

```
PENDING → IN_PROGRESS → COMPLETED
                      → FAILED (after maxRetryCount=5 or permanent error)
FAILED → PENDING (via retryFailed())
```

### ConflictLog Status

```
PENDING → RESOLVED (via conflict resolution UI)
```

### Record SyncStatus

```
PENDING_SYNC → SYNCED (after successful push)
             → CONFLICT (after conflict detection)
```
