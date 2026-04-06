# Data Model: Products & Clients

**Branch**: `004-products-clients`  
**Date**: 2026-04-05

---

## Overview

This document defines the data model changes required for Phase 4. The base schema was created in Phase 2 (002-core-data-model). This phase adds missing columns and documents the full entity model used by the application layer.

---

## Entity: Product

### Full Schema (after migration)

| Field | Type | Constraints | Notes |
|---|---|---|---|
| id | TEXT(36) | PK, UUID v4 | Generated locally on create |
| name | TEXT(255) | NOT NULL, UNIQUE | Case-insensitive uniqueness enforced by app |
| description | TEXT | nullable | Auto-merge field for sync |
| defaultSalePrice | INTEGER | NOT NULL | Minor-unit integer (e.g., 50000 = 500.00 YER) |
| costPrice | INTEGER | nullable | **NEW** — Minor-unit integer. Conflict-required for sync |
| unit | TEXT | nullable | **NEW** — e.g., "قطعة", "كيلو". Auto-merge for sync |
| sku | TEXT | nullable | **NEW** — Stock Keeping Unit. Auto-merge for sync |
| isActive | BOOLEAN | NOT NULL, default=true | false = disabled. Auto-merge for sync |
| createdAt | DATETIME | NOT NULL | Set on create |
| updatedAt | DATETIME | NOT NULL | Set on every mutation |
| deviceId | TEXT(36) | NOT NULL, FK→devices.id | Origin device |
| rowVersion | INTEGER | NOT NULL, default=1 | Incremented on every mutation |
| syncStatus | INTEGER | NOT NULL, default=0 | Enum: PENDING(0), SYNCED(1), CONFLICT(2) |

### Indexes

| Index | Columns | Unique |
|---|---|---|
| product_name_idx | name | ✅ |

### Sync Field Classification

| Category | Fields |
|---|---|
| Auto-merge (last-write-wins) | description, isActive, unit, sku |
| Conflict-required | name, defaultSalePrice, costPrice |

### State Transitions

```
[New] → Active (isActive=true)
Active → Disabled (isActive=false)
Disabled → Active (isActive=true, re-enable)
```

No delete transition. Products are never removed.

---

## Entity: Client

### Full Schema (after migration)

| Field | Type | Constraints | Notes |
|---|---|---|---|
| id | TEXT(36) | PK, UUID v4 | Generated locally on create |
| displayName | TEXT(255) | NOT NULL | NOT unique — duplicates allowed |
| phone | TEXT | nullable | Identifying field. Auto-merge for sync |
| email | TEXT | nullable | **NEW** — Identifying field. Auto-merge for sync |
| address | TEXT | nullable | **NEW** — Identifying field. Auto-merge for sync |
| note | TEXT | nullable | Identifying field. Auto-merge for sync |
| clientCode | TEXT | nullable | Identifying field. Auto-merge for sync |
| isActive | BOOLEAN | NOT NULL, default=true | Not used in Phase 4 (no client disable) |
| createdAt | DATETIME | NOT NULL | Set on create |
| updatedAt | DATETIME | NOT NULL | Set on every mutation |
| deviceId | TEXT(36) | NOT NULL, FK→devices.id | Origin device |
| rowVersion | INTEGER | NOT NULL, default=1 | Incremented on every mutation |
| syncStatus | INTEGER | NOT NULL, default=0 | Enum: PENDING(0), SYNCED(1), CONFLICT(2) |

### Indexes

| Index | Columns | Unique |
|---|---|---|
| idx_client_display_name | displayName | ❌ |

### Identifying Field Rule

At least ONE of these fields must be non-empty:
- phone, email, address, note, clientCode

This is enforced at the **application layer** (form validation), not by a database constraint.

### Sync Field Classification

| Category | Fields |
|---|---|
| Auto-merge (last-write-wins) | displayName, phone, email, address, note, clientCode |
| Conflict-required | (none for clients) |

---

## Derived / Computed Data

| Computation | Source Tables | Formula |
|---|---|---|
| Client Outstanding Balance | invoices, receipts | SUM(active_invoice.total) - SUM(active_receipt.amount) |
| Client Transaction History | invoices, receipts, returns | Recent records ordered by date, filtered by clientId |

These are **computed on-read** per constitution. No cached columns.

---

## Schema Migration Plan

### Drift (Local SQLite)

Add 3 columns to Products table:
- `costPrice`: `IntColumn` nullable
- `unit`: `TextColumn` nullable
- `sku`: `TextColumn` nullable

Add 2 columns to Clients table:
- `email`: `TextColumn` nullable
- `address`: `TextColumn` nullable

All new columns are nullable, so the migration is additive and non-breaking.

### Serverpod (Cloud PostgreSQL)

Add matching fields to `product.spy.yaml`:
- `costPrice: int?`
- `unit: String?`
- `sku: String?`

Add matching fields to `client_record.spy.yaml`:
- `email: String?`
- `address: String?`

Run `serverpod generate` and create the migration.

### FieldClassifier Update

Add new fields to the existing classifier:
- Product: `costPrice` → conflict-required, `unit` → auto-merge, `sku` → auto-merge
- Client: `email` → auto-merge, `address` → auto-merge
