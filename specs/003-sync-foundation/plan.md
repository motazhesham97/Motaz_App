# Implementation Plan: Sync Foundation

**Branch**: `003-sync-foundation` | **Date**: 2026-04-04 | **Spec**: [spec.md](spec.md)  
**Input**: Feature specification from `/specs/003-sync-foundation/spec.md`

---

## Summary

Build the two-way sync engine connecting the Flutter offline-first app to the Serverpod cloud backend. This includes push (outbox → server), pull (server → local), conflict detection (row version mismatch with auto-merge/conflict-required field classification), void-wins enforcement, connectivity-triggered sync cycles, retry/backoff, staged attachment upload, sync status UI, and conflict resolution UI.

---

## Technical Context

**Language/Version**: Dart 3.x (Flutter 3.x + Serverpod latest)  
**Primary Dependencies**: Drift (local DB), Serverpod (backend endpoints + ORM), flutter_riverpod (state), connectivity_plus (network detection), cloudinary_dart or HTTP (uploads)  
**Storage**: SQLite (Drift) local, PostgreSQL (Neon) cloud, Cloudinary (attachments)  
**Testing**: flutter_test (unit), integration_test, dart test (server), mockito/mocktail (mocking)  
**Target Platform**: Android + Windows (offline-first)  
**Project Type**: Mobile+Desktop app with backend  
**Performance Goals**: Sync cycle < 30s for normal loads; 500+ entry backlog pushed in single session  
**Constraints**: Offline-capable, single owner, 2 devices, no real-time push notifications  
**Scale/Scope**: 2 devices (MVP), ~14 entity types to sync, ~6 Serverpod endpoints

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Constitution Rule | Compliance | Evidence |
|---|---|---|
| Offline-first: local save first, sync later | ✅ | Outbox pattern: all mutations save locally first, push when online |
| Financial records: no hard delete | ✅ | Void semantics preserved through sync — void-wins rule |
| Financial conflicts: no silent merge | ✅ | Conflict-required field list enforced server-side; ConflictLog created |
| Void-wins over edit | ✅ | Server-side void-wins check in push logic (FR-009) |
| Attachments: server-approved upload only | ✅ | Three-step flow: approval → signed URL → confirm |
| Attachments preserved on void | ✅ | Upload still proceeds for voided records (FR-018) |
| Client never writes directly to cloud DB | ✅ | All writes go through Serverpod endpoints |
| All synced operations authenticated | ✅ | Every endpoint requires owner session |
| Server validates identity, row version, conflict rules | ✅ | SyncService enforces all three on every push |
| Devices identifiable | ✅ | DeviceEndpoint registration, device ID on every push |
| Single owner in MVP | ✅ | Auth required; no multi-user logic |
| No hard delete | ✅ | Void semantics only; no DELETE operations in sync |

**Gate result**: ✅ PASS — no violations.

---

## Project Structure

### Documentation (this feature)

```text
specs/003-sync-foundation/
├── spec.md              # Feature specification
├── plan.md              # This file
├── research.md          # Phase 0: technical decisions
├── data-model.md        # Phase 1: data model + payload schemas
├── quickstart.md        # Phase 1: build & run guide
├── contracts/
│   └── endpoints.md     # Phase 1: Serverpod endpoint contracts
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
```

### Source Code (repository root)

```text
motaz_app_server/lib/src/
├── endpoints/
│   ├── device_endpoint.dart       # [NEW] Device registration
│   ├── sync_endpoint.dart         # [NEW] Push, pull, conflict resolution
│   └── attachment_endpoint.dart   # [NEW] Upload approval + confirmation
├── services/
│   ├── sync_service.dart          # [NEW] Row version check, conflict detection, auto-merge, void-wins
│   └── attachment_service.dart    # [NEW] Cloudinary integration, upload policy
└── models/
    ├── push_request.spy.yaml      # [NEW] Push endpoint payload model
    ├── push_response.spy.yaml     # [NEW] Push endpoint response model
    ├── pull_request.spy.yaml      # [NEW] Pull endpoint payload model
    ├── pull_response.spy.yaml     # [NEW] Pull endpoint response model
    ├── conflict_payload.spy.yaml  # [NEW] Conflict data nested model
    ├── conflict_resolution_request.spy.yaml  # [NEW]
    ├── conflict_resolution_response.spy.yaml # [NEW]
    ├── device_registration_request.spy.yaml  # [NEW]
    ├── device_registration_response.spy.yaml # [NEW]
    ├── attachment_upload_request.spy.yaml     # [NEW]
    ├── attachment_upload_approval.spy.yaml    # [NEW]
    ├── attachment_confirm_request.spy.yaml    # [NEW]
    └── attachment_confirm_response.spy.yaml   # [NEW]

motaz_app_flutter/lib/
├── features/
│   └── sync/
│       ├── application/
│       │   ├── sync_coordinator.dart       # [NEW] Main orchestrator
│       │   ├── outbox_processor.dart        # [NEW] Push cycle logic
│       │   ├── pull_processor.dart          # [NEW] Pull cycle logic
│       │   ├── attachment_uploader.dart     # [NEW] Staged attachment upload
│       │   └── sync_providers.dart          # [NEW] Riverpod providers
│       ├── domain/
│       │   ├── sync_state.dart              # [NEW] SyncState + SyncPhase models
│       │   └── field_classifier.dart        # [NEW] Auto-merge vs conflict-required classification
│       └── presentation/
│           ├── sync_status_badge.dart       # [NEW] App bar sync indicator widget
│           └── conflict_resolution_screen.dart # [NEW] Side-by-side conflict viewer
└── core/
    └── connectivity/
        └── connectivity_provider.dart  # [EXISTING] Already provides online/offline stream

motaz_app_server/test/
└── sync/
    ├── sync_service_test.dart           # [NEW] Unit tests for conflict logic
    ├── push_endpoint_test.dart          # [NEW] Push endpoint integration tests
    └── pull_endpoint_test.dart          # [NEW] Pull endpoint integration tests

motaz_app_flutter/test/
└── features/sync/
    ├── sync_coordinator_test.dart       # [NEW] Coordinator state machine tests
    ├── outbox_processor_test.dart       # [NEW] Push cycle unit tests
    ├── pull_processor_test.dart         # [NEW] Pull cycle unit tests
    └── field_classifier_test.dart       # [NEW] Auto-merge/conflict classification tests
```

