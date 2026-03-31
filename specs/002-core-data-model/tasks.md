# Tasks: Core Data Model

**Input**: Design documents from `/specs/002-core-data-model/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, quickstart.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- All file paths are relative to repository root `d:\Motaz_App2\`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create shared Dart enum definitions and utility files needed by all entities.

- [X] T001 [P] Create Drift enum file for SyncStatus (PENDING, SYNCED, CONFLICT, FAILED) in `motaz_app/motaz_app_flutter/lib/core/database/enums/sync_status.dart`
- [X] T002 [P] Create Drift enum file for RecordStatus (ACTIVE, VOIDED) in `motaz_app/motaz_app_flutter/lib/core/database/enums/record_status.dart`
- [X] T003 [P] Create Drift enum file for ExpenseCategory (OWNER_DRAW, PARTNER_DRAW, MARGIN_DRAW, OPERATIONAL, PRODUCTION) in `motaz_app/motaz_app_flutter/lib/core/database/enums/expense_category.dart`
- [X] T004 [P] Create Drift enum file for ReceiptType (INVOICE_LINKED, GENERAL) in `motaz_app/motaz_app_flutter/lib/core/database/enums/receipt_type.dart`
- [X] T005 [P] Create Drift enum file for AuditOperation (CREATE, UPDATE, VOID) in `motaz_app/motaz_app_flutter/lib/core/database/enums/audit_operation.dart`
- [X] T006 [P] Create Drift enum file for ConflictStatus (PENDING, RESOLVED) in `motaz_app/motaz_app_flutter/lib/core/database/enums/conflict_status.dart`
- [X] T007 [P] Create Drift enum file for SyncOutboxStatus (PENDING, IN_PROGRESS, COMPLETED, FAILED) in `motaz_app/motaz_app_flutter/lib/core/database/enums/sync_outbox_status.dart`
- [X] T008 [P] Create Drift enum file for ParentEntityType (SALES_INVOICE, RECEIPT, PRODUCT, CLIENT, EXPENSE, SALES_RETURN) in `motaz_app/motaz_app_flutter/lib/core/database/enums/parent_entity_type.dart`
- [X] T009 [P] Create Drift enum file for DevicePlatform (ANDROID, WINDOWS) in `motaz_app/motaz_app_flutter/lib/core/database/enums/device_platform.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Extend existing Phase 1 tables to match the spec and create Serverpod enum models. All user story tables depend on these being correct first.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

### Extend Phase 1 Drift Tables

- [X] T010 Extend Devices table to add `device_code` (text, NOT NULL, UNIQUE), `next_invoice_sequence` (integer, NOT NULL, DEFAULT 1), and convert `platform` to use DevicePlatform intEnum, convert timestamps to `dateTime()` in `motaz_app/motaz_app_flutter/lib/core/database/tables/devices.dart`
- [X] T011 Extend SyncOutbox table to use UUID text PK instead of autoIncrement int, convert `entityType` to ParentEntityType intEnum, `operation` to AuditOperation intEnum, `status` to SyncOutboxStatus intEnum, convert `createdAt` to `dateTime()` in `motaz_app/motaz_app_flutter/lib/core/database/tables/sync_outbox.dart`
- [X] T012 Extend SyncCursor table to add UUID text `id` PK (replacing entityType-as-PK), convert `entityType` to ParentEntityType intEnum with UNIQUE, add `updatedAt` as `dateTime()`, convert `lastPulledAt` to nullable `dateTime()` in `motaz_app/motaz_app_flutter/lib/core/database/tables/sync_cursor.dart`

### Create Serverpod Enum Models

