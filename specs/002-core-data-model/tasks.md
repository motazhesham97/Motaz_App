# Tasks: Core Data Model

**Input**: Design documents from `specs/002-core-data-model/`
**Prerequisites**: plan.md, spec.md, data-model.md, research.md, quickstart.md

**Organization**: Tasks are grouped by user story. Since this is a schema-only phase, user stories map to entity groups rather than features. All Drift tables (local) and Serverpod models (cloud) for each entity group are co-located within the same story phase.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Create the database infrastructure and directory structure

- [ ] T001 Create Drift database directory at `motaz_app/motaz_app_flutter/lib/core/database/tables/`
- [ ] T002 Create Serverpod models directory at `motaz_app/motaz_app_server/lib/src/models/`
- [ ] T003 [P] Create Drift enum definitions for all 9 enums (SyncStatus, RecordStatus, ExpenseCategory, ReceiptType, AuditOperation, ConflictStatus, SyncOutboxStatus, ParentEntityType, DevicePlatform) at `motaz_app/motaz_app_flutter/lib/core/database/enums.dart`
- [ ] T004 [P] Create Serverpod enum model definitions — one `.spy.yaml` per enum: `motaz_app/motaz_app_server/lib/src/models/sync_status.spy.yaml`, `record_status.spy.yaml`, `expense_category.spy.yaml`, `receipt_type.spy.yaml`, `audit_operation.spy.yaml`, `conflict_status.spy.yaml`, `sync_outbox_status.spy.yaml`, `parent_entity_type.spy.yaml`, `device_platform.spy.yaml`

**Checkpoint**: Directory structure and enum definitions ready for entity creation

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Base entities with no foreign key dependencies — all other entities depend on these

**⚠️ CRITICAL**: No user story entity work can begin until Device, Product, and Client tables exist

- [ ] T005 [P] Create Drift table for Device at `motaz_app/motaz_app_flutter/lib/core/database/tables/device_table.dart` — fields: id (text PK), device_name (text NOT NULL), platform (DevicePlatform enum NOT NULL), device_code (text NOT NULL UNIQUE), next_invoice_sequence (integer NOT NULL DEFAULT 1), created_at (datetime NOT NULL), last_active_at (datetime NOT NULL)
- [ ] T006 [P] Create Serverpod model for Device at `motaz_app/motaz_app_server/lib/src/models/device.spy.yaml` — table: device, matching fields with UNIQUE index on device_code
- [ ] T007 [P] Create Drift table for Product at `motaz_app/motaz_app_flutter/lib/core/database/tables/product_table.dart` — fields: id (text PK), name (text NOT NULL UNIQUE), description (text NULLABLE), default_sale_price (integer NOT NULL), is_active (boolean NOT NULL DEFAULT true), created_at, updated_at, device_id (text NOT NULL FK→Device), row_version (integer NOT NULL DEFAULT 1), sync_status (SyncStatus enum NOT NULL DEFAULT PENDING). Index on name
- [ ] T008 [P] Create Serverpod model for Product at `motaz_app/motaz_app_server/lib/src/models/product.spy.yaml` — table: product, matching fields with UNIQUE index on name
- [ ] T009 [P] Create Drift table for Client at `motaz_app/motaz_app_flutter/lib/core/database/tables/client_table.dart` — fields: id (text PK), display_name (text NOT NULL, no UNIQUE), phone (text NULLABLE), note (text NULLABLE), client_code (text NULLABLE), is_active (boolean NOT NULL DEFAULT true), created_at, updated_at, device_id (text NOT NULL FK→Device), row_version (integer NOT NULL DEFAULT 1), sync_status (SyncStatus enum NOT NULL DEFAULT PENDING). Index on display_name
- [ ] T010 [P] Create Serverpod model for Client at `motaz_app/motaz_app_server/lib/src/models/client.spy.yaml` — table: client, matching fields with index on display_name

**Checkpoint**: Device, Product, and Client tables exist in both local and cloud schemas. All subsequent entities can reference these via FKs.

---

## Phase 3: User Story 3 — Invoice & Invoice Line Schema (Priority: P1) 🎯 MVP

**Goal**: Define the SalesInvoice and SalesInvoiceLine schema in both local and cloud databases

**Independent Test**: Insert an invoice with lines into local DB, compute total, verify minor-unit integer precision and client FK enforcement

### Implementation for User Story 3

