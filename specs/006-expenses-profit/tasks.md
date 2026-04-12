# Tasks: Expenses & Monthly Profit Distribution

**Input**: Design documents from `/specs/006-expenses-profit/`  
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/endpoints.md ✅, quickstart.md ✅

**Tests**: Not explicitly requested — test tasks omitted.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

**⚠️ CRITICAL INSTRUCTION FOR IMPLEMENTATION MODEL**: Before implementing ANY task, read the following repository documents as the source of truth. Do NOT guess architecture, business rules, or framework behavior from memory:
- `.specify/memory/constitution.md` — non-negotiable rules
- `specs/006-expenses-profit/spec.md` — functional requirements FR-001 to FR-035
- `specs/006-expenses-profit/plan.md` — technical context, structure, constitution check
- `specs/006-expenses-profit/research.md` — 9 technical decisions
- `specs/006-expenses-profit/data-model.md` — entity fields, constraints, state transitions
- `specs/006-expenses-profit/contracts/endpoints.md` — repository method signatures
- `docs/implementation-plan.md` — master implementation plan (Phase 6 section)

**Stack rules enforced**:
- Flutter frontend, flutter_riverpod for state, Drift for local SQLite
- Money as minor-unit integers only — no `double` anywhere in the money path
- All mutations: entity + outbox in single `_db.transaction()`
- Financial conflicts never silently auto-merged
- Void wins over edit
- Arabic RTL for all UI text

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US9)
- Exact file paths included in every task

---

## Phase 1: Schema & Infrastructure

**Purpose**: Add the MonthlyDistributions table, update enums, bump migration. Must be complete before any feature work.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

### T001 — Create MonthlyDistributions table definition

- [x] T001 Create the MonthlyDistributions Drift table in `motaz_app_flutter/lib/core/database/tables/monthly_distributions.dart`

**Objective**: Define a new Drift table class for monthly profit distributions.

**Before implementing**: Read `specs/006-expenses-profit/data-model.md` §2 (MonthlyDistribution) for the exact field list, types, and constraints. Read `motaz_app_flutter/lib/core/database/tables/expenses.dart` for the established table pattern.

**Files to create**:
- `motaz_app_flutter/lib/core/database/tables/monthly_distributions.dart`

**Exact scope**:
1. Create a file importing `package:drift/drift.dart`, `../enums/sync_status.dart`, `../enums/record_status.dart`, and `devices.dart`.
2. Add table indexes:
   - `@TableIndex(name: 'idx_distribution_year_month', columns: {#year, #month})`
   - `@TableIndex(name: 'idx_distribution_status', columns: {#status})`
3. Define `class MonthlyDistributions extends Table` with these columns:
   - `id` — `text().withLength(min: 36, max: 36)()` (PK)
   - `year` — `integer()()`
   - `month` — `integer()()`
   - `netProfit` — `integer()()`
   - `ownerShare` — `integer()()`
   - `partnerShare` — `integer()()`
   - `marginShare` — `integer()()`
   - `status` — `intEnum<RecordStatus>().withDefault(const Constant(0))()`
   - `voidReason` — `text().nullable()()`
   - `createdAt` — `dateTime()()`
   - `updatedAt` — `dateTime()()`
   - `deviceId` — `text().withLength(min: 36, max: 36).references(Devices, #id)()`
   - `rowVersion` — `integer().withDefault(const Constant(1))()`
   - `syncStatus` — `intEnum<SyncStatus>().withDefault(const Constant(0))()`
4. Override `primaryKey` to return `{id}`.
5. Add a unique constraint on `(year, month)` using: `@override List<Set<Column>> get uniqueKeys => [{year, month}];`

**Dependencies**: None — this is the first task.

**Acceptance criteria**:
- File compiles with `dart analyze` (no errors).
- Table has all 14 columns matching data-model.md exactly.
- Unique constraint on (year, month) is defined.
- Two indexes are defined.

---

### T002 — Add MONTHLY_DISTRIBUTION to ParentEntityType enum

- [x] T002 [P] Add `MONTHLY_DISTRIBUTION` to enum in `motaz_app_flutter/lib/core/database/enums/parent_entity_type.dart`

**Objective**: Add the new sync entity type for monthly distributions at the END of the existing enum.

**Before implementing**: Read `specs/006-expenses-profit/data-model.md` §4 for the exact enum index. The existing values MUST NOT be reordered — new value must be appended at the end.

**Files to update**:
- `motaz_app_flutter/lib/core/database/enums/parent_entity_type.dart`

**Exact scope**:
1. Add `MONTHLY_DISTRIBUTION,` as the LAST value in the `ParentEntityType` enum, after `ATTACHMENT_METADATA`.
2. This gives it index 10. Do NOT reorder any existing values.

**Dependencies**: None.

**Acceptance criteria**:
- `ParentEntityType.MONTHLY_DISTRIBUTION.index == 10`.
- All existing enum values retain their original indexes (0-9).
- File compiles with no errors.

---

### T003 — Register table and bump schema version in AppDatabase

- [x] T003 Register MonthlyDistributions in `motaz_app_flutter/lib/core/database/app_database.dart` and bump schema to 4

**Objective**: Add the new table to the Drift database registration and create a migration step.

**Before implementing**: Read `specs/006-expenses-profit/research.md` §9 (Migration Strategy). Read the existing `app_database.dart` to understand the current migration pattern (current schema version is 3).

**Files to update**:
- `motaz_app_flutter/lib/core/database/app_database.dart`

**Exact scope**:
1. Import `tables/monthly_distributions.dart`.
2. Add `MonthlyDistributions` to the `@DriftDatabase(tables: [...])` list.
3. Change `schemaVersion` from `3` to `4`.
4. Add a new migration step in `onUpgrade`:
   ```dart
   if (from < 4) {
     await m.createTable(monthlyDistributions);
   }
   ```
