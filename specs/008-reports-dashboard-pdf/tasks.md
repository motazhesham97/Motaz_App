# Tasks: Reports, Statements, Dashboard & PDF

**Input**: Design documents from `/specs/008-reports-dashboard-pdf/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, quickstart.md

**Tests**: Not explicitly requested. Test tasks are omitted.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Flutter app**: `motaz_app/motaz_app_flutter/lib/`
- **Server**: `motaz_app/motaz_app_server/`
- All paths are relative to repository root `d:\Motaz_App2\`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add new dependencies and bundle the Arabic font asset required for PDF generation.

> ⚠️ Before implementing any task in this phase, read:
> - `.specify/memory/constitution.md`
> - `specs/008-reports-dashboard-pdf/plan.md`
> - `specs/008-reports-dashboard-pdf/research.md` (sections R1, R2)
> Do not guess architecture or framework behavior from memory.

- [X] T001 Add `pdf` and `printing` dependencies to `motaz_app/motaz_app_flutter/pubspec.yaml`
  - **Objective**: Add the two Dart packages required for PDF generation and sharing/printing.
  - **Files**: `motaz_app/motaz_app_flutter/pubspec.yaml`
  - **Scope**: Add `pdf: ^3.11.1` and `printing: ^5.13.3` under `dependencies`. Run `flutter pub get` to verify resolution.
  - **Dependencies**: None.
  - **Verification**: `flutter pub get` completes without errors. Both packages appear in `pubspec.lock`.

- [X] T002 Download and bundle Cairo Arabic TTF font files as Flutter assets in `motaz_app/motaz_app_flutter/assets/fonts/`
  - **Objective**: Bundle Cairo-Regular.ttf and Cairo-Bold.ttf so they are available offline for PDF generation.
  - **Files**: `motaz_app/motaz_app_flutter/assets/fonts/Cairo-Regular.ttf` [NEW], `motaz_app/motaz_app_flutter/assets/fonts/Cairo-Bold.ttf` [NEW], `motaz_app/motaz_app_flutter/pubspec.yaml` [MODIFY]
  - **Scope**: Download the two TTF files from Google Fonts (https://fonts.google.com/specimen/Cairo). Place them in `assets/fonts/`. Add both paths to the `flutter.assets` list in pubspec.yaml, under the existing `assets/config.json` entry.
  - **Dependencies**: None.
  - **Verification**: `flutter pub get` succeeds. Fonts are listed in the asset bundle. A test call to `rootBundle.load('assets/fonts/Cairo-Regular.ttf')` returns bytes without error.

- [X] T003 [P] Create shared money formatting utility in `motaz_app/motaz_app_flutter/lib/core/utils/money_formatter.dart`
  - **Objective**: Extract the repeated `_formatMoney` pattern used in dashboard_screen.dart and other screens into a single shared function.
  - **Files**: `motaz_app/motaz_app_flutter/lib/core/utils/money_formatter.dart` [NEW]
  - **Scope**: Create a top-level function `String formatMoney(int minorUnits)` that returns `'${(minorUnits / 100).toStringAsFixed(2)} ر.ي.'`. This must use integer division and string formatting only — no `double` in the actual money storage path (the `/ 100` is display formatting only). Also create `String formatMoneyPlain(int minorUnits)` that returns the numeric string without the currency suffix (for PDF table cells). No other logic.
  - **Dependencies**: None.
  - **Verification**: Calling `formatMoney(125000)` returns `'1250.00 ر.ي.'`. Calling `formatMoney(-50000)` returns `'-500.00 ر.ي.'`. Calling `formatMoneyPlain(125000)` returns `'1250.00'`.

- [X] T004 [P] Create shared DateRange model in `motaz_app/motaz_app_flutter/lib/core/utils/date_range.dart`
  - **Objective**: Create a value object representing a start/end date range with factory constructors for each quick filter.
  - **Files**: `motaz_app/motaz_app_flutter/lib/core/utils/date_range.dart` [NEW]
  - **Scope**: Create a `DateRange` class with `final DateTime start` and `final DateTime end` fields. Add factory constructors: `DateRange.today()`, `DateRange.thisWeek()` (Monday start, Sunday end per ISO 8601), `DateRange.thisMonth()` (1st to last day), `DateRange.thisYear()` (Jan 1 to Dec 31), `DateRange.allTime()` (DateTime(2000) to DateTime(2100)), `DateRange.custom(DateTime start, DateTime end)`. The custom factory must assert `start <= end`. Implement `==` and `hashCode` so this can be used as a Riverpod family key. Add a `String label` getter that returns the Arabic label for each type (e.g., `'اليوم'`, `'هذا الأسبوع'`, `'هذا الشهر'`, `'هذا العام'`, `'الكل'`, `'مخصص'`). Refer to `specs/008-reports-dashboard-pdf/data-model.md` for the exact fields.
  - **Dependencies**: None.
  - **Verification**: `DateRange.today().start` and `DateRange.today().end` span exactly one day. `DateRange.thisMonth()` on April 19 gives start=April 1, end=April 30. `DateRange.custom(DateTime(2026,5,1), DateTime(2026,3,1))` throws an assertion error.

**Checkpoint**: Setup complete. Dependencies installed, fonts bundled, shared utilities ready.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Replace the existing dashboard placeholder data with the full 9-card query/provider layer. Update existing dashboard screen to use the shared money formatter. This phase is blocking because US1 (Dashboard) and all report screens depend on these foundations.

> ⚠️ Before implementing any task in this phase, read:
> - `.specify/memory/constitution.md` (§I monetary rules, §IV data rules)
> - `specs/008-reports-dashboard-pdf/spec.md` (FR-001 through FR-010)
> - `specs/008-reports-dashboard-pdf/plan.md` (Query Design section)
> - `specs/008-reports-dashboard-pdf/data-model.md`
> Do not guess business rules or SQL from memory. Use the plan.md Query Design section for exact SQL.

- [X] T005 Refactor `motaz_app/motaz_app_flutter/lib/features/dashboard/presentation/dashboard_screen.dart` to use shared `formatMoney` from `core/utils/money_formatter.dart`
  - **Objective**: Remove the private `_formatMoney` method and import the shared one.
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/dashboard/presentation/dashboard_screen.dart` [MODIFY]
  - **Scope**: Replace `import` and all calls to `_formatMoney(x)` with `formatMoney(x)` from `core/utils/money_formatter.dart`. Delete the private `_formatMoney` method. No other changes.
  - **Dependencies**: T003.
  - **Verification**: `dart analyze` passes. Dashboard screen renders identically to before.

