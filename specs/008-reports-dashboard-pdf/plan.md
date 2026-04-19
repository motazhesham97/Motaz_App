# Implementation Plan: Reports, Statements, Dashboard & PDF

**Branch**: `008-reports-dashboard-pdf` | **Date**: 2026-04-19 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/008-reports-dashboard-pdf/spec.md`

## Summary

This phase turns Motaz_App into a real daily operating tool by implementing all 8 reports, a complete 9-card dashboard, client statements, and PDF export with Arabic RTL support. All data is computed locally from SQLite via Drift queries (compute-on-read strategy). No new database tables are needed — all reporting is derived from existing transactional tables. PDF generation uses the `pdf` + `printing` Dart packages with an embedded Arabic font.

## Technical Context

**Language/Version**: Dart 3.8+ / Flutter 3.32+
**Primary Dependencies**: flutter_riverpod, drift, go_router, pdf (^3.11.1), printing (^5.13.3), google_fonts
**Storage**: SQLite via Drift (local, compute-on-read queries; no new tables)
**Testing**: flutter_test, integration tests with Drift in-memory DB
**Target Platform**: Android + Windows
**Project Type**: Mobile/Desktop app (Flutter)
**Performance Goals**: Dashboard < 2s, reports < 3s, PDF generation < 5s for 200 items
**Constraints**: Offline-first, all data from local SQLite, Arabic RTL for PDF
**Scale/Scope**: ~2,000 invoices, ~3,000 receipts, ~500 expenses over 12 months

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Status | Evidence |
|------|--------|----------|
| Offline-first (§II) | ✅ PASS | All reports and dashboard compute from local SQLite. PDF generated locally. |
| No hard delete (§II) | ✅ PASS | No deletes. Reports filter by `status = ACTIVE`. Voided records excluded from totals. |
| Single-currency YER (§I) | ✅ PASS | All monetary values displayed as YER with 2 decimal places from minor-unit integers. |
| Minor-unit integers (§I) | ✅ PASS | All query aggregations use integer SQL (SUM on integer columns). Formatting only at display layer. |
| Monthly-only distributions (§I) | ✅ PASS | Profit report shows distribution rows only for monthly periods. Non-monthly ranges are view-only. |
| PDF for reports+statements (§IV) | ✅ PASS | FR-039 requires PDF export for every report and statement. |
| Arabic RTL (§V) | ✅ PASS | PDF uses embedded Arabic font with RTL layout via `pdf` package Directionality. |
| Date range filtering (§IV) | ✅ PASS | Every report has Start/End date pickers + quick filters. |
| Dashboard mandatory (§V) | ✅ PASS | 9 KPI cards per §14 of implementation plan. |
| Receivables aging by invoice date (§IV) | ✅ PASS | Aging buckets computed from `invoiceDate` and remaining balance. |
| Fiscal year = calendar year (§IV) | ✅ PASS | "This Year" quick filter uses Jan 1 – Dec 31. |

No gate violations. Proceeding to design.

## Project Structure

### Documentation (this feature)

```text
specs/008-reports-dashboard-pdf/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── contracts/           # N/A (no external interfaces)
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (via /speckit.tasks)
```

### Source Code (repository root)

```text
motaz_app/motaz_app_flutter/lib/
├── core/
│   ├── database/          # Existing — no changes
│   ├── router/
│   │   └── app_router.dart              # [MODIFY] Add report sub-routes
│   └── utils/
│       ├── money_formatter.dart         # [NEW] Shared YER formatting helper
│       └── date_range.dart              # [NEW] DateRange model + quick filter logic
├── features/
│   ├── dashboard/
│   │   ├── data/
│   │   │   └── dashboard_queries.dart   # [MODIFY] Add today net sales, receivables, activity feed
│   │   ├── application/
│   │   │   └── dashboard_providers.dart # [MODIFY] Add missing providers
│   │   └── presentation/
│   │       └── dashboard_screen.dart    # [MODIFY] Expand to 9 KPI cards
│   └── reports/
│       ├── data/
│       │   ├── report_queries.dart           # [NEW] All 8 report SQL queries
│       │   └── client_statement_queries.dart # [NEW] Client statement query
│       ├── application/
│       │   └── report_providers.dart         # [NEW] Riverpod providers for all reports
│       ├── presentation/
│       │   ├── reports_hub_screen.dart       # [NEW] Hub listing all reports
│       │   ├── sales_report_screen.dart      # [NEW]
│       │   ├── sales_by_product_screen.dart  # [NEW]
│       │   ├── expenses_by_type_screen.dart  # [NEW]
│       │   ├── profit_report_screen.dart     # [NEW]
│       │   ├── client_statement_screen.dart  # [NEW]
│       │   ├── receivables_screen.dart       # [NEW]
│       │   ├── receivables_aging_screen.dart # [NEW]
│       │   ├── party_balances_report_screen.dart # [NEW]
│       │   └── widgets/
│       │       ├── date_range_picker.dart    # [NEW] Reusable date picker + quick filters
│       │       └── report_summary_row.dart   # [NEW] Reusable total/subtotal row widget
│       └── pdf/
│           ├── pdf_generator.dart            # [NEW] Core PDF generation engine
│           ├── pdf_styles.dart               # [NEW] Arabic font, text styles, RTL config
│           └── pdf_templates/
│               ├── sales_report_pdf.dart          # [NEW]
│               ├── sales_by_product_pdf.dart      # [NEW]
│               ├── expenses_by_type_pdf.dart      # [NEW]
│               ├── profit_report_pdf.dart         # [NEW]
│               ├── client_statement_pdf.dart      # [NEW]
│               ├── receivables_pdf.dart           # [NEW]
│               ├── receivables_aging_pdf.dart     # [NEW]
│               └── party_balances_pdf.dart        # [NEW]

