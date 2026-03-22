# Feature Specification: Core Data Model

**Feature Branch**: `002-core-data-model`
**Created**: 2026-03-22
**Status**: Draft
**Input**: User description: "Phase 2 Core Data Model — Build the canonical local and cloud schema for products, clients, invoices, invoice lines, receipts, receipt allocations, expenses, returns, return lines, attachment metadata, devices, audit events, conflicts, sync cursors, and sync outbox."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Product Data Is Structured and Ready for Use (Priority: P1)

The system stores and retrieves product records with all required fields: a unique identity, a unique name, an optional description, a default sale price stored as a minor-unit integer, and an active/disabled status. The owner can rely on this structure to create products later (in Phase 4) and reference them in invoices. Product names must be unique across the system. Products can never be hard-deleted — only disabled.

**Why this priority**: Products are master data referenced by invoices, returns, and reports. Without a correct product schema, no commercial transaction can be built.

**Independent Test**: Can be tested by inserting a product record into the local database, retrieving it, confirming all fields persist correctly, and verifying that duplicate product names are rejected.

**Acceptance Scenarios**:

1. **Given** the database is initialized, **When** a product record is inserted with a unique name, description, default sale price, and active status, **Then** the record persists and all fields are retrievable with correct values.
2. **Given** a product exists with name "منتج أ", **When** another product is inserted with the same name, **Then** the operation is rejected due to the uniqueness constraint.
3. **Given** a product exists, **When** the product is disabled, **Then** its `is_active` field is set to false and no data is deleted.
4. **Given** a product with a default sale price of 1250.00 YER, **When** the price is stored, **Then** it is persisted as the integer `125000` (minor-unit representation).
5. **Given** a product record exists, **When** it is retrieved, **Then** it includes `created_at`, `updated_at`, `device_id`, `row_version`, and `sync_status` fields.

---

### User Story 2 - Client Data Is Structured and Distinguishable (Priority: P1)

The system stores and retrieves client records with all required fields: a unique identity, a display name, at least one additional identifying field (phone, note, or client code) to distinguish clients with the same name, and status metadata. Client names are not required to be unique. Clients can never be hard-deleted.

**Why this priority**: Clients are referenced by every invoice and receipt. Without a correct client schema and the ability to distinguish same-name clients, the commercial transaction engine cannot function.

**Independent Test**: Can be tested by inserting two client records with the same display name but different identifying fields, retrieving both, and confirming they are distinguishable.

**Acceptance Scenarios**:

1. **Given** the database is initialized, **When** a client record is inserted with a display name, phone number, and optional note, **Then** the record persists and all fields are retrievable.
2. **Given** a client named "أحمد" exists, **When** another client named "أحمد" with a different phone number is inserted, **Then** both records coexist without conflict.
3. **Given** a client exists, **When** it is retrieved, **Then** it includes `created_at`, `updated_at`, `device_id`, `row_version`, and `sync_status` fields.
4. **Given** multiple clients with the same name exist, **When** they are listed, **Then** each is distinguishable by its additional identifying field (phone, note, or client code).

---

### User Story 3 - Invoice and Invoice Line Data Is Structured for Financial Correctness (Priority: P1)

The system stores sales invoices with a UUID primary key, a human-readable local reference (`INV-<deviceCode>-<localSequence>`), a mandatory link to a client, an optional invoice-level discount, a computed total, a status (active/voided), void reason, and audit fields. Each invoice contains one or more invoice lines with quantity, unit price, and line total — all stored as minor-unit integers. The schema enforces that every invoice belongs to exactly one client.

**Why this priority**: Invoices are the central financial entity. All receipts, returns, and reports depend on invoice structure. Getting this wrong invalidates the entire accounting system.

**Independent Test**: Can be tested by inserting an invoice with multiple lines, computing the total, and verifying the stored values match the expected minor-unit integer calculations.

**Acceptance Scenarios**:

