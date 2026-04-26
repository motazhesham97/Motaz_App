# Research: Hardening & Release Readiness

**Branch**: `009-hardening-release` | **Date**: 2026-04-20

## R1: Sync Retry Strategy — Exponential Backoff with Jitter

**Decision**: Keep the existing `OutboxProcessor._computeCumulativeDelay()` with exponential backoff + jitter (0.8–1.2x). Already capped at 32 seconds. maxRetryCount = 5.

**Rationale**: The existing implementation already matches FR-005 requirements. Exponential backoff prevents server overload; jitter prevents thundering herd. The current `retryFailed()` method correctly resets entries to PENDING, enabling the manual retry path required by FR-006.

**Alternatives Considered**:
- Fixed-interval retry: Rejected — too aggressive on unreliable networks.
- Infinite retries: Rejected — constitution mandates surfacing conflicts to the user.

**Gap Found**: The `SyncCoordinator.runSyncCycle()` catches all exceptions but doesn't distinguish between transient network errors and permanent server errors. Hardening should add explicit `SocketException`/`TimeoutException` handling to avoid marking network-only failures as errors.

---

## R2: Local Error Log — File-Based Structured Logging

**Decision**: Extend the existing `AppLogger` class to write structured log entries with timestamps, severity, category, and message to a rotatable log file. Expose a `SettingsScreen` with log viewer and clear button.

**Rationale**: The existing `AppLogger` already writes to a file (`motaz_app.log`) via `IOSink`. The improvement needed is:
1. Add structured format: `[ISO-8601 timestamp] [LEVEL] [category]: message`
2. Add log rotation (max 1 MB, keep last 2 files)
3. Create a settings screen that reads and displays the file content
4. Store log file in `getApplicationDocumentsDirectory()` (not next to executable) for Android compatibility

**Alternatives Considered**:
- SQLite-based log storage: Rejected — adds DB size overhead and potential circular dependency (logging DB errors to DB).
- Cloud crash reporting (Sentry/Crashlytics): Rejected — violates offline-first principle and adds external dependency.

**Gap Found**: Current `logFile()` uses `Platform.resolvedExecutable.parent` which works on Windows but fails on Android (APK path is not writable). Must use `path_provider`'s documents directory on all platforms.

---

## R3: Database Migration Safety — Pre-migration Backup

**Decision**: Before running any Drift migration, copy the current database file to `motaz_app.db.backup`. If migration fails, restore from backup. Show error message to user on failure.

**Rationale**: Drift migrations are synchronous and atomic per-statement, but a multi-statement migration can fail midway leaving the DB in a partial state. A file-level backup provides a clean rollback point. This approach is simple, requires no additional dependencies, and covers the FR-014 requirement.

**Alternatives Considered**:
- SQLite SAVEPOINT/ROLLBACK: This works for single-statement failures but Drift's `MigrationStrategy.onUpgrade` runs multiple statements. Not reliable for all failure modes.
- Dual-database approach: Rejected — too complex for MVP.

---

## R4: Sync Status Badge Enhancement — Pending Count & Last Sync Info

**Decision**: Enhance the existing `SyncStatusBadge` to show a bottom sheet on tap (any state) with: pending count, last sync timestamp, failed count, and conflict count. Keep the color coding (green/yellow/red) as-is.

**Rationale**: The existing badge already shows green (synced), spinner (syncing), orange (conflicts), and red (error with retry tap). The enhancement adds informational depth (FR-007 states display pending info on tap, FR-004 compliance surface).

**Alternatives Considered**:
- Full sync details screen: Over-engineered for single-owner MVP.
- Toast/snackbar: Poor for persistent status info.

---

## R5: Conflict Resolution Screen — Arabization & Device Labels

**Decision**: Translate the existing `ConflictResolutionScreen` to Arabic. Replace "Local"/"Remote" labels with device names from the `devices` table. Add timestamps to payload cards.

**Rationale**: The conflict resolution screen exists and is functional but uses English labels ("Local", "Remote", "Conflict Resolution"). FR-020 requires device source labels and timestamps. The screen must be Arabic-first per §V.

**Alternatives Considered**:
- Redesign from scratch: Rejected — current side-by-side diff card approach is sound.

---

## R6: Audit Trail Viewer — Entity-Level Audit History

**Decision**: Add an "Audit History" button to each financial entity detail screen (invoice detail, receipt detail, expense detail, return detail). Tapping opens a bottom sheet listing audit events for that entity, showing operation type, timestamp, device, and changed fields.

**Rationale**: FR-025 requires the owner to be able to view audit trails from within the app. The `AuditEvents` table exists with entity indexes. The implementation is a reusable widget + Drift query.

**Alternatives Considered**:
- Dedicated audit log screen: Rejected — per-entity access is more useful for the single owner than a global log.
- Both global + per-entity: Deferred — per-entity is sufficient for MVP.

---

## R7: Performance Optimization — SQLite Indexing & Query Tuning

**Decision**: Audit existing indexes against the performance targets in FR-026 through FR-029. Add missing indexes for dashboard KPI queries (date-based filtering on `sales_invoices.invoiceDate`, `receipts.receiptDate`, `expenses.expenseDate`). Ensure all report queries use indexed columns in WHERE clauses.

**Rationale**: Current queries use `customSelect` with date range WHERE clauses. Without proper indexes on date columns, queries will scan full tables as data grows. Adding targeted indexes is the simplest optimization with highest impact.

**Alternatives Considered**:
- Materialized views: Rejected — constitution mandates compute-on-read.
- In-memory caching: Rejected — adds state management complexity for marginal gain.

---

## R8: Cross-Platform Testing Strategy

**Decision**: Manual QA using a structured test matrix. No automated UI testing framework (Flutter integration tests are fragile on Windows). Each test case in the matrix maps to a spec acceptance scenario.

**Rationale**: The MVP targets exactly 2 devices (1 Android phone, 1 Windows laptop). The single owner performs QA. Automated cross-platform UI tests would require CI infrastructure that doesn't exist yet. Manual QA with a checklist is the pragmatic choice.

**Alternatives Considered**:
- Flutter integration tests: Partially useful for widget logic but not for cross-platform rendering validation.
- Platform-specific test builds: Over-engineered for 2-device MVP.