- [X] T006 Create value object classes for dashboard and activity feed in `motaz_app/motaz_app_flutter/lib/features/dashboard/data/dashboard_models.dart`
  - **Objective**: Define `ActivityFeedItem` and `ActivityType` enum so DashboardQueries can return typed data.
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/dashboard/data/dashboard_models.dart` [NEW]
  - **Scope**: Create `enum ActivityType { invoice, receipt, expense, returnItem, voidAction }`. Create `class ActivityFeedItem` with fields: `final ActivityType type`, `final String entityId`, `final String reference`, `final DateTime timestamp`. Constructor required. Refer to `data-model.md` ActivityFeedItem section for exact fields.
  - **Dependencies**: None.
  - **Verification**: File compiles without errors. `dart analyze` passes.

- [X] T007 Add `getTodayNetSales()` method to `motaz_app/motaz_app_flutter/lib/features/dashboard/data/dashboard_queries.dart`
  - **Objective**: Add a query that computes today's net sales (active invoice totals minus active return totals for today).
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/dashboard/data/dashboard_queries.dart` [MODIFY]
  - **Scope**: Add method `Future<int> getTodayNetSales() async`. Use `customSelect` with two queries as documented in plan.md Query Design Q1. Filter `sales_invoices` by `status = RecordStatus.ACTIVE.index` and `invoice_date` between today 00:00 and tomorrow 00:00. Similarly for `sales_returns`. Return `invoiceSum - discountSum - returnSum`. All values are minor-unit integers.
  - **Dependencies**: None.
  - **Verification**: Method returns `int`. With no data it returns 0. The SQL matches plan.md Q1.

- [X] T008 Add `getThisMonthNetSales()` method to `motaz_app/motaz_app_flutter/lib/features/dashboard/data/dashboard_queries.dart`
  - **Objective**: Compute this month's net sales. This reuses the existing `ProfitEngine.computeMonthlyNetSales` — just delegate to it.
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/dashboard/data/dashboard_queries.dart` [MODIFY]
  - **Scope**: Add method `Future<int> getThisMonthNetSales()`. Implementation: `final now = DateTime.now(); return _engine.computeMonthlyNetSales(now.year, now.month);`. The ProfitEngine already computes invoices minus returns for a given month, which matches FR-003.
  - **Dependencies**: None.
  - **Verification**: Method returns `int`. Delegating to ProfitEngine ensures consistency with the profit report.

- [X] T009 Add `getOutstandingReceivablesTotal()` method to `motaz_app/motaz_app_flutter/lib/features/dashboard/data/dashboard_queries.dart`
  - **Objective**: Compute the total remaining unpaid balances across all active invoices.
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/dashboard/data/dashboard_queries.dart` [MODIFY]
  - **Scope**: Add method `Future<int> getOutstandingReceivablesTotal() async`. Use `customSelect` with the SQL from plan.md Query Design Q2. For each active invoice: `total - allocated_receipts - active_returns`. Sum all rows where `remaining > 0`. Return the grand total as minor-unit integer. Must not use `double` in the computation.
  - **Dependencies**: None.
  - **Verification**: Method returns `int`. With no invoices, returns 0. With a fully-paid invoice, that invoice contributes 0.

- [X] T010 Add `getRecentActivityFeed()` method to `motaz_app/motaz_app_flutter/lib/features/dashboard/data/dashboard_queries.dart`
  - **Objective**: Return the 10 most recent actions across invoices, receipts, expenses, and returns.
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/dashboard/data/dashboard_queries.dart` [MODIFY]
  - **Scope**: Add import for `dashboard_models.dart`. Add method `Future<List<ActivityFeedItem>> getRecentActivityFeed() async`. Use `customSelect` with a UNION ALL query across `sales_invoices`, `receipts`, `expenses`, and `sales_returns` as documented in plan.md Q3. Each row returns type string, id, reference, and `created_at`. ORDER BY `created_at DESC LIMIT 10`. Map results to `List<ActivityFeedItem>`. For voided records (status != ACTIVE), set type to `ActivityType.voidAction`.
  - **Dependencies**: T006.
  - **Verification**: Returns `List<ActivityFeedItem>` with at most 10 items, sorted by timestamp descending.

- [X] T011 Add missing providers to `motaz_app/motaz_app_flutter/lib/features/dashboard/application/dashboard_providers.dart`
  - **Objective**: Add Riverpod FutureProviders for the 4 new dashboard queries.
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/dashboard/application/dashboard_providers.dart` [MODIFY]
  - **Scope**: Add 4 new providers: `dashboardTodayNetSalesProvider` (FutureProvider<int>), `dashboardThisMonthNetSalesProvider` (FutureProvider<int>), `dashboardReceivablesTotalProvider` (FutureProvider<int>), `dashboardActivityFeedProvider` (FutureProvider<List<ActivityFeedItem>>). Each delegates to the corresponding method on `dashboardQueriesProvider`. Import `dashboard_models.dart`.
  - **Dependencies**: T007, T008, T009, T010.
  - **Verification**: All 4 providers compile. `dart analyze` passes.

**Checkpoint**: Foundation ready. All 9 dashboard data sources available as providers. User story implementation can begin.

---

## Phase 3: User Story 1 — Dashboard with KPI Cards (Priority: P1) 🎯 MVP

**Goal**: Expand the existing dashboard from 5 cards to the full 9 KPI cards specified in FR-001 through FR-010.

**Independent Test**: Open the dashboard, verify all 9 cards render with correct values. Create/void data, verify dashboard refreshes.

> ⚠️ Before implementing this task, read:
> - `specs/008-reports-dashboard-pdf/spec.md` (User Story 1, FR-001 to FR-010)
> - `specs/008-reports-dashboard-pdf/data-model.md` (DashboardData section)
> - The existing `motaz_app/motaz_app_flutter/lib/features/dashboard/presentation/dashboard_screen.dart`
> Follow the approved constitution and spec boundaries. Do not add cards beyond the 9 specified.

- [X] T012 [US1] Expand `motaz_app/motaz_app_flutter/lib/features/dashboard/presentation/dashboard_screen.dart` to display all 9 KPI cards
  - **Objective**: Rebuild the dashboard screen to show all 9 cards as specified in the implementation plan §14 and spec FR-001.
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/dashboard/presentation/dashboard_screen.dart` [MODIFY]
  - **Scope**: Add `ref.watch()` calls for the 4 new providers from T011. Reorganize the `Column` children to render 9 cards in this exact order: (1) Today Net Sales, (2) This Month Net Sales, (3) This Month Net Profit, (4) Outstanding Receivables Total, (5) Owner Balance, (6) Partner Balance, (7) Margin Balance, (8) This Month Expense Summary by Type, (9) Recent Activity Feed. Use `formatMoney()` from shared utility. For the activity feed, render a `ListView` of `ListTile` widgets showing type icon, reference, and timestamp. For empty states: show `'0.00 ر.ي.'` for monetary cards and `'لا توجد أنشطة حديثة'` for the activity feed when empty. Keep AppDrawerScaffold wrapper. Keep Arabic labels for all cards.
  - **Dependencies**: T005, T011.
  - **Verification**: Dashboard shows 9 cards. All monetary values formatted as YER. Empty states display correctly. Activity feed shows at most 10 items. `dart analyze` passes.

**Checkpoint**: Dashboard complete with all 9 KPI cards. US1 independently verifiable.

---

## Phase 4: User Story 2 — Sales Report by Period (Priority: P1)

**Goal**: Implement the Sales Report with date range filtering and display of active invoices with net sales computation.

**Independent Test**: Create invoices across dates, open Sales Report, apply date filter, verify only matching invoices appear with correct totals.

> ⚠️ Before implementing tasks in this phase, read:
> - `specs/008-reports-dashboard-pdf/spec.md` (User Story 2, FR-011 to FR-018)
> - `specs/008-reports-dashboard-pdf/plan.md` (Query Design section)
> - `specs/008-reports-dashboard-pdf/data-model.md` (SalesReportRow, SalesReportSummary)
> Follow the approved constitution. All money in minor-unit integers. No double in money path.

- [X] T013 [P] [US2] Create report value objects in `motaz_app/motaz_app_flutter/lib/features/reports/data/report_models.dart`
  - **Objective**: Define the Dart value objects for all report result types.
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/reports/data/report_models.dart` [NEW]
  - **Scope**: Create all report model classes as documented in `data-model.md`: `SalesReportRow`, `SalesReportSummary`, `ProductSalesRow`, `ExpenseByCategoryRow`, `ProfitReportData`, `ProfitDistribution`, `ClientStatementEntry`, `ClientStatementData`, `ReceivablesRow`, `AgingRow`, `PartyBalanceRow`. Also create `enum StatementEntryType { invoice, receipt, returnItem }`. All monetary fields must be `int` (minor-unit integers). No `double` for money. The `percentageOfTotal` field in `ProductSalesRow` and `ExpenseByCategoryRow` is `double` (it is a percentage, not money).
  - **Dependencies**: None.
  - **Verification**: File compiles. `dart analyze` passes. All monetary fields are `int`.