1. **Given** the database is initialized and a client exists, **When** a sales invoice is created with a client reference, local ref, and one or more lines, **Then** the invoice and its lines persist correctly.
2. **Given** an invoice with 3 lines: (qty=2, price=50000), (qty=1, price=75000), (qty=3, price=30000), and an invoice-level discount of 10000, **When** the total is computed, **Then** it equals `(2×50000 + 1×75000 + 3×30000) − 10000 = 255000` (stored as integer).
3. **Given** an invoice exists, **When** it is voided, **Then** its status changes to "voided", a void reason is recorded, and no data is deleted.
4. **Given** no client is specified, **When** an invoice is created, **Then** the operation is rejected (client is mandatory).
5. **Given** an invoice exists, **When** its local reference is checked, **Then** it follows the format `INV-<deviceCode>-<localSequence>`, where `deviceCode` is the first 4 hex characters of the device's UUID.
6. **Given** an invoice is created on a device, **When** the invoice is saved, **Then** the device's `next_invoice_sequence` counter is incremented and the new value is used as the `localSequence` in the local reference.
7. **Given** an invoice record exists, **When** it is retrieved, **Then** it includes `created_at`, `updated_at`, `device_id`, `row_version`, `sync_status`, and `invoice_date` fields.

---

### User Story 4 - Receipt and Allocation Data Supports Both Receipt Types (Priority: P1)

The system stores receipts with a type indicator (invoice-linked or general client receipt), a link to a client, an optional link to a specific invoice (for invoice-linked receipts), the receipt amount as a minor-unit integer, a status (active/voided), and audit fields. Receipt allocations are stored explicitly as separate records linking a receipt to an invoice with an allocated amount, supporting the FIFO allocation strategy.

**Why this priority**: Receipts and their allocations determine client balances, outstanding receivables, and payment tracking. Explicit allocation records are a constitutional requirement for FIFO and recalculation.

**Independent Test**: Can be tested by inserting a receipt with explicit allocation records, retrieving them, and verifying the allocated amounts sum correctly.

**Acceptance Scenarios**:

1. **Given** an invoice exists, **When** an invoice-linked receipt is created with the invoice reference and a payment amount, **Then** the receipt and its allocation record persist correctly.
2. **Given** a client has multiple unpaid invoices, **When** a general client receipt is created, **Then** allocation records can be stored linking the receipt to specific invoices with specific amounts.
3. **Given** a receipt exists, **When** it is voided, **Then** its status changes to "voided", a void reason is recorded, and no data is deleted.
4. **Given** allocation records exist for a receipt, **When** they are retrieved, **Then** each allocation includes receipt ID, invoice ID, allocated amount, and audit fields.

---

### User Story 5 - Expense Data Supports All Five Categories (Priority: P1)

The system stores expenses with one of exactly five category types: OWNER_DRAW, PARTNER_DRAW, MARGIN_DRAW, OPERATIONAL, or PRODUCTION. Each expense includes an amount (minor-unit integer), a date, an optional note, a status (active/voided), and audit fields. The schema enforces that only valid category values are stored.

**Why this priority**: Expenses feed directly into the profit calculation engine. Only OPERATIONAL and PRODUCTION affect net profit. Without the correct category structure, profit distribution is impossible.

**Independent Test**: Can be tested by inserting expenses of each category type and verifying they persist with correct values, and that an invalid category is rejected.

**Acceptance Scenarios**:

1. **Given** the database is initialized, **When** an expense is created with category "OPERATIONAL", amount 50000, and date, **Then** the record persists correctly.
2. **Given** the five valid categories, **When** expenses are created for each category, **Then** all five persist successfully.
3. **Given** a valid expense exists, **When** it is voided, **Then** its status changes to "voided", a void reason is recorded, and no data is deleted.
4. **Given** an expense record, **When** it is retrieved, **Then** it includes `created_at`, `updated_at`, `device_id`, `row_version`, `sync_status`, and `expense_date` fields.

---

### User Story 6 - Return and Return Line Data Supports Partial Financial Returns (Priority: P2)