5. Do NOT modify any existing migration steps.

**Dependencies**: T001 (table definition exists).

**Acceptance criteria**:
- `schemaVersion` returns `4`.
- `MonthlyDistributions` is in the `tables` list.
- Migration creates the `monthly_distributions` table for users upgrading from version 3.
- File compiles with no errors.

---

### T004 — Run build_runner to regenerate Drift code

- [x] T004 Run `dart run build_runner build --delete-conflicting-outputs` in `motaz_app_flutter/`

**Objective**: Regenerate Drift-generated code after adding the new table and registering it.

**Exact scope**:
1. Run `dart run build_runner build --delete-conflicting-outputs` from within `motaz_app_flutter/`.
2. Verify the generated `app_database.g.dart` includes the `MonthlyDistributions` table.
3. Run `dart analyze` to verify no errors.

**Dependencies**: T003 (database registration complete).

**Acceptance criteria**:
- Build runner completes without errors.
- `app_database.g.dart` is regenerated with the new table accessors.
- `dart analyze` shows no errors in new or modified files.

---

## Phase 2: Expense Repository (Data Layer)

**Purpose**: Build the expense data layer that all expense-related user stories depend on.

### T005 — Create ExpenseRepository with create method

- [x] T005 Create ExpenseRepository in `motaz_app_flutter/lib/features/expenses/data/expense_repository.dart`

**Objective**: Build the expense creation flow with atomic save and outbox entry.

**Before implementing**: Read `specs/006-expenses-profit/contracts/endpoints.md` §ExpenseRepository for exact method signatures. Read `motaz_app_flutter/lib/features/products/data/product_repository.dart` for the established transaction + outbox pattern. Read `specs/006-expenses-profit/spec.md` FR-001, FR-003, FR-004. Do not guess architecture from memory.

**Files to create**:
- `motaz_app_flutter/lib/features/expenses/data/expense_repository.dart`

**Exact scope**:
1. Create class `ExpenseRepository` with constructor `ExpenseRepository(this._db)` taking `AppDatabase`.
2. Add `final _uuid = const Uuid()`.
3. Implement `Future<Expense> create({required ExpenseCategory category, required int amount, required DateTime expenseDate, String? note, required String deviceId})`:
   - Validate `amount > 0` — throw if not positive.
   - Generate UUID for expense ID.
   - Build JSON payload for outbox entry with all fields.
   - Inside `_db.transaction(() async { ... })`:
     a. Insert the Expense row (id, category, amount, expenseDate, note, status=ACTIVE, voidReason=null, createdAt=now, updatedAt=now, deviceId, rowVersion=1, syncStatus=PENDING).
     b. Insert outbox entry (entityType=EXPENSE, entityId=id, operation=CREATE, payload, rowVersion=1).
   - Return the inserted Expense row by querying `getById(id)` after transaction.
4. Add `Future<Expense> getById(String id)` — select single expense by ID.
5. All amounts are `int`. No `double` anywhere.

**Dependencies**: T004 (generated code ready).

**Acceptance criteria**:
- File compiles with `dart analyze`.
- `create()` inserts expense + outbox in single transaction.
- `amount <= 0` throws.
- All amounts are `int`.
- Follows the `ProductRepository` transaction + outbox pattern exactly.

---

### T006 — Add update and void methods to ExpenseRepository

- [x] T006 Add `update` and `voidExpense` methods to `motaz_app_flutter/lib/features/expenses/data/expense_repository.dart`

**Objective**: Implement expense editing and voiding with validation.

**Before implementing**: Read `specs/006-expenses-profit/spec.md` FR-005 through FR-011. Read `specs/006-expenses-profit/contracts/endpoints.md` §ExpenseRepository mutations. Follow the void pattern from `InvoiceRepository.voidInvoice`.

**Files to update**:
- `motaz_app_flutter/lib/features/expenses/data/expense_repository.dart`

**Exact scope**:
1. Implement `Future<void> update({required String id, required ExpenseCategory category, required int amount, required DateTime expenseDate, String? note, required String deviceId})`:
   - Fetch existing via `getById(id)`.
   - Validate `existing.status == RecordStatus.ACTIVE` — throw if voided (FR-006).
   - Validate `amount > 0`.
   - Inside `_db.transaction(() async { ... })`:
     a. Update the expense row: category, amount, expenseDate, note, updatedAt=now, rowVersion+1, syncStatus=PENDING.
     b. Create outbox entry (operation=UPDATE) with full payload.
2. Implement `Future<void> voidExpense(String id, String reason, String deviceId)`:
   - Validate `reason.trim().isNotEmpty` — throw if empty.
   - Fetch existing via `getById(id)`.
   - Validate `existing.status == RecordStatus.ACTIVE` — throw if already voided (FR-009).
   - Inside `_db.transaction(() async { ... })`:
     a. Update: status=VOIDED, voidReason=reason, updatedAt=now, rowVersion+1, syncStatus=PENDING.
     b. Create outbox entry (operation=UPDATE) with full payload including status=VOIDED.

**Dependencies**: T005 (file exists with create method and getById).

**Acceptance criteria**:
- Voided expenses cannot be updated (throws).
- Empty void reason throws.
- Already-voided expense cannot be voided again.
- All updates in single transaction with outbox entries.
- No hard delete (FR-011).

---

### T007 — Add query methods to ExpenseRepository

- [x] T007 Add query methods to `motaz_app_flutter/lib/features/expenses/data/expense_repository.dart`

**Objective**: Add all read-only query methods needed by UI and by the profit engine.

**Before implementing**: Read `specs/006-expenses-profit/contracts/endpoints.md` §ExpenseRepository queries. Read `specs/006-expenses-profit/spec.md` FR-012 through FR-016 for display requirements.

**Files to update**:
- `motaz_app_flutter/lib/features/expenses/data/expense_repository.dart`