- [ ] T011 [P] [US3] Create Drift table for SalesInvoice at `motaz_app/motaz_app_flutter/lib/core/database/tables/sales_invoice_table.dart` — fields: id (text PK), local_ref (text NOT NULL UNIQUE), official_no (text NULLABLE), client_id (text NOT NULL FK→Client), invoice_date (datetime NOT NULL), discount (integer NOT NULL DEFAULT 0), total (integer NOT NULL), note (text NULLABLE), status (RecordStatus enum NOT NULL DEFAULT ACTIVE), void_reason (text NULLABLE), created_at, updated_at, device_id (text NOT NULL FK→Device), row_version (integer NOT NULL DEFAULT 1), sync_status (SyncStatus enum NOT NULL DEFAULT PENDING). Indexes on invoice_date, client_id, status
- [ ] T012 [P] [US3] Create Serverpod model for SalesInvoice at `motaz_app/motaz_app_server/lib/src/models/sales_invoice.spy.yaml` — table: sales_invoice, matching fields with UNIQUE on local_ref, indexes on invoice_date, client_id, status
- [ ] T013 [P] [US3] Create Drift table for SalesInvoiceLine at `motaz_app/motaz_app_flutter/lib/core/database/tables/sales_invoice_line_table.dart` — fields: id (text PK), invoice_id (text NOT NULL FK→SalesInvoice), product_id (text NOT NULL FK→Product), quantity (integer NOT NULL), unit_price (integer NOT NULL), line_total (integer NOT NULL), created_at, updated_at. Index on invoice_id
- [ ] T014 [P] [US3] Create Serverpod model for SalesInvoiceLine at `motaz_app/motaz_app_server/lib/src/models/sales_invoice_line.spy.yaml` — table: sales_invoice_line, matching fields with index on invoice_id

**Checkpoint**: Invoice and invoice line schema complete in both databases. Can verify client FK, local_ref uniqueness, and minor-unit integer storage.

---

## Phase 4: User Story 4 — Receipt & Allocation Schema (Priority: P1)

**Goal**: Define the Receipt and ReceiptAllocation schema in both local and cloud databases

**Independent Test**: Insert a receipt with allocation records, verify both types (INVOICE_LINKED, GENERAL), verify allocated amounts stored as minor-unit integers

### Implementation for User Story 4

- [ ] T015 [P] [US4] Create Drift table for Receipt at `motaz_app/motaz_app_flutter/lib/core/database/tables/receipt_table.dart` — fields: id (text PK), receipt_type (ReceiptType enum NOT NULL), client_id (text NOT NULL FK→Client), invoice_id (text NULLABLE FK→SalesInvoice), amount (integer NOT NULL), receipt_date (datetime NOT NULL), note (text NULLABLE), status (RecordStatus enum NOT NULL DEFAULT ACTIVE), void_reason (text NULLABLE), created_at, updated_at, device_id (text NOT NULL FK→Device), row_version (integer NOT NULL DEFAULT 1), sync_status (SyncStatus enum NOT NULL DEFAULT PENDING). Indexes on client_id, receipt_date, status
- [ ] T016 [P] [US4] Create Serverpod model for Receipt at `motaz_app/motaz_app_server/lib/src/models/receipt.spy.yaml` — table: receipt, matching fields
- [ ] T017 [P] [US4] Create Drift table for ReceiptAllocation at `motaz_app/motaz_app_flutter/lib/core/database/tables/receipt_allocation_table.dart` — fields: id (text PK), receipt_id (text NOT NULL FK→Receipt), invoice_id (text NOT NULL FK→SalesInvoice), allocated_amount (integer NOT NULL), created_at, updated_at. Indexes on receipt_id, invoice_id
- [ ] T018 [P] [US4] Create Serverpod model for ReceiptAllocation at `motaz_app/motaz_app_server/lib/src/models/receipt_allocation.spy.yaml` — table: receipt_allocation, matching fields

**Checkpoint**: Receipt and allocation schema complete. Can verify dual receipt types and explicit allocation records.

---

## Phase 5: User Story 5 — Expense Schema (Priority: P1)

**Goal**: Define the Expense schema with 5 category types in both local and cloud databases

**Independent Test**: Insert expenses of each category type, verify enum constraint rejects invalid categories

### Implementation for User Story 5

- [ ] T019 [P] [US5] Create Drift table for Expense at `motaz_app/motaz_app_flutter/lib/core/database/tables/expense_table.dart` — fields: id (text PK), category (ExpenseCategory enum NOT NULL), amount (integer NOT NULL), expense_date (datetime NOT NULL), note (text NULLABLE), status (RecordStatus enum NOT NULL DEFAULT ACTIVE), void_reason (text NULLABLE), created_at, updated_at, device_id (text NOT NULL FK→Device), row_version (integer NOT NULL DEFAULT 1), sync_status (SyncStatus enum NOT NULL DEFAULT PENDING). Indexes on expense_date, category, status
- [ ] T020 [P] [US5] Create Serverpod model for Expense at `motaz_app/motaz_app_server/lib/src/models/expense.spy.yaml` — table: expense, matching fields