- [X] T014 [P] [US2] Create date range picker widget in `motaz_app/motaz_app_flutter/lib/features/reports/presentation/widgets/date_range_picker.dart`
  - **Objective**: Build a reusable widget that shows Start/End date pickers and quick filter chips.
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/reports/presentation/widgets/date_range_picker.dart` [NEW]
  - **Scope**: Create a `DateRangePickerWidget` (StatefulWidget) that takes `onRangeChanged: void Function(DateRange)` callback. Display: a Row of quick filter chips (اليوم, هذا الأسبوع, هذا الشهر, هذا العام, الكل) plus two date fields for Start and End that open `showDatePicker`. When a quick filter is tapped, auto-populate both date fields and call `onRangeChanged`. When custom dates are entered, validate that start ≤ end (FR-013) and show a SnackBar error if invalid. Default to `DateRange.thisMonth()` on first render.
  - **Dependencies**: T004.
  - **Verification**: Widget renders 5 chips and 2 date fields. Tapping "هذا الشهر" populates correct dates. Setting end before start shows error. Widget calls `onRangeChanged` with correct `DateRange`.

- [X] T015 [P] [US2] Create report summary row widget in `motaz_app/motaz_app_flutter/lib/features/reports/presentation/widgets/report_summary_row.dart`
  - **Objective**: Build a reusable widget for displaying total/subtotal rows in report screens.
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/reports/presentation/widgets/report_summary_row.dart` [NEW]
  - **Scope**: Create `ReportSummaryRow` widget that takes `String label` and `int amountMinorUnits`. Renders a Row with bold label on the right (RTL) and `formatMoney(amount)` on the left. Optional `bool isGrandTotal` parameter for stronger styling. Use shared `formatMoney()`.
  - **Dependencies**: T003.
  - **Verification**: Widget renders label and formatted amount. `dart analyze` passes.

- [X] T016 [US2] Create sales report query in `motaz_app/motaz_app_flutter/lib/features/reports/data/report_queries.dart`
  - **Objective**: Implement the SQL query for the sales report.
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/reports/data/report_queries.dart` [NEW]
  - **Scope**: Create `class ReportQueries` that takes `AppDatabase _db` in constructor. Add method `Future<SalesReportSummary> getSalesReport(DateRange range) async`. Query `sales_invoices` joined with `clients` for active invoices in the date range. Also query `sales_returns` for total returns in the range. Return `SalesReportSummary` with rows, gross sales, total discounts, total returns, and net sales. Use `customSelect` with raw SQL. All values are `int` (minor-unit integers). Refer to plan.md for SQL patterns.
  - **Dependencies**: T004, T013.
  - **Verification**: Method compiles. Returns `SalesReportSummary`. With no data, returns empty rows and zeroes.

- [X] T017 [US2] Create sales report provider in `motaz_app/motaz_app_flutter/lib/features/reports/application/report_providers.dart`
  - **Objective**: Create a Riverpod provider for the sales report query.
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/reports/application/report_providers.dart` [NEW]
  - **Scope**: Create `reportQueriesProvider` (Provider<ReportQueries>) that reads `appDatabaseProvider`. Create `salesReportProvider` as `FutureProvider.family<SalesReportSummary, DateRange>` that reads `reportQueriesProvider` and calls `getSalesReport(range)`. Import `database_provider.dart`, `report_queries.dart`, `report_models.dart`, and `date_range.dart`.
  - **Dependencies**: T016.
  - **Verification**: Provider compiles. `dart analyze` passes.

- [X] T018 [US2] Create sales report screen in `motaz_app/motaz_app_flutter/lib/features/reports/presentation/sales_report_screen.dart`
  - **Objective**: Implement the sales report UI with date filtering and data display.
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/reports/presentation/sales_report_screen.dart` [NEW]
  - **Scope**: Create `SalesReportScreen` (ConsumerStatefulWidget). Layout: AppDrawerScaffold with title `'تقرير المبيعات'` and currentRoute `'/reports/sales'`. Body: `DateRangePickerWidget` at top, then a `ListView` of invoice rows (local_ref, client name, date, total, discount), then a summary section showing gross sales, total discounts, total returns, and net sales using `ReportSummaryRow`. Use `salesReportProvider(dateRange)`. On range change, update local state to trigger re-watch. Show `CircularProgressIndicator` while loading. Show `'لا توجد بيانات'` for empty results. Use `formatMoney()` for all amounts.
  - **Dependencies**: T014, T015, T017.
  - **Verification**: Screen renders date picker, invoice list, and summary. Changing date range reloads data. Empty state shown when no data. All amounts formatted as YER.

**Checkpoint**: Sales Report complete. US2 independently verifiable.

---

## Phase 5: User Story 5 — Profit Report by Period (Priority: P1)

**Goal**: Implement the profit report showing gross sales, discounts, returns, net sales, expenses breakdown, and net profit. Show distribution rows for monthly periods.

**Independent Test**: Create invoices, expenses, and a distribution for a month, open Profit Report, verify all figures match hand calculation.

> ⚠️ Before implementing, read:
> - `specs/008-reports-dashboard-pdf/spec.md` (User Story 5, FR-023 to FR-025)
> - `specs/008-reports-dashboard-pdf/data-model.md` (ProfitReportData, ProfitDistribution)
> - The existing `motaz_app/motaz_app_flutter/lib/features/profit_distribution/data/profit_engine.dart`
> Accounting rule: Net Profit = Net Sales − Operational Expenses − Production Expenses. Distribution only for monthly periods.

- [X] T019 [US5] Add `getProfitReport(DateRange)` method to `motaz_app/motaz_app_flutter/lib/features/reports/data/report_queries.dart`
  - **Objective**: Implement the profit report query.
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/reports/data/report_queries.dart` [MODIFY]
  - **Scope**: Add method `Future<ProfitReportData> getProfitReport(DateRange range) async`. Query gross sales (SUM of invoice totals), discounts (SUM of invoice discounts), returns (SUM of return totals), operational expenses, and production expenses for the date range. Compute net sales and net profit using the formulas from constitution §I: Net Sales = Gross Sales − Discounts − Returns; Net Profit = Net Sales − Operational − Production. For monthly periods (same year+month for start and end), also query `monthly_distributions` for that year/month to populate the `distribution` field. For non-monthly ranges, set `distribution` to null. Use `ExpenseCategory.OPERATIONAL.index` and `ExpenseCategory.PRODUCTION.index` for expense filtering. All values `int`.
  - **Dependencies**: T013, T016 (file exists).
  - **Verification**: Returns `ProfitReportData`. With no data, all fields are 0 and distribution is null. For a monthly range with a distribution record, distribution is populated.

