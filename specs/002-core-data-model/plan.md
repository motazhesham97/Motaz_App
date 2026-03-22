# Implementation Plan: Core Data Model

**Branch**: `002-core-data-model` | **Date**: 2026-03-22 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/002-core-data-model/spec.md`

## Summary

Build the canonical local (Drift/SQLite) and cloud (Serverpod ORM/Neon PostgreSQL) database schemas for all 17 core entities defined in the constitution and implementation plan. This phase creates no business logic or UI — it delivers schema definitions, constraints, indexes, and migration support that all subsequent phases build upon.

## Technical Context

**Language/Version**: Dart 3.x (Flutter SDK 3.32.0)
**Primary Dependencies**: Drift (local SQLite ORM), Serverpod ORM (cloud PostgreSQL ORM), drift_dev (code generation)
**Storage**: SQLite (local, via Drift), PostgreSQL on Neon (cloud, via Serverpod ORM)
**Testing**: `flutter test` for Drift unit tests, `serverpod generate` for model validation, `dart run build_runner build` for Drift code generation
**Target Platform**: Android + Windows (Flutter)
**Project Type**: Mobile + Desktop app with backend
**Performance Goals**: Schema migration < 5 seconds, CRUD operations < 50ms on local DB
**Constraints**: Offline-first, no floating-point in money path, no hard delete for financial records
**Scale/Scope**: ~2 devices, ~500 products, ~1000 clients, ~10,000 invoices (MVP scale)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Status | Evidence |
|------|--------|----------|
| Offline-first mandatory | ✅ Pass | All entities defined in local SQLite schema (Drift) |
| No hard delete for financial records | ✅ Pass | All financial entities use `status` + `void_reason` fields |
| Financial conflicts never silently merged | ✅ Pass | ConflictLog entity with explicit payloads and resolution status |
| Void wins over edit | ✅ Pass | Schema supports `status` field for void state; business logic in Phase 3 |
| Minor-unit integers for money | ✅ Pass | All monetary columns use INTEGER type, no REAL/DOUBLE |
| Attachments only for invoices and receipts | ✅ Pass | AttachmentMetadata has `parent_entity_type` constrained to invoice/receipt |
| Attachments: no binary in DB | ✅ Pass | AttachmentMetadata stores only references, file type, size |
| Attachment preservation on void | ✅ Pass | No cascade delete on attachment FK; attachments survive void |
| Single-owner auth via Serverpod | ✅ Pass | Device entity tracks owner; auth handled in Phase 1 |
| Product names unique | ✅ Pass | UNIQUE constraint on `name` column |
| Client names NOT unique | ✅ Pass | No UNIQUE constraint on `display_name`; additional identifying fields present |
| Invoice numbering: UUID + local_ref | ✅ Pass | UUID PK + `local_ref` text field with format `INV-<deviceCode>-<seq>` |
| 5 expense categories only | ✅ Pass | Enum constraint: OWNER_DRAW, PARTNER_DRAW, MARGIN_DRAW, OPERATIONAL, PRODUCTION |
| Invoice discount at invoice level only | ✅ Pass | `discount` on SalesInvoice, not on SalesInvoiceLine |
| Receipts: two types | ✅ Pass | `receipt_type` enum: INVOICE_LINKED, GENERAL |
| FIFO allocation records explicit | ✅ Pass | ReceiptAllocation as separate entity |
| Audit fields on all financial records | ✅ Pass | `created_at`, `updated_at`, `device_id`, `row_version`, `sync_status` on all |
| Immutable audit events | ✅ Pass | AuditEvent has no update/void capability by design |

**No violations. All gates pass.**

## Project Structure

### Documentation (this feature)

```text
specs/002-core-data-model/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output (entity definitions)
├── quickstart.md        # Phase 1 output (dev setup guide)
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
```

### Source Code (repository root)

```text
motaz_app/
├── motaz_app_flutter/
│   └── lib/
│       └── core/
│           └── database/
│               ├── app_database.dart          # Drift database class
│               ├── app_database.g.dart        # Generated
│               └── tables/
│                   ├── product_table.dart
│                   ├── client_table.dart
│                   ├── sales_invoice_table.dart
│                   ├── sales_invoice_line_table.dart
│                   ├── receipt_table.dart
│                   ├── receipt_allocation_table.dart
│                   ├── expense_table.dart
│                   ├── sales_return_table.dart
│                   ├── sales_return_line_table.dart
│                   ├── attachment_metadata_table.dart
│                   ├── local_attachment_staging_table.dart
│                   ├── device_table.dart
│                   ├── audit_event_table.dart
│                   ├── conflict_log_table.dart
│                   ├── sync_outbox_table.dart
│                   └── sync_cursor_table.dart
│
├── motaz_app_server/
│   └── lib/
│       └── src/
│           └── models/
│               ├── product.spy.yaml
│               ├── client.spy.yaml
│               ├── sales_invoice.spy.yaml
│               ├── sales_invoice_line.spy.yaml
│               ├── receipt.spy.yaml
│               ├── receipt_allocation.spy.yaml
│               ├── expense.spy.yaml
│               ├── sales_return.spy.yaml
│               ├── sales_return_line.spy.yaml
│               ├── attachment_metadata.spy.yaml
│               ├── local_attachment_staging.spy.yaml
│               ├── device.spy.yaml
│               ├── audit_event.spy.yaml
│               ├── conflict_log.spy.yaml
│               ├── sync_outbox.spy.yaml
│               └── sync_cursor.spy.yaml
│
└── motaz_app_client/
    └── lib/
        └── src/
            └── protocol/       # Auto-generated by serverpod generate