**Checkpoint**: Expense schema complete with all 5 categories enforced.

---

## Phase 6: User Story 6 — Return & Return Line Schema (Priority: P2)

**Goal**: Define the SalesReturn and SalesReturnLine schema in both local and cloud databases

**Independent Test**: Insert a return against an invoice with return lines, verify invoice FK and invoice_line FK

### Implementation for User Story 6

- [ ] T021 [P] [US6] Create Drift table for SalesReturn at `motaz_app/motaz_app_flutter/lib/core/database/tables/sales_return_table.dart` — fields: id (text PK), invoice_id (text NOT NULL FK→SalesInvoice), return_date (datetime NOT NULL), total_returned_amount (integer NOT NULL), note (text NULLABLE), status (RecordStatus enum NOT NULL DEFAULT ACTIVE), void_reason (text NULLABLE), created_at, updated_at, device_id (text NOT NULL FK→Device), row_version (integer NOT NULL DEFAULT 1), sync_status (SyncStatus enum NOT NULL DEFAULT PENDING). Indexes on invoice_id, return_date, status
- [ ] T022 [P] [US6] Create Serverpod model for SalesReturn at `motaz_app/motaz_app_server/lib/src/models/sales_return.spy.yaml` — table: sales_return, matching fields
- [ ] T023 [P] [US6] Create Drift table for SalesReturnLine at `motaz_app/motaz_app_flutter/lib/core/database/tables/sales_return_line_table.dart` — fields: id (text PK), return_id (text NOT NULL FK→SalesReturn), invoice_line_id (text NOT NULL FK→SalesInvoiceLine), returned_quantity (integer NOT NULL), returned_amount (integer NOT NULL), created_at, updated_at. Index on return_id
- [ ] T024 [P] [US6] Create Serverpod model for SalesReturnLine at `motaz_app/motaz_app_server/lib/src/models/sales_return_line.spy.yaml` — table: sales_return_line, matching fields

**Checkpoint**: Return and return line schema complete. Can verify invoice/line FK relationships.

---

## Phase 7: User Story 7 — Attachment Schema (Priority: P2)

**Goal**: Define AttachmentMetadata and LocalAttachmentStaging schema in both local and cloud databases

**Independent Test**: Insert attachment metadata linked to an invoice, verify no binary content stored, verify parent entity link

### Implementation for User Story 7

- [ ] T025 [P] [US7] Create Drift table for AttachmentMetadata at `motaz_app/motaz_app_flutter/lib/core/database/tables/attachment_metadata_table.dart` — fields: id (text PK), parent_entity_type (ParentEntityType enum NOT NULL), parent_entity_id (text NOT NULL), storage_reference (text NOT NULL), secure_url (text NULLABLE), file_type (text NOT NULL), file_size (integer NULLABLE), created_at, updated_at, device_id (text NOT NULL FK→Device), row_version (integer NOT NULL DEFAULT 1), sync_status (SyncStatus enum NOT NULL DEFAULT PENDING). Composite index on (parent_entity_type, parent_entity_id)
- [ ] T026 [P] [US7] Create Serverpod model for AttachmentMetadata at `motaz_app/motaz_app_server/lib/src/models/attachment_metadata.spy.yaml` — table: attachment_metadata, matching fields
- [ ] T027 [P] [US7] Create Drift table for LocalAttachmentStaging at `motaz_app/motaz_app_flutter/lib/core/database/tables/local_attachment_staging_table.dart` — fields: id (text PK), parent_entity_type (ParentEntityType enum NOT NULL), parent_entity_id (text NOT NULL), local_file_path (text NOT NULL), file_type (text NOT NULL), file_size (integer NULLABLE), upload_status (text NOT NULL DEFAULT 'PENDING'), created_at, updated_at. Index on upload_status
- [ ] T028 [P] [US7] Create Serverpod model for LocalAttachmentStaging at `motaz_app/motaz_app_server/lib/src/models/local_attachment_staging.spy.yaml` — table: local_attachment_staging, matching fields

**Checkpoint**: Attachment metadata and staging schema complete. No binary content in DB.

---

## Phase 8: User Story 8 — Audit Event Schema (Priority: P2)

**Goal**: Define the immutable AuditEvent schema in both local and cloud databases

**Independent Test**: Insert an audit event, verify immutability (no update/delete), verify diff_data stores JSON

### Implementation for User Story 8

