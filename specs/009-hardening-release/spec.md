# Feature Specification: Hardening & Release Readiness

**Feature Branch**: `009-hardening-release`  
**Created**: 2026-04-19  
**Status**: Draft  
**Input**: Phase 9 from `docs/implementation-plan.md` — Make the system ready for real usage.

## Clarifications

### Session 2026-04-19

- Q: Should this phase produce formal deliverable documents (production checklist, release notes, known limitations)? → A: Use the constitution's Definition of Done as the production checklist; document only known limitations.
- Q: Should the app include structured error logging for production diagnostics? → A: Local error log only — structured log file on device, viewable from settings, no cloud crash reporting.

## Context

Phases 1–8 have built all functional features: foundation, data model, sync, products & clients, invoices & receipts, expenses & profit distribution, partial returns & reversals, and reports/dashboard/PDF. Phase 9 is the final hardening pass — it does not add new features but stress-tests, polishes, and validates existing functionality across all platforms, network conditions, and edge cases to produce a release candidate.

## Assumptions

- All functional features from Phases 1–8 are implemented and individually verified.
- The application runs on Android and Windows (the two MVP target platforms).
- The sync engine, PDF generator, and offline-first architecture are operational.
- The owner has been using the app with real data during development; this phase formalizes QA against the constitution's Definition of Done.
- "Release readiness" means a production-ready app for the single owner's daily use, not an app-store release.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Offline Resilience & Restart Recovery (Priority: P1)

The owner launches the app on their Android phone while completely offline (e.g., airplane mode, no Wi-Fi). They create an invoice, record a receipt, add an expense, and generate a PDF report — all without any connectivity. They then close the app entirely (force-quit), reopen it, and verify that all data they entered is intact. Later, when connectivity returns, they confirm that all offline mutations sync automatically to the server and appear on their Windows laptop.

**Why this priority**: The entire app's value proposition is offline-first. If any data is lost after a restart or fails to sync, the system is unusable for daily business operations.

**Independent Test**: Put the device in airplane mode, perform a full business workflow (invoice → receipt → expense → PDF), force-quit the app, reopen, verify data persistence, then enable connectivity and verify sync completion.

**Acceptance Scenarios**:

1. **Given** the device is in airplane mode and the app is open, **When** the owner creates an invoice, records a receipt, and adds an expense, **Then** all three records are saved to the local database immediately and are visible in the UI.
2. **Given** records were created offline, **When** the owner force-quits the app and reopens it, **Then** all previously created records are present and the dashboard KPIs reflect them accurately.
3. **Given** offline mutations exist in the sync outbox, **When** connectivity is restored, **Then** all pending mutations are pushed to the server within 60 seconds and the sync status badge reflects completion.
4. **Given** records were synced from Device A (phone), **When** the owner opens Device B (laptop), **Then** the synced records appear on Device B after the next pull cycle, with identical values.

---

### User Story 2 — Sync Failure Recovery & Retry (Priority: P1)

The owner's internet drops mid-sync (e.g., uploading a batch of mutations). The sync process must not corrupt local data, must not lose pending mutations, and must automatically retry when connectivity returns. The owner should see clear feedback about sync status.

**Why this priority**: Unreliable internet is the norm for the target user. If sync failures cause data loss or orphaned records, the owner will lose trust in the system.

**Independent Test**: Start a sync while connected, disconnect the network mid-push, verify no data corruption, reconnect, and verify automatic retry completes successfully.

**Acceptance Scenarios**:

1. **Given** the sync is pushing mutations, **When** the network drops mid-transfer, **Then** no local data is lost or corrupted, and the failed mutations remain in the outbox with their retry count incremented.
2. **Given** sync failed with pending outbox entries, **When** the network is restored, **Then** the sync coordinator automatically retries within 30 seconds.
3. **Given** a mutation fails server-side validation (e.g., row version conflict), **When** the server returns an error, **Then** the app surfaces the conflict to the owner via the conflict resolution UI and does not silently discard the mutation.
4. **Given** the sync status badge shows "pending", **When** the owner taps the badge, **Then** they see a summary of pending items count and last sync timestamp.

---

### User Story 3 — Cross-Platform Consistency (Priority: P1)