The system stores sales returns linked to a specific invoice, with one or more return lines specifying the quantity and amount being returned. Returns are financial records — not note-only markers. Each return includes a status (active/voided), void reason, and audit fields. Return lines reference the original invoice line.

**Why this priority**: Returns reduce outstanding balances or create client credits. Without proper return structure, the accounting reversal logic cannot function.

**Independent Test**: Can be tested by inserting a return against an existing invoice, adding return lines, and verifying all fields persist correctly.

**Acceptance Scenarios**:

1. **Given** an invoice with lines exists, **When** a partial return is created referencing the invoice with return lines, **Then** the return and its lines persist correctly.
2. **Given** a return exists, **When** it is voided, **Then** its status changes to "voided", a void reason is recorded, and no data is deleted.
3. **Given** a return line, **When** it is retrieved, **Then** it includes the original invoice line reference, returned quantity, returned amount (minor-unit integer), and audit fields.

---

### User Story 7 - Attachment Metadata Is Stored Without Binary Content (Priority: P2)

The system stores attachment metadata records linking a file to an invoice or receipt. Metadata includes the storage reference (for the external file service), file type, file size, the parent entity type and ID, and audit fields. No binary file content is stored in the database.

**Why this priority**: Attachments are allowed for invoices and receipts per the constitution. The metadata structure enables offline staging and later upload.

**Independent Test**: Can be tested by inserting an attachment metadata record linked to an invoice, retrieving it, and verifying the storage reference and parent link are correct.

**Acceptance Scenarios**:

1. **Given** an invoice exists, **When** attachment metadata is created linking to the invoice, **Then** the metadata record persists with storage reference, file type, and parent link.
2. **Given** a receipt exists, **When** attachment metadata is created linking to the receipt, **Then** the metadata record persists correctly.
3. **Given** attachment metadata exists for a voided invoice, **When** the metadata is retrieved, **Then** it is still present and linked to the voided record (attachments are preserved on void).
4. **Given** an attachment metadata record, **When** it is retrieved, **Then** it does not contain any binary file content.

---

### User Story 8 - Audit Events Provide Immutable Financial History (Priority: P2)

The system logs every financial mutation (create, update, void) as an immutable audit event record. Each audit event includes the entity type, entity ID, the operation performed, a diff of the changed fields, the device that performed the operation, and a timestamp. For standard edits, only the modified fields are captured. For financially sensitive operations (voids, returns, allocations), all financially sensitive fields affected by the operation may be included in the diff. Audit events can never be modified or deleted.

**Why this priority**: Audit history is a constitutional governance requirement. Every financial mutation must be traceable for accountability and conflict resolution.

**Independent Test**: Can be tested by performing a financial operation (e.g., creating an invoice), retrieving the audit event, and verifying the diff contains the correct changed fields and the record is immutable.

**Acceptance Scenarios**:

1. **Given** a financial operation is performed (create, update, or void), **When** the operation completes, **Then** an audit event record is created with entity type, entity ID, operation, changed-fields diff, device ID, and timestamp.
2. **Given** an audit event exists, **When** an attempt is made to modify or delete it, **Then** the operation is rejected (immutability enforced).
3. **Given** multiple operations on the same entity, **When** audit events are queried for that entity, **Then** all events are returned in chronological order.
4. **Given** a void or return operation is performed, **When** the audit event is created, **Then** the diff includes all financially sensitive fields affected by the operation, not just the status change.

---

### User Story 9 - Conflict Records Surface Sync Disputes for User Resolution (Priority: P2)

The system stores explicit conflict records when two devices make conflicting changes to the same financial record. Each conflict record includes the entity type, entity ID, the conflicting payloads from both devices, the conflict type, a resolution status (pending/resolved), and audit fields.

**Why this priority**: Financial conflicts must never be silently auto-merged per the constitution. Explicit conflict records are the mechanism for surfacing disputes.

**Independent Test**: Can be tested by inserting a conflict record with two conflicting payloads and verifying it persists with correct structure and status.

