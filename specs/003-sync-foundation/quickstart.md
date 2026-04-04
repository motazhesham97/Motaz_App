# Quickstart: Sync Foundation

**Date**: 2026-04-04  
**Feature**: 003-sync-foundation

---

## Prerequisites

1. **Phase 1** complete: Flutter app shell, Serverpod project, auth, connectivity monitoring, Riverpod providers.
2. **Phase 2** complete: All 16 Drift tables, all Serverpod models, enums, migration v2 stable.
3. Serverpod dev server running locally (`cd motaz_app_server && dart bin/main.dart`).
4. `build_runner` and `serverpod generate` both pass cleanly.

---

## Key Files to Create

### Server Side (`motaz_app_server/lib/src/`)

| File | Purpose |
|------|---------|
| `endpoints/device_endpoint.dart` | Device registration endpoint |
| `endpoints/sync_endpoint.dart` | Push, pull, conflict resolution endpoints |
| `endpoints/attachment_endpoint.dart` | Upload approval and confirmation endpoints |
| `services/sync_service.dart` | Server-side sync logic: row version checks, conflict detection, auto-merge, void-wins |
| `services/attachment_service.dart` | Cloudinary integration, upload approval, metadata storage |

### Flutter Side (`motaz_app_flutter/lib/`)

| File | Purpose |
|------|---------|
| `features/sync/application/sync_coordinator.dart` | Main sync orchestrator: push-pull cycle, mutex, retry logic |
| `features/sync/application/outbox_processor.dart` | Processes outbox entries, calls push endpoint |
| `features/sync/application/pull_processor.dart` | Calls pull endpoint, applies remote changes locally |
| `features/sync/application/attachment_uploader.dart` | Processes staged attachments, upload flow |
| `features/sync/application/sync_providers.dart` | Riverpod providers for sync coordinator, state, triggers |
| `features/sync/domain/sync_state.dart` | SyncState, SyncPhase models |
| `features/sync/domain/sync_models.dart` | PushRequest/Response, PullRequest/Response payload models |
| `features/sync/presentation/sync_status_badge.dart` | App bar badge widget showing sync status |
| `features/sync/presentation/conflict_resolution_screen.dart` | Side-by-side conflict viewer |

---

## Build & Test Commands

```bash
# Generate Serverpod protocol classes after adding endpoint models
cd motaz_app_server && serverpod generate

# Generate Drift code (if any schema changes needed)
cd motaz_app_flutter && dart run build_runner build --delete-conflicting-outputs

# Run sync unit tests
cd motaz_app_flutter && flutter test test/features/sync/

# Run server integration tests
cd motaz_app_server && dart test test/sync/

# Start dev server
cd motaz_app_server && dart bin/main.dart
```

---

## Implementation Order

1. **Server endpoints** (DeviceEndpoint, SyncEndpoint.push, SyncEndpoint.pull) — foundation for all client work
2. **SyncService** (server-side business logic) — conflict detection, auto-merge, void-wins
3. **Outbox processor** (client-side) — push cycle
4. **Pull processor** (client-side) — pull cycle
5. **SyncCoordinator** (client-side) — ties push+pull together with connectivity trigger and mutex
6. **Sync status badge** (UI) — visual indicator
7. **Conflict resolution** (server endpoint + client UI) — resolution flow
8. **Attachment upload** (server + client) — staged upload pipeline
9. **Integration tests** — full end-to-end sync round-trip
