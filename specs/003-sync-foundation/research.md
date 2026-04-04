# Research: Sync Foundation

**Date**: 2026-04-04  
**Feature**: 003-sync-foundation

---

## R-001: Outbox Processing Pattern for Drift + Serverpod

**Decision**: Use a local SyncOutbox Drift table as the mutation queue. A SyncCoordinator Riverpod provider watches connectivity state and processes entries in FIFO order. Each push is a Serverpod endpoint call.

**Rationale**: The outbox pattern is the standard approach for offline-first sync. Drift provides reactive streams (`.watch()`) for outbox entry changes. Riverpod manages the coordinator's lifecycle tied to app state. Serverpod endpoints provide type-safe RPC between Flutter client and server.

**Alternatives considered**:
- Background isolate worker — rejected because Flutter's isolate model complicates Drift database access (no direct DB sharing between isolates on all platforms).
- Write-ahead log (WAL) replay — rejected as overcomplicated for MVP; raw outbox FIFO is sufficient for 2 devices.

---

## R-002: Conflict Detection Strategy — Row Version vs Timestamps

**Decision**: Row version integers as the single conflict detection mechanism. Each entity row has a `rowVersion` integer. The server increments row version on every accepted write. Push requests include the local row version; if it mismatches the server's current version, a conflict is emitted.

**Rationale**: Row versions are monotonically increasing, immune to clock drift, and deterministic. Wall-clock timestamps fail when device clocks differ. The constitution explicitly mandates row versions (FR-022).

**Alternatives considered**:
- Vector clocks — rejected as overkill for 2-device MVP.
- Lamport timestamps — similar to row version but adds coordinator complexity with no benefit.
- Last-write-wins on all fields — rejected; constitution requires explicit conflicts for financial fields.

---

## R-003: Auto-Merge vs Conflict-Required Field Classification

**Decision**: Field-level conflict classification. The server maintains two lists (from the constitution):

**Auto-merge (last-write-wins):** `client.displayName`, `client.phone`, `client.note`, `client.clientCode`, `product.description`, `product.isActive`, `invoice.note`, `receipt.note`, `expense.note`, `return.note`, attachment metadata fields.

**Conflict-required (always emit conflict on version mismatch):** Any monetary amount, quantity, price, discount, financial date, `invoice.clientId`, invoice lines, receipt allocations, returns, expense category, `product.name`, `product.defaultSalePrice`.

**Rationale**: The constitution §11.4 defines these lists exhaustively. Server-side enforcement ensures consistency regardless of client implementation.

**Alternatives considered**:
- Client-side field classification — rejected because a compromised or buggy client could auto-merge financial fields.
- Entity-level (whole-row) conflict — rejected as too aggressive; would conflict on every concurrent edit even for notes.

---

## R-004: Sync Cycle Architecture — Push-Then-Pull

**Decision**: Every sync cycle follows a strict push-then-pull ordering:
1. Push all PENDING outbox entries (oldest first)
2. Pull all changed rows since each entity's last cursor position
3. Update sync cursors
4. Process any received conflicts locally

**Rationale**: Push-first ensures the server has the latest local state before pulling remote changes, minimizing the window for stale conflict detection. Pull-second ensures the local device gets the freshest state including any just-applied mutations from the push phase.

**Alternatives considered**:
- Pull-then-push — rejected because pulling first could overwrite local uncommitted changes.
- Interleaved push-pull per entity — rejected as more complex with no significant benefit for 2-device MVP.

---

## R-005: Retry and Backoff Strategy

**Decision**: Exponential backoff with jitter. Base delay: 2 seconds. Multiplier: 2x per retry. Max retries: 5. Delays: ~2s, ~4s, ~8s, ~16s, ~32s. Add ±20% random jitter to avoid thundering herd. Non-retryable errors (HTTP 4xx except 408/429) immediately mark FAILED.

**Rationale**: Standard for distributed systems. 5 retries covers ~62 seconds of total retry window, which handles most transient outages. Jitter prevents synchronized retry storms if multiple entities fail simultaneously.

**Alternatives considered**:
- Fixed interval retry (e.g., every 10s) — rejected because it wastes time on short outages and doesn't back off on long ones.
- Infinite retry — rejected because truly broken payloads would retry forever.

---

## R-006: Connectivity Detection and Sync Triggering

**Decision**: Leverage the existing `connectivityProvider` (from Phase 1) which emits `ConnectivityStatus.online/offline` via `connectivity_plus`. The SyncCoordinator listens to this stream:
- On transition to online: start sync cycle after 5-second debounce.
- While online: schedule periodic sync every 5 minutes.
- On manual trigger: immediate sync if no cycle in progress.
- Mutex/lock: only one cycle active at a time.

**Rationale**: `connectivity_plus` is already integrated in Phase 1. Debounce prevents rapid-fire sync attempts during flaky connectivity transitions.

**Alternatives considered**:
- Server-sent events (SSE) for push notifications — rejected for MVP; adds server complexity.
- Firebase Cloud Messaging — rejected; adds Google dependency not aligned with self-hosted architecture.

---

## R-007: Attachment Upload Flow via Serverpod

**Decision**: Three-step server-approved upload:
1. Client requests upload approval from Serverpod endpoint (sends file metadata: type, size, parent entity).
2. Server validates, returns a signed Cloudinary upload URL + upload preset.
3. Client uploads directly to Cloudinary using the signed URL.
4. Client confirms upload completion via Serverpod endpoint, which stores the Cloudinary reference.

**Rationale**: Server-approved flow ensures upload policy enforcement (file type restrictions, size limits) without proxying file bytes through Serverpod — reducing server bandwidth and latency.

**Alternatives considered**:
- Proxy through Serverpod (server relays bytes to Cloudinary) — rejected for MVP due to server bandwidth overhead.
- Direct unsigned upload from client — rejected; constitution requires server-approved upload flows.

---

## R-008: Sync Coordinator State Management

**Decision**: A `SyncCoordinator` class exposed via a Riverpod provider. Internal state machine with states: `idle`, `syncing`, `error`. Exposes a reactive stream of `SyncState` (containing: status, pending count, last synced timestamp, error info, unresolved conflict count). The app bar widget subscribes to this stream for real-time badge updates.

**Rationale**: Riverpod provides lifecycle management (auto-dispose when app terminates), dependency injection (connectivity, database, server client), and reactive UI updates.

**Alternatives considered**:
- Bloc/Cubit pattern — rejected; project standardized on Riverpod in Phase 1.
- Raw StreamController — rejected; Riverpod provides better lifecycle, testing, and dependency management.