**Acceptance Scenarios**:

1. **Given** a financial conflict is detected, **When** a conflict record is created, **Then** it includes entity type, entity ID, local payload, remote payload, conflict type, and a "pending" status.
2. **Given** a pending conflict exists, **When** it is resolved, **Then** its status changes to "resolved" and the resolution is recorded.
3. **Given** conflict records exist, **When** they are queried by status, **Then** pending and resolved conflicts can be filtered independently.

---

### User Story 10 - Sync Infrastructure Tables Are Ready for the Sync Engine (Priority: P1)

The system provides sync outbox and sync cursor tables that the future sync engine (Phase 3) will use. The sync outbox queues every local mutation with entity type, entity ID, operation, payload snapshot, row version, device ID, retry count, and status. The sync cursor tracks the last-pulled timestamp per entity type. These tables enable Phase 3 to build the actual sync logic without schema changes.

**Why this priority**: Without the sync infrastructure schema in place, Phase 3 cannot begin. These tables are a prerequisite for the entire offline-first architecture.

**Independent Test**: Can be tested by inserting records into both tables and verifying all fields persist correctly. The actual sync logic is tested in Phase 3.

**Acceptance Scenarios**:

1. **Given** a local mutation occurs, **When** an outbox record is created with entity type, entity ID, operation, payload, row version, device ID, retry count, and status, **Then** the record persists correctly.
2. **Given** the sync cursor table exists, **When** a cursor record is upserted with entity type and last-pulled timestamp, **Then** the record persists correctly.
3. **Given** outbox records exist with different statuses, **When** they are queried by status, **Then** pending and completed records can be filtered.

---

### Edge Cases

- What happens when a product's default sale price is set to zero? The system must allow zero-price products (e.g., free samples or promotional items) and store the value as `0`.
- What happens when an invoice has no lines? The schema must require at least one line per invoice at the application level (enforced by the business logic layer, not a database constraint, since lines are in a separate table).
- What happens when every field in a record is at its maximum length? The system must handle maximum-length text fields gracefully without truncation or errors.
- What happens when the local database schema needs to be upgraded after an app update? The migration system must upgrade the schema while preserving all existing data.
- What happens when two devices create records with the same UUID? UUID v4 collision probability is negligible, but the schema should use UUID as the primary key type to support this assumption.
- What happens when a receipt allocation amount exceeds the invoice remaining balance? The schema supports any integer value; business logic validation (not schema constraint) should prevent this in later phases.

## Clarifications

### Session 2026-03-22