**Exact scope**:
1. `Stream<List<Expense>> watchAll()` — watch all expenses ordered by `expenseDate DESC, createdAt DESC`.
2. `Stream<List<Expense>> searchByText(String query)` — filter where `note LIKE '%query%'` OR category matches the Arabic label. Use a helper method that maps Arabic category labels (تشغيلي, إنتاج, سحب مالك, سحب شريك, سحب هامش) to their enum values, then filter in Dart. Order by expenseDate DESC.
3. `Future<int> getMonthlyTotalByCategory(ExpenseCategory category, int year, int month)` — `SELECT COALESCE(SUM(amount), 0) FROM expenses WHERE category = ? AND status = 0 AND expenseDate BETWEEN startOfMonth AND endOfMonth`. Compute month start as `DateTime(year, month, 1)` and month end as `DateTime(year, month + 1, 1)`. Returns `int`.

**Dependencies**: T006 (file has all mutation methods).

**Acceptance criteria**:
- All 3 query methods compile and return correct types.
- `watchAll` orders by expenseDate DESC, createdAt DESC.
- `searchByText` filters by Arabic category label or note text.
- `getMonthlyTotalByCategory` returns sum of active expenses for a specific category in a month.

---

## Phase 3: Expense Providers & UI (US1-US4)

**Purpose**: Build the expense list, form, and interactions — covers User Stories 1, 2, 3, and 4.

**Goal**: Owner can create, edit, void, and search expenses.

**Independent Test**: Create an expense for 5,000 YER under OPERATIONAL, see it in the list, edit the amount, void it, and search by category name.

### T008 — Create expense providers

- [x] T008 Create expense providers in `motaz_app_flutter/lib/features/expenses/application/expense_providers.dart`

**Objective**: Create Riverpod providers for expense repository access and reactive data streams.

**Before implementing**: Read `motaz_app_flutter/lib/features/invoices/application/invoice_providers.dart` for the established provider pattern.

**Files to create**:
- `motaz_app_flutter/lib/features/expenses/application/expense_providers.dart`

**Exact scope**:
1. `final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) { ... })` — wraps `ExpenseRepository(ref.watch(appDatabaseProvider))`.
2. `final expenseListProvider = StreamProvider<List<Expense>>((ref) { ... })` — calls `repo.watchAll()`.
3. `final expenseSearchProvider = StreamProvider.family<List<Expense>, String>((ref, query) { ... })` — calls `repo.searchByText(query)`.

**Dependencies**: T007 (repository complete).

**Acceptance criteria**:
- File compiles.
- All 3 providers created with correct types.
- List provider exposes expenses ordered by expenseDate DESC.

---

### T009 — Create expense form screen (create and edit modes)

- [x] T009 [US1] [US2] Create expense form screen in `motaz_app_flutter/lib/features/expenses/presentation/expense_form_screen.dart`

**Objective**: Build the form for creating and editing expenses.

**Before implementing**: Read `specs/006-expenses-profit/spec.md` US1, US2, FR-001 through FR-007, FR-016 for Arabic labels. Read `motaz_app_flutter/lib/features/invoices/presentation/invoice_form_screen.dart` for the established form pattern. Do not guess architecture from memory.

**Files to create**:
- `motaz_app_flutter/lib/features/expenses/presentation/expense_form_screen.dart`

**Exact scope**:
1. `ExpenseFormScreen` — a `ConsumerStatefulWidget` accepting optional `Expense? existingExpense` for edit mode.
2. **Fields**:
   - Category: dropdown with Arabic labels per FR-016 — تشغيلي (OPERATIONAL), إنتاج (PRODUCTION), سحب مالك (OWNER_DRAW), سحب شريك (PARTNER_DRAW), سحب هامش (MARGIN_DRAW). Required — validate before save.
   - Amount: `TextField` displayed in YER with 2 decimals, converted to/from minor-unit integer. Validated: `> 0`.
   - Expense date: `DateTime` field defaulting to `DateTime.now()`. Date picker.
   - Note: optional multiline `TextField`.
3. **Create mode**: Title "إضافة مصروف". On save: `expenseRepository.create(...)`.
4. **Edit mode**: Title "تعديل مصروف". On init: populate fields from `existingExpense` (convert minor-unit amount to display format). On save: `expenseRepository.update(...)`. If expense is voided, the form should NOT be reachable (guard at call site).
5. Get `deviceId` from `deviceServiceProvider.ensureCurrentDevice()`.
6. Show loading indicator during save. Catch errors and display via `SnackBar`.
7. After save, pop navigation.
8. All labels in Arabic.
9. No `double` in the save path — convert display text to `int` minor units before calling repository.

**Dependencies**: T008 (providers ready).

**Acceptance criteria**:
- Form renders all 4 fields.
- Category dropdown shows 5 Arabic labels.
- Amount validates > 0.
- Create mode calls `create()`, edit mode calls `update()`.
- Amount conversion: display format ↔ minor-unit integers with no double leaking to repository.
- Arabic labels on all fields.

---

### T010 — Create expense list screen with void action

- [x] T010 [US3] [US4] Create expense list screen in `motaz_app_flutter/lib/features/expenses/presentation/expense_list_screen.dart`

**Objective**: Build the expense list with search, void action, and navigation to form.

**Before implementing**: Read `specs/006-expenses-profit/spec.md` US3, US4, FR-008 through FR-015. Read `motaz_app_flutter/lib/features/receipts/presentation/receipt_list_screen.dart` for the established list + void pattern (debounce, AppDrawerScaffold, PopupMenuButton, void dialog).

**Files to create**:
- `motaz_app_flutter/lib/features/expenses/presentation/expense_list_screen.dart`

