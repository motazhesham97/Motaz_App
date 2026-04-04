# Feature Specification: Sync Foundation

**Feature Branch**: `003-sync-foundation`  
**Created**: 2026-04-04  
**Status**: Draft  
**Input**: Phase 3 from `docs/implementation-plan.md` — Build the real sync engine with push/pull services, outbox processing, conflict detection, connectivity-triggered sync, and sync status UI.

---

## Clarifications

### Session 2026-04-04

- Q: While a conflict is PENDING (unresolved), what version of the entity does the local device display? → A: Keep the local version visible but mark the record with a conflict badge; the owner resolves at their convenience.

---

## User Scenarios & Testing

### User Story 1 — Push Local Changes to the Server (Priority: P1)

As the business owner, I want every local action (creating invoices, receipts, expenses, product updates, client updates, returns) to automatically sync to the cloud server when internet connectivity is available, so that my data is safely backed up and available to all my devices.

**Why this priority**: Without push, no data leaves the device. This is the most fundamental sync capability — the entire system depends on outbox processing and reliable server delivery.

**Independent Test**: Create an invoice on the phone while offline. Connect to the internet. Verify the invoice appears on the server's database within the sync interval.

**Acceptance Scenarios**:

1. **Given** a device is offline and the owner creates an invoice, **When** internet connectivity returns, **Then** the sync engine automatically pushes the outbox entry to the server and marks it as COMPLETED.
2. **Given** an outbox entry exists with status PENDING, **When** the push cycle runs, **Then** the server receives the entity payload including entity type, entity ID, operation type, payload snapshot, and row version.
3. **Given** the push request fails due to a transient network error, **When** the sync engine retries, **Then** the retry count is incremented and the outbox entry remains as PENDING or FAILED with exponential backoff applied.
4. **Given** the server successfully processes a pushed mutation, **When** the server responds with success, **Then** the outbox entry is marked COMPLETED and the local entity's sync status is updated to SYNCED.
5. **Given** multiple outbox entries exist, **When** the push cycle runs, **Then** entries are processed in chronological order (oldest first) to preserve causal consistency.

---

### User Story 2 — Pull Remote Changes to Local (Priority: P1)

As the business owner, I want changes made from my other device (e.g., my laptop) to automatically appear on my phone when the phone is online, so that I always see the latest data regardless of which device I used.

**Why this priority**: Without pull, a multi-device setup is useless. This is the complementary half of two-way sync.

**Independent Test**: Create a product on the laptop and sync. On the phone, trigger a sync and verify the product appears locally.

**Acceptance Scenarios**:

1. **Given** Device A has synced a new product to the server, **When** Device B runs a pull cycle, **Then** Device B receives the new product and inserts it into its local database.
2. **Given** Device A has updated a client's phone number (auto-merge field), **When** Device B pulls, **Then** Device B's local client record is updated with the new phone number without conflict.
3. **Given** Device B's sync cursor for Products is at row version 5, **When** a pull cycle runs, **Then** the server returns only product rows with row version > 5.
4. **Given** a pull response includes voided records, **When** the local database is updated, **Then** the voided status and void reason are applied locally, and any related audit events are stored.
5. **Given** a pull cycle completes successfully, **When** the new cursor position is saved, **Then** the sync cursor for each entity type is updated to reflect the latest row version received.

---

### User Story 3 — Conflict Detection and Recording (Priority: P1)

As the business owner, I want the system to detect when conflicting changes are made on different devices and show me the conflicts clearly, so that I can decide the correct version without losing data.

**Why this priority**: Financial data integrity is non-negotiable. Silent merging of monetary fields would violate the constitution and could cause accounting errors.

**Independent Test**: Edit the same invoice's total amount on two devices while both are offline. Sync both devices. Verify a conflict record is created and surfaced.

**Acceptance Scenarios**:

1. **Given** Device A changes an invoice's total and Device B changes the same invoice's total before syncing, **When** Device B pushes its change, **Then** the server detects a row version mismatch and emits a conflict record with both the local and remote payloads.
2. **Given** Device A edits an invoice's note (auto-merge field) and Device B edits the same invoice's note, **When** both sync, **Then** last-write-wins is applied silently with no conflict record created.
3. **Given** Device A voids an invoice and Device B edits the same invoice's total before syncing, **When** Device B pushes, **Then** the void takes precedence (void-wins rule) and Device B receives the voided record during pull.
4. **Given** a conflict record is created on the server, **When** the conflicting device pulls, **Then** the conflict record is stored locally in the ConflictLog table with both payloads, conflict type, and PENDING resolution status.
5. **Given** an unresolved conflict exists, **When** the owner views the conflict, **Then** both the local and server values are displayed side-by-side with the option to choose one.

