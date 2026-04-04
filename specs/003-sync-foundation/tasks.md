# Tasks: Sync Foundation

**Input**: Design documents from `/specs/003-sync-foundation/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/endpoints.md, quickstart.md

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US5)
- Include exact file paths in descriptions

## Path Conventions

- **Server**: `motaz_app_server/lib/src/`
- **Flutter**: `motaz_app_flutter/lib/`
- **Server tests**: `motaz_app_server/test/`
- **Flutter tests**: `motaz_app_flutter/test/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create the feature module structure and Serverpod payload models needed by all sync stories.

- [x] T001 Create sync feature directory structure: `motaz_app_flutter/lib/features/sync/application/`, `motaz_app_flutter/lib/features/sync/domain/`, `motaz_app_flutter/lib/features/sync/presentation/`
- [x] T002 Create server services directory: `motaz_app_server/lib/src/services/` (if not exists)
- [x] T003 [P] Create `push_request.spy.yaml` Serverpod model in `motaz_app_server/lib/src/models/push_request.spy.yaml` — fields: outboxId (String), entityType (String), entityId (String), operation (String), payload (String), rowVersion (int), deviceId (String)
- [x] T004 [P] Create `push_response.spy.yaml` Serverpod model in `motaz_app_server/lib/src/models/push_response.spy.yaml` — fields: success (bool), newRowVersion (int?), conflictId (String?), errorCode (String?), errorMessage (String?)
- [x] T005 [P] Create `pull_request.spy.yaml` Serverpod model in `motaz_app_server/lib/src/models/pull_request.spy.yaml` — fields: entityType (String), sinceRowVersion (int), deviceId (String), limit (int)
- [x] T006 [P] Create `pull_response.spy.yaml` Serverpod model in `motaz_app_server/lib/src/models/pull_response.spy.yaml` — fields: entityType (String), rows (List<String>), hasMore (bool), latestRowVersion (int)
- [x] T007 [P] Create `conflict_payload.spy.yaml` Serverpod model in `motaz_app_server/lib/src/models/conflict_payload.spy.yaml` — fields: entityType (String), entityId (String), localPayload (String), remotePayload (String), conflictType (String)
- [x] T008 [P] Create `conflict_resolution_request.spy.yaml` in `motaz_app_server/lib/src/models/conflict_resolution_request.spy.yaml` — fields: conflictId (String), chosenVersion (String)
- [x] T009 [P] Create `conflict_resolution_response.spy.yaml` in `motaz_app_server/lib/src/models/conflict_resolution_response.spy.yaml` — fields: success (bool), newRowVersion (int?), errorMessage (String?)
- [x] T010 [P] Create `device_registration_request.spy.yaml` in `motaz_app_server/lib/src/models/device_registration_request.spy.yaml` — fields: deviceId (String), deviceCode (String), platform (String), deviceName (String)
- [x] T011 [P] Create `device_registration_response.spy.yaml` in `motaz_app_server/lib/src/models/device_registration_response.spy.yaml` — fields: success (bool), errorMessage (String?)
- [x] T012 [P] Create `attachment_upload_request.spy.yaml` in `motaz_app_server/lib/src/models/attachment_upload_request.spy.yaml` — fields: parentEntityType (String), parentEntityId (String), fileType (String), fileSize (int)
- [x] T013 [P] Create `attachment_upload_approval.spy.yaml` in `motaz_app_server/lib/src/models/attachment_upload_approval.spy.yaml` — fields: approved (bool), uploadUrl (String?), uploadPreset (String?), rejectionReason (String?)
- [x] T014 [P] Create `attachment_confirm_request.spy.yaml` in `motaz_app_server/lib/src/models/attachment_confirm_request.spy.yaml` — fields: parentEntityType (String), parentEntityId (String), publicId (String), secureUrl (String), fileType (String), fileSize (int)
- [x] T015 [P] Create `attachment_confirm_response.spy.yaml` in `motaz_app_server/lib/src/models/attachment_confirm_response.spy.yaml` — fields: success (bool), attachmentMetadataId (String?), errorMessage (String?)
- [x] T016 Run `serverpod generate` in `motaz_app_server/` to generate protocol classes from all new `.spy.yaml` models
- [x] T017 [P] Create `SyncState` and `SyncPhase` domain models in `motaz_app_flutter/lib/features/sync/domain/sync_state.dart` — SyncPhase enum (idle, pushing, pulling, error), SyncState class (status, pendingCount, lastSyncedAt, errorMessage, unresolvedConflictCount)
- [x] T018 [P] Create `FieldClassifier` in `motaz_app_flutter/lib/features/sync/domain/field_classifier.dart` — static maps defining auto-merge fields and conflict-required fields per entity type, per data-model.md field classification tables

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Server-side sync service containing the core business logic that all push/pull operations depend on.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T019 Implement `SyncService` in `motaz_app_server/lib/src/services/sync_service.dart` — core methods: `validateDeviceIdentity(session, deviceId)`, `checkRowVersion(entityType, entityId, expectedVersion)`, `classifyChangedFields(entityType, localPayload, remotePayload)` returning auto-merge vs conflict-required classification
- [x] T020 Add void-wins detection to `SyncService` in `motaz_app_server/lib/src/services/sync_service.dart` — method: `applyVoidWinsRule(localStatus, remoteStatus)` returning whether void takes precedence per constitution
- [x] T021 Add auto-merge application logic to `SyncService` in `motaz_app_server/lib/src/services/sync_service.dart` — method: `applyAutoMerge(entityType, existingRow, incomingPayload)` that applies last-write-wins only for allowed fields, preserving conflict-required fields from the existing row
- [x] T022 Add conflict emission logic to `SyncService` in `motaz_app_server/lib/src/services/sync_service.dart` — method: `emitConflict(session, entityType, entityId, localPayload, remotePayload, conflictType, deviceId)` that creates a ConflictLog record and returns the conflict UUID
- [x] T023 Add row version incrementing to `SyncService` in `motaz_app_server/lib/src/services/sync_service.dart` — method: `acceptMutation(session, entityType, entityId, payload, operation, deviceId)` that writes the entity, increments row version, writes AuditEvent, and returns the new row version
- [x] T024 Implement `AttachmentService` in `motaz_app_server/lib/src/services/attachment_service.dart` — methods: `validateUploadRequest(parentEntityType, parentEntityId, fileType, fileSize)`, `generateSignedUploadUrl(parentEntityType, parentEntityId)` returning upload URL and preset, `confirmUpload(parentEntityType, parentEntityId, publicId, secureUrl, fileType, fileSize)` creating AttachmentMetadata record

