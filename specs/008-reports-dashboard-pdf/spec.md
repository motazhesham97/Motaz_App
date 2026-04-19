# Feature Specification: Reports, Statements, Dashboard & PDF

**Feature Branch**: `008-reports-dashboard-pdf`  
**Created**: 2026-04-19  
**Status**: Draft  
**Input**: Phase 8 from docs/implementation-plan.md — Reports, Statements, Dashboard, PDF

---

## Clarifications

### Session 2026-04-19

- Q: How does the owner navigate to the 8 reports and client statement? → A: A single "التقارير" (Reports) drawer item in the app navigation leads to a reports hub screen that lists all 8 report types and the client statement.

---

## User Scenarios & Testing

### User Story 1 — Dashboard with KPI Cards (Priority: P1)

The business owner opens the app and sees a dashboard that provides an instant financial snapshot of their business. The dashboard displays exactly 9 KPI cards: Today Net Sales, This Month Net Sales, This Month Net Profit, Outstanding Receivables Total, Owner Balance, Partner Balance, Margin Balance, This Month Expense Summary by Type, and Recent Activity Feed (latest 10 actions). All data is computed locally from the device's database and is available even without internet.

**Why this priority**: The dashboard is the first screen the owner sees every day. It provides the single most important overview of business health and drives daily decision-making. Without it, the owner must manually navigate to multiple reports.

**Independent Test**: Can be fully tested by creating sample invoices, receipts, expenses, returns, and monthly distributions, then verifying each of the 9 KPI cards shows the correct computed values.

**Acceptance Scenarios**:

1. **Given** no data in the system, **When** the owner opens the dashboard, **Then** all 9 KPI cards display zero/empty states with meaningful defaults (e.g., "0.00 YER", "لا توجد أنشطة حديثة").
2. **Given** 3 active invoices created today totaling 500,000 (minor units) and 1 active return of 50,000, **When** the owner views "Today Net Sales", **Then** the card shows 4,500.00 YER (i.e., 450,000 minor units formatted).
3. **Given** active invoices this month totaling 2,000,000 and returns of 100,000, **When** the owner views "This Month Net Sales", **Then** the card shows 19,000.00 YER.
4. **Given** this month's net sales of 19,000.00 and total expenses of 7,000.00, **When** the owner views "This Month Net Profit", **Then** the card shows 12,000.00 YER.
5. **Given** 5 active invoices with remaining unpaid balances, **When** the owner views "Outstanding Receivables Total", **Then** the card shows the sum of all remaining balances.
6. **Given** accumulated monthly distributions and draws for each party, **When** the owner views Owner/Partner/Margin Balance cards, **Then** each shows the correct balance (shares − draws ± reversals), including negative balances.
7. **Given** current-month expenses across 3 of the 5 categories, **When** the owner views "This Month Expense Summary by Type", **Then** a breakdown by category is shown with correct totals; categories with no expenses show 0.00 YER.
8. **Given** 15 recent actions (invoices, receipts, expenses, returns, voids), **When** the owner views "Recent Activity Feed", **Then** exactly the latest 10 appear in reverse chronological order with action type, reference, and timestamp.

---

### User Story 2 — Sales Report by Period (Priority: P1)

The business owner navigates to the Sales Report and selects a date range through Start Date and End Date pickers, or uses a quick filter (Today, This Week, This Month, This Year, All Time). The report displays all active sales invoices within the selected period, their totals, applicable discounts, returns, and the computed net sales for that period.

**Why this priority**: Sales reporting is the most frequently used report — the owner checks it daily or weekly to track revenue. It is the basis for all other financial analysis.

**Independent Test**: Create invoices across multiple dates, apply the date range filter, and verify only matching invoices appear with correct totals.

**Acceptance Scenarios**:

1. **Given** invoices on 3 different dates, **When** the owner filters by a range covering 2 of the dates, **Then** only invoices from those 2 dates appear.
2. **Given** active and voided invoices in the range, **When** the report is generated, **Then** voided invoices are excluded from totals but may appear visually marked.
3. **Given** the quick filter "This Month" is selected, **When** the report loads, **Then** the date range auto-populates to the first and last day of the current month.
4. **Given** an empty date range (no invoices), **When** the report is generated, **Then** an empty state message is shown with totals at 0.00 YER.

---

### User Story 3 — Sales by Product Report (Priority: P2)