---

### User Story 4 — Auto-Merge Safe Fields (Priority: P1)

As the business owner, I want non-financial field changes (notes, display names, phone numbers, descriptions, attachment metadata) to merge automatically without creating conflicts, so that I am not bothered with trivial conflicts on every sync.

**Why this priority**: Without auto-merge, the owner would face a conflict for every edit across two devices, making the system unusable in practice.

**Independent Test**: Change a client's phone number on Device A and the same client's note on Device B. Sync both. Verify both changes merge cleanly.

**Acceptance Scenarios**:

1. **Given** Device A updates `client.phone` and Device B updates `client.note`, **When** both sync, **Then** both changes merge without conflict and the final client record has both updates.
2. **Given** Device A updates `product.description`, **When** Device B pulls, **Then** the description is updated locally via last-write-wins with no conflict.
3. **Given** the auto-merge allowlist includes: `client.displayName`, `client.phone`, `client.note`, `client.clientCode`, `product.description`, `product.isActive`, `invoice.note`, `receipt.note`, `expense.note`, `return.note`, and attachment metadata, **When** both devices edit any of these fields simultaneously, **Then** last-write-wins resolves without conflict.
4. **Given** Device A updates `product.name` (conflict-required field) and Device B updates the same `product.name`, **When** both sync, **Then** a conflict record is created because `product.name` is not on the auto-merge allowlist.

---

### User Story 5 — Device Registration and Identity (Priority: P1)

As the business owner, when I first set up a new device and sign in, I want the device to register itself with the server automatically, so that the system can track which device made which changes and resolve conflicts properly.

**Why this priority**: Device identity is required for conflict resolution, audit trails, and outbox processing — all core sync capabilities depend on it.

**Independent Test**: Sign in on a fresh device. Verify the device record appears on the server with correct device code, platform, and local sequence.

**Acceptance Scenarios**:

1. **Given** a new device has not been registered, **When** the owner signs in and the first sync cycle runs, **Then** the device's local identity (UUID, device code, platform, device name) is pushed to the server.
2. **Given** a device is already registered on the server, **When** a sync cycle runs, **Then** the device's `lastActiveAt` is updated on the server.
3. **Given** two devices are registered, **When** each device pushes, **Then** the server associates each mutation with the originating device ID.

---

### User Story 6 — Connectivity-Triggered Sync (Priority: P2)

As the business owner, I want the sync to happen automatically in the background when my device connects to the internet, and I want to also be able to trigger a manual sync, so that I don't have to think about syncing.

**Why this priority**: Automatic sync removes friction. Without it, the owner must remember to sync manually, which defeats the offline-first promise.

**Independent Test**: Turn off airplane mode on the phone. Verify a sync cycle starts within a defined interval. Also verify a manual "Sync Now" action triggers an immediate cycle.

**Acceptance Scenarios**:

1. **Given** the device transitions from offline to online, **When** connectivity is detected, **Then** a push-then-pull sync cycle starts automatically within 5 seconds.
2. **Given** the device is online, **When** the owner taps "Sync Now", **Then** a push-then-pull cycle starts immediately regardless of any scheduled interval.
3. **Given** a sync cycle is already in progress, **When** the owner taps "Sync Now" or connectivity changes, **Then** the duplicate request is ignored and the current cycle completes first.
4. **Given** the device is online and idle, **When** a periodic interval elapses (configurable, default 5 minutes), **Then** a background sync cycle runs automatically.
5. **Given** the device is offline, **When** the owner taps "Sync Now", **Then** the system shows a clear message that no internet connection is available.

---

### User Story 7 — Sync Status Visibility (Priority: P2)

As the business owner, I want to see the current sync status and the number of pending changes at a glance, so that I know whether my data is up to date or still waiting to be synced.

**Why this priority**: Without visibility, the owner has no confidence in data freshness. A badge or indicator is essential for trust in the offline-first system.

**Independent Test**: Create several invoices offline. Verify the pending count badge shows the correct number. Sync and verify the badge clears.

**Acceptance Scenarios**:

1. **Given** 3 outbox entries are PENDING, **When** the owner views the app bar or status area, **Then** a badge displays "3" indicating pending changes.
2. **Given** all outbox entries are COMPLETED, **When** the owner views the status area, **Then** the badge shows a checkmark or "Synced" indicator with the time of the last successful sync.
3. **Given** a sync cycle is in progress, **When** the owner views the status area, **Then** a progress indicator (spinner or animation) is visible.
4. **Given** the last sync cycle failed, **When** the owner views the status area, **Then** an error indicator is shown with a "Retry" option.
5. **Given** unresolved conflicts exist, **When** the owner views the status area, **Then** a conflict warning badge is displayed with the number of unresolved conflicts.

---

### User Story 8 — Retry and Backoff on Failure (Priority: P2)

As the business owner, I want the system to retry failed sync operations automatically with sensible delays, so that temporary network issues don't cause permanent data loss or require manual intervention.

**Why this priority**: Network outages are routine. Without retry logic, a single network blip could leave data stuck in the outbox indefinitely.

**Independent Test**: Start a push while the server is unreachable. Verify retries occur with increasing delays. Restore server connectivity. Verify the entry eventually pushes successfully.

**Acceptance Scenarios**:

1. **Given** a push fails with a transient error (timeout, 5xx), **When** the retry timer elapses, **Then** the sync engine retries the push.
2. **Given** a push has failed 3 consecutive times, **When** retries continue, **Then** the delay between retries increases with each failure (exponential backoff with a cap).
3. **Given** an outbox entry has exceeded the maximum retry count, **When** the retry limit is reached, **Then** the entry is marked FAILED and the owner is notified via the sync status indicator.
4. **Given** a FAILED entry exists, **When** the owner taps "Retry" manually, **Then** the retry count resets and the push is attempted again.
5. **Given** a push fails with a 4xx client error (invalid data), **When** the error is non-retryable, **Then** the entry is immediately marked FAILED without further retries.

---

### User Story 9 — Staged Attachment Sync (Priority: P2)

As the business owner, I want attachments (photos of invoices, receipts) that I add while offline to automatically upload to the cloud when connectivity returns, so that my supporting documents are safely backed up without manual effort.

**Why this priority**: Attachments are part of the complete audit trail. Without staged upload, offline-captured photos would remain stranded on the device.

**Independent Test**: Take a photo and attach it to an invoice while offline. Connect to the internet. Verify the photo is uploaded to Cloudinary and the metadata is updated on the server.

**Acceptance Scenarios**:

1. **Given** a photo is attached to an invoice while offline, **When** connectivity returns, **Then** the sync engine uploads the staged file to Cloudinary via the server-approved upload flow.
2. **Given** the upload completes successfully, **When** the Cloudinary reference is returned, **Then** the local staging record's status is updated to UPLOADED and the AttachmentMetadata record is updated with the storage reference and secure URL.
3. **Given** an attachment upload fails, **When** the retry logic runs, **Then** the upload is retried with the same backoff rules as entity push operations.
4. **Given** the record that an attachment belongs to is voided, **When** connectivity returns, **Then** the attachment is still uploaded and preserved (constitution: attachments preserved on void).
5. **Given** multiple staged attachments exist, **When** the upload cycle runs, **Then** attachments are uploaded one at a time in chronological order to avoid overwhelming the network.

---

### User Story 10 — Conflict Resolution by Owner (Priority: P2)

As the business owner, when a conflict is detected, I want to review the conflicting values side-by-side and choose the correct version, so that my financial records remain accurate and I maintain control over disputed data.

**Why this priority**: Conflicts are inevitable in a two-device setup. Without resolution UI, conflict records pile up with no way to clear them.

**Independent Test**: Trigger a conflict on an invoice amount. Open the conflict resolution screen. Choose one version. Verify the chosen version is applied and the conflict is resolved.

**Acceptance Scenarios**:

1. **Given** an unresolved conflict exists for a product's price, **When** the owner opens the conflict resolution screen, **Then** both the local value and remote value are displayed side-by-side with clear labels.
2. **Given** the owner chooses the remote version, **When** the choice is confirmed, **Then** the local entity is updated to the remote values, the conflict status is set to RESOLVED, and the resolution is synced.
3. **Given** the owner chooses the local version, **When** the choice is confirmed, **Then** the local entity is kept, the remote is overwritten on next push, the conflict is marked RESOLVED.
4. **Given** a void-wins conflict was auto-resolved, **When** the owner views the conflict log, **Then** the record shows it was auto-resolved with the void winning, and no manual action is required.

---

### Edge Cases

