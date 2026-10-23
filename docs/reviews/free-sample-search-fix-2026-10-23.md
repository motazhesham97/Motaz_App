# Free Sample Search Regression Fix

Date: 2026-10-23

## Root Causes

- Product and beneficiary search compared a complete query against a single
  name word. Adding a second word therefore removed valid matches.
- The form truncated both suggestion lists to six entries. The beneficiary
  repository independently truncated search results to twelve entries.
- Typing an existing beneficiary's full name hid the create action without
  selecting that beneficiary, leaving the save action disabled.
- Newly created beneficiaries were missing from the open dialog's snapshot,
  so clearing and retyping the name could not find them in that same dialog.
- Exact-name lookup treated different internal spacing as different names.

## Changes

- Share name normalization and word-prefix matching between the form and
  beneficiary repository. Every query word must match a name-word prefix;
  repeated whitespace and letter case are ignored. Blank queries match nothing.
- Remove arbitrary result caps; matching products remain in the form's scroll
  view and beneficiaries remain in the dialog's scroll view.
- Select an exact beneficiary automatically, hide its suggestions after
  selection, and clear the selection when the user changes to another name.
- Add a newly created beneficiary to the dialog's local list immediately and
  disable input while creation is pending.
- Reuse beneficiaries with the same normalized name instead of creating an
  extra record and sync operation.
- Use the existing end-of-frame focus cleanup pattern for dialog confirmation
  and cancellation instead of a fixed 260 ms delay.
- Preserve creation of a genuinely different name even when it is a prefix
  of an existing beneficiary's name.

No schema changes, backend changes, new dependencies, or production database
operations are involved. All reads and writes remain local-first.

## Regression Tests

Added four widget tests in
`motaz_app/motaz_app_flutter/test/features/free_samples/presentation/free_sample_form_screen_test.dart`:

1. Product results survive typing the second word and full name.
2. All ten matching products are available, including selecting the last one;
   selecting a result clears the search and its suggestions.
3. A saved non-client beneficiary is found by a multiword query; exact-name
   typing enables saving and changing to an unrelated name disables it.
4. Create a beneficiary, clear and search again in the same dialog, then save
   two samples using that beneficiary while offline. Verify one beneficiary,
   two local samples, and pending outbox entries for the beneficiary, samples,
   and lines. No real server is contacted.

Added three repository tests in
`motaz_app/motaz_app_flutter/test/features/free_samples/data/beneficiary_repository_test.dart`:

1. Multiword prefixes, normalized whitespace, inactive exclusion, and empty or
   nonmatching queries.
2. Return fourteen matching beneficiaries without truncation.
3. Reuse a beneficiary despite different internal spacing, without duplicate
   local records or outbox entries.

Tests use isolated in-memory SQLite databases with foreign keys enabled,
controlled offline connectivity, and a fixed device service. Database streams
provide completion signals; no arbitrary sleeps are used. New tests were run
individually before proceeding. Initial failures reproduced the search and
selection bugs. Test-only fixes addressed scrolling before tapping, async
database completion, snackbar dismissal between saves, and watcher cleanup.

## Verification

Run from `D:\dev\Motaz_App\motaz_app\motaz_app_flutter`:

```powershell
flutter --no-version-check test --no-pub test/features/free_samples/presentation/free_sample_form_screen_test.dart
flutter --no-version-check test --no-pub test/features/free_samples/data/beneficiary_repository_test.dart
flutter --no-version-check test --no-pub
```

Observed full-suite result: **95 tests passed**, including seven new tests.
Individual tests were run with `--plain-name` during development.
The full suite was also rerun after the final behavioral adjustment.

Per the user's standing instruction, analyze and format commands were not run.
Native-device manual verification and release builds were not performed.

## Manual Device Check

1. Search a common product word and scroll to a previously hidden result.
2. Type a product's second word and full name; select it and confirm the list
   disappears while the selected product remains in the sample.
3. Create a non-client beneficiary, clear the input, and find it again by a
   partial multiword name without closing the dialog.
4. Save the sample, start another, and select the same beneficiary. Also try
   typing its full name without tapping a suggestion; Save should be enabled.
5. Repeat while offline, then reconnect through the normal synchronization
   flow. Automated tests here verify local persistence and outbox creation,
   not a live production synchronization session.

Existing installed apps need a rebuilt APK or Windows release to receive the
fix. This change does not require a Neon migration or Railway redeployment.