- Q: Should the cloud schema (Neon/Serverpod ORM) be defined in this phase or only the local schema (Drift)? → A: Both local and cloud schemas are in scope per the implementation plan Phase 2.
- Q: Should the local attachment staging table be included? → A: Yes, include `LocalAttachmentStaging` alongside `AttachmentMetadata` for offline attachment support.
- Q: Are device and sync tables part of this phase even though basic versions exist from Phase 1? → A: Phase 1 created initial Drift tables for devices, sync_outbox, and sync_cursor. Phase 2 extends these to the cloud schema and ensures the complete entity set is defined in both local and cloud databases.
- Q: How should the deviceCode portion of invoice local_ref be derived? → A: Auto-generated from the first 4 hex characters of the device UUID (e.g., device UUID starting with "a3b8..." produces deviceCode "a3b8").
- Q: What should the audit event snapshot contain? → A: Changed fields only (diff/delta) by default. For financially sensitive operations (voids, returns, allocations), the diff may include all financially sensitive fields affected by the operation.
- Q: Should the schema include a field to persist the per-device invoice sequence counter? → A: Yes, add a `next_invoice_sequence` integer field to the Device entity. The counter lives with the device record and survives app restarts.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST define a complete local database schema covering all core entities: Product, Client, SalesInvoice, SalesInvoiceLine, Receipt, ReceiptAllocation, Expense, SalesReturn, SalesReturnLine, AttachmentMetadata, LocalAttachmentStaging, Device, AuditEvent, ConflictLog, SyncOutbox, and SyncCursor.
- **FR-002**: The system MUST define a complete cloud database schema covering the same entities as the local database, suitable for the server-side data store.
- **FR-003**: All monetary fields MUST be stored as minor-unit integers (2 decimal places). No floating-point types are permitted in any money column.
- **FR-004**: Product names MUST have a uniqueness constraint in both local and cloud schemas.
- **FR-005**: Client names MUST NOT have a uniqueness constraint. Clients MUST have at least one additional identifying field (phone, note, or client code).
- **FR-006**: Every sales invoice MUST reference exactly one client. The client reference MUST be enforced by a foreign key or equivalent constraint.
- **FR-007**: Every sales invoice MUST have a UUID primary key and a human-readable local reference in the format `INV-<deviceCode>-<localSequence>`, where `deviceCode` is the first 4 hex characters of the device's UUID.
- **FR-008**: Sales invoice discounts MUST be at the invoice level only. No line-level discounts.
- **FR-009**: Receipts MUST support two types: invoice-linked and general client receipt.
- **FR-010**: Receipt allocations MUST be stored as explicit, separate records linking a receipt to an invoice with an allocated amount.
- **FR-011**: Expenses MUST be categorized using exactly five values: OWNER_DRAW, PARTNER_DRAW, MARGIN_DRAW, OPERATIONAL, PRODUCTION.
- **FR-012**: Sales returns MUST reference exactly one invoice. Return lines MUST reference the corresponding invoice line.
- **FR-013**: Attachment metadata MUST NOT contain binary file content. Only storage references, file type, size, and parent entity link are stored.
- **FR-014**: Attachments MUST be allowed only for invoices and receipts.
- **FR-015**: Audit events MUST be immutable. No update or delete operations are permitted on audit event records.
- **FR-016**: Conflict records MUST store payloads from both conflicting devices and a resolution status.
- **FR-017**: Every financial record MUST include: `created_at`, `updated_at`, `device_id` (origin device), `row_version`, and `sync_status` fields.
- **FR-018**: Financial records MUST NOT use hard delete. Void/cancel semantics with a status field and void reason MUST be used instead.
- **FR-019**: The local schema MUST support migration (schema versioning and upgrade) to preserve existing data across app updates.
- **FR-020**: The cloud schema MUST support migration to preserve existing data across server updates.
- **FR-021**: The sync outbox MUST store: entity type, entity ID, operation type, payload snapshot, row version, device ID, retry count, status, and timestamp.
- **FR-022**: The sync cursor MUST track the last-pulled timestamp and last row version per entity type.
- **FR-023**: Local attachment staging MUST store the local file path, parent entity type and ID, and upload status for offline-captured attachments.

### Key Entities