The owner uses the app on both Android (phone) and Windows (laptop). All screens, reports, and PDF exports must render correctly on both platforms. Data created on one device must appear identically on the other after sync.

**Why this priority**: The MVP explicitly targets Android + Windows. If the app is broken on either platform, 50% of the target functionality is lost.

**Independent Test**: Perform the same business workflow on both platforms, compare screen layouts, report values, and PDF outputs for consistency.

**Acceptance Scenarios**:

1. **Given** an invoice created on Android, **When** it syncs to Windows, **Then** the invoice displays with identical values (total, discount, lines, client name, local_ref) on both devices.
2. **Given** the dashboard is open on both devices, **When** both devices have synced to the same state, **Then** all 9 KPI cards show identical values.
3. **Given** a Sales Report PDF is generated on Android and the same report is generated on Windows (same date range, same data), **Then** both PDFs contain identical data, correct Arabic RTL rendering, and properly embedded Cairo font.
4. **Given** any screen in the app (all report screens, all form screens, the dashboard), **When** viewed on Windows, **Then** the RTL layout renders correctly with no overlapping elements, no truncated Arabic text, and no misaligned UI components.

---

### User Story 4 — Database Migration Safety (Priority: P2)

When the owner updates the app to a new version, the local SQLite database must migrate safely without data loss. The migration must handle all existing data, including edge cases like voided records, zero-balance invoices, and negative party balances.

**Why this priority**: Data loss during updates would be catastrophic for an accounting system. However, since MVP has no prior production users, migration testing is about ensuring the upgrade path is safe from the current schema version forward.

**Independent Test**: Create a populated database with diverse data, apply the migration, and verify all data is preserved with correct values.

**Acceptance Scenarios**:

1. **Given** a local database with invoices, receipts, expenses, returns, and distributions, **When** the app is updated to a new version with schema changes, **Then** all existing records are preserved and accessible.
2. **Given** a database containing voided records and records with zero balances, **When** the migration runs, **Then** voided records retain their status, audit history, and linked attachments.
3. **Given** a database with negative party balances, **When** the migration runs, **Then** party balance computations produce identical results before and after migration.

---

### User Story 5 — PDF Reliability Across Content Scenarios (Priority: P2)

The owner generates PDF exports for all 8 reports and the client statement. PDFs must render correctly for all content scenarios: empty data, large datasets, long Arabic names, mixed content, and edge-case date ranges.

**Why this priority**: PDF exports are the owner's primary way to share financial information with partners and clients. Broken PDFs undermine trust.

**Independent Test**: Generate PDFs for each report type with various data scenarios (empty, single row, 100+ rows, long Arabic names) and verify correct rendering.

**Acceptance Scenarios**:

1. **Given** a report type (any of the 8 reports or client statement), **When** a PDF is generated with no data for the selected date range, **Then** the PDF shows a clear empty-state message in Arabic and does not crash.
2. **Given** a Sales Report with 100+ invoices, **When** a PDF is generated, **Then** the PDF correctly paginates across multiple pages with headers repeated on each page, and all data is present.
3. **Given** a client with a very long Arabic name (40+ characters), **When** the client statement PDF is generated, **Then** the name is displayed without truncation or overflow, wrapping correctly within the layout.
4. **Given** any report PDF, **When** the PDF is opened on a standard PDF reader (Adobe, Chrome, or system viewer), **Then** all Arabic text is readable, all numbers are correctly formatted, and the RTL layout is intact.

---

### User Story 6 — Conflict Resolution UX (Priority: P2)

When a sync conflict occurs (e.g., the same invoice is edited on both devices before sync), the owner is presented with a clear, understandable UI to resolve the conflict. The resolution UX must show both conflicting versions side-by-side with clear labels and allow the owner to choose which version to keep.

**Why this priority**: Without clear conflict resolution, the owner may unknowingly lose data or accept incorrect values. The constitution mandates that financial conflicts must never be silently auto-merged.

**Independent Test**: Create a conflict scenario (edit same invoice monetary field on both devices before sync), trigger sync, and verify the conflict resolution UI appears with correct information.

**Acceptance Scenarios**:

