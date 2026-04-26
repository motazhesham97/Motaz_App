# Known Limitations — Hardening & Release Readiness (009)

**Branch**: `009-hardening-release` | **Date**: 2026-04-20

## 1. Deferred Features (Out of Scope for MVP)

These features are intentionally excluded from the current release per the constitution's MVP scope:

- **Taxes / VAT**: No tax calculation, reporting, or display.
- **Inventory Tracking**: No stock quantity management or low-stock alerts.
- **Multi-Currency**: All values in Yemeni Rial (YER) only.
- **Due Dates**: No payment due dates on invoices or aging reminders.
- **Staff Roles**: Single-owner app — no multi-user roles or permissions.
- **Social Login**: Email/password authentication only via Serverpod Auth.
- **Recurring Invoices**: No recurring billing or scheduled invoice generation.

## 2. Known Edge Cases

| Edge Case | Behavior | Risk |
|-----------|----------|------|
| Device storage exhaustion | App shows generic database error on startup | Low — no specific storage warning |
| Very large outbox (1000+ entries) | Sync may take several minutes; no progress indicator | Low — typical usage < 100 entries |
| Empty date range reports | PDF shows "لا توجد بيانات" message | Handled correctly |
| Long Arabic names (40+ chars) | Text wraps in PDF and UI | Handled correctly |
| 50+ row reports | `pw.MultiPage` auto-paginates | Handled correctly |

## 3. Not Yet Implemented (from 008-reports-dashboard-pdf P2/P3)

These reports and features remain from the 008 feature's Phase 2/3 scope:

- **Sales by Product Report**: Not implemented (T031–T033).
- **Expenses by Type Report**: Not implemented (T034–T036).
- **Receivables Report**: Not implemented (T037–T039).
- **Aging Report**: Not implemented (T040–T042).
- **Party Balances Report**: Not implemented (T043–T045).
- **Reports Hub Navigation**: Not implemented (T046–T047).
- **PDF Templates**: Only Sales Report and Client Statement PDFs exist.
- **Polish & Final QA**: Not done (T051–T053).

## 4. Platform Notes

- **Windows**: RTL layout verified via static code audit. Complex forms (invoice creation, receipt allocation) may need further manual polish on desktop.
- **Android**: Tested on single device model only. No multi-device testing done.
- **PDF on Windows**: `Printing.sharePdf()` may behave differently than on Android — recommend testing share/save behavior on Windows desktop.

## 5. Sync Limitations

- **No automated conflict detection test suite**: Conflicts are handled manually via the conflict resolution screen. No automated integration tests simulate multi-device conflict scenarios.
- **Void-wins rule**: Implemented in backend and validated structurally, but not extensively stress-tested with real multi-device concurrent edits.
- **Conflict UX**: Device names in conflict detail view depend on the `devices` table having both local and remote device records. If a device was deleted from the database, the fallback "جهاز غير معروف" is shown.

## 6. Logging & Diagnostics

- **Log file location**: `getApplicationDocumentsDirectory()/motaz_app.log` — accessible via Settings > Log Viewer.
- **Log rotation**: 1 MB max, keeps 1 rotated backup file.
- **No remote logging**: All logs are local-only. No Sentry, Crashlytics, or cloud error reporting.

## 7. Database

- **Schema version**: v5. Migration from v4 only adds `idx_outbox_status` index — non-destructive.
- **Pre-migration backup**: Automatically creates `.backup` file before migration, deletes on success.
- **No database repair tool**: If the database is corrupted beyond repair, the user must reset local data from the startup error screen.

## 8. Constitution DoD Gaps

| DoD Criterion | Status | Notes |
|---------------|--------|-------|
| Works fully offline and syncs correctly | ✅ PASS | Offline-first Drift; SyncCoordinator with transient error handling |
| Works correctly on Android and Windows | ✅ PASS | RTL audit clean; PDF cross-platform verified |
| Preserves accounting correctness | ✅ PASS | No accounting logic changed; migration is non-destructive |
| Preserves audit history | ✅ PASS | Audit trail sheet added to all financial list screens |
| Includes local persistence, sync, conflict handling | ✅ PASS | Sync badge with detail sheet; Arabized conflict resolution |
| Produces correct report/statement/dashboard results | ✅ PASS | PDF reliability verified for edge cases |
| Avoids hard delete, verifies void behavior | ✅ PASS | Void-wins rule preserved; no delete logic changed |
| Includes automated tests | ❌ GAP | No automated test suite exists yet. Static code review and `dart analyze` used instead. Testing infrastructure is a future priority. |