The business owner views a report that groups and sums sales by product for a given date range. Each row shows the product name, total quantity sold, total revenue, and percentage of overall sales. The report helps identify best-selling and underperforming products.

**Why this priority**: Product-level sales insights directly influence purchasing and pricing decisions. It depends on invoice data which is P1.

**Independent Test**: Create invoices with multiple products, run the report for a date range, verify quantities and revenues per product are correct.

**Acceptance Scenarios**:

1. **Given** 10 invoices containing 3 different products within the date range, **When** the report is generated, **Then** each product row shows the correct aggregated quantity and revenue.
2. **Given** a product with zero sales in the selected range, **When** the report is generated, **Then** that product does not appear in the results.
3. **Given** returns exist against some invoice lines, **When** the report is generated, **Then** returned quantities and amounts are subtracted from the product totals.

---

### User Story 4 — Expenses by Type Report (Priority: P2)

The business owner views a report that groups expenses by the 5 approved categories for a selected date range. Each category row shows the total expense amount and percentage of total expenses. The report also shows a grand total of all expenses.

**Why this priority**: Understanding expense distribution is critical for monthly profit calculation and cost control.

**Independent Test**: Create expenses across all 5 categories, run the report, verify each category total and the grand total.

**Acceptance Scenarios**:

1. **Given** expenses in 4 of 5 categories within the range, **When** the report is generated, **Then** 4 categories show correct totals and the 5th shows 0.00 YER.
2. **Given** voided expenses exist, **When** the report is generated, **Then** voided expenses are excluded from all totals.
3. **Given** the "All Time" quick filter, **When** the report is generated, **Then** all non-voided expenses across all dates are included.

---

### User Story 5 — Profit Report by Period (Priority: P1)

The business owner views a profit report for a selected date range showing: gross sales, discounts, returns, net sales, operational expenses, production expenses, and net profit. For monthly periods that have been distributed, the report also shows the owner/partner/margin shares.

**Why this priority**: Profit tracking is the core reason the app exists — it answers "how much did I earn?"

**Independent Test**: Create invoices, returns, and expenses for a month, verify the profit report matches hand-calculated values using the defined formulas.

**Acceptance Scenarios**:

1. **Given** a single month with invoices totaling 1,000,000, discounts of 50,000, returns of 30,000, operational expenses of 200,000, and production expenses of 100,000, **When** the profit report is generated for that month, **Then** it shows Net Sales = 920,000(= 1,000,000 − 50,000 − 30,000), Net Profit = 620,000 (= 920,000 − 200,000 − 100,000).
2. **Given** a non-monthly date range (e.g., 2 weeks), **When** the profit report is generated, **Then** profit is shown as a reporting view only — no distribution rows are shown.
3. **Given** a month with a completed distribution, **When** the monthly profit report is generated, **Then** owner share, partner share, and margin share are displayed.

---

### User Story 6 — Client Statement (Priority: P1)

The business owner selects a client and a date range, and views the client's financial statement: a chronological list of all invoices, receipts, returns, and credits for that client within the period. The statement shows a running balance after each transaction and the final balance (debtor or creditor).

**Why this priority**: Client statements are essential for collections.  The owner uses them to verify and communicate outstanding balances with clients.

**Independent Test**: Create multiple invoices, receipts, and returns for a client, generate the statement, verify the running balance after each transaction and the final balance.

**Acceptance Scenarios**:

1. **Given** a client with 3 invoices, 2 receipts, and 1 return within the date range, **When** the statement is generated, **Then** all 6 transactions appear in chronological order with correct running balances.
2. **Given** a client with a positive balance (debtor), **When** the statement is generated, **Then** the final line clearly indicates the outstanding amount owed.
3. **Given** a client with a credit balance (creditor due to returns after full payment), **When** the statement is generated, **Then** the final line shows the credit amount with clear labeling.
4. **Given** no transactions for the client in the selected range, **When** the statement is generated, **Then** an empty state is shown with the opening balance (if any) from before the range.

---

### User Story 7 — Receivables Report (Priority: P2)

The business owner views a report of all clients with outstanding (unpaid) invoice balances. Each row shows the client name, total invoiced, total paid, total returned, and remaining balance. The report provides a grand total of all outstanding receivables.

**Why this priority**: Critical for cash flow management — the owner needs to know who owes money and how much.

**Independent Test**: Create invoices with various payment states, generate the report, verify remaining balances per client and the grand total.