- [ ] T029 [P] [US8] Create Drift table for AuditEvent at `motaz_app/motaz_app_flutter/lib/core/database/tables/audit_event_table.dart` — fields: id (text PK), entity_type (ParentEntityType enum NOT NULL), entity_id (text NOT NULL), operation (AuditOperation enum NOT NULL), diff_data (text NOT NULL), device_id (text NOT NULL FK→Device), created_at (datetime NOT NULL). Indexes on (entity_type, entity_id) and on created_at. No updated_at field (immutable)
- [ ] T030 [P] [US8] Create Serverpod model for AuditEvent at `motaz_app/motaz_app_server/lib/src/models/audit_event.spy.yaml` — table: audit_event, matching fields

**Checkpoint**: Audit event schema complete. Immutability constraint documented for application-level enforcement.

---

## Phase 9: User Story 9 — Conflict Log Schema (Priority: P2)

**Goal**: Define the ConflictLog schema in both local and cloud databases

**Independent Test**: Insert a conflict record with local and remote payloads, verify pending/resolved status transitions

### Implementation for User Story 9

- [ ] T031 [P] [US9] Create Drift table for ConflictLog at `motaz_app/motaz_app_flutter/lib/core/database/tables/conflict_log_table.dart` — fields: id (text PK), entity_type (ParentEntityType enum NOT NULL), entity_id (text NOT NULL), local_payload (text NOT NULL), remote_payload (text NOT NULL), conflict_type (text NOT NULL), resolution_status (ConflictStatus enum NOT NULL DEFAULT PENDING), resolved_at (datetime NULLABLE), resolution_data (text NULLABLE), created_at (datetime NOT NULL), device_id (text NOT NULL FK→Device). Indexes on (entity_type, entity_id) and on resolution_status
- [ ] T032 [P] [US9] Create Serverpod model for ConflictLog at `motaz_app/motaz_app_server/lib/src/models/conflict_log.spy.yaml` — table: conflict_log, matching fields

**Checkpoint**: Conflict log schema complete. Can verify dual payload storage and resolution status.

---

## Phase 10: User Story 10 — Sync Infrastructure Schema (Priority: P1)

**Goal**: Define SyncOutbox and SyncCursor schema in both local and cloud databases

**Independent Test**: Insert outbox records with various statuses, verify cursor upsert with entity type

### Implementation for User Story 10

- [ ] T033 [P] [US10] Create Drift table for SyncOutbox at `motaz_app/motaz_app_flutter/lib/core/database/tables/sync_outbox_table.dart` — fields: id (text PK), entity_type (ParentEntityType enum NOT NULL), entity_id (text NOT NULL), operation (AuditOperation enum NOT NULL), payload (text NOT NULL), row_version (integer NOT NULL), device_id (text NOT NULL FK→Device), retry_count (integer NOT NULL DEFAULT 0), status (SyncOutboxStatus enum NOT NULL DEFAULT PENDING), created_at (datetime NOT NULL). Indexes on status and on created_at
- [ ] T034 [P] [US10] Create Serverpod model for SyncOutbox at `motaz_app/motaz_app_server/lib/src/models/sync_outbox.spy.yaml` — table: sync_outbox, matching fields
- [ ] T035 [P] [US10] Create Drift table for SyncCursor at `motaz_app/motaz_app_flutter/lib/core/database/tables/sync_cursor_table.dart` — fields: id (text PK), entity_type (ParentEntityType enum NOT NULL UNIQUE), last_pulled_at (datetime NULLABLE), last_row_version (integer NOT NULL DEFAULT 0), updated_at (datetime NOT NULL). UNIQUE on entity_type
- [ ] T036 [P] [US10] Create Serverpod model for SyncCursor at `motaz_app/motaz_app_server/lib/src/models/sync_cursor.spy.yaml` — table: sync_cursor, matching fields with UNIQUE on entity_type

**Checkpoint**: Sync infrastructure schema complete. Phase 3 (Sync Foundation) can now build on these tables.

---

## Phase 11: Integration & Code Generation

**Purpose**: Wire all tables into the Drift database class, run code generation for both platforms, verify everything compiles

- [ ] T037 Create Drift AppDatabase class at `motaz_app/motaz_app_flutter/lib/core/database/app_database.dart` — import all 16 table files, declare `@DriftDatabase(tables: [...])`, set `schemaVersion = 1`, add `MigrationStrategy` with `onCreate`
- [ ] T038 Run Drift code generation — execute `dart run build_runner build --delete-conflicting-outputs` in `motaz_app/motaz_app_flutter/`, verify exit code 0 and `app_database.g.dart` generated
- [ ] T039 Run Serverpod code generation — execute `serverpod generate` in `motaz_app/motaz_app_server/`, verify exit code 0 and generated protocol classes created
- [ ] T040 Verify no REAL or DOUBLE types in monetary columns — grep all table files and `.spy.yaml` files for `real()`, `double`, `REAL`, `DOUBLE` and confirm zero matches