**Checkpoint**: Server-side business logic ready — endpoint and client implementation can now begin.

---

## Phase 3: User Story 5 — Device Registration (Priority: P1) 🎯

**Goal**: Devices register with the server on first sync after sign-in so every mutation is traceable.

**Independent Test**: Sign in on a fresh device, trigger sync, verify device record exists on the server.

### Implementation for User Story 5

- [x] T025 [US5] Implement `DeviceEndpoint.registerDevice` in `motaz_app_server/lib/src/endpoints/device_endpoint.dart` — validate session, upsert device record by deviceId (insert if new, update lastActiveAt if existing), return DeviceRegistrationResponse
- [x] T026 [US5] Implement device registration call in `motaz_app_flutter/lib/features/sync/application/sync_coordinator.dart` — on first sync cycle, call DeviceEndpoint.registerDevice with local device identity from DeviceService before starting push/pull

**Checkpoint**: Device registration working end-to-end.

---

## Phase 4: User Story 1 — Push Local Changes (Priority: P1) 🎯 MVP

**Goal**: Outbox entries are pushed to the server in chronological order, with server-side validation and row version assignment.

**Independent Test**: Create an invoice offline, connect, verify it appears on the server with correct row version after sync.

### Implementation for User Story 1

- [x] T027 [US1] Implement `SyncEndpoint.push` in `motaz_app_server/lib/src/endpoints/sync_endpoint.dart` — accept PushRequest, call SyncService for idempotency check, row version validation, field classification, void-wins check, auto-merge or conflict emission, return PushResponse
- [x] T028 [US1] Implement `OutboxProcessor` in `motaz_app_flutter/lib/features/sync/application/outbox_processor.dart` — query SyncOutbox for PENDING entries ordered by createdAt ASC, for each: set status to IN_PROGRESS, call SyncEndpoint.push, on success: set to COMPLETED and update entity syncStatus to SYNCED, on conflict: set to COMPLETED and update entity syncStatus to CONFLICT, on retryable failure: increment retryCount and set back to PENDING, on permanent failure: set to FAILED
- [x] T029 [US1] Add exponential backoff logic to `OutboxProcessor` in `motaz_app_flutter/lib/features/sync/application/outbox_processor.dart` — compute delay as 2^retryCount seconds with ±20% jitter, cap at 32 seconds, skip entries whose next retry time has not elapsed, immediately mark FAILED on non-retryable errors (4xx except 408/429), max retry count = 5

