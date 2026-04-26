# Tasks: Hardening & Release Readiness

**Input**: Design documents from `/specs/009-hardening-release/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, quickstart.md

**Tests**: Not explicitly requested — no test tasks generated. Verification is manual QA per spec.

**Organization**: Tasks grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

All paths are relative to `motaz_app/motaz_app_flutter/lib/` unless stated otherwise.

---

## Phase 1: Setup (No Story)

**Purpose**: Foundational fixes that unblock all user stories. No new features.

> ⚠️ **IMPORTANT NOTE FOR IMPLEMENTATION MODEL**: Before implementing ANY task in this file, read the following documents as the source of truth:
> - `.specify/memory/constitution.md` — governing principles and rules
> - `specs/009-hardening-release/spec.md` — feature specification with acceptance scenarios
> - `specs/009-hardening-release/plan.md` — approved technical design
> - `specs/009-hardening-release/research.md` — technical decisions and rationale
>
> Do NOT guess architecture or business behavior from memory. Follow the approved constitution, Master Implementation Plan, and current spec boundaries. Do NOT introduce features, tables, or patterns not described in these documents.

---

### T001: Fix AppLogger log file path for Android compatibility

- [X] T001 Fix log file path in `core/logging/app_logger.dart`

**Objective**: The current `logFile()` method uses `Platform.resolvedExecutable.parent` which is not writable on Android. Fix it to use `path_provider`'s `getApplicationDocumentsDirectory()`.

**Files to update**:
- `core/logging/app_logger.dart`

**Scope**:
1. Change `logFile()` to be `static Future<File> logFile() async` (async because `getApplicationDocumentsDirectory()` is async).
2. Call `final dir = await getApplicationDocumentsDirectory();` and return `File('${dir.path}${Platform.pathSeparator}motaz_app.log')`.
3. Change `_createLogSink()` to be async: `static Future<IOSink?> _createLogSink() async`.
4. Update `initialize()` to be `static Future<void> initialize() async` and `await _createLogSink()`.
5. Import `package:path_provider/path_provider.dart` (already a project dependency).
6. Keep existing logger instances (`auth`, `connectivity`, `database`, `server`) unchanged.
7. Add `import 'package:path_provider/path_provider.dart';` at the top.

**Dependencies**: None.

**Verification**: Run `dart analyze` — 0 errors. Run app on Windows — log file is created in documents directory. The file path should work on both Android and Windows.

---

### T002: Add structured log format and rotation to AppLogger

- [X] T002 Add structured format and log rotation in `core/logging/app_logger.dart`

**Objective**: Upgrade the log line format to include ISO-8601 timestamps and add log rotation (max 1 MB, keep 2 files).

**Files to update**:
- `core/logging/app_logger.dart`

**Scope**:
1. In `initialize()`, change the `onRecord` listener to produce structured format:
   ```
   [2026-04-20T10:30:15.123] [WARNING] [motaz.sync]: Sync cycle error: message
   ```
   Use `record.time.toIso8601String()` for the timestamp.
2. Add a `sync` logger: `static final Logger sync = Logger('motaz.sync');`
3. Add rotation logic in `_createLogSink()`: before opening the file for append, check `file.lengthSync()`. If > 1,048,576 (1 MB), rename current file to `motaz_app.log.1` (overwriting any existing `.log.1`), then open a fresh `motaz_app.log`.
4. Add `static Future<String> getLogContents() async` — reads and returns the full `motaz_app.log` contents as a string. Return empty string if file doesn't exist.
5. Add `static Future<void> clearLog() async` — truncates (overwrites with empty) the `motaz_app.log` file. Close and re-create the `IOSink`.
6. Ensure `_fileSink` is properly managed — closing and reopening on rotation/clear.

**Dependencies**: T001 (file path fix must be done first).

**Verification**: Run `dart analyze` — 0 errors. Run app, perform actions, check that log file in documents directory contains structured entries with timestamps.

---

### T003: Add sync_outbox status index

- [X] T003 [P] Add `@TableIndex` on `status` column in `core/database/tables/sync_outbox.dart`

**Objective**: The `sync_outbox` table is queried by `status` in `OutboxProcessor.processPending()` and `retryFailed()`. Add a missing index for query performance.

**Files to update**:
- `core/database/tables/sync_outbox.dart`

**Scope**:
1. Add `@TableIndex(name: 'idx_outbox_status', columns: {#status})` above the `SyncOutbox` class.
2. Do NOT change the schema version yet — that happens in T004.

**Dependencies**: None.

**Verification**: Run `dart analyze` — 0 errors. The index annotation is present.

> **Note**: All other required indexes already exist per the grep audit:
> - `sales_invoices`: `idx_invoice_date` ✅, `idx_invoice_client` ✅, `idx_invoice_status` ✅
> - `receipts`: `idx_receipt_date` ✅, `idx_receipt_client` ✅, `idx_receipt_status` ✅
> - `expenses`: `idx_expense_date` ✅, `idx_expense_category` ✅, `idx_expense_status` ✅
> - `conflict_logs`: `idx_conflict_status` ✅
> - `audit_events`: `idx_audit_entity` ✅, `idx_audit_created` ✅

---

### T004: Bump schema version and add migration for new index

- [X] T004 Bump schema version to 5 and add migration in `core/database/app_database.dart`

**Objective**: The new `sync_outbox.status` index from T003 requires a schema version bump and migration step.

**Files to update**:
- `core/database/app_database.dart`

**Scope**:
1. Change `int get schemaVersion => 4;` to `int get schemaVersion => 5;`.
2. In `onUpgrade`, add a block: `if (from < 5) { await m.createIndex(idxOutboxStatus); }`.
3. Do NOT change any other migration blocks.

**Dependencies**: T003 (index annotation must exist).

**Verification**: Run `dart analyze` — 0 errors. Run app — migration runs without crash, DB opens at version 5.

---

### T005: Add pre-migration database backup logic

- [X] T005 Add pre-migration backup in `core/database/app_database.dart`

**Objective**: Before any Drift migration, copy the database file to `.backup`. If migration fails, the backup is preserved for manual recovery. If migration succeeds, delete the backup.

**Files to update**:
- `core/database/app_database.dart`

**Scope**:
1. In `_openConnection()` or using Drift's `MigrationStrategy.beforeOpen` callback, add logic:
   - Before `onUpgrade` runs, copy the DB file (`motaz_app.db`) to `motaz_app.db.backup` using `File.copy()`.
   - Wrap the `onUpgrade` body in a `try/catch`.
   - On successful migration: delete `motaz_app.db.backup`.
   - On failure: log the error via `AppLogger.database.severe(...)`. The `.backup` file remains for manual recovery.
2. The backup target path is the same directory as the DB file (from `getApplicationDocumentsDirectory()`).
3. Import `dart:io` for `File` operations (if not already imported).
4. Do NOT change the `onCreate` path — backup is only needed for upgrades.

**Dependencies**: T001 (path fix), T004 (schema version).

**Verification**: Run `dart analyze` — 0 errors. Run app with existing schema v4 DB — migration to v5 succeeds, no `.backup` file remains. Manually corrupt a migration step → verify `.backup` file is preserved.

---

**Checkpoint**: Setup complete. All foundational fixes are in place. User story work can now begin.

---

## Phase 2: US1 — Offline Resilience & Restart Recovery (Priority: P1) 🎯

**Goal**: Verify that all data created offline persists after force-quit and syncs when connectivity returns.

**Independent Test**: Put device in airplane mode → create invoice + receipt + expense → force-quit → reopen → verify data present → enable connectivity → verify sync completes.

> **Note**: This user story is primarily about **verification** of existing behavior. The logging infrastructure from Phase 1 enables error diagnosis if issues are found. No new features expected unless bugs are discovered.

---

### T006: Verify offline data persistence on Windows

- [X] T006 [US1] Verify offline persistence by running app on Windows in airplane mode

**Objective**: Manually verify that the app functions fully offline on Windows. Create records, force-quit, reopen, confirm data intact.

**Files to update**: None (verification only). If defects are found, create follow-up tasks.

**Scope**:
1. Run app on Windows via `flutter run -d windows`.
2. Disconnect network (disable Wi-Fi/Ethernet).
3. Create: 1 invoice with 2 lines, 1 receipt, 1 expense.
4. Verify all 3 records appear in their respective list screens.
5. Verify dashboard KPI cards update to reflect the new records.
6. Force-quit the app (close window).
7. Reopen — verify all 3 records are still present.
8. Reconnect network — verify sync status badge transitions from "pending" to "synced" within 60 seconds.

**Dependencies**: T001, T002 (logging must work to diagnose any issues).

**Verification**: All 8 steps pass without errors. If any fail, create a defect task with specific error details.

---

### T007: Verify offline data persistence on Android

- [X] T007 [US1] Verify offline persistence by running app on Android device in airplane mode

**Objective**: Same verification as T006, but on Android.

**Files to update**: None (verification only).

**Scope**:
1. Run app on Android via `flutter run -d <device-id>`.
2. Enable airplane mode on the phone.
3. Create: 1 invoice with 2 lines, 1 receipt, 1 expense.
4. Verify all 3 records appear in their respective list screens.
5. Verify dashboard KPIs update.
6. Force-quit the app (swipe away from recents).
7. Reopen — verify all 3 records are still present.
8. Disable airplane mode — verify sync completes within 60 seconds.

**Dependencies**: T001, T002.

**Verification**: All 8 steps pass without errors.

---

## Phase 3: US2 — Sync Failure Recovery & Retry (Priority: P1) 🎯

**Goal**: Ensure the sync coordinator handles network failures gracefully, retries automatically, and surfaces clear status to the owner.

**Independent Test**: Start sync → kill network mid-transfer → verify no data loss → restore network → verify auto-retry succeeds.

---

### T008: Add transient error handling to SyncCoordinator

- [X] T008 [US2] Add SocketException/TimeoutException handling in `features/sync/application/sync_coordinator.dart`

**Objective**: Distinguish transient network errors from permanent server errors. On transient errors, keep outbox entries as PENDING and don't transition to error state. Add a 10-second minimum cooldown between sync cycles.

**Files to update**:
- `features/sync/application/sync_coordinator.dart`

**Scope**:
1. Import `dart:io` for `SocketException` and `dart:async` for `TimeoutException`.
2. In `runSyncCycle()`, change the generic `catch (e)` block:
   - If `e` is `SocketException` or `TimeoutException`: log via `AppLogger.sync.info('Transient network error: $e')` and emit state with `status: SyncPhase.idle` (not error). Keep outbox entries PENDING.
   - Otherwise (other exceptions): keep existing error behavior — emit `SyncPhase.error` with `errorMessage`.
3. Add a `DateTime? _lastSyncAttempt` field.
4. At the start of `runSyncCycle()`, after `if (_isRunning) return;`, add: if `_lastSyncAttempt != null && DateTime.now().difference(_lastSyncAttempt!) < Duration(seconds: 10)`, return early.
5. Set `_lastSyncAttempt = DateTime.now()` right before the push phase.
6. Replace `AppLogger.database.warning('Sync cycle error: $e')` with `AppLogger.sync.warning('Sync cycle error: $e')`.

**Dependencies**: T002 (sync logger must exist).

**Verification**: Run `dart analyze` — 0 errors. App compiles. Disconnect network mid-sync → verify no red error badge, outbox entries remain PENDING.

---

### T009: Add failedCount field to SyncState

- [X] T009 [US2] Add `failedCount` field to `features/sync/domain/sync_state.dart`

**Objective**: The sync status bottom sheet (T010) needs a failed count. Add it to `SyncState`.

**Files to update**:
- `features/sync/domain/sync_state.dart`

**Scope**:
1. Add `final int failedCount;` field with default value `0`.
2. Add `failedCount` to the constructor with default: `this.failedCount = 0`.
3. Add `int? failedCount` to `copyWith()` parameters and include in the returned `SyncState`.
4. Do NOT change any existing fields or their defaults.

**Dependencies**: None.

**Verification**: Run `dart analyze` — 0 errors.

---

### T010: Add info bottom sheet to SyncStatusBadge

- [X] T010 [US2] Add sync info bottom sheet on tap in `features/sync/presentation/sync_status_badge.dart`

**Objective**: When the owner taps the sync status badge in any state, show a modal bottom sheet with sync details: status label, pending count, failed count, last sync time, conflict count, and a manual retry button.

**Files to update**:
- `features/sync/presentation/sync_status_badge.dart`

**Scope**:
1. Wrap the entire badge widget in a `GestureDetector` with `onTap` that calls `_showSyncInfoSheet(context, syncState, pendingCount, conflictCount, ref)`.
2. Remove the existing `GestureDetector` on the error icon (line 67–75) — the new tap handler covers all states.
3. Create `_showSyncInfoSheet()` static method that calls `showModalBottomSheet()` with rounded top corners, showing:
   - Arabic sync status label: idle → "متزامن", pushing/pulling → "قيد المزامنة", error → "خطأ في المزامنة".
   - Row: "التغييرات المعلقة: {pendingCount}" with cloud upload icon.
   - Row: "آخر مزامنة: {lastSyncedAt formatted}" or "لم تتم المزامنة بعد" if null.
   - Row: "التعارضات: {conflictCount}" with warning icon (only if conflictCount > 0).
   - If error state: show `ElevatedButton` with text "إعادة المحاولة" that calls `ref.read(syncCoordinatorProvider).retryAndSync()` and closes the sheet.
4. Use `Navigator.pop(context)` after retry is triggered.
5. All strings in Arabic.

**Dependencies**: T008 (coordinator changes), T009 (failedCount field).

**Verification**: Run `dart analyze` — 0 errors. Run app → tap sync badge → bottom sheet appears with all expected information in Arabic. Verify retry button works when in error state.

---

## Phase 4: US3 — Cross-Platform Consistency (Priority: P1) 🎯

**Goal**: All screens, reports, and PDFs render correctly on both Android and Windows.

**Independent Test**: Perform same workflow on both platforms, compare screen layouts, report values, PDF outputs.

---

### T011: Verify RTL layout on Windows for all core screens

- [X] T011 [US3] Verify RTL layout on Windows for all screens listed in app_router.dart

**Objective**: Run the app on Windows and visually verify every screen for RTL correctness: no overlapping elements, no truncated Arabic text, no misaligned components.

**Files to update**: None (verification only). If defects are found, fix inline or create follow-up tasks.

**Scope**:
Check each route defined in `core/router/app_router.dart`:
1. `/home` — HomeScreen
2. `/dashboard` — DashboardScreen (all 9 KPI cards)
3. `/products` — ProductListScreen
4. `/clients` — ClientListScreen
5. `/invoices` — InvoiceListScreen
6. `/receipts` — ReceiptListScreen
7. `/expenses` — ExpenseListScreen
8. `/returns` — ReturnListScreen
9. `/reports` — ReportsPlaceholderScreen (verify placeholder renders)
10. `/party-balances` — PartyBalancesScreen
11. `/distributions` — DistributionScreen
12. `/settings` — SettingsScreen (after T014)

For each screen: verify text direction is RTL, alignment is correct, no UI overflow warnings in console.

**Dependencies**: None.

**Verification**: All screens render correctly on Windows with proper RTL. Document any issues found.

---

### T012: Verify PDF output consistency across platforms

- [X] T012 [US3] Generate Sales Report PDF on both platforms and compare

**Objective**: Generate the same report PDF on both platforms with identical data and verify the outputs are visually consistent.

**Files to update**: None (verification only).

**Scope**:
1. Ensure both devices have synced to the same data state.
2. On Windows: navigate to Sales Report, select "هذا الشهر", generate PDF.
3. On Android: same steps with same date range.
4. Open both PDFs and compare:
   - Same number of rows
   - Same totals (minor-unit integer formatting consistent)
   - Arabic text renders correctly in both
   - Cairo font is embedded in both (no missing glyphs)
   - RTL layout intact in both

**Dependencies**: T006, T007 (data must exist on both platforms).

**Verification**: Both PDFs contain identical data with correct Arabic RTL rendering.

---

## Phase 5: US4 — Database Migration Safety (Priority: P2)

**Goal**: Ensure migrations preserve all data and handle failures gracefully.

**Independent Test**: Populate database → apply migration → verify data integrity.

> **Note**: T005 already implements the backup mechanism. This phase validates it.

---

### T013: Validate migration from v4 to v5 preserves all data

- [X] T013 [US4] Validate migration preserves data by running app with v4 database

**Objective**: Start the app with a pre-existing schema v4 database, allow migration to v5, and verify all records are intact.

**Files to update**: None (verification only).

**Scope**:
1. Create a populated v4 database with: 5 invoices (including 1 voided), 3 receipts, 2 expenses, 1 return, 1 distribution.
2. Launch the app — migration runs automatically.
3. Verify all records are present and accessible in their list screens.
4. Verify voided records show correct void status.
5. Verify dashboard KPIs compute correctly post-migration.
6. Verify the `.backup` file was deleted after successful migration.

**Dependencies**: T004 (schema v5), T005 (backup logic).

**Verification**: All records intact, no data loss, `.backup` file cleaned up.

---

## Phase 6: US5 — PDF Reliability Across Content Scenarios (Priority: P2)

**Goal**: PDFs generate correctly for empty data, large datasets, long names, and all report types.

**Independent Test**: Generate PDFs for each report type with edge-case data.

---

### T014: Verify PDF empty state for all implemented reports

- [X] T014 [US5] Generate PDF for each implemented report with empty date range and verify empty-state message

**Objective**: Verify that PDF generation doesn't crash on empty datasets and shows a clear Arabic empty-state message.

**Files to update**: None unless bugs are found. Check these PDF templates:
- `features/reports/pdf/pdf_templates/sales_report_pdf.dart`
- `features/reports/pdf/pdf_templates/client_statement_pdf.dart`
- Any other PDF templates that exist.

**Scope**:
1. For each implemented report (Sales Report, Client Statement):
   - Select a date range with no data (e.g., a future month).
   - Tap "تصدير PDF".
   - Verify the PDF is generated without crash.
   - Open the PDF and verify it shows "لا توجد بيانات" or equivalent Arabic empty-state message.
2. If any template crashes on empty data, fix it by adding an empty-state check before the table rendering (follow the pattern in `sales_report_pdf.dart` which already does this).

**Dependencies**: None.

**Verification**: All implemented reports generate valid PDFs on empty data without crashes.

---

### T015: Verify PDF pagination with large dataset

- [X] T015 [US5] Generate Sales Report PDF with 50+ invoices and verify pagination

**Objective**: Verify that `pw.MultiPage` correctly paginates the sales report table across multiple pages.

**Files to update**: None unless bugs are found.

**Scope**:
1. Create 50+ invoices (either manually or via a test script).
2. Generate Sales Report PDF for the period containing all invoices.
3. Open the PDF and verify:
   - Multiple pages are generated.
   - All 50+ rows are present (count them).
   - Summary section appears after the table.
   - No data is cut off or missing.

**Dependencies**: None.

**Verification**: PDF contains all rows across multiple pages. No data loss.

---

### T016: Verify PDF handling of long Arabic names

- [X] T016 [US5] Generate Client Statement PDF for client with 40+ character Arabic name

**Objective**: Verify that long Arabic client names wrap correctly in the PDF without overflow.

**Files to update**: None unless bugs are found.

**Scope**:
1. Create or edit a client with a very long Arabic name (40+ characters), e.g., "عبدالرحمن بن محمد بن عبدالله الهاشمي الصنعاني".
2. Create an invoice for this client.
3. Generate Client Statement PDF.
4. Open and verify: name is displayed completely, wrapping correctly, not truncated or overflowing.

**Dependencies**: None.

**Verification**: Long name renders correctly with proper wrapping.

---

## Phase 7: US6 — Conflict Resolution UX (Priority: P2)

**Goal**: Arabize the conflict resolution screen, add device labels, timestamps, and void-wins indicator.

**Independent Test**: Create a conflict scenario → verify Arabic conflict UI with device names.

---

### T017: Arabize conflict resolution screen strings

- [X] T017 [US6] Translate all English strings to Arabic in `features/sync/presentation/conflict_resolution_screen.dart`

**Objective**: Replace all English strings in the conflict resolution screen with Arabic equivalents per the plan.

**Files to update**:
- `features/sync/presentation/conflict_resolution_screen.dart`

**Scope**:
1. Replace these strings exactly:
   - `'Conflict Resolution'` → `'حل التعارضات'`
   - `'No pending conflicts'` → `'لا توجد تعارضات معلقة'`
   - `'Choose Local'` → `'اختيار نسخة هذا الجهاز'`
   - `'Choose Remote'` → `'اختيار النسخة الأخرى'`
   - `'Conflict resolved successfully'` → `'تم حل التعارض بنجاح'`
   - `'Cancel'` → `'إلغاء'`
   - `'Confirm'` → `'تأكيد'`
   - `'Error: $e'` → `'خطأ: $e'`
   - `'Confirm ${...} Version'` title → `'تأكيد اختيار النسخة'`
   - `'Are you sure...'` content → `'هل أنت متأكد من اختيار هذه النسخة؟ لا يمكن التراجع عن هذا الإجراء.'`
   - `'Resolution failed: ${...}'` → `'فشل حل التعارض: ${...}'`
2. Replace `'${conflict.entityType.name} Conflict'` with `'تعارض ${_entityTypeLabel(conflict.entityType)}'` and add a helper method `_entityTypeLabel()` that maps entity types to Arabic names (e.g., `SALES_INVOICE` → `'فاتورة'`, `RECEIPT` → `'سند قبض'`, etc.).
3. Do NOT change any logic, only strings.

**Dependencies**: None.

**Verification**: Run `dart analyze` — 0 errors. Run app → navigate to conflict resolution screen → all text is in Arabic.

---

### T018: Add device name resolution to conflict detail view

- [X] T018 [US6] Replace "Local"/"Remote" labels with device names in `features/sync/presentation/conflict_resolution_screen.dart`

**Objective**: Instead of showing "Local" and "Remote", show actual device names from the `devices` table.

**Files to update**:
- `features/sync/presentation/conflict_resolution_screen.dart`

**Scope**:
1. In `_buildDetail()`, extract `deviceId` from `localPayload` and `remotePayload` JSON (field name: `deviceId` or `device_id`).
2. Query the `devices` table for each device ID: `(db.select(db.devices)..where((t) => t.id.equals(deviceId))).getSingleOrNull()`.
3. Use `device.deviceName` as the card title instead of `'Local'`/`'Remote'`. If device lookup fails, fall back to `'جهاز غير معروف'` (unknown device).
4. Add the `createdAt` timestamp from each payload to the card header (formatted as `yyyy-MM-dd HH:mm`).
5. Store the device query as a `FutureBuilder` or use `ref.watch` with a family provider.

**Dependencies**: T017 (Arabic strings must be in place first).

**Verification**: Run `dart analyze` — 0 errors. Create a test conflict → view details → see device names instead of "Local"/"Remote" and timestamps on each card.

---

## Phase 8: US7 — Audit Coverage Validation (Priority: P3)

**Goal**: The owner can view audit trails for any financial record. Every mutation has a corresponding audit event.

**Independent Test**: Perform mutations → view audit trail → verify every mutation has an event.

---

### T019: Create reusable audit trail bottom sheet widget

- [X] T019 [US7] Create `shared/widgets/audit_trail_sheet.dart` with `showAuditTrailSheet()` function

**Objective**: A reusable function that shows a `DraggableScrollableSheet` listing all audit events for a given entity.

**Files to create**:
- `shared/widgets/audit_trail_sheet.dart` — **NEW FILE**

**Scope**:
1. Create a function: `Future<void> showAuditTrailSheet(BuildContext context, WidgetRef ref, ParentEntityType entityType, String entityId)`.
2. Inside, call `showModalBottomSheet` with a `DraggableScrollableSheet`.
3. Query audit events from the database: `SELECT * FROM audit_events WHERE entity_type = ? AND entity_id = ? ORDER BY created_at DESC`.
4. Use `ref.read(appDatabaseProvider)` to access the database.
5. Display each audit event as a `ListTile` with:
   - Leading icon: `Icons.add_circle` (green) for CREATE, `Icons.edit` (blue) for UPDATE, `Icons.cancel` (red) for VOID.
   - Title: Arabic operation label — `AuditOperation.CREATE` → `'إنشاء'`, `UPDATE` → `'تعديل'`, `VOID` → `'إلغاء'`.
   - Subtitle line 1: Timestamp formatted as `yyyy-MM-dd HH:mm`.
   - Subtitle line 2: Device name (query `devices` table by `deviceId`). Fall back to `'جهاز غير معروف'` if not found.
6. Title of the sheet: `'سجل التعديلات'`.
7. If no audit events exist, show: `'لا يوجد سجل تعديلات'`.
8. Import `ParentEntityType` from `core/database/enums/parent_entity_type.dart`.
9. Import `AuditOperation` from `core/database/enums/audit_operation.dart`.
10. Import `appDatabaseProvider` from `core/database/database_provider.dart`.

**Dependencies**: None.

**Verification**: Run `dart analyze` — 0 errors. File compiles. Widget can be called from any screen.

---

### T020: Add audit trail button to invoice list items

- [X] T020 [US7] Add audit history icon button to invoice list tiles in the invoice list screen

**Objective**: Add a history icon button to each invoice in the invoice list. Tapping it calls `showAuditTrailSheet()` with `ParentEntityType.SALES_INVOICE`.

**Files to update**:
- Locate the invoice list screen (likely `features/invoices/presentation/invoice_list_screen.dart`).

**Scope**:
1. Import `shared/widgets/audit_trail_sheet.dart`.
2. Add a trailing `IconButton` with `Icons.history` or `Icons.access_time` to each invoice `ListTile` or `Card`.
3. On tap: call `showAuditTrailSheet(context, ref, ParentEntityType.SALES_INVOICE, invoice.id)`.
4. Do NOT change any other invoice list behavior.

**Dependencies**: T019 (audit trail sheet must exist).

**Verification**: Run `dart analyze` — 0 errors. Run app → invoice list → tap history icon → audit trail sheet appears with events for that invoice.

---

### T021: Add audit trail button to receipt, expense, and return lists

- [X] T021 [P] [US7] Add audit history icon button to receipt, expense, and return list items

**Objective**: Same as T020 but for receipts, expenses, and returns.

**Files to update**:
- `features/receipts/presentation/receipt_list_screen.dart`
- `features/expenses/presentation/expense_list_screen.dart`
- `features/returns/presentation/return_list_screen.dart`

**Scope**:
1. In each file, import `shared/widgets/audit_trail_sheet.dart`.
2. Add a trailing `IconButton` with `Icons.history` to each list item.
3. On tap, call `showAuditTrailSheet()` with the appropriate `ParentEntityType`:
   - Receipt: `ParentEntityType.RECEIPT`
   - Expense: `ParentEntityType.EXPENSE`
   - Return: `ParentEntityType.SALES_RETURN`
4. Do NOT change any other list behavior.

**Dependencies**: T019 (audit trail sheet must exist).

**Verification**: Run `dart analyze` — 0 errors. Run app → each list screen → tap history icon → audit trail sheet appears.

---

## Phase 9: Settings & Navigation (No Story — Cross-cutting)

**Goal**: Replace the settings placeholder with a real screen, add log viewer, update routes.

---

### T022: Create SettingsScreen replacing placeholder

- [X] T022 Create `features/settings/presentation/settings_screen.dart` replacing placeholder

**Objective**: Replace `SettingsPlaceholderScreen` with a real settings screen showing app info, device info, log viewer link, and manual sync trigger.

**Files to update**:
- `features/settings/presentation/settings_screen.dart` — **OVERWRITE** existing `placeholder_screen.dart`. Note: the existing file may be named `placeholder_screen.dart`. The router imports it as `SettingsPlaceholderScreen`. Create `settings_screen.dart` and update the import.

**Scope**:
1. Create `SettingsScreen` as a `ConsumerWidget` (not stateful — simple read-only screen).
2. Use `Scaffold` with AppBar title `'الإعدادات'`.
3. Body is a `ListView` with these sections:
   - **App Info section**: `ListTile` showing app version `'1.0.0'` with subtitle `'إصدار'`.
   - **Device Info section**: Read from `DeviceService` / device provider. Show `ListTile` with device ID (truncated to 8 chars) and device code. Title: `'معلومات الجهاز'`.
   - **Log Viewer**: `ListTile` with leading `Icons.article_outlined`, title `'سجل الأخطاء'`, trailing `Icons.chevron_right`. On tap: navigate to log viewer screen (T023).
   - **Manual Sync**: `ListTile` with leading `Icons.sync`, title `'مزامنة يدوية'`. On tap: call `ref.read(syncCoordinatorProvider).syncNow()`. Show a `SnackBar` with `'جاري المزامنة...'`.
4. Import `sync_providers.dart` for the sync coordinator.
5. All strings in Arabic.

**Dependencies**: T001, T002 (logging), T008 (sync coordinator changes).

**Verification**: Run `dart analyze` — 0 errors. Route to `/settings` shows the real settings screen with all sections in Arabic.

---

### T023: Create LogViewerScreen

- [X] T023 Create `features/settings/presentation/log_viewer_screen.dart`

**Objective**: A simple screen that displays the contents of the local log file and allows the owner to clear it.

**Files to create**:
- `features/settings/presentation/log_viewer_screen.dart` — **NEW FILE**

**Scope**:
1. Create `LogViewerScreen` as a `StatefulWidget` (needs to reload after clear).
2. AppBar title: `'سجل الأخطاء'`.
3. AppBar action: `IconButton` with `Icons.delete_outline` that calls `AppLogger.clearLog()`, shows `SnackBar` with `'تم مسح السجل'`, and calls `setState()` to reload.
4. Body: `FutureBuilder<String>` that calls `AppLogger.getLogContents()`.
   - On loading: show `CircularProgressIndicator`.
   - On data: show `SingleChildScrollView` → `SelectableText` with monospace font, padding 16.
   - On empty/error: show `Center` with `Text('لا توجد سجلات')`.
5. Import `core/logging/app_logger.dart`.

**Dependencies**: T002 (getLogContents() and clearLog() must exist).

**Verification**: Run `dart analyze` — 0 errors. Navigate to settings → tap log viewer → see log contents. Tap clear → log is cleared.

---

### T024: Update app_router.dart with settings screen imports and log viewer route

- [X] T024 Update `core/router/app_router.dart` to import new SettingsScreen and add log viewer route

**Objective**: Replace the placeholder import with the real SettingsScreen. Add a nested route for the log viewer.

**Files to update**:
- `core/router/app_router.dart`

**Scope**:
1. Change import from `'../../features/settings/presentation/placeholder_screen.dart'` to `'../../features/settings/presentation/settings_screen.dart'`.
2. Add import for `'../../features/settings/presentation/log_viewer_screen.dart'`.
3. Change the `/settings` route builder from `SettingsPlaceholderScreen()` to `SettingsScreen()`.
4. Add a new route: `GoRoute(path: '/settings/logs', builder: (context, state) => const LogViewerScreen())`.
5. Update the settings screen's log viewer `ListTile` onTap to use `context.push('/settings/logs')`.
6. Do NOT change any other routes.

**Dependencies**: T022 (SettingsScreen), T023 (LogViewerScreen).

**Verification**: Run `dart analyze` — 0 errors. Navigation works: `/settings` shows SettingsScreen, tapping log viewer navigates to `/settings/logs`.

---

## Phase 10: Polish & Cross-Cutting Concerns (No Story)

**Goal**: Final validation, dart analyze, documentation.

---

### T025: Run dart analyze and fix all errors/warnings

- [X] T025 Run `dart analyze` in `motaz_app/motaz_app_flutter` and fix all errors and warnings

**Objective**: Ensure the entire codebase is clean after all hardening changes.

**Files to update**: Any files with errors or warnings.

**Scope**:
1. Run `dart analyze` from `motaz_app/motaz_app_flutter`.
2. Fix any errors (must be 0).
3. Fix any warnings (must be 0).
4. Infos are acceptable (existing pre-Phase 9 infos are allowed).
5. Do NOT introduce new code — only fix issues.

**Dependencies**: All previous tasks.

**Verification**: `dart analyze` output shows 0 errors, 0 warnings.

---

### T026: Create known-limitations.md release deliverable

- [X] T026 Create `specs/009-hardening-release/known-limitations.md`

**Objective**: Document all known limitations, deferred features, and edge cases not covered in MVP. This is the release deliverable per spec SC-010.

**Files to create**:
- `specs/009-hardening-release/known-limitations.md` — **NEW FILE**

**Scope**:
Document these categories, using the constitution's Definition of Done as the checklist:
1. **Deferred Features**: Taxes, inventory tracking, multi-currency, due dates, staff roles, social login.
2. **Known Edge Cases**:
   - Device storage exhaustion → app shows generic error, not a specific storage warning.
   - Very large outbox (1000+ entries) → sync may take several minutes.
   - PDF generated from Profit Report does not exist yet (Phase 8 P2 tasks incomplete).
3. **Not Yet Implemented from Phase 8**:
   - 5 remaining reports (Sales by Product, Expenses by Type, Receivables, Aging, Party Balances).
   - Reports Hub navigation screen.
   - PDF templates for remaining reports.
4. **Platform Notes**:
   - Windows: desktop RTL layout tested but complex forms may need further polish.
   - Android: tested on single device model only.
5. **Sync Limitations**:
   - No automated conflict detection testing suite.
   - Void-wins rule implemented but not extensively stress-tested with real multi-device conflicts.

**Dependencies**: All previous verification tasks (T006, T007, T011–T016).

**Verification**: File exists and contains all categories above with clear, honest documentation.

---

### T027: Verify constitution Definition of Done checklist

- [X] T027 Verify all constitution DoD criteria against current app state

**Objective**: Final gate check — verify every item in the constitution's Definition of Done section applies to the current release candidate.

**Files to update**: None (verification only). Update `known-limitations.md` with any gaps.

**Scope**:
Check each DoD item from `.specify/memory/constitution.md` §Governance:
1. ✅ or ❌: Works fully offline and syncs correctly when connectivity returns.
2. ✅ or ❌: Works correctly on both Android and Windows.
3. ✅ or ❌: Preserves accounting correctness after create, edit, void, partial payment, partial return, and resync.
4. ✅ or ❌: Preserves audit history for every financial mutation.
5. ✅ or ❌: Includes local persistence, sync behavior, and conflict handling.
6. ✅ or ❌: Produces correct results in reports, client statements, and dashboard summaries.
7. ✅ or ❌: Avoids hard delete for financial records and verifies void behavior.
8. ✅ or ❌: Includes tests for calculation rules, balance effects, PDF generation, and sync/conflict edge cases.

For any ❌ items: document in `known-limitations.md` as a known gap with rationale.

**Dependencies**: T026 (known-limitations.md must exist).

**Verification**: All DoD items are explicitly checked. Any gaps are documented.

---

### T028: Final commit and push to GitHub

- [X] T028 Commit all changes and push `009-hardening-release` branch to GitHub

**Objective**: Commit all hardening work and push to remote.

**Files to update**: None (git operations only).

**Scope**:
1. `git add -A`
2. `git commit -m "feat(009): hardening & release readiness — logging, migration safety, sync recovery, conflict UX, audit trail, settings screen"`
3. `git push origin 009-hardening-release`

**Dependencies**: T025 (dart analyze must pass).

**Verification**: Branch pushed. GitHub shows the new commit.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately.
- **Phase 2 (US1)**: Depends on Phase 1 (T001, T002).
- **Phase 3 (US2)**: Depends on Phase 1 (T002).
- **Phase 4 (US3)**: Can start after Phase 2.
- **Phase 5 (US4)**: Depends on Phase 1 (T004, T005).
- **Phase 6 (US5)**: No dependencies — can start any time.
- **Phase 7 (US6)**: No dependencies — can start any time.
- **Phase 8 (US7)**: No dependencies — can start any time.
- **Phase 9 (Settings)**: Depends on Phase 1 (T001, T002), Phase 3 (T008).
- **Phase 10 (Polish)**: Depends on all previous phases.

### User Story Dependencies

- **US1 (Offline Resilience)**: Depends on logging setup (T001, T002).
- **US2 (Sync Recovery)**: Depends on logging setup (T002).
- **US3 (Cross-Platform)**: Can run in parallel after US1 verification.
- **US4 (Migration Safety)**: Depends on T003, T004, T005 from setup.
- **US5 (PDF Reliability)**: No dependencies — can start any time.
- **US6 (Conflict UX)**: No dependencies — can start any time.
- **US7 (Audit Trail)**: No dependencies — can start any time.

### Parallel Opportunities

Tasks marked `[P]` within the same phase can run in parallel. Additionally:
- T003 can run in parallel with T001 and T002.
- T006 and T007 can run in parallel (different platforms).
- T014, T015, T016 can run in parallel (different PDF scenarios).
- T020 and T021 can run in parallel (different files).
- T017 and T019 can run in parallel (different files).

---

## Implementation Strategy

### MVP First (P1 Stories)

1. Complete Phase 1: Setup (T001–T005)
2. Complete Phase 2: US1 (T006–T007) — verify offline resilience
3. Complete Phase 3: US2 (T008–T010) — sync recovery
4. Complete Phase 4: US3 (T011–T012) — cross-platform
5. **STOP and VALIDATE**: All P1 stories verified
6. Proceed to P2/P3 stories

### Incremental Delivery

1. Setup → Foundation ready
2. US1 → Offline resilience verified ✅
3. US2 → Sync recovery hardened ✅
4. US3 → Cross-platform validated ✅
5. US4 → Migration safety confirmed ✅
6. US5 → PDF edge cases covered ✅
7. US6 → Conflict UX Arabized ✅
8. US7 → Audit trail viewable ✅
9. Settings → Real settings screen ✅
10. Polish → Release candidate ready ✅

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story from spec.md
- All monetary values remain as minor-unit integers — no changes in this phase
- No new database tables — only 1 new index on existing table
- Financial conflicts are NEVER silently auto-merged — this phase validates, not changes
- Void-wins rule is validated, not modified
- All strings must be in Arabic per constitution §V
- Before implementing any task, read the constitution and spec documents — do not guess
