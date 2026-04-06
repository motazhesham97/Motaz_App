# Endpoint Contracts: Products & Clients

**Branch**: `004-products-clients`  
**Date**: 2026-04-05

---

## No New Endpoints Required

Products and Clients use the **existing sync infrastructure** from Phase 3 (003-sync-foundation). All CRUD operations follow this pattern:

1. **Local save** → Drift insert/update to SQLite
2. **Outbox entry** → SyncOutbox row created in same transaction
3. **Push** → `SyncEndpoint.push()` sends the mutation via the existing generic push pipeline
4. **Pull** → `SyncEndpoint.pull()` retrieves server-side changes via the existing generic pull pipeline

No product-specific or client-specific Serverpod endpoints are needed. The sync engine already handles:
- Entity type routing via `ParentEntityType` enum (PRODUCT, CLIENT already defined)
- Row version checks and conflict detection
- Auto-merge vs. conflict-required field classification
- Void-wins enforcement

### What Changes

| Component | Change |
|---|---|
| `SyncService.acceptMutation` column allowlist | Add `costPrice`, `unit`, `sku` for Product; `email`, `address` for Client |
| `PullProcessor._entityTableName` mapping | Already mapped from Phase 3 — no change needed |
| `FieldClassifier` | Add new fields to classification (see data-model.md) |