- [X] T020 [US5] Add `profitReportProvider` to `motaz_app/motaz_app_flutter/lib/features/reports/application/report_providers.dart`
  - **Objective**: Create the Riverpod provider for the profit report.
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/reports/application/report_providers.dart` [MODIFY]
  - **Scope**: Add `profitReportProvider` as `FutureProvider.family<ProfitReportData, DateRange>` that calls `reportQueries.getProfitReport(range)`.
  - **Dependencies**: T019.
  - **Verification**: Provider compiles. `dart analyze` passes.

- [X] T021 [US5] Create profit report screen in `motaz_app/motaz_app_flutter/lib/features/reports/presentation/profit_report_screen.dart`
  - **Objective**: Build the profit report UI.
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/reports/presentation/profit_report_screen.dart` [NEW]
  - **Scope**: Create `ProfitReportScreen` (ConsumerStatefulWidget). Layout: AppDrawerScaffold, DateRangePickerWidget, then a breakdown section using `ReportSummaryRow` for each line: Gross Sales, (−) Discounts, (−) Returns, = Net Sales, (−) Operational Expenses, (−) Production Expenses, = Net Profit. If `distribution` is not null, show a section below with Owner Share, Partner Share, Margin Share. If distribution is null and period is non-monthly, show `'فترة غير شهرية - عرض فقط'`. Empty state for no data. Use `formatMoney()`.
  - **Dependencies**: T014, T015, T020.
  - **Verification**: Screen shows complete profit breakdown. Distribution section appears only for monthly periods with a distribution record. All amounts in YER.

**Checkpoint**: Profit Report complete. US5 independently verifiable.

---

## Phase 6: User Story 6 — Client Statement (Priority: P1)

**Goal**: Implement the client statement showing a chronological ledger of transactions for a selected client and date range, with running balance and final balance.

**Independent Test**: Select a client with invoices, receipts, and returns. Verify running balance is correct after each entry. Verify final balance matches.

> ⚠️ Before implementing, read:
> - `specs/008-reports-dashboard-pdf/spec.md` (User Story 6, FR-026 to FR-028)
> - `specs/008-reports-dashboard-pdf/plan.md` (Query Design Q6)
> - `specs/008-reports-dashboard-pdf/data-model.md` (ClientStatementEntry, ClientStatementData)
> Running balance formula: previousBalance + invoice − receipt − return. Opening balance is computed from pre-range transactions.

- [X] T022 [US6] Create client statement queries in `motaz_app/motaz_app_flutter/lib/features/reports/data/client_statement_queries.dart`
  - **Objective**: Implement the SQL queries for client statement and opening balance.
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/reports/data/client_statement_queries.dart` [NEW]
  - **Scope**: Create `class ClientStatementQueries` with `AppDatabase _db` constructor. Add method `Future<ClientStatementData> getClientStatement(String clientId, DateRange range) async`. First, compute the opening balance using price-range transactions: SUM(invoices before range) − SUM(receipts before range) − SUM(returns before range for that client). Use the exact SQL from plan.md Q6 and the opening balance query from research.md R6. Then query in-range transactions using UNION ALL across invoices, receipts, and returns for the client with status = ACTIVE. Sort by date ASC. Compute running balance in Dart: start from openingBalance, for each entry add invoices and subtract receipts/returns. Query the client's `displayName` from `clients` table. Return `ClientStatementData` with all fields populated. All amounts as `int`.
  - **Dependencies**: T004, T013.
  - **Verification**: Method returns `ClientStatementData`. Opening balance correct. Running balance after each entry is correct. Final closingBalance equals openingBalance + SUM(invoices) − SUM(receipts) − SUM(returns).

- [X] T023 [US6] Add `clientStatementProvider` to `motaz_app/motaz_app_flutter/lib/features/reports/application/report_providers.dart`
  - **Objective**: Create the Riverpod provider for the client statement query.
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/reports/application/report_providers.dart` [MODIFY]
  - **Scope**: Create `clientStatementQueriesProvider` (Provider<ClientStatementQueries>). Create `clientStatementProvider` as `FutureProvider.family<ClientStatementData, ({String clientId, DateRange range})>` that calls `getClientStatement(arg.clientId, arg.range)`. The family key is a record type.
  - **Dependencies**: T022.
  - **Verification**: Provider compiles. `dart analyze` passes.

- [X] T024 [US6] Create client statement screen in `motaz_app/motaz_app_flutter/lib/features/reports/presentation/client_statement_screen.dart`
  - **Objective**: Build the client statement UI with client selector, date range, and transaction ledger.
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/reports/presentation/client_statement_screen.dart` [NEW]
  - **Scope**: Create `ClientStatementScreen` (ConsumerStatefulWidget). Layout: AppDrawerScaffold with title `'كشف حساب عميل'`. Top section: client dropdown/search using existing client list from `appDatabaseProvider` (query all active clients). Below: `DateRangePickerWidget`. Below: a table/list showing transaction rows with columns: Date, Type (فاتورة/سند قبض/مرتجع), Reference, Amount, Running Balance. Type column shows Arabic labels. Below the list: a final row showing closing balance labeled as `'رصيد مدين'` (debtor/positive) or `'رصيد دائن'` (creditor/negative). If no client selected, show `'اختر عميلاً'`. If no transactions, show opening balance and `'لا توجد حركات في هذه الفترة'` per FR-028. Use `formatMoney()`.
  - **Dependencies**: T014, T023.
  - **Verification**: Screen shows client selector, date picker, transaction ledger. Running balances are correct. Final balance labeled correctly. Empty state works.

**Checkpoint**: Client Statement complete. US6 independently verifiable.

---

## Phase 7: User Story 10 — PDF Export (Priority: P1)

**Goal**: Implement PDF generation with Arabic RTL support for all reports and client statement. Add export actions to existing report screens.

**Independent Test**: Generate a sales report PDF and a client statement PDF. Verify Arabic text renders correctly RTL. Verify date range matches.

> ⚠️ Before implementing, read:
> - `specs/008-reports-dashboard-pdf/spec.md` (User Story 10, FR-039 to FR-045)
> - `specs/008-reports-dashboard-pdf/research.md` (R1 Arabic RTL PDF, R2 Font Strategy)
> - The `pdf` package docs for `pw.Directionality`, `pw.Font.ttf()`, `pw.TableHelper.fromTextArray()`
> Use Cairo font from bundled assets. PDF must work offline.

- [X] T025 [US10] Create PDF styles module in `motaz_app/motaz_app_flutter/lib/features/reports/pdf/pdf_styles.dart`
  - **Objective**: Define shared PDF styles, Arabic font loading, and RTL configuration.
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/reports/pdf/pdf_styles.dart` [NEW]
  - **Scope**: Create `class PdfStyles`. Add static async method `Future<PdfStyles> load()` that loads `Cairo-Regular.ttf` and `Cairo-Bold.ttf` from `rootBundle` and creates `pw.Font` instances. Expose: `pw.Font regularFont`, `pw.Font boldFont`, `pw.TextStyle bodyStyle` (Cairo Regular, 10pt), `pw.TextStyle headerStyle` (Cairo Bold, 14pt), `pw.TextStyle titleStyle` (Cairo Bold, 18pt), `pw.TextStyle tableHeaderStyle` (Cairo Bold, 9pt, white foreground), `pw.TextStyle tableCellStyle` (Cairo Regular, 9pt). Add method `pw.Document createDocument()` that returns a `pw.Document(theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont))`.  All text styles must use the loaded Cairo font. Import `package:pdf/pdf.dart` and `package:pdf/widgets.dart` as `pw`.
  - **Dependencies**: T002.
  - **Verification**: `PdfStyles.load()` completes without error. `createDocument()` returns a valid `pw.Document`.