motaz_app/motaz_app_flutter/pubspec.yaml    # [MODIFY] Add pdf + printing deps
motaz_app/motaz_app_flutter/assets/fonts/   # [NEW] Bundled Arabic font file (Cairo)
```

**Structure Decision**: Follows the existing Feature-First Modular Monolith pattern. Reports get a full `data/`, `application/`, `presentation/`, and new `pdf/` sublayer. Dashboard extends its existing structure. Shared utilities go under `core/utils/`.

## Design Decisions

### D1: Compute-on-Read via Raw SQL
All reports use `customSelect` with raw SQL on existing Drift tables. This avoids creating new Drift table classes or materialized views. It is consistent with the existing `ProfitEngine` and `DashboardQueries` patterns.

### D2: Shared DateRange Model
A `DateRange` value object with factory constructors for each quick filter (today, thisWeek, thisMonth, thisYear, allTime) centralizes date logic and prevents duplication across 8+ reports.

### D3: PDF Architecture — Template Per Report
Each report type gets its own PDF template file that receives computed data and produces a `pw.Document`. A shared `PdfStyles` class provides the Arabic font, common text styles, and RTL configuration. `PdfGenerator` orchestrates generation and uses `printing` package for share/print.

### D4: Arabic Font Strategy
Bundle the Cairo Regular and Cairo Bold `.ttf` fonts as assets. Load them once at PDF generation time. The `pdf` library supports TTF fonts natively with full Arabic shaping and RTL via `pw.Directionality`.

### D5: Dashboard Completion — Extend, Don't Rebuild
The existing `DashboardQueries` / `DashboardScreen` already has 5 of 9 cards (net profit, 3 party balances, expense summary). We add 4 more queries/providers for: Today Net Sales, This Month Net Sales, Outstanding Receivables, and Recent Activity Feed.

### D6: Reports Hub Navigation
The existing `/reports` route (currently a placeholder) becomes the `ReportsHubScreen`. Sub-routes like `/reports/sales`, `/reports/receivables-aging`, etc. provide deep-linkable navigation.

### D7: Money Formatting
Extract the existing `_formatMoney` inline function into a shared `core/utils/money_formatter.dart` so all screens and PDF templates use the same formatting logic.

## Query Design

### Q1: Today Net Sales
```sql
SELECT COALESCE(SUM(total), 0) - COALESCE(SUM(discount), 0) AS net
FROM sales_invoices
WHERE status = 0  -- ACTIVE
  AND invoice_date >= ?todayStart AND invoice_date < ?tomorrowStart