- **E-001**: What happens when an entity is created on Device A and immediately voided on Device A before syncing? — Both the create and void must be pushed in order; the server receives both and the final state is voided.
- **E-002**: What happens when the same outbox entry is pushed simultaneously by two sync cycles? — Only one sync cycle may run at a time; a mutex/lock prevents concurrent cycles.
- **E-003**: What happens if the server is permanently unreachable for days? — Outbox entries accumulate locally. When connectivity returns, all entries push in chronological order. No data is lost.
- **E-004**: What happens when a pull response is very large (many rows changed)? — Pull responses should be paginated by entity type using cursor-based pagination.
- **E-005**: What happens when the server rejects a push due to version mismatch but the conflict is on an auto-merge field? — The server applies last-write-wins for allowed fields and returns success; no conflict record is created.
- **E-006**: What happens when Device A is offline for weeks and then syncs? — The cursor-based pull retrieves all changes since the last sync. No time limit on cursor validity.
- **E-007**: What happens when the device's clock is significantly wrong? — The server's clock is authoritative for `updatedAt` timestamps. Local timestamps are used only for local display; sync logic relies on row versions, not wall-clock time.
- **E-008**: What happens if the owner edits a record that has an unresolved conflict? — The local version remains the working copy. New edits are queued to the outbox. When the conflict is resolved, the resolution takes the latest state into account.

---

## Requirements

### Functional Requirements

- **FR-001**: The system MUST process outbox entries in chronological order (oldest first) during push cycles.
- **FR-002**: The system MUST send each outbox entry to the server with: entity type, entity ID, operation type, full entity payload, local row version, and device ID.
- **FR-003**: The server MUST validate the device identity, row version, and conflict rules for every pushed mutation.
- **FR-004**: The server MUST return changed rows since the client's last sync cursor position during pull cycles.
- **FR-005**: The sync cursor MUST track the last-pulled row version per entity type.
- **FR-006**: The server MUST detect row version conflicts when a pushed row version does not match the server's current row version.
- **FR-007**: The system MUST apply last-write-wins (auto-merge) without creating a conflict record for these fields: `client.displayName`, `client.phone`, `client.note`, `client.clientCode`, `product.description`, `product.isActive`, `invoice.note`, `receipt.note`, `expense.note`, `return.note`, and attachment metadata.
- **FR-008**: The system MUST create an explicit ConflictLog record for any pushed change to a conflict-required field where the row version does not match. Conflict-required fields include: any monetary amount, quantity, price, discount, financial date, `invoice.clientId`, invoice lines, receipt allocations, returns, expense category, `product.name`, `product.defaultSalePrice`.
- **FR-009**: The system MUST enforce the void-wins rule: if one device voids a financial record and another device edits the same record, the void MUST take precedence.
- **FR-010**: The system MUST retry failed push operations with exponential backoff (doubling delay) up to a configurable maximum retry count.
- **FR-011**: The system MUST mark an outbox entry as FAILED when the maximum retry count is exceeded or when a non-retryable error occurs (4xx).
- **FR-012**: The system MUST start a sync cycle automatically within 5 seconds of detecting internet connectivity restore.
- **FR-013**: The system MUST support manual sync triggering by the owner at any time.
- **FR-014**: The system MUST prevent concurrent sync cycles; only one push-pull cycle may run at a time.
- **FR-015**: The system MUST display the current sync status: pending count, synced indicator, syncing progress, error state, and unresolved conflict count.
- **FR-016**: The system MUST register the local device identity (UUID, device code, platform, device name) with the server on the first sync cycle after sign-in.
- **FR-017**: The system MUST upload locally staged attachments to Cloudinary through the server-approved upload flow when connectivity returns.
- **FR-018**: The system MUST preserve staged attachment uploads even when the parent record is voided.
- **FR-019**: The system MUST provide a conflict resolution interface where the owner can view conflicting values side-by-side and choose the correct version.
- **FR-020**: The system MUST update the ConflictLog resolution status to RESOLVED after the owner makes a choice.
- **FR-021**: The system MUST support periodic background sync at a configurable interval (default: 5 minutes) while the device is online.
- **FR-022**: The system MUST use row versions (not wall-clock time) as the authoritative ordering mechanism for conflict detection.
- **FR-023**: The system MUST handle pull response pagination for entity types with many changed rows.
- **FR-024**: While a conflict is PENDING, the system MUST keep the local version of the entity visible and editable, marked with a conflict indicator badge. The owner resolves the conflict at their convenience; new edits to the conflicted record are queued to the outbox as normal.

### Key Entities