- [X] T013 [P] Create Serverpod enum model for SyncStatus in `motaz_app/motaz_app_server/lib/src/models/enums/sync_status.spy.yaml`
- [X] T014 [P] Create Serverpod enum model for RecordStatus in `motaz_app/motaz_app_server/lib/src/models/enums/record_status.spy.yaml`
- [X] T015 [P] Create Serverpod enum model for ExpenseCategory in `motaz_app/motaz_app_server/lib/src/models/enums/expense_category.spy.yaml`
- [X] T016 [P] Create Serverpod enum model for ReceiptType in `motaz_app/motaz_app_server/lib/src/models/enums/receipt_type.spy.yaml`
- [X] T017 [P] Create Serverpod enum model for AuditOperation in `motaz_app/motaz_app_server/lib/src/models/enums/audit_operation.spy.yaml`
- [X] T018 [P] Create Serverpod enum model for ConflictStatus in `motaz_app/motaz_app_server/lib/src/models/enums/conflict_status.spy.yaml`
- [X] T019 [P] Create Serverpod enum model for SyncOutboxStatus in `motaz_app/motaz_app_server/lib/src/models/enums/sync_outbox_status.spy.yaml`
- [X] T020 [P] Create Serverpod enum model for ParentEntityType in `motaz_app/motaz_app_server/lib/src/models/enums/parent_entity_type.spy.yaml`
- [X] T021 [P] Create Serverpod enum model for DevicePlatform in `motaz_app/motaz_app_server/lib/src/models/enums/device_platform.spy.yaml`

### Create Serverpod Foundational Models

- [X] T022 Create Serverpod model for Device with all fields, relation to other entities, indexes in `motaz_app/motaz_app_server/lib/src/models/device.spy.yaml`
- [X] T023 [P] Create Serverpod model for SyncOutbox with relations, indexes in `motaz_app/motaz_app_server/lib/src/models/sync_outbox.spy.yaml`
- [X] T024 [P] Create Serverpod model for SyncCursor with UNIQUE on entity_type, indexes in `motaz_app/motaz_app_server/lib/src/models/sync_cursor.spy.yaml`

**Checkpoint**: Foundation ready — all enums defined, Phase 1 tables extended, foundational Serverpod models created.

---

## Phase 3: User Story 1 — Product Data (Priority: P1) 🎯 MVP

**Goal**: Products are stored with unique name, optional description, default sale price as minor-unit integer, active/disabled status, and all audit/sync fields.

**Independent Test**: Insert a product, retrieve it, confirm all fields persist. Attempt duplicate name — rejected.

### Implementation for User Story 1

- [X] T025 [P] [US1] Create Drift table for Products with text UUID PK, name (NOT NULL, UNIQUE), description (nullable), default_sale_price (integer), is_active (boolean, DEFAULT true), created_at, updated_at, device_id FK, row_version, sync_status intEnum in `motaz_app/motaz_app_flutter/lib/core/database/tables/products.dart`
- [X] T026 [P] [US1] Create Serverpod model for Product with all fields, relation to Device, unique index on name in `motaz_app/motaz_app_server/lib/src/models/product.spy.yaml`

**Checkpoint**: Product entity defined in both local and cloud schemas.

---

## Phase 4: User Story 2 — Client Data (Priority: P1)

**Goal**: Clients are stored with display name (NOT unique), phone, note, client_code as identifying fields, and all audit/sync fields.

**Independent Test**: Insert two clients with the same display name but different phones. Retrieve both — they coexist and are distinguishable.

### Implementation for User Story 2

- [X] T027 [P] [US2] Create Drift table for Clients with text UUID PK, display_name (NOT NULL, no unique constraint), phone (nullable), note (nullable), client_code (nullable), is_active, created_at, updated_at, device_id FK, row_version, sync_status; index on display_name in `motaz_app/motaz_app_flutter/lib/core/database/tables/clients.dart`
- [X] T028 [P] [US2] Create Serverpod model for Client with all fields, relation to Device, index on display_name in `motaz_app/motaz_app_server/lib/src/models/client_record.spy.yaml`

**Checkpoint**: Client entity defined in both schemas.

---

## Phase 5: User Story 3 — Invoice & Invoice Line Data (Priority: P1)

**Goal**: SalesInvoice with UUID PK, local_ref (`INV-<deviceCode>-<seq>`), mandatory client FK, invoice-level discount, total, status/void_reason, and all audit fields. SalesInvoiceLine with invoice FK, product FK, quantity, unit_price, line_total — all minor-unit integers.

**Independent Test**: Insert an invoice with lines, compute total, verify stored values match expected minor-unit integer calculations.

