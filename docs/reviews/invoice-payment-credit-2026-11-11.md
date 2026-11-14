# Invoice Payment And Client Credit

The previously documented exclusion of non-versioned child rows from pulls is
addressed in [the 2026-11-14 sync repair](sync-reports-startup-navigation-2026-11-14.md).
Backend redeployment and the updated Flutter build are required for that repair.

## Owner-Approved Workflow

An amount written as paid on an invoice is received money, recorded exactly once.
It is not evidence that another paper receipt was issued. GENERAL receipts are
the separate paper receipts actually issued by the owner and can retain photos.
INVOICE_LINKED records remain internal payment records to preserve local history,
allocation, accounting, and the existing sync contract.

Invoice payment priority:

1. Pay its source invoice up to total less active returns.
2. Pay the same client's other oldest unpaid invoices (date, creation, ID).
3. Leave excess as unallocated client credit, available to subsequent invoices.

Example in YER: older debt 8,000; new invoice 10,000; received on that invoice
15,000. The invoice is fully settled, 5,000 reduces the older debt, and the client
owes 3,000. Without older debt, the same payment leaves 5,000 credit for the client.
Excess received is never additional sales or profit. There is no cash refund
transaction or extra paper receipt generated automatically.

## Local Implementation

- Existing Receipt and ReceiptAllocation tables suffice; no migrations,
  dependencies, generated protocol changes, or production data resets are needed.
- One per-client allocation planner derives capacity from active invoices,
  returns, and full active received amounts, not from stale allocation totals.
- Invoice/payment create, corrections, customer transfers, invoice/payment void,
  and return create/void reconcile inside their existing local transactions.
- Source invoice and allocation target remain different fields. An excess payment
  can have multiple target allocations but remains one received amount.
- Matching receipt/invoice pairs retain allocation IDs. Removed assignments are
  zero tombstones queued for sync; unchanged reconciliation emits no new writes.
- Changing an invoice's customer moves only its direct invoice payments. GENERAL
  receipts remain owned by their original customer; both accounts are reconciled.
- Lowering a paid amount or cancelling a payment reopens the affected debt.
  Voiding a sale alone does not pretend the money was refunded: received money
  remains active and is reallocated or retained as credit.
- The existing invoice financial lock when active returns exist remains in place.

## Presentation

- New and edited invoices accept paid amounts above the total; negative/nonfinite
  inputs are rejected. Quick entry shows partial payment, nonnegative invoice
  remainder, and excess for account settlement separately.
- The paper receipt list includes only GENERAL records. Its add/photo workflow
  remains intact. Internal payments remain accessible from invoice details.
- Internal payment forms use an invoice-payment title and omit paper-photo entry.
  No existing stored attachment is deleted by this presentation change.
- Invoice details include incoming allocations from other invoices or paper
  receipts and distinguish full received amount from amount assigned to this sale.
- Customer history and statement UI/PDF label internal payments separately.
  Statements subtract the full received amount once, never its allocations again.
- Invoice detail summary rows wrap on narrow mobile screens instead of overflowing.

## Sync Safety

- Return headers/lines are processed before allocation changes. Parent failures
  or conflicts keep dependent work pending, not deleted.
- Account dependencies include old allocation tombstones and source invoices,
  so moving a sale or payment cannot let another account's grant bypass a failed
  correction. Unrelated client accounts are not globally blocked.
- Allocation reductions precede grants. Pending/failed releases block related
  grants until retry succeeds, including legacy zero updates without metadata.
- Repeated queued edits coalesce against their original amount baseline. The
  `previousAllocatedAmount` field is local queue metadata and is stripped from
  the outgoing request; it is not added to the backend/Neon schema.
- Positive legacy queued updates without a previous-amount baseline cannot be
  reliably classified; this and separate-request remote atomicity remain limits.

## Verification

