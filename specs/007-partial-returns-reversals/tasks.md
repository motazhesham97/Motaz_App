# Tasks: Partial Returns & Reversals

**Input**: Design documents from `/specs/007-partial-returns-reversals/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/endpoints.md, quickstart.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

All source files are relative to `motaz_app/motaz_app_flutter/lib/`.

---

## Phase 1: Foundational — ReturnRepository Core

**Purpose**: Build the core data layer that all user stories depend on. No user story work can begin until this phase is complete.

**⚠ CRITICAL**: No user story work can begin until this phase is complete.

> **Before implementing any task in this phase, read the following source-of-truth documents:**
> - `.specify/memory/constitution.md`
> - `specs/007-partial-returns-reversals/spec.md`
> - `specs/007-partial-returns-reversals/data-model.md`
> - `specs/007-partial-returns-reversals/contracts/endpoints.md`
> - `specs/007-partial-returns-reversals/research.md`
>
> Do not guess architecture or business rules from memory. Follow the approved constitution, Master Implementation Plan, and current spec boundaries.

- [ ] T001 Create `ReturnRepository` with `create()` method in `features/returns/data/return_repository.dart`

  **Objective**: Implement the core return creation logic with all validations and atomic transaction.

  **Files to create**: `motaz_app/motaz_app_flutter/lib/features/returns/data/return_repository.dart`

  **Implementation scope**:
  - Create class `ReturnRepository` with constructor accepting `AppDatabase _db` and a `final _uuid = const Uuid()` field.
  - Implement `create()` method per the contract in `contracts/endpoints.md`:
    - Parameters: `invoiceId`, `returnDate`, `note` (optional), `lines` (list of `({String invoiceLineId, int returnedQuantity, int returnedAmount})`), `deviceId`.
    - **Validation (in this order)**:
      1. `lines` must not be empty → throw `ArgumentError('Return must have at least one line')`.
      2. Fetch the invoice by `invoiceId`. If not found or status is not `RecordStatus.ACTIVE`, throw `StateError('Invoice must be active to create a return')`.
      3. For each line, fetch the invoice line by `invoiceLineId`. Validate:
         - `returnedQuantity > 0` and `returnedAmount > 0` → throw `ArgumentError`.
         - Compute already-returned quantity for this invoice line: `SELECT COALESCE(SUM(srl.returned_quantity), 0) FROM sales_return_lines srl JOIN sales_returns sr ON sr.id = srl.return_id WHERE srl.invoice_line_id = ? AND sr.status = ?` (status = ACTIVE). If `returnedQuantity > invoiceLine.quantity - alreadyReturned`, throw `StateError('Returned quantity exceeds available quantity')`.
         - If `returnedAmount > returnedQuantity * invoiceLine.unitPrice`, throw `StateError('Returned amount exceeds maximum allowed')`.
      4. Compute `totalReturnedAmount = SUM(all line returnedAmount values)`.
      5. Compute cumulative active returns for invoice: `SELECT COALESCE(SUM(total_returned_amount), 0) FROM sales_returns WHERE invoice_id = ? AND status = ?` (ACTIVE). If `existingTotal + totalReturnedAmount > invoice.total`, throw `StateError('Cumulative return total exceeds invoice total')`.
    - **Atomic transaction** (wrap everything in `_db.transaction(() async { ... })`):
      1. Generate return ID via `_uuid.v4()`.
      2. Insert `SalesReturnsCompanion` with: id, invoiceId, returnDate, totalReturnedAmount, note, status=ACTIVE, voidReason=null, createdAt=now, updatedAt=now, deviceId, rowVersion=1, syncStatus=PENDING.
      3. For each line: generate line ID, insert `SalesReturnLinesCompanion` with: id, returnId, invoiceLineId, returnedQuantity, returnedAmount, createdAt=now, updatedAt=now.
      4. Insert sync outbox entry for each return line: entityType=`ParentEntityType.SALES_RETURN_LINE`, entityId=lineId, operation=`AuditOperation.CREATE`, payload=JSON of line fields.
      5. Insert sync outbox entry for return header: entityType=`ParentEntityType.SALES_RETURN`, entityId=returnId, operation=`AuditOperation.CREATE`, payload=JSON of header fields.
    - Return the created `SalesReturn` object by fetching it from the DB after the transaction.
  - **Pattern reference**: Follow `ExpenseRepository.create()` in `features/expenses/data/expense_repository.dart` for transaction structure, outbox entry format, and JSON payload shape.
  - **Money rule**: All amounts are `int` (minor units). No `double` anywhere.
  - Import `dart:convert`, `package:drift/drift.dart`, `package:uuid/uuid.dart`, and the required database/enum files.

  **Dependencies**: None (first task).

  **Verification**:
  - File exists at the specified path.
  - Class compiles without errors.
  - `dart analyze` passes for this file.

---

- [ ] T002 Add `voidReturn()` method to `ReturnRepository` in `features/returns/data/return_repository.dart`

  **Objective**: Add the void return method with status/reason validation, atomic transaction, and outbox entry.

  **Files to update**: `motaz_app/motaz_app_flutter/lib/features/returns/data/return_repository.dart`

  **Implementation scope**:
  - Add `voidReturn(String id, String reason, String deviceId)` method:
    - Trim `reason`. If empty, throw `ArgumentError('Void reason is required')`.
    - Fetch return by `id`. If not found, throw `StateError`.
    - If `return.status != RecordStatus.ACTIVE`, throw `StateError('Return is already voided')`.
    - In `_db.transaction`:
      1. Update return: set `status = VOIDED`, `voidReason = reason`, `updatedAt = now`, `rowVersion = existing + 1`, `syncStatus = PENDING`.
      2. Insert sync outbox entry: entityType=`SALES_RETURN`, entityId=id, operation=`AuditOperation.UPDATE`, payload=JSON snapshot with updated fields.
  - **Pattern reference**: Follow `ExpenseRepository.voidExpense()` for the void pattern.

  **Dependencies**: T001.

  **Verification**:
  - Method signature matches contract in `contracts/endpoints.md`.
  - `dart analyze` passes.

---

- [ ] T003 Add query methods to `ReturnRepository` in `features/returns/data/return_repository.dart`

  **Objective**: Add all read/query methods needed by UI and other features.

  **Files to update**: `motaz_app/motaz_app_flutter/lib/features/returns/data/return_repository.dart`

  **Implementation scope**:
  - `Future<SalesReturn> getById(String id)`: Select from `salesReturns` where id matches. Throw if not found.
  - `Stream<List<SalesReturn>> watchAll()`: Watch `salesReturns` ordered by `returnDate` descending, then `createdAt` descending.
  - `Stream<List<SalesReturn>> searchByText(String query)`: Watch `salesReturns` where `note` contains query (case-insensitive LIKE), ordered by `returnDate` descending.
  - `Future<List<SalesReturnLine>> getReturnLinesForReturn(String returnId)`: Select from `salesReturnLines` where `returnId` matches.
  - `Future<int> getActiveReturnTotalForInvoice(String invoiceId)`: `SELECT COALESCE(SUM(total_returned_amount), 0) FROM sales_returns WHERE invoice_id = ? AND status = ?` (ACTIVE).
  - `Future<int> getReturnedQuantityForInvoiceLine(String invoiceLineId)`: `SELECT COALESCE(SUM(srl.returned_quantity), 0) FROM sales_return_lines srl JOIN sales_returns sr ON sr.id = srl.return_id WHERE srl.invoice_line_id = ? AND sr.status = ?` (ACTIVE).
  - `Future<bool> hasActiveReturnsForInvoice(String invoiceId)`: Returns `true` if any `SalesReturn` with `invoiceId` and `status = ACTIVE` exists. Use `SELECT COUNT(*) ...` and check `> 0`.
  - **All queries must use `RecordStatus.ACTIVE.index`** for the status parameter.

  **Dependencies**: T001.

  **Verification**:
  - All 7 method signatures match contracts in `contracts/endpoints.md`.
  - `dart analyze` passes.

---

- [ ] T004 Create Riverpod providers in `features/returns/application/return_providers.dart`

  **Objective**: Create the Riverpod providers that expose the repository and streams to the UI.

  **Files to create**: `motaz_app/motaz_app_flutter/lib/features/returns/application/return_providers.dart`

  **Implementation scope**:
  - `returnRepositoryProvider`: `Provider<ReturnRepository>` that reads `databaseProvider` and creates `ReturnRepository(db)`.
  - `returnListProvider`: `StreamProvider<List<SalesReturn>>` that reads `returnRepositoryProvider` and calls `watchAll()`.
  - `returnSearchProvider`: `StreamProvider.family<List<SalesReturn>, String>` that reads `returnRepositoryProvider` and calls `searchByText(query)`.
  - Import the repository and database provider.
  - **Pattern reference**: Follow `features/expenses/application/expense_providers.dart` exactly.

  **Dependencies**: T001.

  **Verification**:
  - File exists. Providers compile without errors.
  - `dart analyze` passes.

**Checkpoint**: Foundation ready — return repository and providers operational. User story phases can now begin.

---

## Phase 2: User Story 1 — Create Partial Return from Invoice (Priority: P1) 🎯 MVP

**Goal**: Owner can select an invoice, pick lines to return with quantity/amount, and save the return.

**Independent Test**: Create an invoice with lines, then create a return against it. Verify the return and return lines are saved correctly in the local database.

> **Before implementing any task in this phase, read:**
> - `specs/007-partial-returns-reversals/spec.md` — User Story 1 acceptance scenarios
> - `specs/007-partial-returns-reversals/data-model.md` — Validation rules V-001 through V-008
> - `specs/007-partial-returns-reversals/contracts/endpoints.md` — `create()` contract

- [ ] T005 [US1] Create return form screen in `features/returns/presentation/return_form_screen.dart`

  **Objective**: Build the UI form for creating a partial return against a specific invoice.

  **Files to create**: `motaz_app/motaz_app_flutter/lib/features/returns/presentation/return_form_screen.dart`

  **Implementation scope**:
  - Create `ReturnFormScreen` as a `ConsumerStatefulWidget`.
  - Constructor accepts an optional `String? invoiceId` parameter (pre-filled when navigating from invoice screen).
  - **State variables**: `_selectedInvoiceId` (String?), `_returnDate` (DateTime, defaults to today), `_note` (String), list of return line entries.
  - **Invoice selection**: If `invoiceId` is not pre-filled, show a dropdown or search field to select an active invoice. Filter to only ACTIVE invoices.
  - **Line selection UI**: Once an invoice is selected, load its invoice lines via `InvoiceRepository`. For each line, display:
    - Product name (from product lookup), original quantity, original unit price, already-returned quantity (via `ReturnRepository.getReturnedQuantityForInvoiceLine()`), available quantity.
    - A checkbox to include this line in the return.
    - Quantity input field (default 0, max = available quantity).
    - Amount field: **auto-fills** as `enteredQuantity × unitPrice` when quantity changes. User can manually lower the amount but **cannot increase** above `enteredQuantity × unitPrice`. Use a `TextEditingController` and update on quantity change.
  - **Return date picker**: Date picker defaulting to today, not allowing future dates beyond today.
  - **Note field**: Optional `TextField`.
  - **Save button**: Collects all selected lines with quantity > 0, calls `ReturnRepository.create()` via provider. On success, show snackbar "تم إنشاء المرتجع بنجاح" and navigate back. On error, show error snackbar.
  - **Validation UX**: Disable save if no lines selected or any validation fails. Show inline errors.
  - **Money display**: Use `_formatMoney(int minorUnits)` helper → `(minorUnits / 100).toStringAsFixed(2)` with `ر.ي.` suffix. This is for **display only** — all computation and storage uses `int`.
  - Imports: material, flutter_riverpod, return_providers, invoice_providers, product_providers, database types.

  **Dependencies**: T001, T003, T004.

  **Verification**:
  - Screen renders without errors.
  - Quantity entry auto-fills the amount field.
  - Amount cannot exceed `qty × unitPrice`.
  - `dart analyze` passes.

---

- [ ] T006 [US1] Update app router to add return form route in `core/router/app_router.dart`

  **Objective**: Add a route for the return form screen so it can be navigated to with an optional invoice ID.

  **Files to update**: `motaz_app/motaz_app_flutter/lib/core/router/app_router.dart`

  **Implementation scope**:
  - Add import for `return_form_screen.dart`.
  - Add route: `GoRoute(path: '/returns/create', builder: (context, state) => ReturnFormScreen(invoiceId: state.uri.queryParameters['invoiceId']))`.
  - This allows navigation via `context.go('/returns/create')` or `context.go('/returns/create?invoiceId=$id')`.

  **Dependencies**: T005.

  **Verification**:
  - Route exists and navigates to the return form.
  - `dart analyze` passes.

**Checkpoint**: User Story 1 complete. Owner can create partial returns with full validation and auto-fill.

---

## Phase 3: User Story 5 — Void Return with Reversal (Priority: P1)

**Goal**: Owner can void a return, reversing all accounting effects. Balance recomputes automatically because voided returns are excluded from queries.

**Independent Test**: Create a return, void it, verify the invoice remaining balance returns to its pre-return value.

> **Before implementing any task in this phase, read:**
> - `specs/007-partial-returns-reversals/spec.md` — User Story 5 acceptance scenarios
> - `specs/007-partial-returns-reversals/research.md` — Decision 6 (void reversal mechanism)

- [ ] T007 [US5] Add void confirmation dialog pattern to return form/list (no new file — used in T009)

  **Objective**: Define the void dialog pattern for reuse. This is a design note — the actual dialog will be implemented inline in T009 (return list screen).

  **Implementation scope**:
  - The void dialog must:
    1. Show a `TextField` for the void reason.
    2. Require non-empty reason before confirming.
    3. **Capture the reason text BEFORE disposing** the `TextEditingController` (same pattern as `ExpenseListScreen` void dialog).
    4. Call `ReturnRepository.voidReturn(id, reason, deviceId)` via provider.
    5. Show success snackbar "تم إلغاء المرتجع" on success, error snackbar on failure.
  - This task is a design reference — actual code is in T009.

  **Dependencies**: T002.

  **Verification**: N/A (design note consumed by T009).

**Checkpoint**: User Story 5 void logic is in the repository (T002). UI implementation is part of the list screen (T009).

---

## Phase 4: User Story 2 — Financial Effect on Invoice Balance (Priority: P1)

**Goal**: Invoice remaining balance correctly accounts for returns. Client balance shows credit when returns exceed unpaid amount.

**Independent Test**: Create invoice (100,000), pay 50,000 via receipt, create return for 20,000. Remaining balance = 30,000.

> **Before implementing any task in this phase, read:**
> - `specs/007-partial-returns-reversals/data-model.md` — Computed Values section
> - `specs/007-partial-returns-reversals/contracts/endpoints.md` — Invoice Remaining Balance SQL

- [ ] T008 [US2] Verify and update invoice remaining balance computation to include returns

  **Objective**: Ensure the invoice detail screen (and any place showing remaining balance) correctly subtracts active returns.

  **Files to review/update**: `motaz_app/motaz_app_flutter/lib/features/invoices/data/invoice_repository.dart` and/or `motaz_app/motaz_app_flutter/lib/features/invoices/presentation/invoice_detail_screen.dart`

  **Implementation scope**:
  - Check if the existing invoice detail screen already computes the remaining balance. If it does, verify the formula includes active returns. If it does NOT include returns, add the return subtraction.
  - The correct formula is: `remainingBalance = invoice.total − SUM(activeAllocations) − SUM(activeReturnTotals)`.
  - The `SUM(activeReturnTotals)` query: `SELECT COALESCE(SUM(total_returned_amount), 0) FROM sales_returns WHERE invoice_id = ? AND status = 0`.
  - If the existing code already shows remaining balance without returns, add the return subtraction.
  - If no remaining balance is shown yet, add a computed field that uses the full formula.
  - **Do NOT create a stored column**. This must be compute-on-read per constitution §9.
  - Use `ReturnRepository.getActiveReturnTotalForInvoice(invoiceId)` if available, or inline the query.

  **Dependencies**: T001, T003.

  **Verification**:
  - After creating a return against an invoice, the displayed remaining balance decreases by the return amount.
  - After voiding the return, the remaining balance restores.
  - `dart analyze` passes.

**Checkpoint**: User Story 2 complete. Invoice balance correctly reflects returns.

---

## Phase 5: User Story 3 — Client Credit from Fully Paid Return (Priority: P2)

**Goal**: When a return is created against a fully paid invoice, the client balance goes negative (credit).

**Independent Test**: Create fully paid invoice, create return, verify client has negative balance.

> **Before implementing any task in this phase, read:**
> - `specs/007-partial-returns-reversals/data-model.md` — Client Balance formula
> - `specs/007-partial-returns-reversals/research.md` — Decision 8 (client balance)

- [ ] T009 [US3] Verify and update client balance computation to include returns in `features/party_balances/data/party_balance_calculator.dart`

  **Objective**: Ensure the client balance computation subtracts active return totals.

  **Files to review/update**: `motaz_app/motaz_app_flutter/lib/features/party_balances/data/party_balance_calculator.dart` or related client balance query

  **Implementation scope**:
  - Check existing client balance computation. The correct formula is:
    ```
    clientBalance = SUM(active invoice totals for client)
      − SUM(active receipt allocation amounts for client's invoices)
      − SUM(active return totals for client's invoices)
    ```
  - If the existing computation does not subtract returns, add the return component.
  - The return query: `SELECT COALESCE(SUM(sr.total_returned_amount), 0) FROM sales_returns sr JOIN sales_invoices si ON si.id = sr.invoice_id WHERE si.client_id = ? AND sr.status = 0`.
  - Ensure positive = debtor, negative = creditor (credit).

  **Dependencies**: T001.

  **Verification**:
  - Fully paid invoice + return → client balance goes negative.
  - Voiding the return → client balance returns to zero.
  - `dart analyze` passes.

**Checkpoint**: User Story 3 complete. Client credit works correctly.

---

## Phase 6: User Story 4 — View Returns List (Priority: P2)

**Goal**: Owner can view all returns sorted by date, search, and void returns from this screen.

**Independent Test**: Create 5 returns (some voided), open list, verify sort order and visual distinction.

> **Before implementing any task in this phase, read:**
> - `specs/007-partial-returns-reversals/spec.md` — User Story 4 acceptance scenarios
> - `features/expenses/presentation/expense_list_screen.dart` — reference pattern for list screen with search, debounce, void, and AppDrawerScaffold

- [ ] T010 [US4] Create return list screen in `features/returns/presentation/return_list_screen.dart`

  **Objective**: Build the returns list screen with search, void action, and AppDrawerScaffold.

  **Files to create**: `motaz_app/motaz_app_flutter/lib/features/returns/presentation/return_list_screen.dart`

  **Implementation scope**:
  - Create `ReturnListScreen` as a `ConsumerStatefulWidget`.
  - **Search**: TextField with `_searchController`, 300ms debounce via `Timer(const Duration(milliseconds: 300), ...)` (FR-021). Follow exact debounce pattern from `ExpenseListScreen`.
  - **List**: Use `ref.watch(returnListProvider)` or `ref.watch(returnSearchProvider(query))`.
  - **Each list item** (ListTile):
    - Title: show linked invoice `localRef` (fetch via join or separate query).
    - Subtitle: `_formatMoney(return.totalReturnedAmount) - _formatDate(return.returnDate)`.
    - If voided: wrap in `Opacity(opacity: 0.6)` and show "ملغى" badge (Chip or Container with red background).
    - If return has a note, show it.
  - **Void action**: On long-press or trailing icon button for ACTIVE returns, show void dialog (pattern from T007): `TextField` for reason, capture text before dispose, call `ReturnRepository.voidReturn()`.
  - **Floating action button**: Navigate to `/returns/create` to create a new return.
  - **AppDrawerScaffold**: Wrap with `AppDrawerScaffold(title: 'المرتجعات', currentRoute: '/returns', child: ...)`.
  - **Empty state**: When no returns exist, show centered text "لا توجد مرتجعات".
  - **Date format helper**: `_formatDate(DateTime d)` → `'${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}'`.
  - **Money format helper**: `_formatMoney(int minorUnits)` → `'${(minorUnits / 100).toStringAsFixed(2)} ر.ي.'`.
  - Imports: `dart:async`, material, flutter_riverpod, app_drawer, return_providers, database types, record_status, device_service.

  **Dependencies**: T002, T003, T004.

  **Verification**:
  - List loads and displays returns ordered by date descending.
  - Search debounces at 300ms.
  - Voided returns show reduced opacity + "ملغى" badge.
  - Void dialog captures reason and calls repository.
  - Empty state shows when no returns.
  - `dart analyze` passes.

---

- [ ] T011 [US4] Delete returns placeholder and update router in `core/router/app_router.dart`

  **Objective**: Replace the returns placeholder with the real return list screen.

  **Files to delete**: `motaz_app/motaz_app_flutter/lib/features/returns/presentation/placeholder_screen.dart`

  **Files to update**: `motaz_app/motaz_app_flutter/lib/core/router/app_router.dart`

  **Implementation scope**:
  - Delete `features/returns/presentation/placeholder_screen.dart`.
  - In `app_router.dart`:
    - Remove import `'../../features/returns/presentation/placeholder_screen.dart'`.
    - Add import `'../../features/returns/presentation/return_list_screen.dart'`.
    - Change the `/returns` route from `ReturnsPlaceholderScreen()` to `ReturnListScreen()`.

  **Dependencies**: T010.

  **Verification**:
  - Placeholder file deleted.
  - `/returns` route navigates to `ReturnListScreen`.
  - `dart analyze` passes.

**Checkpoint**: User Story 4 complete. Returns list is functional with search and void.

---

## Phase 7: User Story 6 — Invoice Edit Restrictions After Return (Priority: P2)

**Goal**: Financial fields on an invoice are locked when active returns exist. Non-financial fields (notes) remain editable. Voided returns do not restrict.

**Independent Test**: Create invoice + return → try editing discount → blocked. Void the return → edit is allowed again.

> **Before implementing any task in this phase, read:**
> - `specs/007-partial-returns-reversals/spec.md` — User Story 6 acceptance scenarios
> - `specs/007-partial-returns-reversals/research.md` — Decision 5 (invoice edit restrictions)
> - Constitution §IV — "If returns exist, only non-financial fields may be edited"
> - `features/invoices/data/invoice_repository.dart` — existing edit method
> - `features/invoices/presentation/invoice_form_screen.dart` — existing edit form

- [ ] T012 [US6] Add `hasActiveReturnsForInvoice()` check to invoice edit flow in `features/invoices/data/invoice_repository.dart`

  **Objective**: Enforce that invoices with active returns cannot have financial fields modified.

  **Files to update**: `motaz_app/motaz_app_flutter/lib/features/invoices/data/invoice_repository.dart`

  **Implementation scope**:
  - Add import for `ReturnRepository` or add a standalone query method.
  - Add a method (or inline check) that the invoice edit/update method calls before applying financial changes.
  - If the invoice has active returns (query: `SELECT COUNT(*) FROM sales_returns WHERE invoice_id = ? AND status = 0` returns > 0):
    - Block changes to: `clientId`, `discount`, invoice lines (add/remove/modify quantities/prices).
    - Allow changes to: `note`, attachment metadata.
    - Throw `StateError('Cannot edit financial fields: active returns exist')` if financial edit is attempted.
  - If ONLY voided returns exist (no active), financial edits are allowed.
  - The check must happen at the **repository level**, not just the UI.

  **Dependencies**: T001, T003.

  **Verification**:
  - Editing financial fields on an invoice with active returns throws `StateError`.
  - Editing note on an invoice with active returns succeeds.
  - Editing financial fields on an invoice with only voided returns succeeds.
  - `dart analyze` passes.

---

- [ ] T013 [US6] Update invoice form screen to show restriction UI in `features/invoices/presentation/invoice_form_screen.dart`

  **Objective**: When editing an invoice that has active returns, disable financial fields in the UI and show a message explaining why.

  **Files to update**: `motaz_app/motaz_app_flutter/lib/features/invoices/presentation/invoice_form_screen.dart`

  **Implementation scope**:
  - When opening the form in edit mode, check `ReturnRepository.hasActiveReturnsForInvoice(invoiceId)` via provider.
  - If `true`:
    - Disable (set `enabled: false`) on: client dropdown, discount field, line item add/remove/edit controls.
    - Show an info banner or `Text` at the top: "لا يمكن تعديل البيانات المالية لوجود مرتجعات فعّالة" (Cannot edit financial data due to active returns).
    - Keep the note field enabled.
  - If `false`: normal edit mode (no restrictions).
  - Add import for `return_providers.dart` and use `ref.read(returnRepositoryProvider)`.

  **Dependencies**: T003, T004, T012.

  **Verification**:
  - Financial fields are disabled when active returns exist.
  - Info message is displayed.
  - Note field remains editable.
  - No restrictions when only voided returns exist.
  - `dart analyze` passes.

**Checkpoint**: User Story 6 complete. Invoice editing respects return restrictions.

---

## Phase 8: User Story 7 — Return from Invoice Detail Screen (Priority: P3)

**Goal**: Owner can tap "إنشاء مرتجع" from an invoice to jump directly to the return form with the invoice pre-selected.

**Independent Test**: Navigate to an active invoice, tap the action, verify return form opens with invoice pre-linked.

> **Before implementing any task in this phase, read:**
> - `specs/007-partial-returns-reversals/spec.md` — User Story 7 acceptance scenarios

- [ ] T014 [US7] Add "إنشاء مرتجع" action to invoice list screen in `features/invoices/presentation/invoice_list_screen.dart`

  **Objective**: Add a context action on active invoices in the list to create a return.

  **Files to update**: `motaz_app/motaz_app_flutter/lib/features/invoices/presentation/invoice_list_screen.dart`

  **Implementation scope**:
  - For each ACTIVE invoice in the list, add a trailing action (e.g., `PopupMenuButton` or `IconButton`) with option "إنشاء مرتجع".
  - On tap: navigate to `/returns/create?invoiceId=${invoice.id}` via `context.go(...)`.
  - Do NOT show this action for VOIDED invoices.
  - Import `go_router` if not already imported.

  **Dependencies**: T005, T006.

  **Verification**:
  - Action visible on active invoices only.
  - Tapping navigates to return form with invoice pre-selected.
  - `dart analyze` passes.

---

- [ ] T015 [US7] Add "إنشاء مرتجع" action to invoice detail screen in `features/invoices/presentation/invoice_detail_screen.dart`

  **Objective**: Add a "Create Return" button on the invoice detail screen for active invoices.

  **Files to update**: `motaz_app/motaz_app_flutter/lib/features/invoices/presentation/invoice_detail_screen.dart`

  **Implementation scope**:
  - Add an action button (e.g., in the AppBar actions or as a bottom action) labeled "إنشاء مرتجع".
  - Only visible when the invoice status is ACTIVE.
  - On tap: navigate to `/returns/create?invoiceId=${invoice.id}`.
  - Import `go_router` if not already imported.

  **Dependencies**: T005, T006.

  **Verification**:
  - Button visible on active invoice detail.
  - Button hidden on voided invoice detail.
  - Navigation works correctly.
  - `dart analyze` passes.

**Checkpoint**: User Story 7 complete. Return creation is accessible from invoice screens.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Final cleanup, verification, and integration testing.

> **Before implementing any task in this phase, read:**
> - `specs/007-partial-returns-reversals/spec.md` — full spec to verify against
> - `.specify/memory/constitution.md` — governance rules

- [ ] T016 Verify drawer entry for `/returns` exists in `shared/widgets/app_drawer.dart`

  **Objective**: Ensure the returns screen is accessible from the app navigation drawer.

  **Files to review**: `motaz_app/motaz_app_flutter/lib/shared/widgets/app_drawer.dart`

  **Implementation scope**:
  - Check that `appDestinations` contains an entry for returns: `AppDestination(label: 'المرتجعات', icon: Icons.assignment_return_rounded, route: '/returns')`.
  - This entry already exists (line 30). Verify it is present and correct.
  - If missing, add it.

  **Dependencies**: T010, T011.

  **Verification**:
  - Returns entry exists in drawer.
  - Navigation from drawer works.

---

- [ ] T017 Run `dart analyze` and fix any issues across all new and modified files

  **Objective**: Ensure zero errors and zero warnings from Phase 7 files.

  **Files to check**: All files created or modified in T001–T016.

  **Implementation scope**:
  - Run `dart analyze` from `motaz_app/motaz_app_flutter/`.
  - Fix any errors or warnings in Phase 7 files.
  - Verify no new deprecation warnings (use `initialValue` not `value` for `DropdownButtonFormField`).
  - Ensure all imports are correct and no unused imports remain.

  **Dependencies**: T001–T016.

  **Verification**:
  - `dart analyze` produces zero errors/warnings for Phase 7 files.
  - Pre-existing sync warnings (21 from prior phases) are acceptable; no new ones added.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Foundational)**: T001→T002→T003 (sequential), T004 can parallel with T002/T003
- **Phase 2 (US1)**: Depends on Phase 1. T005→T006 (sequential)
- **Phase 3 (US5)**: Depends on T002. T007 is a design note.
- **Phase 4 (US2)**: Depends on T001, T003. T008 standalone.
- **Phase 5 (US3)**: Depends on T001. T009 standalone.
- **Phase 6 (US4)**: Depends on T002, T003, T004. T010→T011 (sequential).
- **Phase 7 (US6)**: Depends on T003, T004. T012→T013 (sequential).
- **Phase 8 (US7)**: Depends on T005, T006. T014 and T015 can parallel [P].
- **Phase 9 (Polish)**: Depends on all previous phases.

### User Story Dependencies

- **US1 (P1)**: Depends on Foundation (Phase 1) only — no other story dependencies
- **US5 (P1)**: Depends on Foundation (T002) — can parallel with US1
- **US2 (P1)**: Depends on Foundation (T001, T003) — can parallel with US1
- **US3 (P2)**: Depends on Foundation (T001) — can parallel with US1
- **US4 (P2)**: Depends on Foundation — can parallel with US1
- **US6 (P2)**: Depends on Foundation — can parallel with US1
- **US7 (P3)**: Depends on US1 (T005, T006) — must follow US1

### Within Each User Story

- Repository methods before UI screens
- Providers before screens that use them
- Routes before navigation actions

### Parallel Opportunities

- T002 and T003 can run in parallel (different methods, same file — coordinate carefully)
- T004 can run in parallel with T002/T003 (different file)
- T008, T009, T010, T012 can all run in parallel once Foundation is complete (different features/files)
- T014 and T015 can run in parallel (different files)

---

## Implementation Strategy

### MVP First (US1 + US5 + US2)

1. Complete Phase 1: Foundation (T001–T004)
2. Complete Phase 2: US1 — Create Return (T005–T006)
3. Complete Phase 3: US5 — Void Return (T007, void dialog in T010)
4. Complete Phase 4: US2 — Balance Effect (T008)
5. **STOP and VALIDATE**: Test create + void + balance effect E2E

### Incremental Delivery

1. Foundation → Create Returns → Void Returns → Balance → **MVP**
2. Add Client Credit (US3) → Test independently
3. Add Returns List (US4) → Test independently
4. Add Invoice Edit Restrictions (US6) → Test independently
5. Add Invoice Entry Point (US7) → Test independently
6. Polish → Final `dart analyze`

---

## Notes

- All monetary values are `int` (minor units). No `double` anywhere in the money path.
- All balance computations are compute-on-read. No stored balance columns.
- Voiding a return automatically reverses accounting effects because queries exclude voided records.
- The ProfitEngine already subtracts active returns from net sales (verified in Phase 6). No modification needed for profit/dashboard.
- The existing tables (SalesReturns, SalesReturnLines) and enum values (SALES_RETURN, SALES_RETURN_LINE) are from Phase 2. No migration needed.
- Follow the `ExpenseRepository` pattern for transaction structure, outbox entries, and JSON payload format.
- Follow the `ExpenseListScreen` pattern for AppDrawerScaffold, 300ms debounce, void dialog, and date formatting.
- Commit after each task or logical group.