### Implementation for User Story 3

- [X] T029 [P] [US3] Create Drift table for SalesInvoices with text UUID PK, local_ref (text, UNIQUE), official_no (nullable), client_id FK → Clients, invoice_date, discount (integer, DEFAULT 0), total (integer), note (nullable), status (RecordStatus), void_reason (nullable), created_at, updated_at, device_id FK, row_version, sync_status; indexes on invoice_date, client_id, status in `motaz_app/motaz_app_flutter/lib/core/database/tables/sales_invoices.dart`
- [X] T030 [P] [US3] Create Drift table for SalesInvoiceLines with text UUID PK, invoice_id FK → SalesInvoices, product_id FK → Products, quantity (integer), unit_price (integer), line_total (integer), created_at, updated_at; index on invoice_id in `motaz_app/motaz_app_flutter/lib/core/database/tables/sales_invoice_lines.dart`
- [X] T031 [P] [US3] Create Serverpod model for SalesInvoice with all fields, relations to Client and Device, unique index on local_ref in `motaz_app/motaz_app_server/lib/src/models/sales_invoice.spy.yaml`
- [X] T032 [P] [US3] Create Serverpod model for SalesInvoiceLine with all fields, relations to SalesInvoice and Product in `motaz_app/motaz_app_server/lib/src/models/sales_invoice_line.spy.yaml`

**Checkpoint**: Invoice and InvoiceLine entities defined in both schemas.

---

## Phase 6: User Story 4 — Receipt & Allocation Data (Priority: P1)

**Goal**: Receipt with type (INVOICE_LINKED/GENERAL), client FK, optional invoice FK, amount as minor-unit integer, status/void fields. ReceiptAllocation with receipt FK, invoice FK, allocated_amount.

**Independent Test**: Insert a receipt with allocation records, retrieve and verify allocated amounts sum correctly.

### Implementation for User Story 4

- [X] T033 [P] [US4] Create Drift table for Receipts with text UUID PK, receipt_type (ReceiptType intEnum), client_id FK → Clients, invoice_id FK nullable → SalesInvoices, amount (integer), receipt_date, note (nullable), status (RecordStatus), void_reason (nullable), created_at, updated_at, device_id FK, row_version, sync_status; indexes on client_id, receipt_date, status in `motaz_app/motaz_app_flutter/lib/core/database/tables/receipts.dart`
- [X] T034 [P] [US4] Create Drift table for ReceiptAllocations with text UUID PK, receipt_id FK → Receipts, invoice_id FK → SalesInvoices, allocated_amount (integer), created_at, updated_at; indexes on receipt_id, invoice_id in `motaz_app/motaz_app_flutter/lib/core/database/tables/receipt_allocations.dart`
- [X] T035 [P] [US4] Create Serverpod model for Receipt with all fields, relations to Client, SalesInvoice (optional), Device in `motaz_app/motaz_app_server/lib/src/models/receipt.spy.yaml`
- [X] T036 [P] [US4] Create Serverpod model for ReceiptAllocation with all fields, relations to Receipt and SalesInvoice in `motaz_app/motaz_app_server/lib/src/models/receipt_allocation.spy.yaml`

**Checkpoint**: Receipt and ReceiptAllocation entities defined in both schemas.

---

## Phase 7: User Story 5 — Expense Data (Priority: P1)

**Goal**: Expense with one of 5 categories (ExpenseCategory enum), amount as minor-unit integer, date, note, status/void fields, and all audit/sync fields.

**Independent Test**: Insert expenses of each category type, verify they persist. Verify invalid category is rejected by enum typing.

### Implementation for User Story 5

- [X] T037 [P] [US5] Create Drift table for Expenses with text UUID PK, category (ExpenseCategory intEnum), amount (integer), expense_date, note (nullable), status (RecordStatus), void_reason (nullable), created_at, updated_at, device_id FK, row_version, sync_status; indexes on expense_date, category, status in `motaz_app/motaz_app_flutter/lib/core/database/tables/expenses.dart`
- [X] T038 [P] [US5] Create Serverpod model for Expense with all fields, relation to Device in `motaz_app/motaz_app_server/lib/src/models/expense.spy.yaml`