Tests use isolated SQLite databases and controlled sync boundaries, never Neon.
Each added test was run directly, and failures were corrected before continuing.
Coverage includes creation with excess, older debt, residual credit/later invoice,
payment correction/cancellation, client transfer with independent paper receipts,
sale cancellation, return/cancellation, unchanged reconciliation, invoice detail
projection, statement accounting, paper receipt/photo UI, quick and edit forms,
and Arabic statement PDF generation. A file-backed SQLite reopen test verifies
that client credit and pending allocations survive a database restart offline.

A specialized sync reviewer implemented and directly ran nine dependency tests
for conflicts, release retry, return ordering, baseline coalescing, moved accounts,
legacy zero updates, and isolation from unrelated account failures. Main work and
the reviewer used separate file scopes; production databases were never contacted.

Final full-suite verification: **158 tests passed**, exit code 0. Compared with
the previous 134-test baseline, this adds 24 tests and updates expectations for
the new owner-approved overpayment policy. Failures exposed the old upper limit,
missing spillover during edits, deleted reversal rows, stale return allocations,
and mobile summary overflow; each focused test was rerun successfully.

Commands actually executed from the Flutter package directory:

```powershell
flutter --no-version-check test --no-pub test/features/invoices/data/invoice_repository_test.dart
flutter --no-version-check test --no-pub test/features/invoices/presentation/invoice_form_screen_test.dart --plain-name "invoice details distinguish an incoming settlement from full received money on mobile"
flutter --no-version-check test --no-pub test/features/receipts/presentation/receipt_form_screen_test.dart
flutter --no-version-check test --no-pub test/features/receipts/presentation/receipt_list_screen_test.dart
flutter --no-version-check test --no-pub test/features/reports/presentation/client_statement_entry_card_test.dart --plain-name "statement labels invoice payments without calling them paper receipts"
flutter --no-version-check test --no-pub test/features/reports/pdf/client_statement_pdf_test.dart
flutter --no-version-check test --no-pub --concurrency=1
flutter --no-version-check build bundle --debug --no-pub
```

The new sync test file was also executed directly by the specialized reviewer,
then rerun in the observed final full suite. Debug bundle compilation succeeded
with exit code 0. `git diff --check` succeeded. Formatting/static analysis and
release APK/Windows builds were not run.

## Manual Acceptance

1. Update the existing app without clearing data. Back up before testing real data.
2. Offline, create older unpaid debt 8,000 for one customer.
3. Create another invoice 10,000 and enter paid 15,000. Expect new remaining zero,
   older remaining 3,000, customer owing 3,000, and no extra paper receipt.
4. Edit paid to 12,000. Expect older remaining 6,000, same payment identity.
5. On another customer with no debt, create 10,000 paid 15,000. Expect credit 5,000.
   Create a later unpaid invoice 7,000; expect remaining 2,000 without new money.
6. Create a real GENERAL paper receipt and attach its photo. Verify the paper list,
   customer history, and exported statement distinguish it from invoice payments.
7. Restart offline; verify balances and pending work remain. Reconnect and check
   sync completion/conflicts. Repeat customer correction and return cancellation.

These automated results do not claim physical-device, live-Neon, or two-device
E2E verification. The pre-existing pull limitation for non-versioned allocation
rows and changed invoice-line replacement remain separate follow-up risks.
Cloud writes are separate requests, not one distributed transaction; dependency
gating protects retries but does not make intermediate remote reads atomic.

## Manual Commands

Formatting and analysis intentionally remain for the owner, as requested:

```powershell
Set-Location 'D:\dev\Motaz_App\motaz_app\motaz_app_flutter'
dart format lib/features/clients lib/features/invoices lib/features/receipts lib/features/returns lib/features/reports lib/features/sync/application/outbox_processor.dart test/features/clients test/features/invoices test/features/receipts test/features/returns test/features/reports test/features/sync
flutter analyze
flutter test --no-pub
flutter build apk --release
```

APK: `build/app/outputs/flutter-apk/app-release.apk`. No Neon migration or backend
redeployment is required by this frontend-only change. No commit/push or release
APK build was performed as part of this change.