- [X] T026 [US10] Create PDF generator orchestrator in `motaz_app/motaz_app_flutter/lib/features/reports/pdf/pdf_generator.dart`
  - **Objective**: Build the orchestration layer that takes a generated PDF document and allows sharing/printing.
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/reports/pdf/pdf_generator.dart` [NEW]
  - **Scope**: Create `class PdfGenerator`. Add static method `Future<void> shareOrPrint(pw.Document doc, String fileName) async`. Implementation: convert `doc` to bytes via `doc.save()`, then call `Printing.sharePdf(bytes: bytes, filename: fileName)`. Add static method `Future<void> printDoc(pw.Document doc) async` that calls `Printing.layoutPdf(onLayout: (_) => doc.save())`. Import `package:printing/printing.dart`.
  - **Dependencies**: T001.
  - **Verification**: Methods compile without errors. `dart analyze` passes.

- [X] T027 [US10] Create sales report PDF template in `motaz_app/motaz_app_flutter/lib/features/reports/pdf/pdf_templates/sales_report_pdf.dart`
  - **Objective**: Generate a PDF document from `SalesReportSummary` data.
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/reports/pdf/pdf_templates/sales_report_pdf.dart` [NEW]
  - **Scope**: Create `class SalesReportPdf`. Add static method `pw.Document generate(PdfStyles styles, SalesReportSummary data, DateRange range)`. Build a multi-page document with: (1) Title `'تقرير المبيعات'` using `titleStyle`, (2) Date range subtitle, (3) A table with columns: المرجع, العميل, التاريخ, الإجمالي, الخصم — using `pw.TableHelper.fromTextArray()`, (4) Summary rows: Gross Sales, Discounts, Returns, Net Sales. Wrap all content in `pw.Directionality(textDirection: pw.TextDirection.rtl, child: ...)` for RTL layout. Use `formatMoneyPlain()` for table cells. For empty data, show `'لا توجد بيانات'` centered. All page layout RTL.
  - **Dependencies**: T025, T013.
  - **Verification**: Generates a valid `pw.Document`. Document has at least 1 page. Arabic text is wrapped in RTL directionality.

- [X] T028 [US10] Create client statement PDF template in `motaz_app/motaz_app_flutter/lib/features/reports/pdf/pdf_templates/client_statement_pdf.dart`
  - **Objective**: Generate a PDF document from `ClientStatementData`.
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/reports/pdf/pdf_templates/client_statement_pdf.dart` [NEW]
  - **Scope**: Create `class ClientStatementPdf`. Add static method `pw.Document generate(PdfStyles styles, ClientStatementData data)`. Build document with: (1) Title `'كشف حساب عميل'`, (2) Client name, (3) Date range, (4) Opening balance row, (5) Table with columns: التاريخ, النوع, المرجع, المبلغ, الرصيد — populated from entries list, (6) Closing balance row at bottom labeled as مدين/دائن. RTL directionality. Use `formatMoneyPlain()`. Empty entries → `'لا توجد حركات'`.
  - **Dependencies**: T025, T013.
  - **Verification**: Generates valid `pw.Document`. Contains client name, transaction table, and closing balance.

- [X] T029 [US10] Add "تصدير PDF" button to sales report screen in `motaz_app/motaz_app_flutter/lib/features/reports/presentation/sales_report_screen.dart`
  - **Objective**: Wire the PDF export action to the sales report screen.
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/reports/presentation/sales_report_screen.dart` [MODIFY]
  - **Scope**: Add a FloatingActionButton or AppBar action with icon `Icons.picture_as_pdf` and label `'تصدير PDF'`. On tap: load `PdfStyles`, call `SalesReportPdf.generate(styles, currentData, currentRange)`, then call `PdfGenerator.shareOrPrint(doc, 'sales_report.pdf')`. Show a `CircularProgressIndicator` during generation. Disable button if data is empty or loading.
  - **Dependencies**: T018, T026, T027.
  - **Verification**: Tapping the button generates and opens the share sheet with a PDF. PDF contains the correct data. Button disabled when no data loaded.

- [X] T030 [US10] Add "تصدير PDF" button to client statement screen in `motaz_app/motaz_app_flutter/lib/features/reports/presentation/client_statement_screen.dart`
  - **Objective**: Wire the PDF export action to the client statement screen.
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/reports/presentation/client_statement_screen.dart` [MODIFY]
  - **Scope**: Add PDF export button, same pattern as T029 but using `ClientStatementPdf.generate(styles, currentStatementData)`. File name: `'client_statement_${clientName}.pdf'`.
  - **Dependencies**: T024, T026, T028.
  - **Verification**: PDF generated for selected client. Contains correct client name and transactions.

**Checkpoint**: PDF generation infrastructure complete. Sales Report PDF and Client Statement PDF working. Remaining report PDFs will be added in later phases.

---

## Phase 8: User Story 3 — Sales by Product Report (Priority: P2)

**Goal**: Implement the Sales by Product report and its PDF export.

**Independent Test**: Create invoices with multiple products, open Sales by Product report, verify aggregated quantities and revenues per product.

> ⚠️ Before implementing, read:
> - `specs/008-reports-dashboard-pdf/spec.md` (User Story 3, FR-019 to FR-020)
> - `specs/008-reports-dashboard-pdf/plan.md` (Query Design Q4)
> - `specs/008-reports-dashboard-pdf/data-model.md` (ProductSalesRow)

- [ ] T031 [US3] Add `getSalesByProduct(DateRange)` to `motaz_app/motaz_app_flutter/lib/features/reports/data/report_queries.dart`
  - **Objective**: Implement the SQL query for sales grouped by product.
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/reports/data/report_queries.dart` [MODIFY]
  - **Scope**: Add method `Future<List<ProductSalesRow>> getSalesByProduct(DateRange range) async`. Use `customSelect` as documented in plan.md Q4: JOIN `sales_invoice_lines`, `sales_invoices`, `products`. GROUP BY product. Also query return lines to subtract returned quantities/amounts. Compute `percentageOfTotal` for each row (row revenue / grand total * 100, returns 0.0 if grand total is 0). ORDER BY revenue DESC. Return `List<ProductSalesRow>`. All monetary values `int`.
  - **Dependencies**: T013.
  - **Verification**: Returns list of `ProductSalesRow`. With no data, returns empty list. Products with no sales in range are excluded.