**Checkpoint**: Expense entity defined in both schemas.

---

## Phase 8: User Story 6 — Return & Return Line Data (Priority: P2)

**Goal**: SalesReturn linked to an invoice with return lines referencing original invoice lines. Return lines have returned_quantity and returned_amount as minor-unit integers.

**Independent Test**: Insert a return against an existing invoice with return lines, verify all fields persist correctly.

### Implementation for User Story 6

- [X] T039 [P] [US6] Create Drift table for SalesReturns with text UUID PK, invoice_id FK → SalesInvoices, return_date, total_returned_amount (integer), note (nullable), status (RecordStatus), void_reason (nullable), created_at, updated_at, device_id FK, row_version, sync_status; indexes on invoice_id, return_date, status in `motaz_app/motaz_app_flutter/lib/core/database/tables/sales_returns.dart`
- [X] T040 [P] [US6] Create Drift table for SalesReturnLines with text UUID PK, return_id FK → SalesReturns, invoice_line_id FK → SalesInvoiceLines, returned_quantity (integer), returned_amount (integer), created_at, updated_at; index on return_id in `motaz_app/motaz_app_flutter/lib/core/database/tables/sales_return_lines.dart`
- [X] T041 [P] [US6] Create Serverpod model for SalesReturn with all fields, relations to SalesInvoice and Device in `motaz_app/motaz_app_server/lib/src/models/sales_return.spy.yaml`
- [X] T042 [P] [US6] Create Serverpod model for SalesReturnLine with all fields, relations to SalesReturn and SalesInvoiceLine in `motaz_app/motaz_app_server/lib/src/models/sales_return_line.spy.yaml`

**Checkpoint**: Return and ReturnLine entities defined in both schemas.

---

## Phase 9: User Story 7 — Attachment Metadata (Priority: P2)

**Goal**: AttachmentMetadata stores file references (no binary) linked to invoices or receipts. LocalAttachmentStaging queues offline-captured files for later upload.

**Independent Test**: Insert attachment metadata linked to an invoice, retrieve it, verify storage reference and parent link are correct. No binary content stored.

### Implementation for User Story 7

- [X] T043 [P] [US7] Create Drift table for AttachmentMetadata with text UUID PK, parent_entity_type (ParentEntityType intEnum), parent_entity_id (text), storage_reference (text), secure_url (nullable), file_type (text), file_size (nullable integer), created_at, updated_at, device_id FK, row_version, sync_status; composite index on (parent_entity_type, parent_entity_id) in `motaz_app/motaz_app_flutter/lib/core/database/tables/attachment_metadata.dart`
- [X] T044 [P] [US7] Create Drift table for LocalAttachmentStaging with text UUID PK, parent_entity_type (ParentEntityType intEnum), parent_entity_id (text), local_file_path (text), file_type (text), file_size (nullable integer), upload_status (text, DEFAULT 'PENDING'), created_at, updated_at; index on upload_status in `motaz_app/motaz_app_flutter/lib/core/database/tables/local_attachment_staging.dart`
- [X] T045 [P] [US7] Create Serverpod model for AttachmentMetadata with all fields, relation to Device in `motaz_app/motaz_app_server/lib/src/models/attachment_metadata.spy.yaml`
- [X] T046 [P] [US7] Create Serverpod model for LocalAttachmentStaging with all fields in `motaz_app/motaz_app_server/lib/src/models/local_attachment_staging.spy.yaml`

**Checkpoint**: Attachment entities defined in both schemas.

---

## Phase 10: User Story 8 — Audit Events (Priority: P2)

**Goal**: Immutable audit event log for every financial mutation. Stores entity type, entity ID, operation, changed-fields diff as JSON, device ID, timestamp. Cannot be modified or deleted.

**Independent Test**: Create an audit event, verify it persists. Attempt to modify or delete — rejected.

### Implementation for User Story 8