```

**Structure Decision**: Feature-First Modular Monolith — all Drift tables live under `lib/core/database/tables/` and the Drift database class at `lib/core/database/app_database.dart`. Server models use Serverpod's `.spy.yaml` convention placed in `lib/src/models/`.

## Implementation Phases

### Phase A — Local Schema (Drift Tables)

Create all 16 Drift table definitions in `motaz_app_flutter/lib/core/database/tables/` and the main `AppDatabase` class. Each table file defines a single Drift `Table` class.

**Order** (dependencies first):
1. `device_table.dart` — no FKs
2. `product_table.dart` — no FKs
3. `client_table.dart` — no FKs
4. `sales_invoice_table.dart` — FK to clients, devices
5. `sales_invoice_line_table.dart` — FK to sales_invoices, products
6. `receipt_table.dart` — FK to clients, optional FK to sales_invoices
7. `receipt_allocation_table.dart` — FK to receipts, sales_invoices
8. `expense_table.dart` — FK to devices
9. `sales_return_table.dart` — FK to sales_invoices
10. `sales_return_line_table.dart` — FK to sales_returns, sales_invoice_lines
11. `attachment_metadata_table.dart` — polymorphic FK (entity type + entity ID)
12. `local_attachment_staging_table.dart` — polymorphic FK (entity type + entity ID)
13. `audit_event_table.dart` — polymorphic FK (entity type + entity ID)
14. `conflict_log_table.dart` — polymorphic FK (entity type + entity ID)
15. `sync_outbox_table.dart` — polymorphic FK (entity type + entity ID)
16. `sync_cursor_table.dart` — no FKs
17. `app_database.dart` — Drift database class, includes all tables

### Phase B — Cloud Schema (Serverpod Models)

Create all 16 `.spy.yaml` model definitions in `motaz_app_server/lib/src/models/`. Each file defines a single Serverpod model class with `table:` to connect to the database.

Run `serverpod generate` to produce the generated Dart classes and migration files.

### Phase C — Verification

Run code generation for both:
- `dart run build_runner build --delete-conflicting-outputs` in `motaz_app_flutter/`
- `serverpod generate` in `motaz_app_server/`

Write a simple smoke test to verify Drift database opens and tables are accessible.

## Verification Plan

### Automated Tests

1. **Drift code generation**: Run `dart run build_runner build --delete-conflicting-outputs` in `motaz_app_flutter/` — must complete with exit code 0 and no errors.

2. **Serverpod code generation**: Run `serverpod generate` in `motaz_app_server/` — must complete with exit code 0 and generate protocol classes.

3. **Drift smoke test**: Create a Flutter test at `motaz_app_flutter/test/core/database/app_database_test.dart` that:
   - Opens an in-memory Drift database
   - Inserts a product record
   - Retrieves it and verifies fields
   - Verifies unique name constraint rejects duplicates
   - Inserts a device record with device_code and next_invoice_sequence
   - Command: `cd motaz_app_flutter && flutter test test/core/database/app_database_test.dart`

### Manual Verification

1. Verify all 16 `.spy.yaml` files exist in `motaz_app_server/lib/src/models/` with correct table names, field types, and relationships.
2. Verify all 16 Drift table files exist in `motaz_app_flutter/lib/core/database/tables/` with correct column types and constraints.
3. Verify no REAL or DOUBLE types are used for monetary columns (grep for `real()` or `double` in table files).

## Complexity Tracking

No constitution violations — this section is intentionally empty.