**Checkpoint**: Push cycle working — local mutations reach server.

---

## Phase 5: User Story 2 — Pull Remote Changes (Priority: P1)

**Goal**: Remote changes are pulled from the server using cursor-based pagination and applied locally.

**Independent Test**: Create a product on Device A, sync, then trigger pull on Device B and verify the product appears.

### Implementation for User Story 2

- [x] T030 [US2] Implement `SyncEndpoint.pull` in `motaz_app_server/lib/src/endpoints/sync_endpoint.dart` — accept PullRequest, query entity table for rows with rowVersion > sinceRowVersion ordered by rowVersion ASC limited to PullRequest.limit, query ConflictLog for PENDING conflicts for this deviceId and entityType, return PullResponse with rows + conflicts + hasMore + latestRowVersion
- [x] T031 [US2] Implement `PullProcessor` in `motaz_app_flutter/lib/features/sync/application/pull_processor.dart` — for each entity type in ParentEntityType: call SyncEndpoint.pull with current cursor position, for each returned row: upsert into local Drift table (insert or update based on existence), for each returned conflict: insert into local ConflictLog table, continue pulling while hasMore is true, update SyncCursor with latestRowVersion after all pages processed

**Checkpoint**: Pull cycle working — remote changes appear locally.

---

## Phase 6: User Story 3 — Conflict Detection (Priority: P1)

**Goal**: Row version conflicts on financial fields are detected, recorded as ConflictLog entries, and local entities are marked with conflict indicator.

**Independent Test**: Edit same invoice amount on two offline devices, sync both, verify ConflictLog record created.

### Implementation for User Story 3

- [ ] T032 [US3] Wire conflict emission into `SyncEndpoint.push` in `motaz_app_server/lib/src/endpoints/sync_endpoint.dart` — when SyncService.classifyChangedFields returns conflict-required fields changed AND row version mismatch, call SyncService.emitConflict and return PushResponse with conflictId
- [ ] T033 [US3] Handle conflict responses in `OutboxProcessor` in `motaz_app_flutter/lib/features/sync/application/outbox_processor.dart` — when PushResponse.conflictId is not null: update local entity's syncStatus to CONFLICT, mark outbox entry as COMPLETED (mutation was processed even though conflicted)
- [ ] T034 [US3] Handle pulled conflicts in `PullProcessor` in `motaz_app_flutter/lib/features/sync/application/pull_processor.dart` — when PullResponse.conflicts is not empty: insert each ConflictPayload as a ConflictLog record locally, update the local entity's syncStatus to CONFLICT and mark it with a conflict badge flag (FR-024)

**Checkpoint**: Conflicts detected and recorded end-to-end.

---

## Phase 7: User Story 4 — Auto-Merge Safe Fields (Priority: P1)

**Goal**: Non-financial field updates (notes, display names, phone numbers, descriptions) merge silently via last-write-wins.

**Independent Test**: Change client phone on Device A and client note on Device B, sync both, verify both changes merged without conflict.

### Implementation for User Story 4

