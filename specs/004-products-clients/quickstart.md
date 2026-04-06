# Quickstart: Products & Clients

**Branch**: `004-products-clients`  
**Date**: 2026-04-05

---

## Prerequisites

1. **Phase 2 complete**: Core data model with Drift tables and Serverpod models
2. **Phase 3 complete**: Sync foundation (outbox, push, pull, conflict detection)
3. **Flutter SDK**: 3.x stable
4. **Serverpod CLI**: Latest stable

---

## Setup Steps

### 1. Switch to feature branch

```bash
git checkout 004-products-clients
```

### 2. Add missing schema columns

**Drift (Flutter)** — Update `products.dart` and `clients.dart` tables to add the new nullable columns (costPrice, unit, sku for Products; email, address for Clients).

**Serverpod models** — Update `product.spy.yaml` and `client_record.spy.yaml` to add matching fields.

### 3. Regenerate code

```bash
# Flutter (Drift)
cd motaz_app/motaz_app_flutter
dart run build_runner build --delete-conflicting-outputs

# Serverpod
cd motaz_app/motaz_app_server
serverpod generate
serverpod create-migration
```

### 4. Run tests

```bash
cd motaz_app/motaz_app_flutter
flutter test
```

### 5. Run the app

```bash
cd motaz_app/motaz_app_flutter
flutter run
```

---

## Key File Locations

| File | Purpose |
|---|---|
| `lib/features/products/data/product_repository.dart` | Product CRUD + search queries |
| `lib/features/products/application/product_providers.dart` | Riverpod state providers |
| `lib/features/products/presentation/product_list_screen.dart` | Product list + search UI |
| `lib/features/products/presentation/product_form_screen.dart` | Add/Edit product form |
| `lib/features/clients/data/client_repository.dart` | Client CRUD + search queries |
| `lib/features/clients/application/client_providers.dart` | Riverpod state providers |
| `lib/features/clients/presentation/client_list_screen.dart` | Client list + search UI |
| `lib/features/clients/presentation/client_form_screen.dart` | Add/Edit client form |
| `lib/features/clients/presentation/client_summary_screen.dart` | Client detail + balance |

---

## Architecture Pattern

```
User taps Save
    ↓
FormScreen validates locally
    ↓
Provider calls Repository.create() / .update()
    ↓
Repository runs Drift transaction:
    1. Insert/Update entity row
    2. Insert SyncOutbox entry
    ↓
Provider refreshes list stream
    ↓
ListScreen auto-updates via Drift .watch()
    ↓
SyncCoordinator picks up outbox entry on next cycle
```