**Acceptance Scenarios**:

1. **Given** 5 clients with outstanding balances, **When** the report is generated, **Then** all 5 appear with correct remaining balance calculations.
2. **Given** a client with all invoices fully paid, **When** the report is generated, **Then** that client does not appear (zero balance).
3. **Given** a client with a credit balance (overpayment or returns), **When** the report is generated, **Then** the client appears with a negative remaining balance clearly marked as credit.

---

### User Story 8 — Receivables Aging Report (Priority: P3)

The business owner views an aging report that groups outstanding receivables into time buckets: Current (0–30 days), 31–60 days, 61–90 days, and Over 90 days. Each client row shows the outstanding amount distributed across these buckets with a total. A grand total row summarizes all buckets.

**Why this priority**: Aging analysis helps prioritize collections, but is less frequently used than basic receivables. It depends on the Receivables Report.

**Independent Test**: Create invoices with various dates, generate the aging report, verify each invoice's remaining balance falls into the correct bucket.

**Acceptance Scenarios**:

1. **Given** invoices dated 10 days ago, 45 days ago, and 100 days ago (all unpaid), **When** the aging report is generated, **Then** they appear in the Current, 31–60, and Over 90 buckets respectively.
2. **Given** a partially paid invoice from 50 days ago, **When** the aging report is generated, **Then** only the remaining unpaid balance appears in the 31–60 bucket.
3. **Given** no outstanding receivables, **When** the aging report is generated, **Then** an empty state is shown.

---

### User Story 9 — Party Balances Report (Priority: P2)

The business owner views a report showing the financial position of each internal party (Owner, Partner, The Margin). For each party, the report shows: accumulated monthly shares, total draws, and current balance. Balances may be negative.

**Why this priority**: The owner needs to know each party's running financial position, especially for draw management.

**Independent Test**: Create monthly distributions and draws, generate the report, verify each party's balance matches the formula: accumulated shares − draws ± reversals.

**Acceptance Scenarios**:

1. **Given** 3 months of distributions and 2 owner draws, **When** the report is generated, **Then** each party shows correct accumulated shares, draws, and net balance.
2. **Given** a party whose draws exceed shares (negative balance), **When** the report is generated, **Then** the balance is displayed as negative with clear visual indication.
3. **Given** no distributions have been made, **When** the report is generated, **Then** all parties show zero shares and only draw entries (if any).

---

### User Story 10 — PDF Export for All Reports and Client Statement (Priority: P1)

The business owner can export any report or client statement to a PDF file. The PDF reflects the currently selected date range and filters. The PDF renders Arabic text correctly with proper right-to-left (RTL) layout. The owner can share or print the generated PDF directly from the device.

**Why this priority**: PDF export is required for sharing reports with partners, clients, or for physical record-keeping. Arabic RTL rendering is mandatory for the target user base.

**Independent Test**: Generate a client statement PDF and a sales report PDF, verify Arabic text render correctly RTL, date range matches, and financial figures are accurate.

**Acceptance Scenarios**:

1. **Given** a Sales Report with date range filters applied, **When** the owner taps "تصدير PDF", **Then** a PDF is generated locally containing only the filtered data.
2. **Given** a Client Statement for a specific client, **When** the owner exports to PDF, **Then** the PDF shows the client name, all transactions in the date range, running balances, and the final balance.
3. **Given** Arabic text in product names, client names, and notes, **When** any PDF is generated, **Then** all Arabic characters render correctly in RTL layout without garbled text.
4. **Given** the device is offline, **When** the owner exports to PDF, **Then** the PDF is generated successfully from local data.
5. **Given** a generated PDF, **When** the owner taps "مشاركة" or "طباعة", **Then** the system share sheet or print dialog opens with the PDF ready.

---

### Edge Cases

- What happens when the date range Start Date is after the End Date? → System blocks with a validation error; the report is not generated.
- What happens when a report has thousands of records? → The report paginates or scrolls efficiently; performance remains acceptable.
- What happens when generating a PDF with no data (empty report)? → A PDF is generated with a header, date range, and an "لا توجد بيانات" message.
- What happens when the device runs low on storage during PDF generation? → The system displays an error message; no partial file is saved.
- What happens when the dashboard is opened and a sync recently changed data? → The dashboard re-computes from the latest local data automatically.
- What happens when quick-filter "Today" is selected but no transactions exist today? → Dashboard and reports show zero/empty states.
- What happens when the owner opens the reports hub with no data in the system? → All 8 report types are still listed and navigable; each individual report shows its own empty state when opened.

