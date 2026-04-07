# Implementation Plan: Invoices & Receipts

**Branch**: `005-invoices-receipts` | **Date**: 2026-04-07 | **Spec**: [spec.md](spec.md)  
**Input**: Feature specification from `/specs/005-invoices-receipts/spec.md`

---

## Summary

Build the core commercial transaction engine — sales invoices with line items and editing constraints, invoice-linked and general receipts with FIFO allocation, void flows with reallocation, and client-facing list/detail/form screens. All operations are offline-first with atomic local transactions and sync outbox entries. This phase consumes Products (autocomplete) and Clients (selection) from Phase 4 and the sync infrastructure from Phase 3. No schema migration is needed — all tables exist from Phase 2.

---

## Technical Context

**Language/Version**: Dart 3.x (Flutter 3.x + Serverpod latest stable)  
**Primary Dependencies**: Drift (local DB queries), flutter_riverpod (state), go_router (navigation), uuid (ID generation)  
**Storage**: SQLite (Drift) local — using existing schema from Phase 2  
**Testing**: flutter_test (unit + widget), integration_test  
**Target Platform**: Android + Windows (offline-first)  
**Project Type**: Mobile+Desktop app with backend  
**Performance Goals**: Invoice save < 2s with 20 lines; search < 1s for 500+ invoices  
**Constraints**: Offline-capable, single owner, Arabic RTL-first, minor-unit integer arithmetic  
**Scale/Scope**: ~11 new Dart files (repositories, allocator, providers, screens) + 1 router update

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Constitution Rule | Compliance | Evidence |
|---|---|---|
| Offline-first: local save first, sync later | ✅ | All CRUD saves to SQLite first with outbox entry |
| Financial records: no hard delete | ✅ | Void/cancel semantics with voidReason; no DELETE |
| Every invoice must have exactly one client | ✅ | clientId is FK NOT NULL; form validates client selection |
| Financial conflicts: no silent merge | ✅ | FieldClassifier already marks all invoice/receipt monetary fields as conflict-required |
| Void wins over edit | ✅ | FieldClassifier marks status and voidReason as conflict-required; sync engine handles |
| Attachments preserved on void | ✅ | Void only changes status/voidReason; no attachment deletion |
| Monetary values as minor-unit integers | ✅ | All totals, prices, discounts, amounts stored as `int` |
| Invoice numbering non-authoritative | ✅ | localRef (`INV-<deviceCode>-<seq>`) generated offline per device |
| Receipt types: invoice-linked and general | ✅ | ReceiptType enum: INVOICE_LINKED, GENERAL |
| General receipts: FIFO allocation | ✅ | ReceiptAllocator uses invoiceDate ASC ordering |
| FIFO allocations stored explicitly | ✅ | ReceiptAllocation table with explicit records |
| Invoice edit: receipt-constrained and return-locked | ✅ | Three-state edit detection: unrestricted, total≥collected, note-only |
| Receipts on voided invoice: realloc or credit | ✅ | Freed amounts re-allocated via FIFO; if no other invoices, becomes client credit |
| Void requires reason and audit | ✅ | voidReason required (app validation); timestamps updated; outbox entry created |
| Arabic RTL layout | ✅ | All screens Arabic-first |
| Devices identifiable | ✅ | deviceId on every invoice and receipt |

**Gate result**: ✅ PASS — no violations.

---

## Project Structure

### Documentation (this feature)

```text
specs/005-invoices-receipts/
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
├── features/
│   ├── invoices/
│   │   ├── data/
│   │   │   └── invoice_repository.dart       # CRUD + void + localRef + edit state
│   │   ├── application/
│   │   │   └── invoice_providers.dart        # Riverpod providers (list, search, detail)
│   │   └── presentation/
│   │       ├── invoice_list_screen.dart       # List with search + status filter
│   │       ├── invoice_form_screen.dart       # Create/edit with line builder
│   │       └── invoice_detail_screen.dart     # Full detail + payments + void action
│   └── receipts/
│       ├── data/
│       │   ├── receipt_repository.dart        # Create linked/general + void
│       │   └── receipt_allocator.dart         # FIFO allocation engine
│       ├── application/
│       │   └── receipt_providers.dart         # Riverpod providers (list, search)
│       └── presentation/
│           ├── receipt_list_screen.dart        # List with search
│           └── receipt_form_screen.dart        # Create linked/general receipt form
└── core/
    └── router/
        └── app_router.dart                   # [MODIFY] Replace placeholder screens
```

**Structure Decision**: Feature-First Modular Monolith. Invoices and Receipts each get `data/`, `application/`, and `presentation/` layers inside `features/`. The FIFO allocator is a separate helper file in the receipts data layer since it's consumed by both the receipt repository and the invoice repository (for reallocation on invoice void).

---

## Complexity Tracking

No violations detected. No complexity justification needed.