- [ ] T032 [US3] Add `salesByProductProvider` to `motaz_app/motaz_app_flutter/lib/features/reports/application/report_providers.dart`
  - **Objective**: Create the Riverpod provider.
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/reports/application/report_providers.dart` [MODIFY]
  - **Scope**: Add `salesByProductProvider` as `FutureProvider.family<List<ProductSalesRow>, DateRange>`.
  - **Dependencies**: T031.
  - **Verification**: Compiles. `dart analyze` passes.

- [ ] T033 [US3] Create sales by product screen in `motaz_app/motaz_app_flutter/lib/features/reports/presentation/sales_by_product_screen.dart`
  - **Objective**: Build the sales by product report UI and PDF export.
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/reports/presentation/sales_by_product_screen.dart` [NEW]
  - **Scope**: Create `SalesByProductScreen`. AppDrawerScaffold, DateRangePickerWidget, then a table showing: Product Name, Quantity Sold, Revenue, % of Total. Grand total row at bottom. PDF export button that generates PDF using a new `SalesByProductPdf` template.
  - **Dependencies**: T014, T015, T032, T025, T026.
  - **Verification**: Screen shows product rows with correct aggregation. PDF export works.

- [ ] T034 [P] [US3] Create sales by product PDF template in `motaz_app/motaz_app_flutter/lib/features/reports/pdf/pdf_templates/sales_by_product_pdf.dart`
  - **Objective**: PDF template for sales by product report.
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/reports/pdf/pdf_templates/sales_by_product_pdf.dart` [NEW]
  - **Scope**: Create `SalesByProductPdf` with static `generate()` method. Table columns: المنتج, الكمية, الإيرادات, النسبة. RTL. Grand total row.
  - **Dependencies**: T025, T013.
  - **Verification**: Generates valid PDF with product data.

**Checkpoint**: Sales by Product report complete.

---

## Phase 9: User Story 4 — Expenses by Type Report (Priority: P2)

**Goal**: Implement the expenses by category report and PDF export.

> ⚠️ Before implementing, read: spec.md US4, FR-021 to FR-022.

- [ ] T035 [US4] Add `getExpensesByType(DateRange)` to `motaz_app/motaz_app_flutter/lib/features/reports/data/report_queries.dart`
  - **Objective**: Query expenses grouped by the 5 approved categories.
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/reports/data/report_queries.dart` [MODIFY]
  - **Scope**: Add method returning `Future<List<ExpenseByCategoryRow>>`. Query `expenses` table with `status = ACTIVE`, grouped by `category`, within date range. Include all 5 `ExpenseCategory` values. Categories with zero use 0. Compute percentage. Use Arabic category labels from the existing `categoryLabel()` function in `expense_form_screen.dart` (or inline the mapping).
  - **Dependencies**: T013.
  - **Verification**: Returns 5 rows (one per category). Voided expenses excluded.

- [ ] T036 [US4] Add `expensesByTypeProvider` to `motaz_app/motaz_app_flutter/lib/features/reports/application/report_providers.dart`
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/reports/application/report_providers.dart` [MODIFY]
  - **Dependencies**: T035.

- [ ] T037 [US4] Create expenses by type screen and PDF template in `motaz_app/motaz_app_flutter/lib/features/reports/presentation/expenses_by_type_screen.dart` and `motaz_app/motaz_app_flutter/lib/features/reports/pdf/pdf_templates/expenses_by_type_pdf.dart`
  - **Objective**: Build the UI and PDF for expense breakdown.
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/reports/presentation/expenses_by_type_screen.dart` [NEW], `motaz_app/motaz_app_flutter/lib/features/reports/pdf/pdf_templates/expenses_by_type_pdf.dart` [NEW]
  - **Scope**: Screen shows categories with totals and percentages, grand total. PDF export with RTL table. Arabic category labels.
  - **Dependencies**: T014, T015, T036, T025, T026.
  - **Verification**: All 5 categories shown. Grand total correct. PDF renders correctly.

**Checkpoint**: Expenses by Type report complete.

---

## Phase 10: User Story 7 — Receivables Report (Priority: P2)

**Goal**: Implement the receivables report showing clients with outstanding balances.

> ⚠️ Before implementing, read: spec.md US7, FR-029 to FR-032, plan.md Q2 for balance formula.
> Balance = invoiceTotal − allocatedReceipts − activeReturns.

- [ ] T038 [US7] Add `getReceivablesReport()` to `motaz_app/motaz_app_flutter/lib/features/reports/data/report_queries.dart`
  - **Objective**: Query all clients with outstanding balances.
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/reports/data/report_queries.dart` [MODIFY]
  - **Scope**: Add method `Future<List<ReceivablesRow>> getReceivablesReport() async`. Group by `client_id`. For each client: SUM(invoice totals), SUM(allocated receipts via receipt_allocations where receipt status=ACTIVE), SUM(active returns). remaining = invoiced − paid − returned. Include clients with remaining ≠ 0 (positive = debtor, negative = creditor per FR-031). Exclude zero-balance clients. Order by remaining DESC. Return `List<ReceivablesRow>`.
  - **Dependencies**: T013.
  - **Verification**: Zero-balance clients excluded. Negative balances included. Grand total computable from sum of remainingBalance.

- [ ] T039 [US7] Add `receivablesProvider` to `motaz_app/motaz_app_flutter/lib/features/reports/application/report_providers.dart`
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/reports/application/report_providers.dart` [MODIFY]
  - **Scope**: `FutureProvider<List<ReceivablesRow>>` (no family key — receivables is a point-in-time snapshot, not date-filtered).
  - **Dependencies**: T038.

- [ ] T040 [US7] Create receivables screen and PDF in `motaz_app/motaz_app_flutter/lib/features/reports/presentation/receivables_screen.dart` and `motaz_app/motaz_app_flutter/lib/features/reports/pdf/pdf_templates/receivables_pdf.dart`
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/reports/presentation/receivables_screen.dart` [NEW], `motaz_app/motaz_app_flutter/lib/features/reports/pdf/pdf_templates/receivables_pdf.dart` [NEW]
  - **Scope**: Screen: table with client name, total invoiced, total paid, total returned, remaining. Credit balances marked with `'دائن'`. Grand total row. PDF with same layout. No date picker (receivables is current snapshot).
  - **Dependencies**: T015, T039, T025, T026.
  - **Verification**: Zero-balance clients absent. Credit clients marked. Grand total correct.

**Checkpoint**: Receivables Report complete.

---

## Phase 11: User Story 9 — Party Balances Report (Priority: P2)

**Goal**: Implement the party balances report for Owner, Partner, and The Margin.

> ⚠️ Before implementing, read: spec.md US9, FR-036 to FR-038. Balance = accumulated shares − draws.

- [ ] T041 [US9] Add `getPartyBalancesReport()` to `motaz_app/motaz_app_flutter/lib/features/reports/data/report_queries.dart`
  - **Objective**: Query accumulated shares and draws for each party.
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/reports/data/report_queries.dart` [MODIFY]
  - **Scope**: Add method `Future<List<PartyBalanceRow>> getPartyBalancesReport() async`. For each of the 3 parties (Owner, Partner, Margin): query `monthly_distributions` for accumulated shares (SUM of `owner_share`/`partner_share`/`margin_share` where status = ACTIVE), query `expenses` for draws (SUM of amount where category = OWNER_DRAW/PARTNER_DRAW/MARGIN_DRAW and status = ACTIVE). Balance = shares − draws. Return 3 `PartyBalanceRow` objects with Arabic names: `'المالك'`, `'الشريك'`, `'الهامش'`. Negative balances are valid.
  - **Dependencies**: T013.
  - **Verification**: Returns exactly 3 rows. Negative balances allowed.