- [ ] T035 [US4] Wire auto-merge path into `SyncEndpoint.push` in `motaz_app_server/lib/src/endpoints/sync_endpoint.dart` — when SyncService.classifyChangedFields returns ONLY auto-merge fields changed (no conflict-required fields): call SyncService.applyAutoMerge and return PushResponse with success=true and newRowVersion, NO ConflictLog created
- [ ] T036 [US4] Add unit tests for FieldClassifier in `motaz_app_flutter/test/features/sync/field_classifier_test.dart` — verify every entity type's fields are correctly categorized per data-model.md field classification tables (auto-merge list and conflict-required list), verify product.name is conflict-required, verify invoice.note is auto-merge, etc.

**Checkpoint**: Auto-merge working for safe fields; conflicts only on financial fields.

---

## Phase 8: User Story 6 — Connectivity-Triggered Sync (Priority: P2)

**Goal**: Sync cycles start automatically on connectivity restore, run periodically, and can be triggered manually.

**Independent Test**: Toggle airplane mode, verify sync starts within 5 seconds. Verify manual "Sync Now" works.

### Implementation for User Story 6

- [ ] T037 [US6] Implement `SyncCoordinator` in `motaz_app_flutter/lib/features/sync/application/sync_coordinator.dart` — state machine with SyncPhase (idle/pushing/pulling/error), mutex to prevent concurrent cycles, `runSyncCycle()` method that executes push-then-pull in order, exposes SyncState reactive stream
- [ ] T038 [US6] Add connectivity trigger to `SyncCoordinator` — listen to `connectivityProvider` stream from `motaz_app_flutter/lib/core/connectivity/connectivity_provider.dart`, on transition from offline to online: schedule sync cycle after 5-second debounce, on online idle: schedule periodic sync every 5 minutes via Timer.periodic
- [ ] T039 [US6] Add manual sync trigger to `SyncCoordinator` — public `syncNow()` method: if already syncing, ignore; if offline, throw/return error with "No internet" message; if idle and online, start immediate cycle
- [ ] T040 [US6] Create `SyncProviders` in `motaz_app_flutter/lib/features/sync/application/sync_providers.dart` — Riverpod providers: `syncCoordinatorProvider` (creates SyncCoordinator with DB, server client, connectivity), `syncStateProvider` (streams SyncState from coordinator), `pendingCountProvider` (watches SyncOutbox PENDING count), `unresolvedConflictCountProvider` (watches ConflictLog PENDING count)

**Checkpoint**: Sync runs automatically on connectivity change and on schedule.

---

## Phase 9: User Story 7 — Sync Status Visibility (Priority: P2)

**Goal**: App bar badge shows pending count, sync progress, error state, and unresolved conflict count.

**Independent Test**: Create invoices offline, verify badge shows correct count. Sync and verify badge clears to "Synced".

### Implementation for User Story 7

- [ ] T041 [US7] Create `SyncStatusBadge` widget in `motaz_app_flutter/lib/features/sync/presentation/sync_status_badge.dart` — consumes `syncStateProvider`, renders: idle + zero pending → checkmark with "last synced at X" tooltip, idle + pending > 0 → number badge with pending count, pushing/pulling → spinner/progress indicator, error → error icon with "Retry" tap action calling syncNow(), conflicts > 0 → warning icon with conflict count badge
- [ ] T042 [US7] Integrate `SyncStatusBadge` into app shell scaffold/app bar in `motaz_app_flutter/lib/core/router/` or `motaz_app_flutter/lib/features/home/presentation/` — place badge in the app bar actions area, visible on all primary screens

**Checkpoint**: Sync status visible at a glance from any screen.

---

## Phase 10: User Story 8 — Retry and Backoff (Priority: P2)

**Goal**: Failed sync operations retry automatically with exponential backoff; permanently failed entries show in UI for manual retry.

**Independent Test**: Push while server unreachable, verify retries with increasing delay, restore server, verify entry eventually pushes.

### Implementation for User Story 8

- [ ] T043 [US8] Add manual retry for FAILED entries to `OutboxProcessor` — public `retryFailed()` method: query SyncOutbox for FAILED entries, reset retryCount to 0 and status to PENDING, triggering normal push cycle processing
- [ ] T044 [US8] Wire retry action from `SyncStatusBadge` — when badge shows error state and user taps "Retry", call `syncCoordinatorProvider.syncNow()` which internally calls outboxProcessor.retryFailed() then starts a fresh cycle