**Exact scope**:
1. `ExpenseListScreen` — a `ConsumerStatefulWidget`.
2. Use `AppDrawerScaffold` with title "المصروفات" and currentRoute "/expenses".
3. Search bar with 300ms debounce (use `Timer` — same pattern as receipt list).
4. Use `expenseListProvider` (no search) or `expenseSearchProvider(query)` (with search).
5. Each list item shows:
   - Category in Arabic per FR-016.
   - Amount formatted as YER: `(amount / 100).toStringAsFixed(2)`.
   - Date formatted as `YYYY-MM-DD`.
   - Status: if voided, show "ملغى" badge + `Opacity(0.6)`.
6. FloatingActionButton → navigate to `ExpenseFormScreen()` (create mode).
7. Tap on an ACTIVE expense → navigate to `ExpenseFormScreen(existingExpense: expense)` (edit mode). Do NOT navigate to edit for voided expenses.
8. For ACTIVE expenses: `PopupMenuButton` with "إلغاء المصروف" (void). Shows dialog asking for reason (required text field). On confirm: calls `expenseRepository.voidExpense(...)`. **Important**: Capture `reasonController.text` before disposing the controller (bug pattern from Phase 5 review).
9. Category label helper: create a helper function `String categoryLabel(ExpenseCategory cat)` that returns the Arabic label per FR-016.

**Dependencies**: T009 (form screen exists for navigation).

**Acceptance criteria**:
- List displays expenses newest-first.
- Search with 300ms debounce filters by category name or note.
- Voided expenses show visual indicator and cannot be edited.
- Void dialog requires reason text.
- FAB navigates to create form.
- Tap navigates to edit form (ACTIVE only).
- Arabic labels.

---

## Phase 4: Profit Engine (US5-US6 Data Layer)

**Purpose**: Build the profit calculation engine that distribution and dashboard depend on.

### T011 — Create ProfitEngine

- [x] T011 Create ProfitEngine in `motaz_app_flutter/lib/features/profit_distribution/data/profit_engine.dart`

**Objective**: Build the stateless helper for monthly profit computation and three-way distribution splitting.

**Before implementing**: Read `specs/006-expenses-profit/contracts/endpoints.md` §ProfitEngine for exact method signatures. Read `specs/006-expenses-profit/spec.md` FR-017 through FR-023. Read `specs/006-expenses-profit/research.md` §2 (Profit Engine Design), §3 (Net Sales), §4 (Month Eligibility). Read `specs/006-expenses-profit/data-model.md` §Computed Values for exact formulas. Read the constitution §10.1–10.3 for accounting rules. Do not guess business rules from memory.

**Files to create**:
- `motaz_app_flutter/lib/features/profit_distribution/data/profit_engine.dart`

**Exact scope**:
1. Create class `ProfitEngine` with constructor `ProfitEngine(this._db)` taking `AppDatabase`.
2. Implement `Future<int> computeMonthlyNetSales(int year, int month)`:
   - Compute month start: `DateTime(year, month, 1)`.
   - Compute month end: `DateTime(year, month + 1, 1)` (exclusive upper bound).
   - Query active invoices: `SELECT COALESCE(SUM(total), 0) FROM sales_invoices WHERE status = 0 AND invoiceDate >= monthStart AND invoiceDate < monthEnd`.
   - Query active returns: `SELECT COALESCE(SUM(total_returned_amount), 0) FROM sales_returns WHERE status = 0 AND returnDate >= monthStart AND returnDate < monthEnd`.
   - Return `invoiceSum - returnSum`.
   - **Note**: Returns table exists but may be empty (Phase 7 not implemented yet). The COALESCE ensures 0 is returned.
3. Implement `Future<int> computeMonthlyNetProfit(int year, int month)`:
   - Call `computeMonthlyNetSales(year, month)`.
   - Query active OPERATIONAL expenses: `SELECT COALESCE(SUM(amount), 0) FROM expenses WHERE category = 3 AND status = 0 AND expenseDate >= monthStart AND expenseDate < monthEnd`. (ExpenseCategory.OPERATIONAL.index == 3)
   - Query active PRODUCTION expenses: `SELECT COALESCE(SUM(amount), 0) FROM expenses WHERE category = 4 AND status = 0 AND expenseDate >= monthStart AND expenseDate < monthEnd`. (ExpenseCategory.PRODUCTION.index == 4)
   - Return `netSales - operationalTotal - productionTotal`.
   - **Critical**: OWNER_DRAW (0), PARTNER_DRAW (1), MARGIN_DRAW (2) are NOT included. Only OPERATIONAL (3) and PRODUCTION (4).
4. Implement `({int ownerShare, int partnerShare, int marginShare}) computeDistribution(int netProfit)`:
   - This is a pure function — no DB access.
   - `ownerShare = netProfit ~/ 3` (truncating integer division).
   - `partnerShare = netProfit ~/ 3`.
   - `marginShare = netProfit - ownerShare - partnerShare`.
   - Works for positive, negative, and zero net profit.
   - Invariant: `ownerShare + partnerShare + marginShare == netProfit` always holds.
5. Implement `bool isPastMonth(int year, int month)`:
   - `final now = DateTime.now();`
   - Returns `year < now.year || (year == now.year && month < now.month)`.
6. All values are `int`. No `double` anywhere.

**Dependencies**: T004 (generated code ready — needs access to sales_invoices, sales_returns, expenses tables).

**Acceptance criteria**:
- File compiles with `dart analyze`.
- `computeMonthlyNetSales` handles empty tables gracefully (returns 0).
- `computeMonthlyNetProfit` excludes draw categories (only OPERATIONAL + PRODUCTION).
- `computeDistribution(100000)` returns `(33333, 33333, 33334)`.
- `computeDistribution(-100000)` returns `(-33333, -33333, -33334)`.
- `computeDistribution(0)` returns `(0, 0, 0)`.
- `computeDistribution(1)` returns `(0, 0, 1)`.
- `isPastMonth` correctly validates current month as ineligible.
- No `double` in any arithmetic.

---

### T012 — Create DistributionRepository

