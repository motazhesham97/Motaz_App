# Implementation Plan: Partial Returns & Reversals

**Branch**: `007-partial-returns-reversals` | **Date**: 2026-04-12 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/007-partial-returns-reversals/spec.md`

---

## Summary

Build the partial return and reversal engine — return creation against invoices with per-line quantity/amount validation, auto-fill with manual override, compute-on-read balance adjustments (invoice remaining balance, client credit), return voiding with full accounting reversal, invoice edit restriction enforcement, and a returns list screen. All operations are offline-first with atomic local transactions and sync outbox entries. No new schema migration is needed — the `SalesReturns` and `SalesReturnLines` tables already exist from Phase 2, and `SALES_RETURN` / `SALES_RETURN_LINE` enum values already exist in `ParentEntityType`. This phase modifies the existing invoice editing logic to enforce financial-edit restrictions when active returns exist.

---

## Technical Context

**Language/Version**: Dart 3.x (Flutter 3.x + Serverpod latest stable)  
**Primary Dependencies**: Drift (local DB queries), flutter_riverpod (state), go_router (navigation), uuid (ID generation)  
**Storage**: SQLite (Drift) local — SalesReturns and SalesReturnLines tables exist from Phase 2  
**Testing**: flutter_test (unit + widget), integration_test  
**Target Platform**: Android + Windows (offline-first)  
**Project Type**: Mobile+Desktop app with backend  
**Performance Goals**: Return save < 1s; balance update < 1s; list load < 1s  
**Constraints**: Offline-capable, single owner, Arabic RTL-first, minor-unit integer arithmetic, no double anywhere in money path  
**Scale/Scope**: ~7 new Dart files (repository, providers, screens) + ~2 modifications (invoice edit restrictions, router update) + 1 placeholder deletion

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Constitution Rule | Compliance | Evidence |
|---|---|---|
| Offline-first: local save first, sync later | ✅ | Return CRUD saves to SQLite first with outbox entry |
| Financial records: no hard delete | ✅ | Void/cancel semantics with voidReason; no DELETE on returns |
| Financial conflicts: no silent merge | ✅ | All return monetary fields marked conflict-required |
| Void wins over edit | ✅ | Constitution rule applies; return referencing voided invoice is handled |
| Monetary values as minor-unit integers | ✅ | All amounts stored as `int` — no `double` |
| Partial returns are financial returns | ✅ | Return reduces outstanding balance or creates credit |
| Return reduces outstanding if unpaid, creates credit if fully paid | ✅ | Remaining balance formula: `total − receipts − activeReturns` |
| Return voiding requires reason and reversal | ✅ | voidReason required; balance recomputed on-read (voided returns excluded) |
| Invoice edit restricted after return | ✅ | Active returns block financial field edits; voided returns do not restrict |
| Cash refund out of scope | ✅ | Credit tracked only; no refund workflow |
| Void requires reason and audit | ✅ | voidReason required; timestamps updated; outbox entry created |
| Arabic RTL layout | ✅ | All screens Arabic-first with RTL |
| Devices identifiable | ✅ | deviceId on every return record |

**Gate result**: ✅ PASS — no violations.

---

## Project Structure

### Documentation (this feature)

```text
specs/007-partial-returns-reversals/
├── spec.md              # Feature specification
├── plan.md              # This file
├── research.md          # Phase 0: technical decisions
├── data-model.md        # Phase 1: data model + schema analysis
├── quickstart.md        # Phase 1: developer quickstart
├── contracts/
│   └── endpoints.md     # Phase 1: repository contracts
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 output (via /speckit.tasks)
```

### Source Code (repository root)

```text
motaz_app_flutter/lib/
├── core/
│   └── router/
│       └── app_router.dart                    # [MODIFY] Replace returns placeholder
├── features/
│   ├── returns/
│   │   ├── data/
│   │   │   └── return_repository.dart         # [NEW] Create, void, queries
│   │   ├── application/
│   │   │   └── return_providers.dart          # [NEW] Riverpod providers (list, repo)
│   │   └── presentation/
│   │       ├── return_list_screen.dart         # [NEW] Returns list with search
│   │       ├── return_form_screen.dart         # [NEW] Create return form
│   │       └── placeholder_screen.dart         # [DELETE] Remove placeholder
│   └── invoices/
│       ├── data/
│       │   └── invoice_repository.dart        # [MODIFY] Add hasActiveReturns check to edit flow
│       └── presentation/
│           ├── invoice_list_screen.dart        # [MODIFY] Add "إنشاء مرتجع" action
│           └── invoice_detail_screen.dart      # [MODIFY] Add "إنشاء مرتجع" action
├── shared/
│   └── widgets/
│       └── app_drawer.dart                    # [MODIFY] Add returns navigation entry
```

**Structure Decision**: Feature-First Modular Monolith. Returns get `data/`, `application/`, and `presentation/` layers inside `features/returns/`. The ReturnRepository handles all CRUD and validation. Balance computation is handled by existing compute-on-read queries that already factor in returns (verified in ProfitEngine from Phase 6). Invoice edit restrictions are added as a guard in the invoice editing flow.

---

## Complexity Tracking

No violations detected. No complexity justification needed.