**Checkpoint**: All code generation passes. Both local and cloud schemas are compilable.

---

## Phase 12: Polish & Verification

**Purpose**: Smoke test and final validation

- [ ] T041 Create Drift smoke test at `motaz_app/motaz_app_flutter/test/core/database/app_database_test.dart` — test: open in-memory DB, insert a Product, retrieve it, verify UNIQUE name constraint rejects duplicate, insert a Device with device_code and next_invoice_sequence, verify fields
- [ ] T042 Run smoke test — execute `flutter test test/core/database/app_database_test.dart` in `motaz_app/motaz_app_flutter/`, verify pass
- [ ] T043 Verify all 16 Drift table files exist in `motaz_app/motaz_app_flutter/lib/core/database/tables/` with correct count
- [ ] T044 Verify all 16 Serverpod `.spy.yaml` model files exist in `motaz_app/motaz_app_server/lib/src/models/` with correct count (excluding enum files)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 enums — Device, Product, Client must be created first
- **User Stories (Phases 3–10)**: All depend on Phase 2 (Device, Product, Client)
  - US3 (Invoice): depends on Client, Product, Device
  - US4 (Receipt): depends on Client, SalesInvoice (→ US3)
  - US5 (Expense): depends on Device only (can run parallel with US3)
  - US6 (Return): depends on SalesInvoice, SalesInvoiceLine (→ US3)
  - US7 (Attachment): depends on Device only (can run parallel with US3)
  - US8 (AuditEvent): depends on Device only (can run parallel with US3)
  - US9 (ConflictLog): depends on Device only (can run parallel with US3)
  - US10 (Sync): depends on Device only (can run parallel with US3)
- **Integration (Phase 11)**: Depends on ALL entity phases complete
- **Polish (Phase 12)**: Depends on Phase 11

### User Story Dependencies

- **US1 (Product)** → Phase 2 Foundational (no story dependency)
- **US2 (Client)** → Phase 2 Foundational (no story dependency)
- **US3 (Invoice)** → Phase 2 (needs Product + Client)
- **US4 (Receipt)** → US3 (needs SalesInvoice FK)
- **US5 (Expense)** → Phase 2 only (independent of US3)
- **US6 (Return)** → US3 (needs SalesInvoice + SalesInvoiceLine FK)
- **US7 (Attachment)** → Phase 2 only (independent of US3)
- **US8 (AuditEvent)** → Phase 2 only (independent of US3)
- **US9 (ConflictLog)** → Phase 2 only (independent of US3)
- **US10 (Sync)** → Phase 2 only (independent of US3)

### Parallel Opportunities

After Phase 2 completes, these can all run in parallel:
- US3 (Invoice) + US5 (Expense) + US7 (Attachment) + US8 (Audit) + US9 (Conflict) + US10 (Sync)

After US3 completes, these can run in parallel:
- US4 (Receipt) + US6 (Return)

Within each user story, Drift and Serverpod tasks are marked [P] and can run in parallel.

---

## Parallel Example: User Story 3 (Invoice)

```bash
# All 4 tasks can launch in parallel (different files):
Task T011: "Drift SalesInvoice table"
Task T012: "Serverpod SalesInvoice model"
Task T013: "Drift SalesInvoiceLine table"
Task T014: "Serverpod SalesInvoiceLine model"
```

---

## Implementation Strategy

### MVP First (Foundational + Invoice Schema)

1. Complete Phase 1: Setup (enums + directories)
2. Complete Phase 2: Foundational (Device, Product, Client)
3. Complete Phase 3: US3 (Invoice + InvoiceLine)
4. **STOP and VALIDATE**: Run code generation, verify schema compiles
5. Proceed to remaining stories

### Incremental Delivery

1. Setup + Foundational → Base schema ready
2. US3 (Invoice) → Core commercial entity ready
3. US4 (Receipt) + US5 (Expense) → Payment and expense tracking ready
4. US6 (Return) → Financial reversal schema ready
5. US7–US10 → Supporting infrastructure ready
6. Integration + Polish → Full schema validated

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each Drift table and Serverpod model pair can be written in parallel
- No test tasks were generated (not requested in spec)
- Smoke test in Phase 12 validates basic CRUD + constraint enforcement
- All monetary columns MUST use `integer()` in Drift and `int` in Serverpod — zero tolerance for `real()` or `double`