---

## Requirements

### Functional Requirements

#### Dashboard

- **FR-001**: System MUST display a dashboard with exactly 9 KPI cards as described in §14 of the implementation plan.
- **FR-002**: System MUST compute "Today Net Sales" as the sum of today's active invoice totals minus today's active return totals.
- **FR-003**: System MUST compute "This Month Net Sales" as the sum of current month's active invoice totals minus invoice discounts minus current month's active return totals.
- **FR-004**: System MUST compute "This Month Net Profit" as This Month Net Sales minus operational expenses minus production expenses for the current month.
- **FR-005**: System MUST compute "Outstanding Receivables Total" as the total remaining unpaid balances across all active invoices (invoiceTotal − allocatedReceipts − activeReturns for each invoice, summed).
- **FR-006**: System MUST compute Owner, Partner, and Margin Balances as: accumulated monthly shares minus draws, ± valid reversals.
- **FR-007**: System MUST display "This Month Expense Summary by Type" as a breakdown of current-month active expenses across all 5 approved categories.
- **FR-008**: System MUST display a "Recent Activity Feed" showing the latest 10 actions (invoice, receipt, expense, return, or void) in reverse chronological order.
- **FR-009**: System MUST compute all dashboard data locally from the device's SQLite database (compute-on-read). Dashboard MUST work fully offline.
- **FR-010**: Dashboard MUST refresh automatically when underlying data changes (e.g., after a sync cycle or local mutation).

#### Reports — General

- **FR-011**: Every report MUST support date filtering via Start Date and End Date pickers.
- **FR-012**: Every report MUST offer quick filters: Today, This Week, This Month, This Year, All Time.
- **FR-013**: System MUST validate that Start Date is on or before End Date. Invalid ranges MUST be blocked.
- **FR-014**: All report data MUST be computed locally from the device's SQLite database (compute-on-read). Reports MUST work fully offline.
- **FR-015**: All monetary values in reports MUST be displayed as YER formatted with 2 decimal places.
- **FR-016**: Voided records (invoices, receipts, returns, expenses) MUST be excluded from report totals. They MAY appear with visual distinction for reference only.

#### Sales Report

- **FR-017**: System MUST display a Sales Report showing all active invoices within the selected date range, with per-invoice totals, discounts, and a grand total.
- **FR-018**: System MUST display the net sales for the selected period: Active Invoice Totals − Invoice Discounts − Active Return Totals.

#### Sales by Product Report

- **FR-019**: System MUST display a Sales by Product Report grouping sales by product for the selected date range.
- **FR-020**: Each product row MUST show: product name, total quantity sold, total revenue (after returns), and percentage of overall sales.

#### Expenses by Type Report

- **FR-021**: System MUST display an Expenses by Type Report grouping active expenses by the 5 approved categories for the selected date range.
- **FR-022**: Each category row MUST show the total expense amount and percentage of total expenses. A grand total MUST be displayed.

#### Profit Report

- **FR-023**: System MUST display a Profit Report showing: gross sales, discounts, returns, net sales, operational expenses, production expenses, and net profit for the selected date range.
- **FR-024**: For monthly periods that have completed distributions, the report MUST also show owner share, partner share, and margin share.
- **FR-025**: For non-monthly date ranges, profit is displayed as a reporting view only. No distribution rows are shown.

#### Client Statement

- **FR-026**: System MUST allow the owner to select a client and a date range, and generate a chronological statement of all invoices, receipts, returns, and credits for that client.
- **FR-027**: The statement MUST show a running balance after each transaction and a final balance clearly labeled as debtor or creditor.
- **FR-028**: If no transactions exist in the selected range, the statement MUST show the opening balance from transactions before the range.

#### Receivables Report

- **FR-029**: System MUST display a Receivables Report listing all clients with outstanding (unpaid) balances.
- **FR-030**: Each client row MUST show: total invoiced, total paid, total returned, and remaining balance.
- **FR-031**: Clients with zero balance MUST NOT appear. Clients with credit balances MUST appear clearly marked.
- **FR-032**: A grand total of all outstanding receivables MUST be displayed.

#### Receivables Aging Report

