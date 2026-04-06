# Research: Products & Clients

**Branch**: `004-products-clients`  
**Date**: 2026-04-05

---

## R-001: Schema Gap Analysis — Missing Product Fields

**Decision**: Add `costPrice` (int, nullable), `unit` (text, nullable), and `sku` (text, nullable) to both the Drift Products table and the Serverpod Product model.

**Rationale**: The spec (FR-001) requires cost price, unit label, and SKU. The existing Phase 2 schema only has `name`, `description`, `defaultSalePrice`, and `isActive`. These fields must be added via a Drift migration and Serverpod model update.

**Alternatives considered**:
- Store cost price as a separate entity: rejected — over-engineering for a single optional field.
- Skip unit/SKU for MVP: rejected — the spec explicitly lists them as product fields.

---

## R-002: Schema Gap Analysis — Missing Client Fields

**Decision**: Add `email` (text, nullable) and `address` (text, nullable) to both the Drift Clients table and the Serverpod ClientRecord model.

**Rationale**: The spec (FR-013) includes email and address as client fields. The clarification (Session 2026-04-05) confirms email and address count as valid identifying fields. The existing Phase 2 schema only has `displayName`, `phone`, `note`, and `clientCode`.

**Alternatives considered**:
- Use a key-value "extras" column: rejected — complicates searching and validation.
- Defer email/address to a later phase: rejected — explicitly required in the clarified spec.

---

## R-003: Repository Pattern — Drift DAO Design

**Decision**: Use thin repository classes that wrap Drift `select`, `insert`, `update` queries. Each repository exposes typed methods (`create`, `update`, `toggleActive`, `search`, `getById`, `getAll`). Repositories do NOT call the sync outbox directly — the calling code (providers or use-case layer) creates the outbox entry in the same Drift transaction.

**Rationale**: Keeps repositories focused on data access. The sync outbox entry creation is a cross-cutting concern handled at the provider/service level, consistent with Phase 3's outbox pattern where `OutboxProcessor` reads from the outbox table independently.

**Alternatives considered**:
- Repository also writes outbox entry: rejected — couples data access with sync infrastructure; harder to test.
- No repository, direct Drift queries in providers: rejected — violates separation of concerns; makes testing harder.

---

## R-004: Product Name Uniqueness — Local Validation Strategy

**Decision**: Before save, query the Products table for an existing product with the same name (case-insensitive). Exclude the current product's ID on edit. This is a Drift `SELECT COUNT` query with `LOWER(name) = LOWER(input)`.

**Rationale**: The unique constraint on the Drift table enforces this at the DB level, but catching it in the repository before attempting the insert gives a clean error message. The DB constraint is a safety net.

**Alternatives considered**:
- Rely only on DB unique constraint and catch `SqliteException`: acceptable fallback but gives cryptic errors without additional mapping.
- Full-text search index: overkill for simple exact-name uniqueness.

---

## R-005: Client Outstanding Balance — Compute-on-Read Query

**Decision**: The client summary screen computes outstanding balance by querying active invoices and receipts for the given client ID. Formula: `SUM(invoice.total) - SUM(receipt.amount)` for non-voided records. If no invoices exist yet (Phase 4 runs before Phase 5), the balance shows zero.

**Rationale**: Constitution mandates compute-on-read (Section 9 of implementation plan). No cached balance column.

**Alternatives considered**:
- Materialized balance column updated on each transaction: rejected — violates compute-on-read principle.
- Defer client summary entirely to Phase 5: rejected — spec explicitly includes it (US8), and it works correctly with zero balance when no invoices exist.

---

## R-006: Sync Outbox Integration Pattern

**Decision**: When saving a product or client, the repository wraps the entity insert/update AND the outbox entry insert in a single Drift `transaction()`. The outbox entry contains: entity type (PRODUCT or CLIENT), entity ID, operation (CREATE or UPDATE), JSON payload snapshot, row version, and device ID.

**Rationale**: Single transaction ensures atomicity — if the outbox entry fails, the entity save is rolled back. This is consistent with the offline-first guarantee.

**Alternatives considered**:
- Separate transactions: rejected — risk of orphaned entity without outbox entry.
- Event-driven (watch Drift changes and auto-create outbox): over-engineering for MVP.

---

## R-007: Search Implementation — Live Filtering

**Decision**: Use Drift's `where` clause with `LIKE '%query%'` for product name search and multi-field `OR` search for clients (displayName, phone, clientCode). Expose as a `Stream` via Drift's `.watch()` for reactive UI updates. Debounce user input at 300ms in the presentation layer.

**Rationale**: Drift's `.watch()` automatically re-emits when the underlying table changes (e.g., after a create/edit), keeping the list always up-to-date. SQLite `LIKE` is sufficient for the MVP scale (up to 2000 records).

**Alternatives considered**:
- FTS5 full-text search: unnecessary for the expected data volume and partial-match needs.
- In-memory filtering of a pre-loaded list: wasteful for large lists; loses reactive updates.

---

## R-008: FieldClassifier Sync Rules — Verification

**Decision**: Verified that the existing `FieldClassifier` (from Phase 3) correctly classifies:
- **Product auto-merge**: `description`, `isActive`
- **Product conflict-required**: `name`, `defaultSalePrice`
- **Client auto-merge**: `displayName`, `phone`, `note`, `clientCode`

New fields need to be added to the classifier:
- **Product**: `costPrice` → conflict-required (financial), `unit` → auto-merge, `sku` → auto-merge
- **Client**: `email` → auto-merge, `address` → auto-merge

**Rationale**: Cost price is a monetary value; per constitution, monetary values must not be silently auto-merged. Unit, SKU, email, and address are non-financial descriptive fields safe for last-write-wins.