```
Minus:
```sql
SELECT COALESCE(SUM(total_returned_amount), 0) AS ret
FROM sales_returns
WHERE status = 0 AND return_date >= ?todayStart AND return_date < ?tomorrowStart
```
Result: `net - ret`

### Q2: Outstanding Receivables Total
```sql
-- Per invoice: total - allocated_receipts - active_returns
SELECT SUM(remaining) FROM (
  SELECT i.total
    - COALESCE((SELECT SUM(allocated_amount) FROM receipt_allocations ra
                JOIN receipts r ON r.id = ra.receipt_id
                WHERE ra.invoice_id = i.id AND r.status = 0), 0)
    - COALESCE((SELECT SUM(total_returned_amount) FROM sales_returns sr
                WHERE sr.invoice_id = i.id AND sr.status = 0), 0)
    AS remaining
  FROM sales_invoices i WHERE i.status = 0
) WHERE remaining > 0
```

### Q3: Recent Activity Feed
```sql
SELECT 'INVOICE' AS type, id, local_ref AS ref, created_at FROM sales_invoices WHERE created_at >= ?cutoff
UNION ALL
SELECT 'RECEIPT', id, id, created_at FROM receipts WHERE created_at >= ?cutoff
UNION ALL
SELECT 'EXPENSE', id, id, created_at FROM expenses WHERE created_at >= ?cutoff
UNION ALL
SELECT 'RETURN', id, id, created_at FROM sales_returns WHERE created_at >= ?cutoff
ORDER BY created_at DESC LIMIT 10
```

### Q4: Sales by Product (date-range parameterized)
```sql
SELECT p.name, SUM(sil.quantity) AS qty, SUM(sil.line_total) AS revenue
FROM sales_invoice_lines sil
JOIN sales_invoices si ON si.id = sil.invoice_id
JOIN products p ON p.id = sil.product_id
WHERE si.status = 0 AND si.invoice_date >= ? AND si.invoice_date < ?
GROUP BY sil.product_id
ORDER BY revenue DESC
```
With return subtraction:
```sql
-- Subtract returned quantities/amounts per product
SELECT srl.product_id, SUM(srl.returned_quantity) AS ret_qty, SUM(srl.returned_amount) AS ret_amount
FROM sales_return_lines srl
JOIN sales_returns sr ON sr.id = srl.return_id
WHERE sr.status = 0 AND sr.return_date >= ? AND sr.return_date < ?
GROUP BY srl.product_id
```
Note: `sales_return_lines` references the invoice line, from which we can derive product_id. The query joins accordingly.

### Q5: Receivables Aging
```sql
SELECT c.display_name, i.id, i.invoice_date, i.total,
  COALESCE(alloc.total_allocated, 0) AS paid,
  COALESCE(ret.total_returned, 0) AS returned,
  (i.total - COALESCE(alloc.total_allocated, 0) - COALESCE(ret.total_returned, 0)) AS remaining,
  CAST(julianday('now') - julianday(i.invoice_date) AS INTEGER) AS age_days