- [X] T047 [P] [US8] Create Drift table for AuditEvents with text UUID PK, entity_type (ParentEntityType intEnum), entity_id (text), operation (AuditOperation intEnum), diff_data (text — JSON), device_id FK, created_at; composite index on (entity_type, entity_id), index on created_at in `motaz_app/motaz_app_flutter/lib/core/database/tables/audit_events.dart`
- [X] T048 [P] [US8] Create Serverpod model for AuditEvent with all fields, relation to Device in `motaz_app/motaz_app_server/lib/src/models/audit_event.spy.yaml`

**Checkpoint**: AuditEvent entity defined in both schemas.

---

## Phase 11: User Story 9 — Conflict Records (Priority: P2)

**Goal**: Explicit conflict records store payloads from both devices, conflict type, resolution status, and audit fields.

**Independent Test**: Insert a conflict record with two payloads, verify it persists with PENDING status. Resolve it, verify status changes to RESOLVED.

### Implementation for User Story 9

- [X] T049 [P] [US9] Create Drift table for ConflictLogs with text UUID PK, entity_type (ParentEntityType intEnum), entity_id (text), local_payload (text — JSON), remote_payload (text — JSON), conflict_type (text), resolution_status (ConflictStatus intEnum, DEFAULT PENDING), resolved_at (nullable dateTime), resolution_data (nullable text — JSON), created_at, device_id FK; composite index on (entity_type, entity_id), index on resolution_status in `motaz_app/motaz_app_flutter/lib/core/database/tables/conflict_logs.dart`
- [X] T050 [P] [US9] Create Serverpod model for ConflictLog with all fields, relation to Device in `motaz_app/motaz_app_server/lib/src/models/conflict_log.spy.yaml`

**Checkpoint**: ConflictLog entity defined in both schemas.

---

## Phase 12: User Story 10 — Sync Infrastructure Tables (Priority: P1)

**Goal**: Verify that SyncOutbox and SyncCursor tables (extended in Phase 2 foundational T011/T012) match the spec for both local and cloud schemas. Serverpod models were created in T023/T024.

**Independent Test**: Insert outbox and cursor records, verify all fields persist. Query by status, verify filtering works.

### Implementation for User Story 10

> No additional tasks needed — SyncOutbox and SyncCursor are handled by foundational tasks T011, T012, T023, T024.

**Checkpoint**: Sync infrastructure tables verified.

---

## Phase 13: Integration & Code Generation

**Purpose**: Register all new tables, run code generation, and verify everything compiles.

- [X] T051 Update `app_database.dart` to import all new table files and add all 16 tables to `@DriftDatabase(tables: [...])` annotation, bump `schemaVersion` to 2, add migration strategy for version 1→2 in `motaz_app/motaz_app_flutter/lib/core/database/app_database.dart`
- [X] T052 Run Drift code generation: `dart run build_runner build --delete-conflicting-outputs` in `motaz_app/motaz_app_flutter/` — verify `app_database.g.dart` is regenerated with all 16 tables
- [X] T053 Run Serverpod code generation: `serverpod generate` in `motaz_app/motaz_app_server/` — verify generated Dart classes and SQL migration files are created
- [X] T054 Run `flutter analyze` from `motaz_app/motaz_app_flutter/` to verify no type errors or warnings
- [X] T055 Run `dart analyze` from `motaz_app/motaz_app_server/` to verify no type errors or warnings

**Checkpoint**: All tables registered, code generated, project compiles cleanly.

---

## Phase 14: Polish & Verification

**Purpose**: Smoke tests, money integer verification, and final validation.