- [ ] T042 [US9] Add `partyBalancesReportProvider` to `motaz_app/motaz_app_flutter/lib/features/reports/application/report_providers.dart`
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/reports/application/report_providers.dart` [MODIFY]
  - **Dependencies**: T041.

- [ ] T043 [US9] Create party balances report screen and PDF in `motaz_app/motaz_app_flutter/lib/features/reports/presentation/party_balances_report_screen.dart` and `motaz_app/motaz_app_flutter/lib/features/reports/pdf/pdf_templates/party_balances_pdf.dart`
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/reports/presentation/party_balances_report_screen.dart` [NEW], `motaz_app/motaz_app_flutter/lib/features/reports/pdf/pdf_templates/party_balances_pdf.dart` [NEW]
  - **Scope**: Screen: 3 rows showing party name, accumulated shares, draws, current balance. Negative balances shown in red. No date picker (cumulative). PDF with same layout, RTL.
  - **Dependencies**: T015, T042, T025, T026.
  - **Verification**: 3 parties shown. Negative balances displayed and colored. PDF correct.

**Checkpoint**: Party Balances Report complete.

---

## Phase 12: User Story 8 — Receivables Aging Report (Priority: P3)

**Goal**: Implement the receivables aging report with time buckets.

> ⚠️ Before implementing, read: spec.md US8, FR-033 to FR-035, plan.md Q5, constitution §IV aging rule.
> Buckets: Current (0–30 days), 31–60, 61–90, Over 90. Based on invoice date.

- [ ] T044 [US8] Add `getReceivablesAging()` to `motaz_app/motaz_app_flutter/lib/features/reports/data/report_queries.dart`
  - **Objective**: Query outstanding receivables with aging buckets.
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/reports/data/report_queries.dart` [MODIFY]
  - **Scope**: Add method `Future<List<AgingRow>> getReceivablesAging() async`. Use the SQL from plan.md Q5 to get per-invoice remaining balances and age in days. Then in Dart, group by client and distribute each invoice's remaining balance into the correct bucket (0–30, 31–60, 61–90, >90). Return `List<AgingRow>` with per-client bucket amounts and row total. Exclude fully-paid invoices (remaining ≤ 0).
  - **Dependencies**: T013.
  - **Verification**: Invoices correctly bucketed by age. Partially paid invoices show only remaining amount.

- [ ] T045 [US8] Add `receivablesAgingProvider` and create screen and PDF
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/reports/application/report_providers.dart` [MODIFY], `motaz_app/motaz_app_flutter/lib/features/reports/presentation/receivables_aging_screen.dart` [NEW], `motaz_app/motaz_app_flutter/lib/features/reports/pdf/pdf_templates/receivables_aging_pdf.dart` [NEW]
  - **Scope**: Provider: `FutureProvider<List<AgingRow>>`. Screen: table with client, Current, 31–60, 61–90, >90, Total columns. Grand total row at bottom. Arabic column headers: `'جاري'`, `'31-60'`, `'61-90'`, `'+90'`, `'الإجمالي'`. PDF: same table, RTL. Empty state if no receivables.
  - **Dependencies**: T044, T014, T015, T025, T026.
  - **Verification**: Buckets correct. Grand total row sums all buckets. Empty state works.

**Checkpoint**: Receivables Aging complete.

---

## Phase 13: User Story 4 — Reports Hub & Profit PDF (Priority: P2 — Navigation)

**Goal**: Create the reports hub screen that lists all 8 report types, wire all routes, and add remaining PDF templates.

> ⚠️ Before implementing, read: spec.md FR-046 to FR-048 (Navigation), spec.md User Story 4 (Expenses).

- [ ] T046 [US4] Create reports hub screen in `motaz_app/motaz_app_flutter/lib/features/reports/presentation/reports_hub_screen.dart`
  - **Objective**: Replace the existing placeholder with a hub listing all 8 report types + client statement.
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/reports/presentation/reports_hub_screen.dart` [NEW]
  - **Scope**: Create `ReportsHubScreen` (StatelessWidget). Wrap in `AppDrawerScaffold` with title `'التقارير'` and currentRoute `'/reports'`. Display a `ListView` of `ListTile` entries: (1) تقرير المبيعات → `/reports/sales`, (2) المبيعات حسب المنتج → `/reports/sales-by-product`, (3) المصروفات حسب النوع → `/reports/expenses-by-type`, (4) تقرير الأرباح → `/reports/profit`, (5) كشف حساب عميل → `/reports/client-statement`, (6) تقرير المستحقات → `/reports/receivables`, (7) تقادم المستحقات → `/reports/receivables-aging`, (8) أرصدة الأطراف → `/reports/party-balances`. Each tile has an appropriate icon and navigates via `context.go(route)`.
  - **Dependencies**: None beyond GoRouter.
  - **Verification**: 8 entries render. Each navigates to its route.

- [ ] T047 Update routes in `motaz_app/motaz_app_flutter/lib/core/router/app_router.dart`
  - **Objective**: Replace the reports placeholder route with the hub and add sub-routes for all 8 reports.
  - **Files**: `motaz_app/motaz_app_flutter/lib/core/router/app_router.dart` [MODIFY]
  - **Scope**: Replace the existing `GoRoute(path: '/reports', builder: ... ReportsPlaceholderScreen())` with `GoRoute(path: '/reports', builder: ... ReportsHubScreen())`. Add 8 additional GoRoute entries: `/reports/sales` → `SalesReportScreen`, `/reports/sales-by-product` → `SalesByProductScreen`, `/reports/expenses-by-type` → `ExpensesByTypeScreen`, `/reports/profit` → `ProfitReportScreen`, `/reports/client-statement` → `ClientStatementScreen`, `/reports/receivables` → `ReceivablesScreen`, `/reports/receivables-aging` → `ReceivablesAgingScreen`, `/reports/party-balances` → `PartyBalancesReportScreen`. Update imports. Remove the old `placeholder_screen.dart` import. Delete `motaz_app/motaz_app_flutter/lib/features/reports/presentation/placeholder_screen.dart`.
  - **Dependencies**: T046, T018, T033, T037, T021, T024, T040, T045, T043.
  - **Verification**: All 9 routes work. Navigating from drawer → Reports → any sub-report works. Back navigation returns to hub.

- [ ] T048 [P] Create profit report PDF template in `motaz_app/motaz_app_flutter/lib/features/reports/pdf/pdf_templates/profit_report_pdf.dart`
  - **Objective**: PDF template for the profit report.
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/reports/pdf/pdf_templates/profit_report_pdf.dart` [NEW]
  - **Scope**: Static `generate()` method taking `PdfStyles`, `ProfitReportData`, `DateRange`. Layout: title, date range, then line items (Gross Sales, Discounts, Returns, Net Sales, Operational Expenses, Production Expenses, Net Profit). If distribution present, add Owner/Partner/Margin shares. RTL. Use `formatMoneyPlain()`.
  - **Dependencies**: T025, T013.
  - **Verification**: Generates valid PDF. Distribution section conditional.

