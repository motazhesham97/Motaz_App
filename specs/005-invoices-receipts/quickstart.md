# Quickstart: Invoices & Receipts

**Feature**: 005-invoices-receipts  
**Date**: 2026-04-07

---

## Prerequisites

- Phase 3 (Sync Foundation) complete and merged to main
- Phase 4 (Products & Clients) complete and merged to main
- Flutter + Dart SDK installed
- `flutter pub get` executed in `motaz_app_flutter/`

## Branch

```bash
git checkout 005-invoices-receipts
```

## What exists (from prior phases)

| Component | Status | Location |
|---|---|---|
| `SalesInvoices` table | ✅ | `lib/core/database/tables/sales_invoices.dart` |
| `SalesInvoiceLines` table | ✅ | `lib/core/database/tables/sales_invoice_lines.dart` |
| `Receipts` table | ✅ | `lib/core/database/tables/receipts.dart` |
| `ReceiptAllocations` table | ✅ | `lib/core/database/tables/receipt_allocations.dart` |
| `RecordStatus` enum | ✅ | `lib/core/database/enums/record_status.dart` |
| `ReceiptType` enum | ✅ | `lib/core/database/enums/receipt_type.dart` |
| `ParentEntityType` enum | ✅ | Includes SALES_INVOICE, SALES_INVOICE_LINE, RECEIPT, RECEIPT_ALLOCATION |
| `FieldClassifier` | ✅ | All invoice/receipt/allocation fields already classified |
| `Devices.nextInvoiceSequence` | ✅ | `lib/core/database/tables/devices.dart` |
| `DeviceService` | ✅ | `lib/core/database/device_service.dart` |
| `activeProductSearchProvider` | ✅ | `lib/features/products/application/product_providers.dart` |
| Product repository | ✅ | Used for autocomplete |
| Client repository | ✅ | Used for client selection |
| App router | ✅ | `/invoices` and `/receipts` routes exist (placeholder screens) |

## What to build (this phase)

### Data Layer (Repositories)
1. `lib/features/invoices/data/invoice_repository.dart` — CRUD + void + local ref generation + edit state queries
2. `lib/features/receipts/data/receipt_repository.dart` — Create linked/general + void
3. `lib/features/receipts/data/receipt_allocator.dart` — FIFO allocation engine

### Application Layer (Providers)
4. `lib/features/invoices/application/invoice_providers.dart` — List, search, detail providers
5. `lib/features/receipts/application/receipt_providers.dart` — List, search providers

### Presentation Layer (Screens)
6. `lib/features/invoices/presentation/invoice_form_screen.dart` — Create/edit with line builder
7. `lib/features/invoices/presentation/invoice_list_screen.dart` — List with search
8. `lib/features/invoices/presentation/invoice_detail_screen.dart` — Full details + payments + void
9. `lib/features/receipts/presentation/receipt_form_screen.dart` — Create linked/general
10. `lib/features/receipts/presentation/receipt_list_screen.dart` — List with search

### Router Update
11. Update `app_router.dart` — Replace placeholder screens with real screens

## Key patterns to follow

- **Transaction pattern**: All mutations wrap entity + outbox in `_db.transaction(() async { ... })` — see `ProductRepository.create()` for reference.
- **Outbox pattern**: Each entity gets its own `SyncOutboxCompanion.insert(...)` — see `ProductRepository.create()`.
- **Provider pattern**: `StreamProvider` for reactive lists, `Provider` for repositories — see `product_providers.dart`.
- **Minor-unit convention**: All monetary values stored as `int`. Display conversion: `(value / 100).toStringAsFixed(2)`.
- **Arabic labels**: All UI text in Arabic. RTL layout.

## Run

```bash
cd motaz_app_flutter
flutter run
```

## Verify

```bash
cd motaz_app_flutter
dart analyze
flutter test
```