**Structure Decision**: Feature-First Modular Monolith. The sync feature lives at `features/sync/` with application/domain/presentation layers. Server-side follows Serverpod's standard endpoints/services pattern.

---

## Implementation Tracks

### Track A: Server — Endpoints & Services

| Step | Deliverable | Dependencies |
|------|-------------|--------------|
| A1 | Serverpod payload models (13 `.spy.yaml` files) | Phase 2 models |
| A2 | `DeviceEndpoint.registerDevice` | A1 |
| A3 | `SyncService` — row version check, auto-merge logic, conflict-required classification, void-wins | A1 |
| A4 | `SyncEndpoint.push` | A2, A3 |
| A5 | `SyncEndpoint.pull` — cursor-based query, pagination, conflict delivery | A3 |
| A6 | `SyncEndpoint.resolveConflict` | A3 |
| A7 | `AttachmentService` — Cloudinary signed URL generation, upload policy | A1 |
| A8 | `AttachmentEndpoint.requestUploadApproval` + `confirmUpload` | A7 |
| A9 | Server-side unit/integration tests for push, pull, conflict, void-wins, auto-merge | A4, A5, A6 |

### Track B: Flutter — Sync Engine

| Step | Deliverable | Dependencies |
|------|-------------|--------------|
| B1 | `SyncState`, `SyncPhase` domain models | — |
| B2 | `FieldClassifier` — auto-merge vs conflict-required field lists | — |
| B3 | `OutboxProcessor` — read PENDING entries, call push endpoint, update status, handle retry/backoff | A4 |
| B4 | `PullProcessor` — call pull endpoint, upsert rows locally, update sync cursors, store conflicts | A5 |
| B5 | `SyncCoordinator` — push-then-pull cycle, mutex, connectivity trigger, periodic timer, manual trigger | B3, B4 |
| B6 | `SyncProviders` — Riverpod providers for coordinator, state stream, pending count | B5 |
| B7 | `AttachmentUploader` — process LocalAttachmentStaging entries, 3-step upload flow | A8, B5 |
| B8 | Client-side unit tests — coordinator, outbox processor, pull processor, field classifier | B5, B6, B7 |

### Track C: Flutter — UI

| Step | Deliverable | Dependencies |
|------|-------------|--------------|
| C1 | `SyncStatusBadge` — app bar widget showing pending count, synced indicator, conflict count, progress, error | B6 |
| C2 | `ConflictResolutionScreen` — list of pending conflicts, side-by-side viewer, choose local/remote, confirm | A6, B6 |
| C3 | Integration of badge into app shell (router/scaffold) | C1 |
| C4 | UI testing — badge states, conflict resolution flow | C1, C2, C3 |

---

## Dependency Graph

```
Phase 2 (complete)
    │
    ├── Track A (Server)
    │   ├── A1 → A2 → A4 ──→ A9
    │   │         │            ↑
    │   │         ├── A3 ──→ A4, A5, A6
    │   │         │           ↑
    │   │         └── A7 → A8
    │   │
    │   └── A5, A6 ──→ A9
    │
    └── Track B (Flutter)          Track C (UI)
        ├── B1, B2                 ┌── C1 ← B6
        │                         │
        ├── B3 ← A4               ├── C2 ← A6, B6
        ├── B4 ← A5               │
        ├── B5 ← B3, B4           ├── C3 ← C1
        ├── B6 ← B5               │
        ├── B7 ← A8, B5           └── C4 ← C1, C2, C3
        └── B8 ← B5, B6, B7
```

---

## Verification Plan

### Automated Tests

1. **Server — SyncService unit tests**: Row version match/mismatch, auto-merge on allowed fields, conflict emit on financial fields, void-wins enforcement.
2. **Server — Endpoint integration tests**: Push valid mutation, push conflict, push void-wins scenario, pull with pagination, resolve conflict.
3. **Client — OutboxProcessor tests**: Process entry, handle success, handle transient failure + retry, handle permanent failure, chronological ordering.
4. **Client — PullProcessor tests**: Insert new row, update existing row, apply void, update cursor.
5. **Client — SyncCoordinator tests**: Push-then-pull ordering, mutex (no concurrent cycles), connectivity trigger, periodic timer, manual trigger.
6. **Client — FieldClassifier tests**: Each entity's fields correctly classified.
7. **Client — SyncStatusBadge tests**: Renders correct state for idle, syncing, error, pending count, conflict count.

### Manual Verification

1. **Two-device round-trip**: Create invoice on Device A offline → sync → verify on Device B.
2. **Conflict flow**: Edit same invoice amount on both devices → sync → verify conflict created → resolve → verify resolved.
3. **Void-wins**: Void on Device A, edit on Device B → sync → verify void wins.
4. **Offline backlog**: Create 20+ entries offline → connect → verify all push successfully.
5. **Attachment staging**: Attach photo offline → connect → verify uploaded to Cloudinary.
6. **Badge accuracy**: Verify badge shows correct pending count, then clears after sync.

---

## Complexity Tracking

No constitution violations. No complexity justifications needed.
