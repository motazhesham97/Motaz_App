# Quickstart: Expenses & Monthly Profit Distribution

**Feature**: 006-expenses-profit  
**Date**: 2026-04-07

---

## Prerequisites

- Phases 1–5 complete (workspace foundation, schema, sync, products/clients, invoices/receipts)
- `motaz_app_flutter` builds and runs (`flutter run --debug`)
- SQLite database at schema version 3

---

## What Already Exists

| Item | Location | Status |
|---|---|---|
| Expenses table | `lib/core/database/tables/expenses.dart` | ✅ Ready |
| ExpenseCategory enum | `lib/core/database/enums/expense_category.dart` | ✅ Ready (5 values) |
| RecordStatus enum | `lib/core/database/enums/record_status.dart` | ✅ Ready |
| ParentEntityType.EXPENSE | `lib/core/database/enums/parent_entity_type.dart` | ✅ Ready |
| SyncOutbox table | `lib/core/database/tables/sync_outbox.dart` | ✅ Ready |
| SalesInvoices table | `lib/core/database/tables/sales_invoices.dart` | ✅ Ready |
| SalesReturns table | `lib/core/database/tables/sales_returns.dart` | ✅ Ready (empty until Phase 7) |
| AppDrawerScaffold | `lib/shared/widgets/app_drawer.dart` | ✅ Ready |
| DeviceService | `lib/core/database/device_service.dart` | ✅ Ready |
| Expense placeholder screen | `lib/features/expenses/presentation/placeholder_screen.dart` | 🗑️ To be replaced |
| Party balances placeholder | `lib/features/party_balances/presentation/placeholder_screen.dart` | 🗑️ To be replaced |
| Dashboard placeholder | `lib/features/dashboard/presentation/placeholder_screen.dart` | 🗑️ To be replaced |
| Route `/expenses` | `lib/core/router/app_router.dart` line 59 | 🔄 Points to placeholder |
| Route `/party-balances` | `lib/core/router/app_router.dart` line 62 | 🔄 Points to placeholder |
| Route `/dashboard` | `lib/core/router/app_router.dart` line 54 | 🔄 Points to placeholder |

---

## What Must Be Created

### Schema (1 new table + 1 enum update + 1 migration)

1. **MonthlyDistributions** table — `lib/core/database/tables/monthly_distributions.dart`
2. **ParentEntityType.MONTHLY_DISTRIBUTION** — append to existing enum
3. **Schema version 3 → 4** — add migration in `app_database.dart`

### Data Layer (4 new files)

1. `lib/features/expenses/data/expense_repository.dart`
2. `lib/features/profit_distribution/data/profit_engine.dart`
3. `lib/features/profit_distribution/data/distribution_repository.dart`
4. `lib/features/party_balances/data/party_balance_calculator.dart`

### Application Layer (3 new files)

1. `lib/features/expenses/application/expense_providers.dart`
2. `lib/features/profit_distribution/application/profit_providers.dart`
3. `lib/features/party_balances/application/party_balance_providers.dart`

### Presentation Layer (5 new + 3 deleted)

1. `lib/features/expenses/presentation/expense_list_screen.dart`
2. `lib/features/expenses/presentation/expense_form_screen.dart`
3. `lib/features/profit_distribution/presentation/distribution_screen.dart`
4. `lib/features/party_balances/presentation/party_balances_screen.dart`
5. `lib/features/dashboard/presentation/dashboard_screen.dart`

Delete:
- `lib/features/expenses/presentation/placeholder_screen.dart`
- `lib/features/party_balances/presentation/placeholder_screen.dart`
- `lib/features/dashboard/presentation/placeholder_screen.dart`

### Dashboard (partial — 2 new files)

1. `lib/features/dashboard/data/dashboard_queries.dart`
2. `lib/features/dashboard/application/dashboard_providers.dart`

### Router Update

- `lib/core/router/app_router.dart` — replace 3 placeholder imports and routes

---

## Key Patterns to Follow

| Pattern | Reference File |
|---|---|
| Repository + outbox atomic transactions | `lib/features/products/data/product_repository.dart` |
| Riverpod providers (repo, list, search) | `lib/features/invoices/application/invoice_providers.dart` |
| AppDrawerScaffold usage | `lib/features/invoices/presentation/invoice_list_screen.dart` |
| Form screen with validation | `lib/features/invoices/presentation/invoice_form_screen.dart` |
| Void dialog with reason | `lib/features/invoices/presentation/invoice_detail_screen.dart` |
| Price formatting (minor → display) | `(value / 100).toStringAsFixed(2)` pattern |
| Search debounce (300ms) | `lib/features/receipts/presentation/receipt_list_screen.dart` |

---

## Build & Verify

```bash
# After adding MonthlyDistributions table to app_database.dart:
dart run build_runner build --delete-conflicting-outputs

# Verify no issues:
dart analyze

# Run app:
flutter run
```