1. **Given** Device A edits an invoice's discount and Device B edits the same invoice's discount before sync, **When** both devices sync, **Then** a conflict record is created and surfaced to the owner.
2. **Given** a conflict is surfaced, **When** the owner views the conflict details, **Then** they see both versions with clear labels (e.g., "جهاز الهاتف" vs "جهاز اللابتوب"), the conflicting field values, and timestamps.
3. **Given** a conflict requiring resolution, **When** the owner selects one version, **Then** the selected version becomes the authoritative record, the conflict is marked resolved, and the resolution is synced to both devices.
4. **Given** Device A voids an invoice while Device B edits the same invoice, **When** both devices sync, **Then** the void takes precedence automatically (void-wins rule), and the edit is discarded with an audit record explaining the resolution.

---

### User Story 7 — Audit Coverage Validation (Priority: P3)

Every financial mutation (create, edit, void, return, receipt, distribution) must have a corresponding audit event. The owner can review the audit trail for any financial record to understand its history.

**Why this priority**: The constitution mandates audit history for every financial mutation. While not a daily UX flow, it ensures accountability and is critical for dispute resolution.

**Independent Test**: Perform a series of financial mutations on a single invoice (create, edit, partial payment, partial return, void), then verify that every mutation has a corresponding audit event with correct details.

**Acceptance Scenarios**:

1. **Given** an invoice is created, **When** the audit log is queried for that invoice, **Then** a "CREATE" event exists with the correct timestamp, device ID, and snapshot of the initial values.
2. **Given** an invoice is edited (discount changed), **When** the audit log is queried, **Then** an "EDIT" event exists showing the previous and new discount values.
3. **Given** a receipt is voided with reason "خطأ في المبلغ", **When** the audit log is queried, **Then** a "VOID" event exists with the reason text and the timestamp of the void action.
4. **Given** all financial mutations across all entity types, **When** the audit log is queried, **Then** every mutation has exactly one audit event — no orphan mutations exist without corresponding audit records.

---

### Edge Cases

- What happens when the app is opened for the first time on a new device with no local database? → The app must create a fresh local database, register the device, and pull all existing data from the server on first sync.
- What happens when both devices are offline for an extended period (days) and accumulate many changes? → The sync must handle large outbox batches without timeout or memory issues. A batch of 500+ mutations should sync within 5 minutes.
- What happens when a PDF is generated while the database is being written to? → PDF generation must use a point-in-time snapshot of the data; concurrent writes must not corrupt the PDF output.
- What happens when the server is completely unavailable for an extended period? → The app must function fully offline with no degradation. When the server returns, all accumulated mutations sync cleanly.
- What happens when the app runs out of device storage? → The app should show a clear error message before the database write fails, not crash silently.
- What happens when a migration encounters corrupted data? → The migration must fail gracefully with an error message and preserve the original database file for manual recovery, not overwrite it.

---

## Requirements *(mandatory)*

### Functional Requirements

#### Offline Resilience
- **FR-001**: The app MUST preserve all locally created records after a force-quit and restart on both Android and Windows.
- **FR-002**: The app MUST function fully (create, edit, void, view reports, generate PDFs) with no network connectivity.
- **FR-003**: The app MUST NOT display any error dialogs or degraded UI when offline, except for sync-specific status indicators.

#### Sync Recovery
- **FR-004**: The sync outbox MUST NOT lose any pending mutations during network failures.
- **FR-005**: The sync coordinator MUST automatically retry failed syncs when connectivity is restored, using exponential backoff with a maximum of 5 retries.
- **FR-006**: After 5 failed retries, the sync coordinator MUST surface a manual retry option to the owner through the sync status badge.
- **FR-007**: The sync status badge MUST show: (a) green when fully synced, (b) yellow/orange when mutations are pending, (c) red when sync has failed after retries.
- **FR-008**: The app MUST handle mid-transfer network disconnections without corrupting local data or the outbox state.

#### Cross-Platform
- **FR-009**: All screens MUST render correctly with proper RTL layout on both Android and Windows.
- **FR-010**: PDF generation MUST produce identical content on both platforms for the same data and date range.
- **FR-011**: All interactive elements (buttons, dropdowns, date pickers, forms) MUST be functional and accessible on both platforms.