- [x] T012 Create DistributionRepository in `motaz_app_flutter/lib/features/profit_distribution/data/distribution_repository.dart`

**Objective**: Build distribution creation and voiding with atomic transactions.

**Before implementing**: Read `specs/006-expenses-profit/contracts/endpoints.md` §DistributionRepository. Read `specs/006-expenses-profit/spec.md` FR-021 through FR-027. Follow the transaction + outbox pattern from `ProductRepository`.

**Files to create**:
- `motaz_app_flutter/lib/features/profit_distribution/data/distribution_repository.dart`

**Exact scope**:
1. Create class `DistributionRepository` with constructor `DistributionRepository(this._db, this._engine)` taking `AppDatabase` and `ProfitEngine`.
2. Add `final _uuid = const Uuid()`.
3. Implement `Future<MonthlyDistribution> distribute({required int year, required int month, required String deviceId})`:
   - Validate `_engine.isPastMonth(year, month)` — throw if current or future month (FR-021).
   - Validate `month >= 1 && month <= 12`.
   - Check no existing ACTIVE distribution: `getForMonth(year, month)`. If not null, throw (FR-024).
   - Compute net profit: `_engine.computeMonthlyNetProfit(year, month)`.
   - Compute shares: `_engine.computeDistribution(netProfit)`.
   - Generate UUID.
   - Build JSON payload for outbox.
   - Inside `_db.transaction(() async { ... })`:
     a. Insert MonthlyDistribution row (id, year, month, netProfit, ownerShare, partnerShare, marginShare, status=ACTIVE, createdAt=now, updatedAt=now, deviceId, rowVersion=1, syncStatus=PENDING).
     b. Create outbox entry (entityType=MONTHLY_DISTRIBUTION, operation=CREATE).
   - Return inserted row via `getById(id)`.
4. Implement `Future<void> voidDistribution(String id, String reason, String deviceId)`:
   - Validate `reason.trim().isNotEmpty`.
   - Fetch existing via `getById(id)`.
   - Validate `existing.status == RecordStatus.ACTIVE`.
   - Inside `_db.transaction()`:
     a. Update: status=VOIDED, voidReason=reason, updatedAt=now, rowVersion+1, syncStatus=PENDING.
     b. Create outbox entry (operation=UPDATE) with full payload.
   - Per FR-027: voiding does NOT auto-redistribute.
5. Implement queries:
   - `Future<MonthlyDistribution> getById(String id)`.
   - `Stream<List<MonthlyDistribution>> watchAll()` — ordered by year DESC, month DESC.
   - `Future<MonthlyDistribution?> getForMonth(int year, int month)` — select where year=? AND month=? AND status=ACTIVE. Return null if not found.

**Dependencies**: T011 (ProfitEngine exists).

**Acceptance criteria**:
- Future month rejected.
- Current month rejected.
- Duplicate distribution for same (year, month) rejected.
- Zero profit produces zero shares.
- Void requires reason, blocks already-voided.
- All in single transaction with outbox.
- No `double` anywhere.

---

## Phase 5: Profit Distribution UI (US5-US6)

**Purpose**: Build the profit distribution screen covering viewing monthly profit and distributing.

### T013 — Create profit distribution providers

- [x] T013 Create profit providers in `motaz_app_flutter/lib/features/profit_distribution/application/profit_providers.dart`

**Objective**: Create Riverpod providers for ProfitEngine, DistributionRepository, and distribution list.

**Before implementing**: Follow the provider pattern from `motaz_app_flutter/lib/features/invoices/application/invoice_providers.dart`.

**Files to create**:
- `motaz_app_flutter/lib/features/profit_distribution/application/profit_providers.dart`

**Exact scope**:
1. `final profitEngineProvider = Provider<ProfitEngine>((ref) => ProfitEngine(ref.watch(appDatabaseProvider)))`.
2. `final distributionRepositoryProvider = Provider<DistributionRepository>((ref) => DistributionRepository(ref.watch(appDatabaseProvider), ref.watch(profitEngineProvider)))`.
3. `final distributionListProvider = StreamProvider<List<MonthlyDistribution>>((ref) => ref.watch(distributionRepositoryProvider).watchAll())`.

**Dependencies**: T012 (repository complete).

**Acceptance criteria**:
- File compiles.
- All 3 providers created with correct types.

---

### T014 — Create distribution screen

- [x] T014 [US5] [US6] Create distribution screen in `motaz_app_flutter/lib/features/profit_distribution/presentation/distribution_screen.dart`

**Objective**: Build the screen where the owner selects a month, sees computed net profit, distributes, and views distribution history.

**Before implementing**: Read `specs/006-expenses-profit/spec.md` US5, US6, FR-021 through FR-027. Follow the void dialog pattern from `InvoiceDetailScreen`.

**Files to create**:
- `motaz_app_flutter/lib/features/profit_distribution/presentation/distribution_screen.dart`

**Exact scope**:
1. `DistributionScreen` — a `ConsumerStatefulWidget`.
2. Use `AppDrawerScaffold` with title "توزيع الأرباح" and a suitable currentRoute.
3. **Month selector**: Year + month dropdowns (or a date picker limited to year/month). Default to previous month.
4. **Profit preview section**: When a month is selected, show:
   - "صافي المبيعات" (Net Sales) — computed via `profitEngine.computeMonthlyNetSales(year, month)`.
   - "صافي الربح" (Net Profit) — computed via `profitEngine.computeMonthlyNetProfit(year, month)`.
   - "حصة المالك" / "حصة الشريك" / "حصة الهامش" — computed via `profitEngine.computeDistribution(netProfit)`.
   - All amounts formatted as YER: `(value / 100).toStringAsFixed(2)`.
5. **Distribute button**: "توزيع" — calls `distributionRepository.distribute(year: year, month: month, deviceId: deviceId)`.
   - Disabled if month is current or future.
   - Disabled if a distribution already exists for that month (show "تم التوزيع" badge).
   - Show loading during operation.
   - On success: reload data, show success SnackBar.
   - On error: show error SnackBar.