- **Product**: Master data for items the business sells. Has unique name, optional description, default sale price (minor-unit integer), active/disabled status.
- **Client**: Master data for customers. Has display name (not unique), phone, note, client code, and other identifying fields.
- **SalesInvoice**: Financial transaction representing a sale to a client. Has UUID PK, local reference, client FK, invoice-level discount, total, status, void reason, invoice date.
- **SalesInvoiceLine**: Line item within an invoice. Has invoice FK, product FK, quantity, unit price, line total — all monetary values as minor-unit integers.
- **Receipt**: Financial record of a payment. Has type (invoice-linked/general), client FK, optional invoice FK, amount, status, void reason, receipt date.
- **ReceiptAllocation**: Explicit allocation record linking a receipt to an invoice with a specific allocated amount. Enables FIFO and recalculation.
- **Expense**: Financial record of a business outflow. Has category (5 types), amount, date, note, status, void reason.
- **SalesReturn**: Financial record of a partial return against an invoice. Has invoice FK, status, void reason, return date.
- **SalesReturnLine**: Line item within a return. Has return FK, invoice line FK, returned quantity, returned amount.
- **AttachmentMetadata**: Storage reference for a file linked to an invoice or receipt. Has parent entity type and ID, storage reference, file type, file size.
- **LocalAttachmentStaging**: Offline queue for attachments captured without connectivity. Has local file path, parent entity type and ID, upload status.
- **Device**: Physical device running the app. Has UUID, device name, platform, device code (first 4 hex chars of UUID, used in invoice local_ref), next invoice sequence counter, created/last active timestamps.
- **AuditEvent**: Immutable log entry for every financial mutation. Has entity type, entity ID, operation, changed-fields diff (expanded to all financially sensitive fields for voids/returns/allocations), device ID, timestamp.
- **ConflictLog**: Explicit record of a sync conflict. Has entity type, entity ID, local payload, remote payload, conflict type, resolution status.
- **SyncOutbox**: Mutation queue for offline-first sync. Has entity type, entity ID, operation, payload, row version, device ID, retry count, status.
- **SyncCursor**: Tracks sync progress per entity type. Has entity type, last-pulled timestamp, last row version.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Every core entity can be created, retrieved, and (where applicable) voided in the local database without errors.
- **SC-002**: Every core entity can be created, retrieved, and (where applicable) voided in the cloud database without errors.
- **SC-003**: All monetary values across both schemas store and retrieve values as minor-unit integers with zero precision loss across 1,000 sample calculations.
- **SC-004**: Product name uniqueness is enforced — duplicate inserts are rejected 100% of the time.
- **SC-005**: Every sales invoice is linked to exactly one client — invoices without a client reference are rejected 100% of the time.
- **SC-006**: Audit event records cannot be modified or deleted after creation — attempted modifications are rejected 100% of the time.
- **SC-007**: Schema migrations upgrade the local database in under 5 seconds while preserving all existing records.
- **SC-008**: Schema migrations upgrade the cloud database while preserving all existing records.
- **SC-009**: All financial records include the required audit fields (`created_at`, `updated_at`, `device_id`, `row_version`, `sync_status`) with no null values in mandatory fields.
- **SC-010**: Hard delete operations on financial records are prevented — only void/cancel status changes are permitted.

## Assumptions

- Phase 1 (Workspace Foundation) has been completed, providing the app shell, authentication, base database setup, and Riverpod infrastructure.
- The Device, SyncOutbox, and SyncCursor tables from Phase 1 exist locally. Phase 2 extends the complete entity set to both local and cloud schemas.
- The business logic layer (repositories, services) that enforces complex validation rules (e.g., "invoice must have at least one line") will be built in later phases. This phase focuses on the schema structure.
- The actual sync engine, FIFO allocation logic, and profit calculation engine are built in later phases. This phase provides only the schema those engines will operate on.
- The `official_no` field on invoices is null in MVP and reserved for future authoritative numbering.
- The `local_ref` sequence counter is stored as `next_invoice_sequence` on the Device entity, managed by application logic (not database auto-increment), because it is per-device.

## Dependencies

- Phase 1 (Workspace Foundation) must be complete — provides the database infrastructure, app shell, and authentication.
- Constitution v1.3.0 defines all data rules, non-negotiables, and entity requirements governing this schema.
- Master Implementation Plan v2 §8 (Core Entities), §9 (Derived Data Strategy), and §10 (Accounting Rules) define the entity structures and relationships.

## Scope Boundaries

**In scope:**
- Complete local database schema (all 17 entities) with Drift table definitions
- Complete cloud database schema (all 17 entities) with Serverpod ORM models and migrations
- Constraints: uniqueness, foreign keys, not-null, valid enum values
- Search indexes for frequently queried fields (product name, client name, invoice date, etc.)
- Schema migration support for both local and cloud databases
- Minor-unit integer enforcement for all monetary columns

**Out of scope:**
- Business logic (repositories, services, domain validation)
- UI screens (product creation, invoice builder, etc.)
- Sync engine implementation (Phase 3)
- FIFO allocation logic (Phase 5)
- Profit calculation engine (Phase 6)
- Report queries and dashboard (Phase 8)
- PDF generation
- Actual data seeding or sample data