- [X] T056 [P] Create Drift smoke test: insert/retrieve/void for each financial entity (Product, Client, SalesInvoice, SalesInvoiceLine, Receipt, ReceiptAllocation, Expense, SalesReturn, SalesReturnLine, AttachmentMetadata, LocalAttachmentStaging, AuditEvent, ConflictLog, SyncOutbox, SyncCursor, Device) in `motaz_app/motaz_app_flutter/test/core/database/drift_smoke_test.dart`
- [X] T057 [P] Create money integer test: verify minor-unit integer storage and retrieval with zero precision loss across sample calculations in `motaz_app/motaz_app_flutter/test/core/database/money_integer_test.dart`
- [X] T058 Run all tests: `flutter test test/core/database/` in `motaz_app/motaz_app_flutter/` — verify all pass
- [X] T059 Verify Serverpod migration SQL files exist and contain correct DDL for all 16 tables in `motaz_app/motaz_app_server/migrations/`
- [X] T060 Run quickstart.md validation — confirm all steps in `specs/002-core-data-model/quickstart.md` work end-to-end

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — all 9 enum tasks can run in parallel
- **Phase 2 (Foundational)**: Depends on Phase 1 — extends Phase 1 tables and creates foundational Serverpod models
- **Phases 3–11 (User Stories)**: All depend on Phase 2 completion. Can then proceed in parallel or sequentially by priority
- **Phase 12 (Integration)**: Depends on all user story phases (3–11) being complete
- **Phase 13 (Polish)**: Depends on Phase 12 — tests run after code generation

### User Story Dependencies

- **US1 (Product)**: Phase 2 only — no other story dependencies
- **US2 (Client)**: Phase 2 only — no other story dependencies
- **US3 (Invoice/Lines)**: Depends on US1 (Product FK) and US2 (Client FK)
- **US4 (Receipt/Allocation)**: Depends on US2 (Client FK) and US3 (Invoice FK)
- **US5 (Expense)**: Phase 2 only — no other story dependencies
- **US6 (Return/Lines)**: Depends on US3 (Invoice FK, InvoiceLine FK)
- **US7 (Attachments)**: Phase 2 only — polymorphic FK, no direct table dependency
- **US8 (Audit Events)**: Phase 2 only — polymorphic FK, no direct table dependency
- **US9 (Conflict Log)**: Phase 2 only — polymorphic FK, no direct table dependency
- **US10 (Sync Infrastructure)**: Handled in Phase 2 foundational tasks

### Within Each User Story

- Drift table and Serverpod model tasks are parallel (different files)
- All model tasks within a story marked [P] can run in parallel

### Parallel Opportunities

**Maximum parallelism after Phase 2**:
- US1, US2, US5, US7, US8, US9 can all start simultaneously (6 parallel tracks)
- US3 starts after US1 + US2 complete
- US4 starts after US3 completes
- US6 starts after US3 completes

---

## Parallel Example: Phase 1 (Enums)

```
# All 9 enum tasks can run simultaneously:
T001: SyncStatus enum
T002: RecordStatus enum
T003: ExpenseCategory enum
T004: ReceiptType enum
T005: AuditOperation enum
T006: ConflictStatus enum
T007: SyncOutboxStatus enum
T008: ParentEntityType enum
T009: DevicePlatform enum
```

## Parallel Example: User Story 3 (Invoice)

```
# All 4 tasks can run in parallel (different files):
T029: Drift SalesInvoices table
T030: Drift SalesInvoiceLines table
T031: Serverpod SalesInvoice model
T032: Serverpod SalesInvoiceLine model
```

---

## Implementation Strategy

### MVP First (US1 + US2 only)

1. Complete Phase 1: Enums (9 tasks, all parallel)
2. Complete Phase 2: Foundational (12 tasks)
3. Complete Phase 3: US1 Product (2 tasks, parallel)
4. Complete Phase 4: US2 Client (2 tasks, parallel)
5. **STOP and VALIDATE**: Register just these tables, run codegen, verify

### Full Delivery (Recommended)

1. Phase 1 → Phase 2 → sequentially
2. US1 + US2 + US5 + US7 + US8 + US9 → all in parallel
3. US3 (after US1 + US2) → US4 + US6 (after US3) → parallel
4. Phase 12 Integration → Phase 13 Polish
5. Total: 60 tasks

### Critical Path

Phase 1 → Phase 2 → US1 + US2 → US3 → US4 → Phase 12 → Phase 13

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks
- [Story] label maps task to specific user story for traceability
- Commit after each phase for clean history
- Serverpod models use `.spy.yaml` format with `table:` key for DB mapping
- Drift tables use Dart class DSL with typed column getters
- All monetary columns: `integer()` in Drift, `int` in Serverpod — never `real()` or `double`
- All UUIDs stored as text strings in both SQLite and PostgreSQL