6. **Distribution history**: Below the form, show a list of all distributions from `distributionListProvider`.
   - Each item: "YYYY-MM", net profit, owner/partner/margin shares, status.
   - Voided distributions show "ملغى" badge + reduced opacity.
   - ACTIVE distributions have PopupMenuButton with "إلغاء التوزيع" (void) option → shows reason dialog → calls `distributionRepository.voidDistribution(...)`.
7. Get `deviceId` from `deviceServiceProvider`.
8. All labels in Arabic.

**Dependencies**: T013 (providers ready).

**Acceptance criteria**:
- Month selector works.
- Profit preview shows correct computed values.
- Distribute button blocked for current/future months.
- Distribute button blocked for already-distributed months.
- Void dialog requires reason.
- Distribution history displays with correct data.
- Arabic labels throughout.

---

## Phase 6: Party Balances (US7-US8)

**Purpose**: Build party balance computation and display.

### T015 — Create PartyBalanceCalculator

- [x] T015 Create party balance calculator in `motaz_app_flutter/lib/features/party_balances/data/party_balance_calculator.dart`

**Objective**: Build the compute-on-read balance queries for all three parties.

**Before implementing**: Read `specs/006-expenses-profit/contracts/endpoints.md` §PartyBalanceCalculator. Read `specs/006-expenses-profit/data-model.md` §Computed Values → Party Balances for exact formulas. Read `specs/006-expenses-profit/spec.md` FR-028 through FR-031. Read `specs/006-expenses-profit/research.md` §5 (Party Balance Computation).

**Files to create**:
- `motaz_app_flutter/lib/features/party_balances/data/party_balance_calculator.dart`

**Exact scope**:
1. Create class `PartyBalanceCalculator` with constructor `PartyBalanceCalculator(this._db)` taking `AppDatabase`.
2. Implement `Future<({int ownerBalance, int partnerBalance, int marginBalance})> computeAllBalances()`:
   - Owner balance:
     - `distribShares = SELECT COALESCE(SUM(owner_share), 0) FROM monthly_distributions WHERE status = 0`
     - `draws = SELECT COALESCE(SUM(amount), 0) FROM expenses WHERE category = 0 AND status = 0` (OWNER_DRAW index = 0)
     - `ownerBalance = distribShares - draws`
   - Partner balance:
     - `distribShares = SELECT COALESCE(SUM(partner_share), 0) FROM monthly_distributions WHERE status = 0`
     - `draws = SELECT COALESCE(SUM(amount), 0) FROM expenses WHERE category = 1 AND status = 0` (PARTNER_DRAW index = 1)
     - `partnerBalance = distribShares - draws`
   - Margin balance:
     - `distribShares = SELECT COALESCE(SUM(margin_share), 0) FROM monthly_distributions WHERE status = 0`
     - `draws = SELECT COALESCE(SUM(amount), 0) FROM expenses WHERE category = 2 AND status = 0` (MARGIN_DRAW index = 2)
     - `marginBalance = distribShares - draws`
   - Return the record with all three values.
3. Balances can be negative — no floor constraint (FR-031).
4. All values are `int`. No `double`.

**Dependencies**: T004 (generated code with monthly_distributions table).

**Acceptance criteria**:
- File compiles.
- Returns `(0, 0, 0)` when no distributions and no draws exist.
- Correctly computes negative balances when draws exceed shares.
- Uses only ACTIVE distributions and ACTIVE draw expenses.
- No `double`.

---

### T016 — Create party balance providers and screen

- [x] T016 [US7] [US8] Create party balance providers and screen in `motaz_app_flutter/lib/features/party_balances/`

**Objective**: Build providers and a display screen for party balances.

**Before implementing**: Read `specs/006-expenses-profit/spec.md` US7, US8, FR-028 through FR-032.

**Files to create**:
- `motaz_app_flutter/lib/features/party_balances/application/party_balance_providers.dart`
- `motaz_app_flutter/lib/features/party_balances/presentation/party_balances_screen.dart`

**Exact scope — providers**:
1. `final partyBalanceCalculatorProvider = Provider<PartyBalanceCalculator>((ref) => PartyBalanceCalculator(ref.watch(appDatabaseProvider)))`.
2. `final partyBalancesProvider = FutureProvider<({int ownerBalance, int partnerBalance, int marginBalance})>((ref) => ref.watch(partyBalanceCalculatorProvider).computeAllBalances())`.

**Exact scope — screen**:
1. `PartyBalancesScreen` — a `ConsumerWidget`.
2. Use `AppDrawerScaffold` with title "أرصدة الأطراف" and currentRoute "/party-balances".
3. Display three cards:
   - "رصيد المالك" (Owner Balance) — amount formatted as YER.
   - "رصيد الشريك" (Partner Balance) — amount formatted as YER.
   - "رصيد الهامش" (Margin Balance) — amount formatted as YER.
4. Negative balances displayed with a red color indicator.
5. Loading state while computing.
6. All labels in Arabic.

**Dependencies**: T015 (calculator exists).

**Acceptance criteria**:
- Providers compile.
- Screen shows 3 balance cards.
- Negative balances shown in red.
- Zeroes shown correctly.
- Arabic labels.

---

## Phase 7: Dashboard Cards (US9)

**Purpose**: Build partial dashboard with 5 cards.

### T017 — Create dashboard queries and providers

- [x] T017 [US9] Create dashboard data and providers in `motaz_app_flutter/lib/features/dashboard/`

**Objective**: Build the dashboard query layer and Riverpod providers.

**Before implementing**: Read `specs/006-expenses-profit/contracts/endpoints.md` §DashboardQueries. Read `specs/006-expenses-profit/spec.md` FR-033 through FR-035.

