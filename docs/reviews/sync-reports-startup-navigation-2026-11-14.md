# Sync, Export, Startup And Navigation Repairs

## Confirmed Causes

1. Invoice details missing after reset: client pull excluded SALES_INVOICE_LINE,
   RECEIPT_ALLOCATION and SALES_RETURN_LINE. The server also returned no rows for
   entities without rowVersion. Headers and totals could therefore restore while
   their children never did. This affects manually entered data too; an imported
   invoice note is not evidence that the migration deleted its product rows.
2. Unnecessary visible refresh: every pulled row was rewritten and notified even
   when identical. Independent row versions were also incorrectly treated as a
   global watermark, potentially missing newly created records with version 1.
   Router reconstruction on auth notifications added a separate refresh source.
3. Online startup waited for network authentication/account checks before local
   navigation. Restoring cached authentication itself is local.
4. Top-level route replacement left Android with no previous page. Root back
   needed explicit home/exit behavior while preserving nested navigation.
5. Missing-client creation existed in the full invoice form but was not exposed
   in the final quick-save dialog.

## Implemented Behavior

- Pull restores product/client/header dependencies before invoice lines, receipt
  allocations and return lines. Child rows do not receive nonexistent local
  sync_status or row_version columns. Pending local child or parent changes win
  over remote snapshots until their mutation is resolved.
- Each received page is applied transactionally; identical row snapshots cause
  no writes or table notifications. Genuine numeric changes still notify the UI.
- The existing integer pull cursor now represents updatedAt microseconds, not a
  record's optimistic-concurrency rowVersion. Server rows still contain their
  real rowVersion for conflict handling. Timestamp boundaries replay inclusively
  between cycles, and timestamp/UUID keyset ordering paginates equal timestamps.
  Old small cursors naturally backfill rows on the first updated-server pull.
- Router identity remains stable across auth notifications. Home/dashboard retain
  previous values during background refresh instead of replacing content.
- Auth restores local state before remote checks. Background transient failures
  do not revoke local access. Revision/disposal checks reject stale responses.
- Back closes dialogs/drawers or pushed subflows first, then returns sections to
  home. At home a second back within two seconds opens an Arabic exit/cancel
  dialog. Only explicit confirmation invokes SystemNavigator.pop.
- Quick-save invoice client entry shows the missing-client prompt, reuses the
  centered creation dialog, saves locally/outbox, and selects the created client
  without discarding products or paid amount. Dialog controller disposal waits
  for route completion rather than an arbitrary sleep.

## Report Export

The export pipeline uses background PDF workers, bounded attachment loading,
cached packaged fonts and a shared multipage policy. Statement tables are allowed
to span pages. Export failures/timeouts return the button to an actionable state.
All report callers, including export from expense history, must use this shared
request pipeline. Oversized/missing images produce an explicit warning rather
than omitting financial rows. Limits are not silent financial-data truncation.

## Verification And Limits

Targeted tests reproduce a fresh database pull and verify quantities, unit prices,
allocations, return lines and the final monthly product breakdown. Other tests
protect no-op update suppression, genuine changes, pending local edits, cursor
selection, blocked-network startup, back/exit behavior and mobile client creation.
Each newly added focused test was run directly before continuing.

Observed final results:

- Full Flutter suite: **201 tests passed**, exit code 0. This includes 43 new
  tests above the previous 158-test baseline.
- Backend service and contract suite: **21 tests passed**, exit code 0,
  including two new cursor/child-query tests.
- Debug bundle build: exit code 0. `git diff --check`: exit code 0.
- A 120-entry Arabic statement generated six PDF pages. Its first and last pages
  were rendered with Poppler and visually checked for table continuation,
  repeated headers and readable totals without clipping.

Commands actually executed:

```powershell
flutter --no-version-check test --no-pub --concurrency=1
flutter --no-version-check build bundle --debug --no-pub
dart test test/services test/contracts
git diff --check
```

Specialized scopes were split between startup/auth, navigation/back, and report
exports; parent work covered client/server pull, no-op refresh, dashboard reload,
invoice client creation and final integration. All worked on separate files.

No production Neon database, imported records or secrets were read or changed.
No new package dependencies, migrations or generated protocol changes are needed.
PostgreSQL integration was not run: Docker's Linux engine is unavailable on this
machine. Backend service/contract tests are isolated and do not access Neon.
Physical Android performance and native predictive-back behavior still require
the acceptance checks below; desktop tests are not a live-device performance claim.

This fixes missing child pulls, not historical cloud rows that were never saved
or were already duplicated by earlier invoice-line replacement. No guessing or
destructive automatic repair of imported financial data is performed. The
existing periodic full reconciliation remains a recovery path for older/backdated
changes. Separate sync requests are not a distributed atomic transaction.

## Deploy And Recover Without Resetting

1. Back up current local and cloud data before changing deployed code.
2. Deploy the updated backend to the same intended Neon branch. Both backend and
   Flutter changes are required; updating only the APK leaves the old server
   refusing child pulls. No new schema migration is required for these fixes.
3. Build/install the updated APK over the current installation, preserving local
   data. Do not reset Neon, uninstall the app, or clear local pending transactions.
4. Run sync. Previously missing child entity cursors start at zero automatically.
   Existing invoices and their cloud product rows should recover without manual
   re-entry. Keep the app open for the initial backfill and inspect sync errors.
5. Check a known invoice's product, quantity, price, total, received payment and
   remaining balance. Then check the monthly report's product breakdown.
6. Export a client statement for a small period, then a two-month period with
   photos. Test sales, expenses, products, receivables, samples and monthly PDF.
   Check any image warning and the actual saved file, not only the success label.
7. Open online with a previously saved session; confirm local entry does not wait
   for server response. Test offline entry and reconnect while observing values.
8. Check back from each main section, nested forms and drawer. At home test one
   back, two backs, Cancel, and explicit Exit on the physical Android device.

## Manual Commands

Formatting and analysis remain manual at the owner's request:

```powershell
Set-Location 'D:\dev\Motaz_App\motaz_app\motaz_app_server'
dart analyze
dart test test/services test/contracts

Set-Location 'D:\dev\Motaz_App\motaz_app\motaz_app_flutter'
dart format lib test
flutter analyze
flutter test --no-pub --concurrency=1
flutter build apk --release
```

APK location: `build/app/outputs/flutter-apk/app-release.apk`.
No release APK build, git commit/push or Railway deployment is implied by local
test results. Those operational actions must be explicitly performed afterward.

## Analysis Follow-up

The five owner-reported analyzer diagnostics were addressed with a mounted
context guard, a direct `BytesBuilder` import, wildcard callback parameters and
removal of the redundant test import. No business logic or schema changed.

The affected tests were rerun after these edits: **21 tests passed**, exit code 0.

```powershell
flutter --no-version-check test --no-pub --concurrency=1 test/core/router/app_back_button_dispatcher_test.dart test/features/reports/pdf/pdf_worker_test.dart test/features/reports/pdf/report_attachment_loader_test.dart
```

Analysis and formatting were not run; they remain manual. Git staging, commit,
push and Railway deployment were not performed.