**Checkpoint**: Retry logic working — transient failures auto-recover, permanent failures surfaced for manual retry.

---

## Phase 11: User Story 9 — Staged Attachment Sync (Priority: P2)

**Goal**: Attachments added offline upload to Cloudinary through the server-approved flow when connectivity returns.

**Independent Test**: Attach photo to invoice offline. Connect. Verify photo uploaded to Cloudinary and metadata stored.

### Implementation for User Story 9

- [ ] T045 [US9] Implement `AttachmentEndpoint.requestUploadApproval` in `motaz_app_server/lib/src/endpoints/attachment_endpoint.dart` — validate session, validate file type (image/jpeg, image/png, application/pdf) and size (≤10MB), validate parent entity exists, call AttachmentService.generateSignedUploadUrl, return AttachmentUploadApproval
- [ ] T046 [US9] Implement `AttachmentEndpoint.confirmUpload` in `motaz_app_server/lib/src/endpoints/attachment_endpoint.dart` — validate session, call AttachmentService.confirmUpload which creates AttachmentMetadata record with Cloudinary reference, writes AuditEvent, return AttachmentConfirmResponse
- [ ] T047 [US9] Implement `AttachmentUploader` in `motaz_app_flutter/lib/features/sync/application/attachment_uploader.dart` — query LocalAttachmentStaging for PENDING entries ordered by createdAt ASC, for each: call requestUploadApproval, if approved: upload file bytes to signed URL, call confirmUpload, update staging status to UPLOADED, on failure: increment retry, apply same backoff rules as outbox
- [ ] T048 [US9] Wire attachment upload into `SyncCoordinator` — after push-pull cycle completes successfully, run AttachmentUploader.processStaged() to upload any pending attachments, process one at a time in chronological order

**Checkpoint**: Offline attachments upload on sync; metadata stored on server.

---

## Phase 12: User Story 10 — Conflict Resolution (Priority: P2)

**Goal**: Owner views conflicts side-by-side and chooses local or remote version. Resolved conflicts update both server and local.

**Independent Test**: Trigger conflict, open resolution screen, choose one version, verify conflict resolved.

### Implementation for User Story 10

- [ ] T049 [US10] Implement `SyncEndpoint.resolveConflict` in `motaz_app_server/lib/src/endpoints/sync_endpoint.dart` — accept ConflictResolutionRequest, load ConflictLog, if already resolved return cached result, if "local": overwrite server entity with local payload + increment row version, if "remote": keep server entity + return current row version, mark ConflictLog RESOLVED, write AuditEvent, return ConflictResolutionResponse
- [ ] T050 [US10] Create `ConflictResolutionScreen` in `motaz_app_flutter/lib/features/sync/presentation/conflict_resolution_screen.dart` — list all PENDING conflicts from local ConflictLog, for each: show entity type, entity ID, and date, tapping opens detail view
- [ ] T051 [US10] Create conflict detail view in `ConflictResolutionScreen` — show local payload and remote payload side-by-side with field labels, highlight differing fields, "Choose Local" and "Choose Remote" action buttons, confirmation dialog before applying
- [ ] T052 [US10] Implement resolution logic in presentation — on confirm: call SyncEndpoint.resolveConflict, update local ConflictLog status to RESOLVED, if local chosen: keep local entity unchanged, if remote chosen: update local entity from remote payload, update entity syncStatus from CONFLICT to SYNCED, navigate back to conflict list

**Checkpoint**: Full conflict resolution flow working end-to-end.

---

## Phase 13: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories.