**Files to create**:
- `motaz_app_flutter/lib/features/dashboard/data/dashboard_queries.dart`
- `motaz_app_flutter/lib/features/dashboard/application/dashboard_providers.dart`

**Exact scope — queries**:
1. Create class `DashboardQueries` with constructor `DashboardQueries(this._db, this._engine, this._balanceCalc)` taking `AppDatabase`, `ProfitEngine`, `PartyBalanceCalculator`.
2. Implement `Future<int> getThisMonthNetProfit()`:
   - `final now = DateTime.now();`
   - Return `_engine.computeMonthlyNetProfit(now.year, now.month)`.
3. Implement `Future<({int ownerBalance, int partnerBalance, int marginBalance})> getPartyBalances()`:
   - Return `_balanceCalc.computeAllBalances()`.
4. Implement `Future<Map<ExpenseCategory, int>> getThisMonthExpensesByCategory()`:
   - For each of the 5 categories, query `SELECT COALESCE(SUM(amount), 0) FROM expenses WHERE category = ? AND status = 0 AND expenseDate >= monthStart AND expenseDate < monthEnd`.
   - Return a map of all 5 categories with their totals.

**Exact scope — providers**:
1. `final dashboardQueriesProvider = Provider<DashboardQueries>((ref) => DashboardQueries(ref.watch(appDatabaseProvider), ref.watch(profitEngineProvider), ref.watch(partyBalanceCalculatorProvider)))`.
2. `final dashboardNetProfitProvider = FutureProvider<int>((ref) => ref.watch(dashboardQueriesProvider).getThisMonthNetProfit())`.
3. `final dashboardPartyBalancesProvider = FutureProvider<({int ownerBalance, int partnerBalance, int marginBalance})>((ref) => ref.watch(dashboardQueriesProvider).getPartyBalances())`.
4. `final dashboardExpenseSummaryProvider = FutureProvider<Map<ExpenseCategory, int>>((ref) => ref.watch(dashboardQueriesProvider).getThisMonthExpensesByCategory())`.

**Dependencies**: T011 (ProfitEngine), T015 (PartyBalanceCalculator).

**Acceptance criteria**:
- All query methods compile and return correct types.
- All 4 providers compile.
- Expense summary returns all 5 categories (even if 0).

---

### T018 — Create dashboard screen

- [x] T018 [US9] Create dashboard screen in `motaz_app_flutter/lib/features/dashboard/presentation/dashboard_screen.dart`

**Objective**: Build the dashboard with 5 cards.

**Before implementing**: Read `specs/006-expenses-profit/spec.md` US9, FR-033 through FR-035. Read `docs/implementation-plan.md` §14 (Dashboard Specification) for context on the full 9 cards — only 5 are built now.

**Files to create**:
- `motaz_app_flutter/lib/features/dashboard/presentation/dashboard_screen.dart`

**Exact scope**:
1. `DashboardScreen` — a `ConsumerWidget`.
2. Use `AppDrawerScaffold` with title "لوحة التحكم" and currentRoute "/dashboard".
3. Display 5 cards in a scrollable grid/list:
   - **Card 1**: "صافي ربح الشهر الحالي" — shows `dashboardNetProfitProvider` formatted as YER. Negative values in red.
   - **Card 2**: "رصيد المالك" — shows Owner balance from `dashboardPartyBalancesProvider`. Negative in red.
   - **Card 3**: "رصيد الشريك" — shows Partner balance. Negative in red.
   - **Card 4**: "رصيد الهامش" — shows Margin balance. Negative in red.
   - **Card 5**: "ملخص مصروفات الشهر" — shows expense breakdown by category from `dashboardExpenseSummaryProvider`. List each category with Arabic label and amount. Show total at bottom.
4. All amounts formatted as YER: `(value / 100).toStringAsFixed(2)`.
5. Show loading indicators while data loads. Show error state on failure.
6. Design cards to be visually consistent — use `Card` widgets with proper spacing, icons, and typography.
7. All labels in Arabic.

**Dependencies**: T017 (queries and providers ready).

**Acceptance criteria**:
- Screen shows exactly 5 cards.
- Net profit card updates with current month data.
- Party balance cards show cumulative balances.
- Expense summary shows all 5 categories with Arabic labels.
- All monetary values in YER format.
- Arabic labels throughout.

---

## Phase 8: Router Update & Placeholder Cleanup

**Purpose**: Connect new screens to the app router and remove placeholders.

### T019 — Update app router and delete placeholders

- [x] T019 Update router in `motaz_app_flutter/lib/core/router/app_router.dart` and delete placeholder files

**Objective**: Replace expense, party balance, and dashboard placeholder screens with real screens.

**Before implementing**: Read `motaz_app_flutter/lib/core/router/app_router.dart` current state. Check which placeholder imports to replace.

**Files to update**:
- `motaz_app_flutter/lib/core/router/app_router.dart`

**Files to delete**:
- `motaz_app_flutter/lib/features/expenses/presentation/placeholder_screen.dart`
- `motaz_app_flutter/lib/features/party_balances/presentation/placeholder_screen.dart`
- `motaz_app_flutter/lib/features/dashboard/presentation/placeholder_screen.dart`

**Exact scope**:
1. Replace import of `ExpensesPlaceholderScreen` with `ExpenseListScreen` from `../../features/expenses/presentation/expense_list_screen.dart`.
2. Replace import of `PartyBalancesPlaceholderScreen` with `PartyBalancesScreen` from `../../features/party_balances/presentation/party_balances_screen.dart`.
3. Replace import of `DashboardPlaceholderScreen` with `DashboardScreen` from `../../features/dashboard/presentation/dashboard_screen.dart`.
4. Update route `/expenses` to use `ExpenseListScreen()`.
5. Update route `/party-balances` to use `PartyBalancesScreen()`.
6. Update route `/dashboard` to use `DashboardScreen()`.
7. Add route for distribution screen: `GoRoute(path: '/distributions', builder: (context, state) => const DistributionScreen())`. Import from `../../features/profit_distribution/presentation/distribution_screen.dart`.
8. Delete the 3 placeholder files listed above.

