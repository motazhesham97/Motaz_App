# Implementation Plan: Products & Clients

**Branch**: `004-products-clients` | **Date**: 2026-04-05 | **Spec**: [spec.md](spec.md)  
**Input**: Feature specification from `/specs/004-products-clients/spec.md`

---

## Summary

Build the application layer and UI for Products and Clients — the two core reference data entities that are prerequisites for the Invoice and Receipt engine (Phase 5). This phase adds local repositories (Drift DAOs), Riverpod state management, form screens with validation, list screens with live search, and the full offline CRUD lifecycle (create, edit, disable, search) for both entities. Schema and sync infrastructure already exist from Phases 2 and 3.

---

## Technical Context

**Language/Version**: Dart 3.x (Flutter 3.x + Serverpod latest stable)  
**Primary Dependencies**: Drift (local DB queries), flutter_riverpod (state), go_router (navigation), uuid (ID generation)  
**Storage**: SQLite (Drift) local — using existing schema from Phase 2  
**Testing**: flutter_test (unit + widget), integration_test, mockito/mocktail  
**Target Platform**: Android + Windows (offline-first)  
**Project Type**: Mobile+Desktop app with backend  
**Performance Goals**: Product/Client save < 1s; local search < 500ms for 2000 records  
**Constraints**: Offline-capable, single owner, Arabic RTL-first  
**Scale/Scope**: ~10 new Dart files (repositories, providers, screens, widgets)

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Constitution Rule | Compliance | Evidence |
|---|---|---|
| Offline-first: local save first, sync later | ✅ | All CRUD saves to SQLite first, then outbox entry for sync |
| Product names must be unique | ✅ | Unique constraint on Drift table + local validation before save |
| Client names are NOT unique | ✅ | No unique constraint; identifying field required |
| Product deletion not allowed — disable only | ✅ | No delete operation; isActive toggle only |
| Financial records: no hard delete | ✅ | N/A for products/clients (not financial), but no delete exposed anyway |
| Financial conflicts: no silent merge | ✅ | product.name and product.defaultSalePrice are conflict-required fields |
| Client auto-merge fields | ✅ | displayName, phone, note, clientCode are auto-merge per FieldClassifier |
| Monetary values as minor-unit integers | ✅ | defaultSalePrice and costPrice stored as `int` (minor units) |
| Client must have identifying field | ✅ | App-level validation: at least one of phone/email/address/note/clientCode |
| Arabic RTL layout | ✅ | All screens use RTL-first layout |
| Devices identifiable | ✅ | deviceId attached to every mutation |

**Gate result**: ✅ PASS — no violations.

---

## Project Structure

### Documentation (this feature)

```text
specs/004-products-clients/
├── spec.md              # Feature specification
├── plan.md              # This file
├── research.md          # Phase 0: technical decisions
├── data-model.md        # Phase 1: data model + schema gap analysis
├── quickstart.md        # Phase 1: developer quickstart
├── contracts/           # Phase 1: no new endpoints needed
│   └── endpoints.md
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 output (via /speckit.tasks)
```

### Source Code (repository root)

```text
motaz_app_flutter/lib/
├── features/
│   ├── products/
│   │   ├── data/
│   │   │   └── product_repository.dart      # Drift DAO for CRUD + search
│   │   ├── application/
│   │   │   └── product_providers.dart        # Riverpod providers
│   │   └── presentation/
│   │       ├── product_list_screen.dart       # List + search + disable toggle
│   │       └── product_form_screen.dart       # Add/Edit form with validation
│   └── clients/
│       ├── data/
│       │   └── client_repository.dart        # Drift DAO for CRUD + search
│       ├── application/
│       │   └── client_providers.dart         # Riverpod providers
│       └── presentation/
│           ├── client_list_screen.dart        # List + search + duplicate-name UX
│           ├── client_form_screen.dart        # Add/Edit form with validation
│           └── client_summary_screen.dart     # Detail + balance + transactions
└── core/
    └── database/
        └── tables/
            ├── products.dart                 # [MODIFY] Add costPrice, unit, sku columns
            └── clients.dart                  # [MODIFY] Add email, address columns

motaz_app_server/lib/src/
└── models/
    ├── product.spy.yaml                      # [MODIFY] Add costPrice, unit, sku fields
    └── client_record.spy.yaml                # [MODIFY] Add email, address fields

motaz_app_flutter/test/
└── features/
    ├── products/
    │   ├── product_repository_test.dart
    │   └── product_providers_test.dart
    └── clients/
        ├── client_repository_test.dart
        └── client_providers_test.dart
```

**Structure Decision**: Feature-First Modular Monolith. Products and Clients each get `data/`, `application/`, and `presentation/` layers inside `features/`. Repositories wrap Drift queries. Providers expose reactive state. Screens consume providers.

---

## Complexity Tracking

No violations detected. No complexity justification needed.
