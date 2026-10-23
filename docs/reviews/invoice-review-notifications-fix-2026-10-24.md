# Invoice Search, Keyboard, and Settlement Review Notifications

Date: 2026-10-24

## Scope and Root Causes

- The settlement warning occupied a permanent row above the routed screen,
  including unsafe space near the system status bar. Its action navigated to
  distribution without selecting the first affected month.
- RawAutocomplete ignores controller changes during its selection callback.
  Clearing the search inside that callback left cached options behind; clearing
  an already empty controller later did not notify it again. Refocusing search
  after selection and invoice reset reopened suggestions and the keyboard.
- Both the outer app shell and quick invoice scaffold resized for keyboard
  insets, leaving little room for invoice lines on mobile.

## Implemented Behavior

### Product Search and Keyboard

- Leave search focus when adding a product. Clear its controller after the
  selection callback, allowing RawAutocomplete to discard the previous options.
- Reset the typed query, controller, and focus after saving or clearing an
  invoice. Starting another invoice does not reopen old results or the keyboard.
- Preserve asynchronous loading of the existing local product provider. A query
  typed before the first local result arrives still resolves without retyping.
- The quick invoice screen keeps its layout when the keyboard opens. The
  keyboard overlays the lower content and closes when a product is selected.
- The app shell no longer applies keyboard resizing itself. Other screens can
  retain their own scaffold's inset handling; invoice editing is unchanged.

### Settlement Review Reminder

- Display a floating, safe-area-aware notification above the routed content,
  without consuming layout space. Show affected month count and earliest month.
- Allow dismissal with the close icon; auto-dismiss after eight seconds.
- Remind when financial review data changes, when returning from the background,
  and every fifteen minutes while the app is in the foreground and reviews remain.
- Identical provider refreshes and ordinary route navigation do not reopen a
  dismissed notice. Hide it on the distribution screen and in the background.
- Reminders reuse cached review state. Timer callbacks do not invalidate
  providers, poll the database, or make remote requests. Cancel timers on disposal.
- The review action navigates with year/month query parameters to the earliest
  affected settlement. The distribution screen lists all affected months, allows
  selecting their previews, and names them in the approval confirmation.
- Direct navigation without a linked month selects the earliest pending review
  once. Explicit user selection or a linked period takes precedence afterward.
- Closing a reminder does not approve or discard settlements. Existing financial
  rules, chronological reapproval, missing-month catch-up, and withdrawal history
  remain unchanged. A backdated invoice does not necessarily mean its own month
  already has an approved settlement; the displayed list comes from the existing
  settlement review engine.

No backend changes, schema changes, migrations, or dependencies were added.
No Neon or Railway operation was performed. Local-first persistence and the
existing synchronization flow are unchanged.

## Regression Tests

Thirteen tests were added across three files under
`motaz_app/motaz_app_flutter/test/`:

`features/invoices/presentation/invoice_form_screen_test.dart`:

1. Selecting a product clears suggestions and dismisses the search keyboard.
2. Search waits for initial local data without requiring query reentry.
3. Keyboard insets do not squeeze the quick invoice's product table.
4. Repeated product selection and clearing leave no stale suggestions.
5. The actual app shell also preserves invoice space with keyboard insets.
6. Saving to a real, isolated local database resets the next invoice's search
   and keyboard, with the invoice pending and synchronization outbox populated.

`features/profit_distribution/presentation/settlement_review_notice_test.dart`:

1. Notification respects the system safe area and closes without resizing content.
2. Eight-second expiry and fifteen-minute reminders do not repeat provider queries.
3. Changed financial data reshows the notice; approval stops reminders.
4. Backgrounding hides reminders; resuming shows pending reviews again.
5. The action navigates to the earliest affected month and navigation does not
   repeatedly reopen the reminder.

`features/profit_distribution/presentation/distribution_screen_test.dart`:

1. Affected months are listed, the earliest is selected initially, and selecting
   another month updates both its preview and the month control.
2. A linked period takes precedence and confirmation names the affected months;
   cancellation performs no distribution writes.

Tests use controlled providers, fake keyboard insets/lifecycle events, and fake
timer advancement. Persistence tests use in-memory SQLite with foreign keys,
valid fixture IDs, and database stream completion rather than arbitrary sleeps.
The save-flow test advances the existing dialog's controller-disposal timer in
fake time; production dialog timing was not changed.

New tests were executed individually before proceeding. Initial failing runs
reproduced focus, layout, stale-option, and first-load-search problems. Test setup
corrections included finding the underlying client TextField, using valid UUID
fixtures, and asserting selected period behavior rather than requiring a
redundant provider load when a cached result was available.

## Verification Observed

Run from `D:\dev\Motaz_App\motaz_app\motaz_app_flutter`:

```powershell
flutter --no-version-check test --no-pub test/features/invoices/presentation/invoice_form_screen_test.dart
flutter --no-version-check test --no-pub test/features/profit_distribution/presentation/settlement_review_notice_test.dart
flutter --no-version-check test --no-pub test/features/profit_distribution/presentation/distribution_screen_test.dart
flutter --no-version-check test --no-pub
flutter --no-version-check build bundle --debug --no-pub
```

The new cases were run directly with `--plain-name` during development. After
the final changes, the full Flutter suite reported **108 tests passed** and
debug bundle compilation exited successfully with code 0. This was not an APK
or Windows release build, and no physical-device or emulator E2E run was made.
Analyze and format commands were deliberately not executed, as requested.

## Manual Follow-Up

1. Rebuild and install the app without clearing its existing local data.
2. Search for a product on mobile, select it, and confirm the list and keyboard
   close while the line remains. Refocus the empty field: no old results appear.
3. Add the same product again, save the invoice, then start another invoice.
   Search remains empty, without the old dropdown or an automatically opened
   keyboard. Test the clear action too.
4. Open the keyboard while invoice lines are present. The invoice layout should
   retain its space; dismiss the keyboard to access content it overlays.
5. Change a backdated invoice that affects approved settlement data. Confirm the
   notice appears below the system status bar and closes using X or after eight
   seconds, without moving the invoice content.
6. Tap the review action and verify the earliest affected month is selected.
   Check all listed months and the confirmation before approving any change.
7. Dismiss the notice, navigate between sections, then background and resume the
   app. A pending review should remind again on resume. After all affected
   settlements are approved, no further reminder should appear.

Optional manual formatting and analysis commands from the frontend directory:

```powershell
dart format lib/core/router/app_router.dart lib/shared/widgets/app_drawer.dart lib/features/invoices/presentation/invoice_form_screen.dart lib/features/profit_distribution/presentation/distribution_screen.dart lib/features/profit_distribution/presentation/settlement_review_notice.dart
dart format test/features/invoices/presentation/invoice_form_screen_test.dart test/features/profit_distribution/presentation
flutter analyze
```

Only rebuilding the frontend is needed to receive these changes. They do not
require a Neon migration or Railway redeployment.
