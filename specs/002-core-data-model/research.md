# Research: Core Data Model

**Branch**: `002-core-data-model` | **Date**: 2026-03-22

## R1: Drift Table Definition Patterns

**Decision**: Use Drift's declarative Dart table classes with typed column definitions.
**Rationale**: Drift's table DSL provides compile-time checked schema definitions with automatic migration support. Each table is a Dart class extending `Table` with typed column getters.
**Alternatives considered**:
- Raw SQL schema files — rejected: lose type safety and Drift's query builder integration.
- Drift `.drift` files — rejected: Dart class approach is more idiomatic and integrates better with the rest of the codebase.

**Key patterns**:
- UUID columns: use `text()` with a UUID string (Drift doesn't have a native UUID column type for SQLite). Set as primary key.
- Money columns: use `integer()` — stores minor-unit integers. Never use `real()`.
- DateTime columns: use `dateTime()` for timestamps.
- Enums: use `intEnum()` for type-safe enum mapping.
- Text enums (sync_status, receipt_type): use `textEnum()`.
- Foreign keys: use `text().references(OtherTable, #id)`.
- Unique constraints: override `uniqueKeys` getter.
- Indexes: use `@TableIndex` annotation.

## R2: Serverpod Model Definition Format

**Decision**: Use `.spy.yaml` files with `table:` key to connect models to PostgreSQL tables.
**Rationale**: Serverpod's standard model file convention. Running `serverpod generate` produces Dart classes and SQL migration files automatically.
**Alternatives considered**:
- Raw SQL migrations — rejected: Serverpod ORM handles this when `table:` key is present.

**Key patterns**:
- UUID fields: use `type: UuidValue` with `defaultPersist: random` and set as `!persist` for auto-generated UUIDs.
- Money fields: use `type: int` (minor-unit integers). Use `columnName:` when snake_case differs.
- DateTime fields: use `type: DateTime`.
- Enums: define as separate `.spy.yaml` files with `enum:` key and `values:` list. Reference with `type: EnumName`.
- Foreign keys: use `relation` parent/field syntax.
- Nullable fields: append `?` to type.
- Indexes: use `indexes:` section in the model definition.

## R3: Polymorphic Foreign Keys (Attachment, Audit, Conflict, Sync)

**Decision**: Use `parent_entity_type` (text) + `parent_entity_id` (text/UUID) columns instead of multiple nullable FKs.
**Rationale**: Several entities (AttachmentMetadata, AuditEvent, ConflictLog, SyncOutbox) can reference any entity type. Polymorphic FK pattern is cleaner than N nullable FK columns.
**Alternatives considered**:
- Separate junction tables per entity type — rejected: excessive table count for a schema-only phase.
- Multiple nullable FKs — rejected: grows linearly with entity types, most would be null.

**Constraint**: No database-level FK enforcement for polymorphic keys. Integrity enforced by application logic in later phases.

## R4: Drift Migration Strategy

**Decision**: Use Drift's schema versioning with `schemaVersion` and `MigrationStrategy`.
**Rationale**: Drift provides built-in migration support. Starting at `schemaVersion = 1` for the initial schema. Future versions increment and define `onUpgrade` callbacks.
**Alternatives considered**:
- Drop-and-recreate on each version — rejected: destroys data, violates constitution.

## R5: Audit Event Diff Storage

**Decision**: Store the changed-fields diff as a JSON text column.
**Rationale**: JSON provides flexible, queryable storage for variable-length diffs. For standard edits, only changed fields are captured. For voids/returns/allocations, all financially sensitive affected fields are included.
**Alternatives considered**:
- Separate audit_field_change table with one row per changed field — rejected: over-normalized for MVP scale.
- Full entity snapshot — rejected per clarification: too much storage.

## R6: Enum Definitions Required

The following enum types are needed in both local and cloud schemas:

| Enum | Values |
|------|--------|
| SyncStatus | PENDING, SYNCED, CONFLICT, FAILED |
| RecordStatus | ACTIVE, VOIDED |
| ExpenseCategory | OWNER_DRAW, PARTNER_DRAW, MARGIN_DRAW, OPERATIONAL, PRODUCTION |
| ReceiptType | INVOICE_LINKED, GENERAL |
| AuditOperation | CREATE, UPDATE, VOID |
| ConflictStatus | PENDING, RESOLVED |
| SyncOutboxStatus | PENDING, IN_PROGRESS, COMPLETED, FAILED |
| ParentEntityType | SALES_INVOICE, RECEIPT, PRODUCT, CLIENT, EXPENSE, SALES_RETURN |
| DevicePlatform | ANDROID, WINDOWS |

**All NEEDS CLARIFICATION items resolved. No unknowns remain.**