- **FR-033**: System MUST display a Receivables Aging Report grouping outstanding receivables into buckets: Current (0–30 days), 31–60 days, 61–90 days, and Over 90 days.
- **FR-034**: Each client row MUST distribute outstanding amounts across the correct time buckets with a row total.
- **FR-035**: A grand total row MUST summarize all buckets.

#### Party Balances Report

- **FR-036**: System MUST display a Party Balances Report for Owner, Partner, and The Margin.
- **FR-037**: Each party row MUST show: accumulated monthly shares, total draws, and current balance.
- **FR-038**: Negative balances MUST be displayed and clearly indicated.

#### PDF Export

- **FR-039**: System MUST provide a PDF export action for every report and every client statement.
- **FR-040**: The exported PDF MUST reflect the currently selected date range and filters.
- **FR-041**: The exported PDF MUST render Arabic text correctly with proper right-to-left (RTL) layout.
- **FR-042**: Arabic fonts MUST be embedded in the PDF to ensure correct rendering on any device.
- **FR-043**: The exported PDF MUST be generated locally from local data. PDF generation MUST work fully offline.
- **FR-044**: After generation, the system MUST allow the owner to share or print the PDF via the device's native share/print functionality.
- **FR-045**: An empty report MUST still produce a valid PDF with header, date range, and an empty-state message.

#### Navigation

- **FR-046**: System MUST provide a single "التقارير" (Reports) item in the app drawer navigation that opens a reports hub screen.
- **FR-047**: The reports hub screen MUST list all 8 report types (Sales, Sales by Product, Expenses by Type, Profit, Client Statement, Receivables, Receivables Aging, Party Balances) as navigable entries.
- **FR-048**: The reports hub screen MUST be wrapped with `AppDrawerScaffold` for consistent navigation.

### Key Entities

- **Dashboard**: Not a persisted entity — a computed view composed of 9 KPI card values, each derived from existing transactional data via local queries.
- **Report**: Not a persisted entity — each report type is a parameterized query (date range + optional filters) executed against local SQLite tables. Results are displayed on-screen and optionally exported as PDF.
- **Client Statement**: A specialized report type scoped to a single client. Produces a chronological transaction ledger with running balance.
- **PDF Document**: A locally generated file produced from report data using embedded Arabic fonts. Not synced or stored in the database.

---

## Success Criteria

### Measurable Outcomes

- **SC-001**: All 9 dashboard KPI cards display correct values within 2 seconds of opening the dashboard, even with 12 months of data (~2,000 invoices, ~3,000 receipts, ~500 expenses).
- **SC-002**: Any report loads and displays results within 3 seconds for a date range covering up to 12 months of data.
- **SC-003**: Quick date filters (Today, This Week, This Month, This Year, All Time) apply instantly (under 500ms perceived latency).
- **SC-004**: 100% of reports and client statements produce accurate results matching hand calculations using the defined accounting formulas.
- **SC-005**: PDF generation completes within 5 seconds for a report containing up to 200 line items.
- **SC-006**: 100% of generated PDFs render Arabic text correctly in RTL layout — verified with multi-line Arabic product names, client names, and notes.
- **SC-007**: All reports and dashboard work fully offline without any error or degradation.
- **SC-008**: The owner can export any report or client statement to PDF and share/print it within 3 taps from the report screen.
- **SC-009**: Receivables aging buckets correctly classify 100% of invoices based on their date relative to today.
- **SC-010**: Client statements correctly show running balances that reconcile with the final balance for every client tested.

---

## Assumptions

- All underlying transactional data (invoices, receipts, expenses, returns, monthly distributions, draws) has been implemented and persisted in prior phases (Phases 2–7).
- The compute-on-read strategy means no new database tables are needed for reports or dashboard. All data is derived from existing tables via Drift queries.
- The 5 approved expense categories are already defined as an enum in the existing schema.
- The `pdf` and `printing` Dart packages are already declared as dependencies in Phase 1.
- The `google_fonts` package (already in `pubspec.yaml`) or a bundled Arabic font (e.g., Cairo) will be used for PDF rendering.
- The Quick Filter values map to deterministic date ranges relative to today: Today = [today, today], This Week = [Monday of current week, Sunday of current week], This Month = [1st of month, last of month], This Year = [Jan 1, Dec 31], All Time = [no date filter].
- Monthly Distribution records already contain owner_share, partner_share, and margin_share values computed in Phase 6.
- Top products, top clients, and advanced analytics charts are explicitly out of scope for the MVP dashboard (per §14 of the implementation plan).