**Dependencies**: T010 (expense list), T016 (party balances), T018 (dashboard), T014 (distribution).

**Acceptance criteria**:
- `/expenses` renders `ExpenseListScreen`.
- `/party-balances` renders `PartyBalancesScreen`.
- `/dashboard` renders `DashboardScreen`.
- `/distributions` renders `DistributionScreen`.
- 3 placeholder files deleted.
- `dart analyze` shows no errors in router file.

---

## Phase 9: Polish & Verification

**Purpose**: Final verification and cleanup.

### T020 — Run static analysis and verify compilation

- [x] T020 Run `dart analyze` in `motaz_app_flutter/` and fix any errors or warnings in new files

**Objective**: Ensure all new code compiles cleanly.

**Exact scope**:
1. Run `dart analyze` from `motaz_app_flutter/`.
2. Fix any errors or warnings in files created/modified in this feature.
3. Do NOT fix pre-existing warnings in other files (sync module, etc.).

**Dependencies**: All previous tasks.

**Acceptance criteria**:
- `dart analyze` reports 0 errors and 0 warnings in expense, profit_distribution, party_balances, and dashboard files.

---

### T021 — Verify end-to-end flow manually

- [x] T021 Verify: create expense, edit, void, distribute profit, view balances, check dashboard

**Objective**: Walk through the complete flow to ensure all pieces connect.

**Exact scope**:
1. Launch the app.
2. Navigate to expenses, create an OPERATIONAL expense for 5,000 YER.
3. Create a PRODUCTION expense for 3,000 YER.
4. Create an OWNER_DRAW expense for 2,000 YER.
5. Verify all 3 appear in the expense list with correct Arabic labels.
6. Edit the OPERATIONAL expense — change amount to 6,000 YER.
7. Void the PRODUCTION expense with reason "خطأ".
8. Navigate to distribution screen.
9. Select a past month that has invoices (or verify zero-profit distribution works).
10. Distribute — verify owner/partner/margin shares computed correctly.
11. Navigate to party balances — verify Owner balance reflects share minus draw.
12. Navigate to dashboard — verify all 5 cards show correct data.
13. Search expenses — verify debounce and filtering work.

**Dependencies**: T020 (clean compilation).

**Acceptance criteria**:
- All 13 steps complete without errors or crashes.
- All amounts display correctly in YER format.
- All Arabic labels render correctly in RTL.
- Profit distribution splits correctly with remainder to Margin.
- Party balances reflect draws correctly.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Schema)**: No dependencies — start immediately. T001→T003→T004 (T002 parallel with T001).
- **Phase 2 (Expense Repo)**: Depends on T004. T005→T006→T007 (sequential).
- **Phase 3 (Expense UI)**: T008→T009→T010 (sequential).
- **Phase 4 (Profit Engine)**: T011 depends on T004. T012 depends on T011.
- **Phase 5 (Distribution UI)**: T013→T014 (sequential).
- **Phase 6 (Party Balances)**: T015 depends on T004. T016 depends on T015.
- **Phase 7 (Dashboard)**: T017 depends on T011 + T015. T018 depends on T017.
- **Phase 8 (Router)**: Depends on T010, T014, T016, T018.
- **Phase 9 (Polish)**: Depends on all previous.

### Critical Path

```
T001 → T003 → T004 (Schema ready)
T004 → T005 → T006 → T007 (ExpenseRepo)
T007 → T008 → T009 → T010 (Expense UI)
T004 → T011 → T012 → T013 → T014 (Profit Distribution)
T004 → T015 → T016 (Party Balances)
T011 + T015 → T017 → T018 (Dashboard)
T010 + T014 + T016 + T018 → T019 (Router)
T019 → T020 → T021 (Verify)
```

### Parallel Opportunities

- T001 and T002 can run in parallel (different files).
- After T004 (schema ready): T005 and T011 and T015 can start in parallel (different feature directories).
- T009 and T014 are independent after their respective providers are ready.

---

## Implementation Strategy

### MVP First (Expense CRUD Only)

1. Complete Phase 1: T001–T004 (Schema)
2. Complete Phase 2: T005–T007 (ExpenseRepository)
3. Complete Phase 3: T008–T010 (Expense UI)
4. **STOP and VALIDATE**: Create, edit, void, search expenses.

### Full Delivery

5. Phase 4: T011–T012 (Profit Engine + Distribution Repo)
6. Phase 5: T013–T014 (Distribution UI)
7. Phase 6: T015–T016 (Party Balances)
8. Phase 7: T017–T018 (Dashboard Cards)
9. Phase 8: T019 (Router)
10. Phase 9: T020–T021 (Polish + Verify)

---

## Notes

- All monetary values use `int` (minor units). Display conversion: `(value / 100).toStringAsFixed(2)`.
- All UI text in Arabic. RTL layout.
- Follow the transaction + outbox pattern established in `ProductRepository`.
- The MonthlyDistributions table requires a schema migration (version 3 → 4).
- The Expenses table already exists from Phase 2 — no schema change needed for expenses.
- `ParentEntityType.EXPENSE` already exists — only `MONTHLY_DISTRIBUTION` needs to be added.
- ExpenseCategory enum values: OWNER_DRAW=0, PARTNER_DRAW=1, MARGIN_DRAW=2, OPERATIONAL=3, PRODUCTION=4.
- Profit calculation accounts for SalesReturns even though the table is empty until Phase 7 — queries use COALESCE to handle empty results.
- Do NOT implement full dashboard (9 cards) — only 5 cards for this phase.
- Do NOT implement reports or PDF — that's Phase 8.
- Do NOT implement sales returns — that's Phase 7.