#### Migration Safety
- **FR-012**: Database migrations MUST preserve all existing data, including voided records, zero-balance records, and records with negative monetary values.
- **FR-013**: Migrations MUST run without user interaction — no manual steps should be required.
- **FR-014**: If a migration fails, the app MUST preserve the original database file and display an error message, not crash.

#### PDF Reliability
- **FR-015**: All 8 reports and the client statement MUST generate valid PDF files that open without errors in standard PDF readers.
- **FR-016**: PDF generation MUST handle empty datasets without crashing, showing a clear Arabic empty-state message.
- **FR-017**: PDF generation MUST handle large datasets (100+ rows) with correct pagination and header repetition.
- **FR-018**: Arabic text in PDFs MUST render correctly with RTL directionality, proper Cairo font embedding, and no missing glyphs.

#### Conflict Resolution
- **FR-019**: Financial field conflicts MUST be surfaced to the owner through a dedicated conflict resolution screen.
- **FR-020**: The conflict resolution UI MUST show both conflicting values, their source devices, and timestamps.
- **FR-021**: The void-wins rule MUST be enforced automatically: if one device voids and another edits, the void takes precedence without user intervention.
- **FR-022**: Auto-merge fields (notes, display names, attachment metadata) MUST merge silently using last-write-wins without creating conflict records.

#### Audit
- **FR-023**: Every financial mutation (create, edit, void) across all entity types (invoices, receipts, expenses, returns, distributions) MUST have a corresponding audit event.
- **FR-024**: Audit events MUST include: timestamp, device ID, operation type, entity type, entity ID, and a snapshot of changed fields.
- **FR-025**: The owner MUST be able to view the audit trail for any financial record from within the app.

#### Performance
- **FR-026**: The dashboard MUST load all 9 KPI cards within 3 seconds on a device with 1000+ records in each table.
- **FR-027**: Any report query MUST return results within 5 seconds for a date range spanning 1 year of data with 1000+ records.
- **FR-028**: PDF generation for a report with 100+ rows MUST complete within 10 seconds.
- **FR-029**: App cold start (from force-quit to usable dashboard) MUST complete within 5 seconds on Android and 3 seconds on Windows.

#### Observability
- **FR-030**: The app MUST maintain a local structured error log on the device, recording unexpected errors, sync failures, and migration issues with timestamps and context.
- **FR-031**: The owner MUST be able to view and clear the error log from within the app settings screen.

### Key Entities

No new entities are introduced in this phase. All entities from Phases 1–8 are the subject of hardening:

- **SalesInvoice, SalesInvoiceLine**: Invoice lifecycle integrity
- **Receipt, ReceiptAllocation**: Payment and FIFO allocation integrity
- **Expense**: Expense recording and categorization integrity
- **SalesReturn, SalesReturnLine**: Return and reversal integrity
- **MonthlyDistribution**: Distribution computation integrity
- **SyncOutbox**: Outbox persistence and retry fidelity
- **ConflictLog**: Conflict detection and resolution completeness
- **AuditEvent**: Audit coverage completeness

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The owner can perform a complete business day workflow (5 invoices, 3 receipts, 2 expenses, 1 return, all reports + PDFs) fully offline on both Android and Windows without any errors or data loss.
- **SC-002**: After a device force-quit during active use, 100% of locally saved records are present upon restart.
- **SC-003**: Sync recovers automatically from network interruptions with zero data loss across both devices.
- **SC-004**: All 9 dashboard KPI cards load within 3 seconds on a device with 1000+ records per table.
- **SC-005**: PDF generation succeeds for all 8 reports and the client statement across both platforms, producing valid, readable Arabic RTL documents.
- **SC-006**: Database migrations preserve 100% of existing records, including edge-case data (voided, zero-balance, negative balances).
- **SC-007**: Every financial mutation in the app produces a corresponding audit event — zero orphan mutations exist.
- **SC-008**: The void-wins conflict rule is enforced in 100% of void-vs-edit scenarios with no manual intervention required.
- **SC-009**: The conflict resolution UI is reachable and functional for all surfaced financial conflicts.
- **SC-010**: The release candidate passes all Definition of Done criteria from the constitution (used as the production checklist), and a known limitations document is produced listing any deferred items or caveats.