- [ ] T053 [P] Add server-side unit tests for SyncService in `motaz_app_server/test/sync/sync_service_test.dart` — test row version match/mismatch, auto-merge on allowed fields only, conflict emit on financial fields, void-wins enforcement, idempotent push handling
- [ ] T054 [P] Add server-side endpoint integration tests in `motaz_app_server/test/sync/sync_endpoint_test.dart` — test push valid mutation, push conflict scenario, push void-wins scenario, pull with pagination, pull with conflicts, resolve conflict
- [ ] T055 [P] Add client-side SyncCoordinator unit tests in `motaz_app_flutter/test/features/sync/sync_coordinator_test.dart` — test push-then-pull ordering, mutex prevents concurrent cycles, connectivity trigger starts cycle, periodic timer fires, manual trigger works, offline manual trigger returns error
- [ ] T056 [P] Add client-side OutboxProcessor unit tests in `motaz_app_flutter/test/features/sync/outbox_processor_test.dart` — test FIFO ordering, success path → COMPLETED, transient failure → retry with backoff, permanent failure → FAILED, max retry exceeded → FAILED
- [ ] T057 [P] Add client-side PullProcessor unit tests in `motaz_app_flutter/test/features/sync/pull_processor_test.dart` — test insert new row, update existing row, apply void, cursor advancement, conflict storage
- [ ] T058 Run `serverpod generate` and `dart run build_runner build --delete-conflicting-outputs` to verify all generated code compiles cleanly
- [ ] T059 Run full test suite: `flutter test test/features/sync/` and `dart test test/sync/` — verify all tests pass
- [ ] T060 Verify two-device end-to-end: create invoice on Device A offline → sync → verify on Device B, edit same record on both → sync → verify conflict detected → resolve → verify resolved

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 (T016 codegen) — BLOCKS all user stories
- **US5 Device Registration (Phase 3)**: Depends on Phase 2 — must complete before push/pull
- **US1 Push (Phase 4)**: Depends on Phase 2 + Phase 3
- **US2 Pull (Phase 5)**: Depends on Phase 2 + Phase 3
- **US3 Conflict Detection (Phase 6)**: Depends on US1 (Phase 4) + US2 (Phase 5)
- **US4 Auto-Merge (Phase 7)**: Depends on US3 (Phase 6)
- **US6 Connectivity Sync (Phase 8)**: Depends on US1 (Phase 4) + US2 (Phase 5)
- **US7 Sync Status (Phase 9)**: Depends on US6 (Phase 8)
- **US8 Retry/Backoff (Phase 10)**: Depends on US1 (Phase 4) — backoff logic built into outbox processor
- **US9 Attachment Sync (Phase 11)**: Depends on US6 (Phase 8) — uses coordinator for upload timing
- **US10 Conflict Resolution (Phase 12)**: Depends on US3 (Phase 6) — needs conflicts to resolve
- **Polish (Phase 13)**: Depends on all user stories complete

### Parallel Opportunities

```
Phase 1: T003-T015 all parallel (different .spy.yaml files)
          T017, T018 parallel (different .dart files)

Phase 2: T019-T024 sequential (same file: sync_service.dart)

Phase 4 + Phase 5: US1 (T027-T029) and US2 (T030-T031) can overlap — 
                    T027 and T030 are different endpoint methods in same file,
                    but T028/T029 and T031 are different files (outbox_processor vs pull_processor)

Phase 8 + Phase 10: US6 (T037-T040) and US8 (T043-T044) can overlap — different files

Phase 13: T053-T057 all parallel (different test files)
```

---

## Implementation Strategy

### MVP First (US5 + US1 + US2 Only)

1. Complete Phase 1: Setup (payload models + codegen)
2. Complete Phase 2: Foundational (SyncService core logic)
3. Complete Phase 3: Device Registration (US5)
4. Complete Phase 4: Push (US1)
5. Complete Phase 5: Pull (US2)
6. **STOP and VALIDATE**: Two-way sync working end-to-end between two devices

### Incremental Delivery

1. Setup + Foundational → Server-side logic ready
2. US5 + US1 + US2 → Basic two-way sync (MVP!)
3. US3 + US4 → Conflict detection + auto-merge → Reliable multi-device
4. US6 + US7 → Automatic sync + status badge → Polished UX
5. US8 → Retry/backoff → Reliable under poor connectivity
6. US9 → Attachment upload → Full audit trail support
7. US10 → Conflict resolution → Complete conflict workflow
8. Polish → Tests, validation, end-to-end verification

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story is independently testable when its phase completes
- Commit after each task or logical group
- Stop at any checkpoint to validate that phase independently
- The SyncService (Phase 2) is the most complex single file — take care with its sequential tasks (T019-T024)
