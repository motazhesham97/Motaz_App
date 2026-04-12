# Quickstart: Partial Returns & Reversals

**Feature**: 007-partial-returns-reversals  
**Date**: 2026-04-12

---

## Prerequisites

- Flutter SDK 3.x installed
- Phase 2 (Core Data Model) completed — SalesReturns and SalesReturnLines tables exist
- Phase 5 (Invoices & Receipts) completed — invoice and receipt flows functional
- Phase 6 (Expenses & Profit Distribution) completed — ProfitEngine with net sales computation

---

## Setup

No additional setup required. The existing schema (version 4) already includes the SalesReturns and SalesReturnLines tables from Phase 2. No migration changes are needed for this feature.

---

## Key Files to Create

| File | Purpose |
|---|---|
| `features/returns/data/return_repository.dart` | CRUD + void + validation queries |
| `features/returns/application/return_providers.dart` | Riverpod providers |
| `features/returns/presentation/return_list_screen.dart` | List with search, void action |
| `features/returns/presentation/return_form_screen.dart` | Create return form with auto-fill |

## Key Files to Modify

| File | Change |
|---|---|
| `features/invoices/data/invoice_repository.dart` | Add `hasActiveReturns` check to edit flow |
| `features/invoices/presentation/invoice_list_screen.dart` | Add "إنشاء مرتجع" action button |
| `features/invoices/presentation/invoice_detail_screen.dart` | Add "إنشاء مرتجع" action button |
| `core/router/app_router.dart` | Replace returns placeholder with real screens |
| `shared/widgets/app_drawer.dart` | Verify `/returns` navigation entry exists |

## Key Files to Delete

| File | Reason |
|---|---|
| `features/returns/presentation/placeholder_screen.dart` | Replaced by real screens |

---

## Development Workflow

1. **Start**: Create `return_repository.dart` with create + void + query methods
2. **Validate**: Write unit tests for quantity/amount validation logic
3. **Integrate**: Create providers, then build the return form screen
4. **Connect**: Add "إنشاء مرتجع" action to invoice screens
5. **List**: Build the return list screen with search
6. **Guard**: Add edit restriction to invoice repository
7. **Route**: Update router and verify drawer entry
8. **Verify**: Run `dart analyze`, test E2E flow

---

## Architecture Notes

- **Compute-on-read**: Invoice remaining balance and client balance are computed from raw tables — no stored balance columns.
- **Atomic transactions**: Return + return lines + outbox entries saved in a single Drift transaction.
- **Auto-fill**: Return form auto-computes `returnedAmount = returnedQuantity × unitPrice`, user can override downward.
- **No reversal records**: Voiding a return simply sets status to VOIDED. Queries already filter by ACTIVE status.

---

## Reference Patterns

- **Repository**: Follow `ExpenseRepository` pattern from Phase 6 for CRUD + void + outbox
- **Providers**: Follow `expense_providers.dart` pattern
- **List Screen**: Follow `ExpenseListScreen` pattern (AppDrawerScaffold, 300ms debounce search, void dialog)
- **Form Screen**: Follow `ExpenseFormScreen` pattern (validation, save, navigation)