- [ ] T049 Add "تصدير PDF" button to profit report, expenses, receivables, aging, party balances, and sales by product screens
  - **Objective**: Wire PDF export to all remaining report screens.
  - **Files**: (MODIFY) `profit_report_screen.dart`, `expenses_by_type_screen.dart`, `receivables_screen.dart`, `receivables_aging_screen.dart`, `party_balances_report_screen.dart`, `sales_by_product_screen.dart`
  - **Scope**: For each screen, add a PDF export button (same pattern as T029). Each calls the corresponding PDF template's `generate()` method and then `PdfGenerator.shareOrPrint()`. File names: `profit_report.pdf`, `expenses_by_type.pdf`, `receivables.pdf`, `receivables_aging.pdf`, `party_balances.pdf`, `sales_by_product.pdf`.
  - **Dependencies**: T048, T034, T037, T040, T043, T045, T026.
  - **Verification**: Each report screen has a working PDF export button. All PDFs render with Arabic RTL.

**Checkpoint**: All reports, hub, routing, and PDF export complete.

---

## Phase 14: Polish & Cross-Cutting Concerns

**Purpose**: Final validation, cleanup, and code quality.

- [ ] T050 Delete unused placeholder file `motaz_app/motaz_app_flutter/lib/features/reports/presentation/placeholder_screen.dart`
  - **Objective**: Remove the old placeholder that has been replaced by the reports hub.
  - **Files**: `motaz_app/motaz_app_flutter/lib/features/reports/presentation/placeholder_screen.dart` [DELETE]
  - **Scope**: Delete the file. Verify no imports reference it (should have been updated in T047).
  - **Dependencies**: T047.
  - **Verification**: `dart analyze` passes with no missing import errors.

- [ ] T051 Run `dart analyze` on the Flutter project and fix all errors/warnings
  - **Objective**: Ensure zero analysis errors.
  - **Files**: All files in `motaz_app/motaz_app_flutter/`
  - **Scope**: Run `dart analyze` in the Flutter project directory. Fix any errors, warnings, or infos (especially unused imports, missing types, deprecated API usage). Do not introduce new features.
  - **Dependencies**: T050.
  - **Verification**: `dart analyze` exits with 0 errors and 0 warnings (infos acceptable if from tool/ directory).

- [ ] T052 Verify all 9 dashboard KPI cards display correct values with sample data
  - **Objective**: Manual verification of dashboard correctness.
  - **Scope**: With sample data in the local SQLite database, verify each of the 9 KPI cards shows the expected value. Cross-reference with hand calculations using the formulas from the constitution. Verify empty states display correctly when no data exists.
  - **Dependencies**: T012.
  - **Verification**: All 9 cards match expected values. Empty states work.

- [ ] T053 Verify Arabic RTL rendering in at least 2 PDF reports
  - **Objective**: Confirm Arabic text renders correctly in generated PDFs.
  - **Scope**: Generate a Sales Report PDF and a Client Statement PDF with Arabic product names, client names, and notes. Open the generated PDFs and verify: Arabic text is not garbled, text flows right-to-left, table columns are in correct RTL order, Cairo font is properly embedded.
  - **Dependencies**: T029, T030.
  - **Verification**: Arabic text is readable. RTL layout is correct. No missing glyphs.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — BLOCKS all user stories
- **User Stories (Phases 3–12)**: All depend on Phase 2 completion
  - US1 (Dashboard): T012 depends on T005, T011
  - US2 (Sales Report): T018 depends on T014, T015, T017
  - US5 (Profit Report): T021 depends on T014, T015, T020
  - US6 (Client Statement): T024 depends on T014, T023
  - US10 (PDF Export): T025–T030 depend on T002, T001. Integration tasks depend on report screens being built.
  - US3, US4, US7, US8, US9: Can proceed after Phase 2, in any order
- **Navigation (Phase 13)**: Depends on all report screens being built
- **Polish (Phase 14)**: Depends on all phases complete

### User Story Dependencies

- **US1 (Dashboard)**: After Phase 2 — no dependency on other stories
- **US2 (Sales Report)**: After Phase 2 — no dependency on other stories
- **US5 (Profit Report)**: After Phase 2 — no dependency on other stories
- **US6 (Client Statement)**: After Phase 2 — no dependency on other stories
- **US10 (PDF Export)**: Depends on US2 and US6 screens being built (for wiring PDF buttons)
- **US3 (Sales by Product)**: After Phase 2 — no dependency on other stories
- **US4 (Expenses by Type)**: After Phase 2 — no dependency on other stories
- **US7 (Receivables)**: After Phase 2 — no dependency on other stories
- **US8 (Receivables Aging)**: After Phase 2 — no dependency on other stories
- **US9 (Party Balances)**: After Phase 2 — no dependency on other stories

### Within Each User Story

- Models (T013) before queries
- Queries before providers
- Providers before screens
- Screens before PDF buttons

### Parallel Opportunities

- T003 and T004 can run in parallel (different files)
- T013, T014, T015 can run in parallel (different files)
- All P2 user stories (US3, US4, US7, US8, US9) can run in parallel after Phase 2
- PDF templates (T027, T028, T034, T048) can be built in parallel

---

## Implementation Strategy

### MVP First (P1 Stories Only)

1. Complete Phase 1: Setup (T001–T004)
2. Complete Phase 2: Foundation (T005–T011)
3. Complete Phase 3: Dashboard (T012)
4. Complete Phase 4: Sales Report (T013–T018)
5. Complete Phase 5: Profit Report (T019–T021)
6. Complete Phase 6: Client Statement (T022–T024)
7. Complete Phase 7: PDF Export (T025–T030)
8. **STOP and VALIDATE**: All P1 stories independently functional

### Incremental Delivery

1. Setup + Foundation → Foundation ready
2. Add Dashboard → 9 KPI cards working (MVP!)
3. Add Sales Report → First report functional
4. Add Client Statement → Client-facing output ready
5. Add PDF Export → Reports shareable
6. Add remaining P2/P3 reports one by one
7. Add Reports Hub + routing → Full navigation
8. Polish → Release ready

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- All monetary values MUST be `int` (minor-unit integers). No `double` in money path.
- All SQL queries use `customSelect` with raw SQL, consistent with existing `ProfitEngine` pattern
- All reports compute from local SQLite only — no server endpoints needed
- PDF generation uses bundled Cairo font — works fully offline
- Verify each checkpoint before proceeding to the next phase
- Commit after each task or logical group
