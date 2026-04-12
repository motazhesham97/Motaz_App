# Implementation Plan: Expenses & Monthly Profit Distribution

**Branch**: `006-expenses-profit` | **Date**: 2026-04-07 | **Spec**: [spec.md](spec.md)  
**Input**: Feature specification from `/specs/006-expenses-profit/spec.md`

---

## Summary

Build the periodic accounting engine — expense CRUD with five approved categories, monthly net profit calculation, three-way profit distribution with integer splitting, party balance computation (accumulation minus draws), and partial dashboard integration (5 cards). All operations are offline-first with atomic local transactions and sync outbox entries. This phase requires a new Drift table (`MonthlyDistributions`) and a new `MONTHLY_DISTRIBUTION` sync entity type. It consumes invoices and returns data from Phase 5 and Phase 7 (returns table exists but is empty until Phase 7). No other schema migration is needed — the Expenses table already exists from Phase 2.

---

## Technical Context

**Language/Version**: Dart 3.x (Flutter 3.x + Serverpod latest stable)  
**Primary Dependencies**: Drift (local DB queries), flutter_riverpod (state), go_router (navigation), uuid (ID generation)  
**Storage**: SQLite (Drift) local — Expenses table exists from Phase 2; MonthlyDistributions table must be added  
**Testing**: flutter_test (unit + widget), integration_test  
**Target Platform**: Android + Windows (offline-first)  
**Project Type**: Mobile+Desktop app with backend  
**Performance Goals**: Expense save < 1s; profit computation < 2s for 12 months; dashboard cards update < 1s  
**Constraints**: Offline-capable, single owner, Arabic RTL-first, minor-unit integer arithmetic, no double anywhere in money path  
**Scale/Scope**: ~14 new Dart files (table, repositories, profit engine, providers, screens) + 2 modifications (app_database.dart, parent_entity_type.dart) + 1 router update

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Constitution Rule | Compliance | Evidence |
|---|---|---|
| Offline-first: local save first, sync later | ✅ | All expense/distribution CRUD saves to SQLite first with outbox entry |
| Financial records: no hard delete | ✅ | Void/cancel semantics with voidReason; no DELETE on expenses or distributions |
| Financial conflicts: no silent merge | ✅ | FieldClassifier will mark all expense/distribution monetary fields as conflict-required |
| Void wins over edit | ✅ | FieldClassifier marks status and voidReason as conflict-required; sync engine handles |
| Monetary values as minor-unit integers | ✅ | All amounts, shares, and profit stored as `int` — no `double` |
| 5 approved expense categories | ✅ | ExpenseCategory enum already exists with OWNER_DRAW, PARTNER_DRAW, MARGIN_DRAW, OPERATIONAL, PRODUCTION |
| Only OPERATIONAL + PRODUCTION in net profit | ✅ | Profit engine query filters by category |
| Profit split: trunc(n/3) with remainder to Margin | ✅ | ProfitEngine.distribute() uses integer truncation |
| Draws affect party balance only, not profit | ✅ | Party balance query sums draws; profit query excludes them |
| Monthly distribution only (other periods are views) | ✅ | MonthlyDistribution entity is per year-month; other periods are reporting |
| Negative balances allowed | ✅ | No floor constraint; computed balance can go negative |
| Distribution restricted to past months only | ✅ | ProfitEngine validates year-month < current month (per clarification) |
| Void requires reason and audit | ✅ | voidReason required; timestamps updated; outbox entry created |
| Arabic RTL layout | ✅ | All screens Arabic-first with RTL |
| Devices identifiable | ✅ | deviceId on every expense and distribution |

**Gate result**: ✅ PASS — no violations.

---

## Project Structure

### Documentation (this feature)

```text
specs/006-expenses-profit/
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
│   ├── database/
│   │   ├── app_database.dart                  # [MODIFY] Register MonthlyDistributions table, bump schema version
│   │   ├── tables/
│   │   │   └── monthly_distributions.dart     # [NEW] MonthlyDistributions table definition
│   │   └── enums/
│   │       └── parent_entity_type.dart        # [MODIFY] Add MONTHLY_DISTRIBUTION
│   └── router/
│       └── app_router.dart                    # [MODIFY] Replace expense/party-balance placeholders
├── features/
│   ├── expenses/
│   │   ├── data/
│   │   │   └── expense_repository.dart        # [NEW] CRUD + void + search
│   │   ├── application/
│   │   │   └── expense_providers.dart         # [NEW] Riverpod providers (list, search, repo)
│   │   └── presentation/
│   │       ├── expense_list_screen.dart        # [NEW] List with search + category filter
│   │       ├── expense_form_screen.dart        # [NEW] Create/edit form
│   │       └── placeholder_screen.dart         # [DELETE] Remove placeholder
│   ├── profit_distribution/
│   │   ├── data/
│   │   │   ├── profit_engine.dart             # [NEW] Monthly profit calc + distribution logic
│   │   │   └── distribution_repository.dart   # [NEW] CRUD + void for MonthlyDistribution
│   │   ├── application/
│   │   │   └── profit_providers.dart          # [NEW] Riverpod providers
│   │   └── presentation/
│   │       └── distribution_screen.dart       # [NEW] Month picker + distribute action + history
│   ├── party_balances/
│   │   ├── data/
│   │   │   └── party_balance_calculator.dart  # [NEW] Balance computation queries
│   │   ├── application/
│   │   │   └── party_balance_providers.dart   # [NEW] Riverpod providers
│   │   └── presentation/
│   │       ├── party_balances_screen.dart      # [NEW] Balance display for all 3 parties
│   │       └── placeholder_screen.dart         # [DELETE] Remove placeholder
│   └── dashboard/
│       ├── data/
│       │   └── dashboard_queries.dart         # [NEW] Dashboard card data queries
│       ├── application/
│       │   └── dashboard_providers.dart       # [NEW] Riverpod providers for dashboard cards
│       └── presentation/
│           ├── dashboard_screen.dart           # [NEW] 5 cards: net profit, 3 party balances, expense summary
│           └── placeholder_screen.dart         # [DELETE] Remove placeholder
```

**Structure Decision**: Feature-First Modular Monolith. Expenses, Profit Distribution, Party Balances, and Dashboard each get `data/`, `application/`, and `presentation/` layers inside `features/`. The ProfitEngine is a stateless helper inside `profit_distribution/data/` consumed by both the distribution repository and the dashboard queries.

---

## Complexity Tracking

No violations detected. No complexity justification needed.
