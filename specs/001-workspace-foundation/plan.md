# Implementation Plan: Workspace Foundation

**Branch**: `001-workspace-foundation` | **Date**: 2026-03-19 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/001-workspace-foundation/spec.md`

## Summary

Establish the complete project foundation for Motaz_App: a Serverpod backend connected to Neon PostgreSQL, a Flutter frontend with Arabic RTL and sidebar navigation, a Drift-managed local SQLite database with device identity, Serverpod email+password authentication with in-app registration, and continuous connectivity monitoring. This phase produces no business features — it delivers the shell, plumbing, and infrastructure that all subsequent phases depend on.

## Technical Context

**Language/Version**: Dart 3.x (Flutter SDK latest stable, Serverpod latest stable)
**Primary Dependencies**: Flutter, Serverpod, Drift, flutter_riverpod, connectivity_plus, go_router, flutter_localizations
**Storage**: SQLite (local via Drift), PostgreSQL on Neon (cloud via Serverpod ORM)
**Testing**: flutter_test, integration_test, serverpod_test_tools
**Target Platform**: Android (phone) + Windows (desktop)
**Project Type**: Mobile + desktop app with backend API
**Performance Goals**: App launch < 5 seconds, server response < 2 seconds, connectivity detection < 5 seconds
**Constraints**: Offline-first, Arabic RTL, single owner, MVP scope
**Scale/Scope**: 1 owner, 2 devices, ~10 navigation sections

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Rule | Status |
|------|------|--------|
| Offline-first | Every action must save locally first | ✅ DB bootstrap creates local storage before any network call |
| No hard delete | Financial records use void/cancel | ✅ N/A — no financial records in this phase |
| Arabic-first RTL | UI must support full RTL from day one | ✅ RTL baseline, Arabic localization, and Arabic font in Phase 1 |
| Single owner auth | All synced ops authenticated as owner | ✅ Serverpod email+password auth, single-account enforcement |
| Device identity | Devices must be identifiable | ✅ UUID device identity generated on first launch, persisted locally |
| Secure sync path | Client must not write directly to cloud DB | ✅ All server access through Serverpod endpoints only |
| Attachment storage | Files in Cloudinary, metadata in DB | ✅ N/A — no attachments in this phase |
| Money as minor-unit int | 2 decimal places, integer storage | ✅ N/A — no monetary fields in this phase |

All gates pass. No violations.

## Project Structure

### Documentation (this feature)

```text
specs/001-workspace-foundation/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── api-contracts.md
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
```

### Source Code (repository root)

```text
motaz_app_server/                    # Serverpod project (backend)
├── lib/
│   └── src/
│       ├── endpoints/               # Serverpod endpoints
│       │   ├── auth_endpoint.dart
│       │   └── health_endpoint.dart
│       └── generated/               # Serverpod generated code
├── config/
│   ├── development.yaml
│   ├── staging.yaml
│   └── production.yaml
├── migrations/                      # Serverpod ORM migrations
└── test/

motaz_app_client/                    # Serverpod client package (generated)

motaz_app_flutter/                   # Flutter frontend package (generated)

motaz_app/                           # Flutter app (main entry point)
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── database/                # Drift database setup
│   │   │   ├── app_database.dart
│   │   │   └── tables/
│   │   │       ├── devices.dart
│   │   │       └── sync_outbox.dart
│   │   ├── auth/                    # Auth state management
│   │   │   ├── auth_provider.dart
│   │   │   └── auth_state.dart
│   │   ├── connectivity/           # Connectivity monitoring
│   │   │   └── connectivity_provider.dart
│   │   ├── router/                 # go_router setup
│   │   │   └── app_router.dart
│   │   ├── theme/                  # Theme and RTL
│   │   │   └── app_theme.dart
│   │   └── l10n/                   # Localization (Arabic-first)
│   │       └── app_ar.arb
│   ├── features/
│   │   ├── auth/
│   │   │   └── presentation/
│   │   │       ├── registration_screen.dart
│   │   │       └── sign_in_screen.dart
│   │   ├── home/
│   │   │   └── presentation/
│   │   │       └── home_screen.dart
│   │   ├── products/               # Placeholder
│   │   ├── clients/                # Placeholder
│   │   ├── invoices/               # Placeholder
│   │   ├── receipts/               # Placeholder
│   │   ├── expenses/               # Placeholder
│   │   ├── returns/                # Placeholder
│   │   ├── reports/                # Placeholder
│   │   ├── dashboard/              # Placeholder
│   │   └── settings/
│   │       └── presentation/
│   │           └── settings_screen.dart
│   └── shared/
│       └── widgets/
│           ├── app_drawer.dart
│           └── connectivity_badge.dart
├── test/
│   ├── unit/
│   └── integration/
├── android/
└── windows/
```

**Structure Decision**: Serverpod creates a multi-package project (`motaz_app_server`, `motaz_app_client`, `motaz_app_flutter`, `motaz_app`). The Flutter app uses feature-first modular monolith inside `lib/features/`, with shared infrastructure in `lib/core/`. Placeholder directories are created for all future feature modules.

## Phase 0: Research

All technology decisions are already frozen in the constitution v1.3.0 and implementation plan v2. See [research.md](research.md) for the consolidated research findings.

## Phase 1: Design & Contracts

### Data Model

See [data-model.md](data-model.md) for the complete entity definitions for this phase.

### API Contracts

See [contracts/api-contracts.md](contracts/api-contracts.md) for the backend endpoint contracts.

### Quickstart

See [quickstart.md](quickstart.md) for environment setup and build instructions.

## Complexity Tracking

No constitution violations to justify. All gates pass cleanly.