- **SyncOutbox**: Queued local mutation awaiting push. Key attributes: entity type, entity ID, operation, payload, row version, device ID, retry count, status, created timestamp.
- **SyncCursor**: Last-pull position per entity type. Key attributes: entity type, last row version, last pulled timestamp, updated timestamp.
- **ConflictLog**: Record of a detected data conflict between two devices. Key attributes: entity type, entity ID, local payload, remote payload, conflict type, resolution status, resolved timestamp, resolution data, device ID.
- **Device**: Registered device identity. Key attributes: UUID, device code, platform, device name, next invoice sequence, last active timestamp.
- **LocalAttachmentStaging**: Offline attachment awaiting upload. Key attributes: parent entity type, parent entity ID, local file path, file type, file size, upload status.
- **AttachmentMetadata**: Cloud attachment reference linked to a financial record. Key attributes: parent entity type, parent entity ID, storage reference, secure URL, file type, file size.

---

## Success Criteria

### Measurable Outcomes

- **SC-001**: A mutation created offline on Device A arrives on Device B within 30 seconds of both devices being online simultaneously.
- **SC-002**: The system successfully reconciles auto-merge field changes between two devices with zero conflict records created for eligible fields.
- **SC-003**: The void-wins rule is enforced in 100% of void-vs-edit conflicts — no exception.
- **SC-004**: Outbox entries that fail due to transient errors are retried and eventually succeed within 5 retry attempts when the server becomes reachable.
- **SC-005**: The sync status badge accurately reflects the outbox count, sync state, and conflict count in real-time within 1 second of any state change.
- **SC-006**: Attachments staged while offline are uploaded within 60 seconds of connectivity returning.
- **SC-007**: Conflict resolution completes in under 30 seconds for the owner — view side-by-side, choose, confirm.
- **SC-008**: Background periodic sync runs reliably at the configured interval without battery drain exceeding 2% per hour of active background sync.
- **SC-009**: No data is ever lost — every outbox entry is either successfully pushed, recorded as a conflict, or retained as FAILED for manual retry.
- **SC-010**: The system handles 500+ accumulated outbox entries (from extended offline periods) and pushes them all successfully in a single sync session.

---

## Assumptions

- **A-001**: The Phase 1 workspace foundation (Serverpod project, Flutter app shell, connectivity monitoring, Riverpod setup, authentication) is complete and working.
- **A-002**: The Phase 2 core data model (all 16 Drift tables, all Serverpod models, enums, indexes, migration) is complete and stable.
- **A-003**: The server is reachable via HTTPS with standard Serverpod endpoint conventions.
- **A-004**: Cloudinary upload credentials and configuration are managed server-side through Serverpod; the client never uploads directly.
- **A-005**: The MVP targets exactly two devices (1 Android phone + 1 Windows laptop). The architecture should remain extensible for more devices in the future.
- **A-006**: The owner is the single authenticated user. No multi-user concurrency within the same entity is expected.
- **A-007**: The maximum retry count for failed push operations defaults to 5 with exponential backoff (2s, 4s, 8s, 16s, 32s).
- **A-008**: Periodic background sync interval defaults to 5 minutes and is not user-configurable in MVP (hardcoded but easily changeable).

---

## Scope Boundaries

### In Scope
- Push cycle: outbox processing → server delivery → status updates
- Pull cycle: cursor-based retrieval → local insert/update → cursor advancement
- Two-way sync: push-then-pull ordering
- Conflict detection: row-version mismatch on push
- Auto-merge: last-write-wins for allowed fields per constitution
- Void-wins: hard rule for void-vs-edit conflicts
- Device registration: automatic on first sync after sign-in
- Sync status UI: badge with pending count, sync state indicator, conflict count
- Retry/backoff: automatic retry for transient failures, manual retry for permanent failures
- Staged attachment uploading: Cloudinary via server-approved flow
- Conflict resolution: side-by-side comparison UI for the owner
- Background periodic sync
- Connectivity-triggered sync

### Out of Scope
- Real-time push notifications (WebSocket, SSE) — not in MVP
- Selective entity sync (syncing only specific tables) — all entities sync in MVP
- Server-to-device push (server initiating sync) — client always initiates
- Batch/bulk push optimization — entries are pushed individually in MVP
- Conflict auto-resolution by AI/heuristic — always manual for conflict-required fields
- Multi-user conflict resolution — single owner only in MVP
- Sync compression or delta payloads — full payload in MVP
- Server-side reporting endpoints triggered by sync — deferred to later phases