FROM sales_invoices i
JOIN clients c ON c.id = i.client_id
LEFT JOIN (
  SELECT ra.invoice_id, SUM(ra.allocated_amount) AS total_allocated
  FROM receipt_allocations ra JOIN receipts r ON r.id = ra.receipt_id WHERE r.status = 0
  GROUP BY ra.invoice_id
) alloc ON alloc.invoice_id = i.id
LEFT JOIN (
  SELECT sr.invoice_id, SUM(sr.total_returned_amount) AS total_returned
  FROM sales_returns sr WHERE sr.status = 0
  GROUP BY sr.invoice_id
) ret ON ret.invoice_id = i.id
WHERE i.status = 0
  AND (i.total - COALESCE(alloc.total_allocated, 0) - COALESCE(ret.total_returned, 0)) > 0
ORDER BY i.invoice_date ASC
```
Aging bucket assignment done in Dart: `ageDays <= 30 → Current, 31–60, 61–90, >90`.

### Q6: Client Statement
```sql
-- Invoices for client in range
SELECT 'INVOICE' AS type, invoice_date AS txn_date, total AS amount, local_ref AS ref, note
FROM sales_invoices WHERE client_id = ? AND status = 0
  AND invoice_date >= ? AND invoice_date < ?

UNION ALL

-- Receipts for client in range
SELECT 'RECEIPT', receipt_date, amount, id, note
FROM receipts WHERE client_id = ? AND status = 0
  AND receipt_date >= ? AND receipt_date < ?

UNION ALL

-- Returns for client in range (via invoice)
SELECT 'RETURN', sr.return_date, sr.total_returned_amount, sr.id, sr.note
FROM sales_returns sr
JOIN sales_invoices si ON si.id = sr.invoice_id
WHERE si.client_id = ? AND sr.status = 0
  AND sr.return_date >= ? AND sr.return_date < ?

ORDER BY txn_date ASC, type ASC
```
Running balance computed in Dart: start from opening balance (pre-range), add invoices, subtract receipts, subtract returns.

## Implementation Phases

### Phase A: Foundation & Shared Utilities
1. Add `pdf` and `printing` dependencies to `pubspec.yaml`
2. Bundle Cairo Arabic font as asset
3. Create `core/utils/money_formatter.dart`
4. Create `core/utils/date_range.dart` with quick filter factories
5. Extract `_formatMoney` from dashboard and use shared helper

### Phase B: Dashboard Completion
1. Add `getTodayNetSales()` to `DashboardQueries`
2. Add `getThisMonthNetSales()` to `DashboardQueries`
3. Add `getOutstandingReceivablesTotal()` to `DashboardQueries`
4. Add `getRecentActivityFeed()` to `DashboardQueries`
5. Add corresponding providers to `dashboard_providers.dart`
6. Expand `DashboardScreen` to show all 9 KPI cards

### Phase C: Report Queries & Providers
1. Create `report_queries.dart` with all 8 report query methods
2. Create `client_statement_queries.dart`
3. Create `report_providers.dart` with FutureProvider.family for each report (keyed by DateRange)
4. Create client statement provider (keyed by clientId + DateRange)

### Phase D: Reports Hub & Individual Report Screens
1. Create `ReportsHubScreen` replacing placeholder
2. Create `DateRangePickerWidget` (shared across all reports)
3. Create `ReportSummaryRow` widget
4. Implement all 8 report screens + client statement screen
5. Update `app_router.dart` with sub-routes under `/reports/`

### Phase E: PDF Generation
1. Create `pdf_styles.dart` — load Cairo font, define RTL document theme
2. Create `pdf_generator.dart` — orchestration (generate → preview/share/print)
3. Create 8 PDF templates (one per report type + client statement)
4. Add "تصدير PDF" button to each report screen
5. Wire share/print via `printing` package

### Phase F: Polish & Testing
1. Verify all 9 dashboard cards with test data
2. Verify all reports with boundary conditions (empty data, single record, large dataset)
3. Verify PDF Arabic RTL rendering
4. Verify offline functionality (airplane mode test)
5. Performance validation against SC-001 through SC-010

## Complexity Tracking

No constitution violations to justify.
