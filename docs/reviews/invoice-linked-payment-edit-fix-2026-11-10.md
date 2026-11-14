# Invoice And Linked Payment Editing

The payment upper-limit and cross-client general-allocation restrictions described
here were superseded by the owner's 2026-11-11 workflow clarification. See
[Invoice Payment And Client Credit](invoice-payment-credit-2026-11-11.md) for the
current behavior. This file retains the earlier implementation history.

## Scope And Root Cause

Invoice updates previously changed the invoice client without updating linked
receipts. Client balances use receipt ownership, so changing an invoice from
Queen Arwa to Tayba left its payment credited to the wrong client. The invoice
edit screen also hid the paid amount and enforced the old collected amount as
a fixed minimum, preventing a simultaneous payment correction.

No production data was accessed or modified. No dependencies, database schema,
generated clients, backend code, or migrations were changed.

## Implemented Behavior

- Invoice editing loads the current amount from active invoice-linked receipts.
  Save is disabled until this read succeeds; a failed read supports retry.
- Invoice, linked receipt ownership/amounts, allocations, and outbox mutations
  commit in one local Drift transaction. Failure rolls back the entire edit.
- Existing receipt IDs, local references, official numbers, dates, notes, and
  originating device IDs are preserved. An invoice edit is a correction, not
  creation of a duplicate receipt.
- With several linked receipts, earlier payments are retained where possible;
  the remaining amount is assigned to the final payment. Unneeded payments are
  voided with a reason. New positive payments on an unpaid invoice create a
  linked receipt using the existing sequence and creation path.
- Setting paid to zero voids the active linked receipts and queues zero-value
  allocation mutations so an old allocation does not remain effective remotely.
- Valid existing overpayment credit is preserved. Allocations cannot exceed
  invoice capacity; unchanged receipt amounts still have their allocations
  recalculated if capacity changes. New excessive amounts are rejected.
- General/FIFO receipt allocations are not counted as direct linked payments or
  silently transferred to another client. A cross-client move with such active
  allocations is rejected atomically and requires reviewing the general receipt.
- The existing restriction on financial edits with active returns remains.
- Re-saving an invoice whose client was previously changed repairs its mismatched
  active linked receipts even if its current client is not changed again.
- A linked receipt displays the current invoice client and provides an edit icon
  that opens the invoice editor. Returning reloads the receipt's client and
  payment; direct amount/date/note editing remains supported. Client identity is
  not made independently editable in a way that could detach it from the invoice.

## Sync And UI Safeguards

- Unchanged invoice lines retain their IDs and do not enqueue new line CREATEs
  during client/payment-only edits.
- Repeated offline edits retain the original server base row version and push
  the latest invoice/receipt snapshots.
- Invoice lines, linked receipts, and allocations wait for pending/failed invoice
  mutations. Allocations also wait for their receipt. Parent conflicts block the
  child pushes while retaining the local corrections.
- Allocation CREATE/UPDATE snapshots coalesce so an older retry cannot overwrite
  a newer zero allocation. Equal SQLite timestamps use local insertion order.
- The edit form no longer changes the product text controller during build or
  searches again for its already-selected product. The totals row wraps on a
  narrow mobile layout without overflowing.

## Verification

Twenty new deterministic tests were created and run incrementally. They cover
client transfer and both balances, paid/total corrections, zero payments, new
payments without duplicates, legacy repair, multiple receipts, general-payment
guards, rollback on validation and queue failure, unchanged line identities,
transient sync failure/retry, parent conflicts, allocation supersession, repeated
offline edits, overpayment credit, capacity expansion, and the form navigation.

Observed successful commands, from the Flutter package directory:

```powershell
flutter --no-version-check test --no-pub --reporter expanded
flutter --no-version-check build bundle --debug --no-pub
```

Full suite: 134 tests passed. Debug bundle compilation: exit code 0.
The network boundary was replaced with controlled push responses in sync tests;
these results are not a real-device or live-Neon E2E verification.

## Existing Invoice Repair

1. Build and install the updated app over the existing installation. Do not
   clear its local data or reset Neon to repair this issue.
2. Open the affected invoice already assigned to Tayba.
3. Confirm invoice total 13,500 and paid amount 11,250, then save once.
4. Verify the same linked receipt now belongs to Tayba and the invoice remaining
   amount is 2,250. Other unrelated transactions retain their existing balances.
5. Reconnect and let sync finish; verify no errors or conflicts remain. Do not
   create a replacement receipt, which would count the payment twice.

No backend redeployment or Neon migration is required for this frontend fix.

## Manual Commands

Formatting and analysis were intentionally not run, following the user's
standing request. From `D:\dev\Motaz_App\motaz_app\motaz_app_flutter`:

```powershell
dart format lib/features/invoices lib/features/receipts lib/features/sync/application/outbox_processor.dart test/features/invoices test/features/receipts
flutter analyze
flutter build apk --release
```

APK output: `build/app/outputs/flutter-apk/app-release.apk`.

## Separate Follow-Up Risks

The existing sync transport sends separate requests, not one distributed
transaction. Dependency gating does not make the entire cloud edit atomic;
temporary partial state can persist until retries succeed. Real-device and
second-device checks are still required before treating this as live E2E proof.

The broader existing mechanisms for replacing changed invoice lines and pulling
non-versioned child rows across devices were not redesigned here. This change
specifically avoids recreating unchanged lines during client/payment corrections.
