# Implementation Plan: Hardening & Release Readiness

**Branch**: `009-hardening-release` | **Date**: 2026-04-20 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/009-hardening-release/spec.md`

## Summary

Phase 9 is the final hardening pass before the MVP release candidate. No new features are added — instead, this phase strengthens the resilience, correctness, and usability of all existing features from Phases 1–8. The work spans 7 areas: logging infrastructure, sync recovery hardening, migration safety, conflict resolution UX polish, audit trail viewer, PDF edge-case reliability, and cross-platform QA. The deliverable is a release candidate with a known limitations document.

## Technical Context

**Language/Version**: Dart 3.8+ / Flutter 3.32+  
**Primary Dependencies**: flutter_riverpod, drift, go_router, pdf (^3.11.1), printing (^5.13.3), logging, connectivity_plus, path_provider  
**Storage**: SQLite via Drift (existing schema v4, no new tables)  
**Testing**: Manual QA matrix (Android + Windows), `dart analyze`, flutter_test for unit tests  
**Target Platform**: Android + Windows  
**Project Type**: Mobile/Desktop app (Flutter)  
**Performance Goals**: Dashboard < 3s, reports < 5s, PDF < 10s, cold start < 5s Android / 3s Windows  
**Constraints**: Offline-first, Arabic-first RTL, no cloud crash reporting, local error log only  
**Scale/Scope**: ~1000+ records per table, 2 devices, 1 owner

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Status | Evidence |
|------|--------|----------|
| Offline-first (§II) | ✅ PASS | No internet-dependent features added. Log file is local. Migration backup is local. |
| No hard delete (§II) | ✅ PASS | No deletes introduced. Log rotation truncates logs, not financial data. |
| Single-currency YER (§I) | ✅ PASS | No currency changes. Audit display uses existing money formatter. |
| Minor-unit integers (§I) | ✅ PASS | No new monetary logic. Audit snapshot preserves raw integer values. |
| Financial conflicts not auto-merged (§II) | ✅ PASS | Conflict resolution UX is being polished, not changed. Void-wins rule is validated. |
| Arabic-first (§V) | ✅ PASS | Conflict resolution screen Arabized. Settings screen in Arabic. |
| PDF for reports+statements (§IV) | ✅ PASS | PDF templates validated for edge cases (empty, large, long names). |
| Audit history (Governance) | ✅ PASS | Audit trail viewer added per FR-025. |
| Cross-platform (§III) | ✅ PASS | QA matrix validates Android + Windows. |

No gate violations.

## Project Structure

### Documentation (this feature)

```text
specs/009-hardening-release/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output (no new entities)
├── quickstart.md        # Phase 1 output
├── contracts/           # N/A (no external interfaces)
├── known-limitations.md # Release deliverable
└── tasks.md             # Phase 2 output (via /speckit.tasks)
```

### Source Code (repository root)

```text
motaz_app/motaz_app_flutter/lib/
├── core/
│   ├── database/
│   │   ├── app_database.dart        # [MODIFY] Add pre-migration backup
│   │   └── tables/*.dart            # [MODIFY] Verify/add date indexes
│   ├── logging/
│   │   └── app_logger.dart          # [MODIFY] Fix path, add rotation, structured format
│   └── router/
│       └── app_router.dart          # [MODIFY] Update settings + conflict routes
├── features/
│   ├── settings/
│   │   └── presentation/
│   │       ├── settings_screen.dart # [MODIFY] Replace placeholder with real screen
│   │       └── log_viewer_screen.dart # [NEW] Log viewer
│   ├── sync/
│   │   ├── application/
│   │   │   ├── sync_coordinator.dart  # [MODIFY] Transient error handling
│   │   │   └── outbox_processor.dart  # [VERIFY] Edge cases
│   │   └── presentation/
│   │       ├── sync_status_badge.dart  # [MODIFY] Add info bottom sheet
│   │       └── conflict_resolution_screen.dart # [MODIFY] Arabize, device labels
│   └── [all financial features]/     # [VERIFY] Audit event emission
└── shared/
    └── widgets/
        └── audit_trail_sheet.dart     # [NEW] Reusable audit history bottom sheet
```

**Structure Decision**: Feature-First Modular Monolith — unchanged. All modifications are within existing feature boundaries. Two new files are added: `log_viewer_screen.dart` and `audit_trail_sheet.dart`.

---

## Detailed Design

### Component 1: Logging Infrastructure (FR-030, FR-031)

**Current State**: `AppLogger` writes to `motaz_app.log` next to the executable. Works on Windows but fails on Android (APK path not writable).

**Changes**:

#### `app_logger.dart` — Fix and Enhance

1. **Fix log file path**: Use `path_provider`'s `getApplicationDocumentsDirectory()` on all platforms (already a dependency).
2. **Structured format**: `[2026-04-20T10:30:15] [WARNING] [motaz.sync]: Sync cycle error: SocketException`
3. **Log rotation**: Before opening, check file size. If > 1 MB, rename to `.log.1` (keep max 2 files). Simple, no external dependency.
4. **Add a `sync` logger**: `static final Logger sync = Logger('motaz.sync');` — dedicated category for sync events.
5. **Expose `getLogContents()` method**: Returns the log file contents as a `Future<String>` for the viewer.
6. **Expose `clearLog()` method**: Truncates the log file.

#### `settings_screen.dart` — Replace Placeholder

Replace the `SettingsPlaceholderScreen` with a real settings screen containing:
- App version info
- Log viewer button → navigates to `LogViewerScreen`
- Manual sync trigger button
- Device info (device ID, device code)

#### `log_viewer_screen.dart` — New

A simple screen that:
- Reads log file contents via `AppLogger.getLogContents()`
- Displays in a scrollable, selectable text area (monospace font)
- Has a "Clear" button that calls `AppLogger.clearLog()` and refreshes
- Arabic title: "سجل الأخطاء"

---

### Component 2: Sync Recovery Hardening (FR-004 – FR-008)

**Current State**: `SyncCoordinator.runSyncCycle()` catches all exceptions generically. `OutboxProcessor` has proper retry/backoff. `SyncStatusBadge` shows basic states.

**Changes**:

#### `sync_coordinator.dart` — Transient Error Handling

1. **Wrap network calls with explicit catch for `SocketException`, `TimeoutException`**: On transient errors, keep outbox entries as PENDING (don't transition to error state). Log the error.
2. **Add `_lastSyncAttempt` timestamp**: Prevents rapid re-sync attempts during connectivity flapping.
3. **Minimum 10-second cooldown between sync cycles**: Prevent battery drain from constant retries.

#### `sync_status_badge.dart` — Info Bottom Sheet

1. **On tap (any state)**: Show a `showModalBottomSheet` with:
   - Sync status label (Arabic: "متزامن" / "قيد المزامنة" / "خطأ في المزامنة")
   - Pending mutations count
   - Failed mutations count
   - Last sync timestamp (formatted in Arabic locale)
   - Conflict count (if > 0, with link to conflict resolution)
   - Manual retry button (visible when failed > 0)
2. **Keep existing color coding**: Green = synced, spinner = syncing, red = error, orange = conflicts.

#### `outbox_processor.dart` — Verification Only

The existing implementation is sound (exponential backoff, max 5 retries, permanent error detection). Verification confirms:
- ✅ `maxRetryCount = 5`
- ✅ `_computeCumulativeDelay()` uses exponential backoff with jitter
- ✅ `_isPermanentError()` catches UNAUTHENTICATED, UNKNOWN_DEVICE, VALIDATION_ERROR, ENTITY_NOT_FOUND
- ✅ `retryFailed()` resets FAILED entries to PENDING with retryCount = 0

---

### Component 3: Migration Safety (FR-012 – FR-014)

**Current State**: `app_database.dart` has `MigrationStrategy` with `onUpgrade` that runs CREATE/ALTER statements. No backup mechanism.

**Changes**:

#### `app_database.dart` — Pre-Migration Backup

1. **Before `onUpgrade` runs**: Copy `motaz_app.db` to `motaz_app.db.backup` using `File.copy()`.
2. **Wrap `onUpgrade` internals in try/catch**: If any migration step throws, log the error and show a user-friendly message.
3. **On migration failure**: The original file is preserved as `.backup`. The DB state is undefined, so the app shows an error screen prompting the user to contact support.
4. **On successful migration**: Delete the `.backup` file to save space.

The implementation requires modifying the `_openConnection()` function to inject backup logic before Drift opens the database, or using Drift's `beforeOpen` callback.

---

### Component 4: Conflict Resolution Polish (FR-019 – FR-022)

**Current State**: `ConflictResolutionScreen` is functional with side-by-side payload diff, "Choose Local" / "Choose Remote" buttons, and confirmation dialog. All labels are English.

**Changes**:

#### `conflict_resolution_screen.dart` — Arabize & Enhance

1. **Translate all strings to Arabic**:
   - "Conflict Resolution" → "حل التعارضات"
   - "Local" / "Remote" → Device names from `devices` table (e.g., "هاتف Android" / "لابتوب Windows")
   - "Choose Local" → "اختيار نسخة هذا الجهاز"
   - "Choose Remote" → "اختيار النسخة الأخرى"
   - "No pending conflicts" → "لا توجد تعارضات معلقة"
   - Confirmation dialogs → Arabic text

2. **Add device name resolution**: Query `devices` table using `deviceId` from the conflict's local/remote payload to get human-readable device names.

3. **Add timestamps to payload cards**: Show `createdAt` and `updatedAt` for both local and remote versions.

4. **Add void-wins indicator**: If the conflict was auto-resolved by void-wins, display a banner explaining: "تم الحل تلقائياً — الإلغاء له الأولوية".

---

### Component 5: Audit Trail Viewer (FR-023 – FR-025)

**Current State**: `AuditEvents` table exists with proper indexes. Events are recorded during financial mutations (verified by checking existing create/edit/void flows). No viewer UI.

**Changes**:

#### `audit_trail_sheet.dart` — New Shared Widget

A reusable `showAuditTrailSheet()` function that:
1. Accepts an `entityType` (ParentEntityType) and `entityId` (String)
2. Queries `audit_events` WHERE `entity_type = ? AND entity_id = ?` ORDER BY `created_at DESC`
3. Displays a `DraggableScrollableSheet` with:
   - Arabic title: "سجل التعديلات"
   - List of audit event cards showing:
     - Operation type icon (add = green, edit = blue, void = red)
     - Operation label (Arabic: "إنشاء" / "تعديل" / "إلغاء")
     - Timestamp (formatted)
     - Device name (from device ID lookup)
     - Changed fields summary (parsed from `diffData` JSON)

#### Integration Points

Add a trailing icon button (🕐 history icon) to the detail/list-tile views of:
- Invoice detail → `audit_trail_sheet(ParentEntityType.SALES_INVOICE, invoiceId)`
- Receipt detail → `audit_trail_sheet(ParentEntityType.RECEIPT, receiptId)`
- Expense detail → `audit_trail_sheet(ParentEntityType.EXPENSE, expenseId)`
- Return detail → `audit_trail_sheet(ParentEntityType.SALES_RETURN, returnId)`

---

### Component 6: Performance Optimization (FR-026 – FR-029)

**Changes**:

#### Index Verification

Verify these indexes exist in the Drift table definitions:

| Table | Index | Status |
|-------|-------|--------|
| `sales_invoices` | `invoice_date` | Needs verification |
| `sales_invoices` | `client_id` | Needs verification |
| `receipts` | `receipt_date` | Needs verification |
| `expenses` | `expense_date` | Exists ✅ (`idx_expense_date`) |
| `expenses` | `expense_category` | Exists ✅ (`idx_expense_category`) |
| `sync_outbox` | `status` | Needs verification |
| `conflict_logs` | `resolution_status` | Needs verification |

Add `@TableIndex` annotations for any missing indexes.

#### Query Optimization

Review dashboard queries in `dashboard_queries.dart` for any full-table scans. The existing queries use date filters and status filters — indexes on those columns will eliminate sequential scans.

#### Cold Start Profiling

Measure app startup time on both platforms. If > target (5s Android, 3s Windows), profile with `dart:developer` timeline and identify bottlenecks (typically: database open, initial query, font loading).

---

### Component 7: PDF Edge-Case Hardening (FR-015 – FR-018)

**Changes**:

#### All PDF Templates

1. **Empty state**: Verify each template handles `data.rows.isEmpty` gracefully (existing sales template does ✅).
2. **Long text wrapping**: Test with 40+ character Arabic client names. The `pdf` package's `pw.Text` auto-wraps by default — verify no overflow in constrained column widths.
3. **Large dataset pagination**: Verify `pw.MultiPage` correctly repeats headers on page breaks for all table-based reports.
4. **Font embedding**: Verify Cairo-Regular.ttf and Cairo-Bold.ttf are loaded in all PDF templates (existing `PdfStyles.load()` handles this ✅).

No code changes expected — this is validation only unless issues are found.

---

### Component 8: Cross-Platform QA & Known Limitations

**Changes**:

#### Manual Test Matrix

Create a structured checklist covering every acceptance scenario from the spec, executed on both Android and Windows:

1. **Offline workflow**: Create invoice → receipt → expense → PDF while offline
2. **Restart recovery**: Force-quit after creating data, reopen, verify persistence
3. **Sync cycle**: Create on Device A, sync, verify on Device B
4. **Conflict scenario**: Edit same financial field on both devices, verify conflict UI
5. **PDF generation**: All 8 reports + client statement with empty/normal/large data
6. **RTL layout**: Verify all screens on Windows (desktop RTL tends to have more issues)
7. **Dashboard accuracy**: Verify all 9 KPIs match manual calculations

#### `known-limitations.md` — Release Deliverable

Document all known limitations, deferred features, and edge cases that aren't covered in MVP. Based on constitution's Definition of Done check.

---

## Implementation Phases

| Phase | Scope | Dependencies |
|-------|-------|--------------|
| **1. Logging** | AppLogger fix, settings screen, log viewer | None |
| **2. Migration Safety** | Pre-migration backup in app_database.dart | None |
| **3. Sync Hardening** | Coordinator transient errors, badge bottom sheet | Phase 1 (logging) |
| **4. Performance** | Index additions, cold start profiling | None |
| **5. Conflict UX** | Arabize conflict screen, device labels | None |
| **6. Audit Trail** | Audit trail sheet widget, integration points | None |
| **7. PDF Validation** | Edge-case testing across all templates | None |
| **8. Cross-Platform QA** | Full test matrix on both platforms | Phases 1–6 |
| **9. Release Deliverables** | Known limitations doc, final constitution DoD check | Phase 8 |

## Complexity Tracking

No constitution violations. No complexity justifications needed.
