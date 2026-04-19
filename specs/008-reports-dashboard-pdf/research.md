# Research: Reports, Statements, Dashboard & PDF

**Branch**: `008-reports-dashboard-pdf`
**Date**: 2026-04-19

## R1: PDF Generation with Arabic RTL in Flutter

**Decision**: Use `pdf` (^3.11.1) + `printing` (^5.13.3) Dart packages.

**Rationale**:
- Pure Dart — works on both Android and Windows without native plugins
- Native TTF font embedding — required for Arabic glyph shaping
- Built-in `pw.Directionality.rtl` support for right-to-left layout
- `printing` package provides share, print, and preview on both platforms
- Already referenced in the implementation plan (§16)

**Alternatives considered**:
- `syncfusion_flutter_pdf`: Feature-rich but commercial license required
- `flutter_html_to_pdf`: Requires WebView, not available on Windows desktop
- Native platform PDF APIs: Would require platform channels, dual implementation

**Key implementation notes**:
- Font must be loaded from asset bundle as `pw.Font.ttf()`
- Use `pw.Directionality(textDirection: pw.TextDirection.rtl)` for correct Arabic rendering
- Tables use `pw.TableHelper.fromTextArray()` for report tabular data
- Share via `Printing.sharePdf()`, print via `Printing.layoutPdf()`

## R2: Arabic Font Strategy

**Decision**: Bundle Cairo Regular and Cairo Bold TTF files as Flutter assets.

**Rationale**:
- Cairo is already the app's UI font (referenced in previous phases)
- TTF format is required by the `pdf` package (OTF not fully supported)
- Bundling as assets ensures offline availability (constitution §II)
- Google Fonts CDN would fail offline

**Alternatives considered**:
- `google_fonts` package download at runtime: Fails offline, violates constitution
- Amiri font: Excellent for Arabic but more formal/serif; Cairo matches the app's visual identity
- Noto Sans Arabic: Good coverage but heavier file size

**Implementation**:
- Download `Cairo-Regular.ttf` and `Cairo-Bold.ttf` from Google Fonts
- Add to `assets/fonts/` directory
- Register in `pubspec.yaml` under `flutter.assets`
- Load once per PDF generation session via `rootBundle.load()`

## R3: Drift Custom Query Patterns

**Decision**: Continue using `customSelect` with raw SQL for all report queries, consistent with existing `ProfitEngine` and `DashboardQueries`.

**Rationale**:
- Report queries involve complex JOINs, UNION ALL, GROUP BY, and subqueries
- Drift's type-safe query builder doesn't support UNION ALL
- Raw SQL is explicitly allowed by the constitution (§III: "Raw SQL: allowed only where justified — heavy reporting queries, optimized aggregations")
- Existing codebase already uses this pattern successfully

**Alternatives considered**:
- Drift Views: Don't support UNION ALL or parameterized CTEs
- Create Dart-side aggregation from typed selects: Would require multiple queries and in-memory joins — worse performance
- Drift `.customStatement()`: Only for writes, not reads

## R4: Report Date Filtering Architecture

**Decision**: Create a `DateRange` value object with factory constructors for quick filters.

**Rationale**:
- 8 reports + 1 client statement all need identical date range logic
- Quick filters map to deterministic date calculations
- Centralizing this avoids 9 copies of date math
- The `DateRange` record can serve as a Riverpod family key for cache invalidation

**Design**:
```dart
class DateRange {
  final DateTime start;
  final DateTime end;
  
  factory DateRange.today() { ... }
  factory DateRange.thisWeek() { ... }   // Mon–Sun
  factory DateRange.thisMonth() { ... }  // 1st–last
  factory DateRange.thisYear() { ... }   // Jan 1–Dec 31
  factory DateRange.allTime() { ... }    // epoch–far future
  factory DateRange.custom(DateTime start, DateTime end) { ... }
}
```

## R5: Dashboard Activity Feed Data Source

**Decision**: Query from the 4 transactional tables (invoices, receipts, expenses, returns) using UNION ALL, ordered by `created_at DESC LIMIT 10`.

**Rationale**:
- No separate activity/event table exists for this purpose
- `audit_events` exists but stores serialized diff data — not ideal for display
- UNION ALL across 4 tables with LIMIT 10 is simple and performant
- Each row just needs: type, id, reference, timestamp

**Alternatives considered**:
- Query `audit_events`: Contains all mutations but `diffData` is serialized JSON — parsing overhead and non-human-readable
- Maintain a separate activity log table: Would require schema change — out of scope per compute-on-read strategy
- Query each table separately and merge in Dart: More round-trips, more code

## R6: Client Statement Opening Balance

**Decision**: Compute opening balance as the sum of all pre-range transactions for the client.

**Rationale**:
- The spec requires showing the opening balance when no transactions exist in the selected range (FR-028)
- Opening balance = SUM(invoices before range) - SUM(receipts before range) - SUM(returns before range)
- This is consistent with the running balance formula used within the statement

**Implementation**:
```sql
-- Opening balance query (pre-range)
SELECT
  COALESCE((SELECT SUM(total) FROM sales_invoices WHERE client_id = ? AND status = 0 AND invoice_date < ?rangeStart), 0)
  - COALESCE((SELECT SUM(amount) FROM receipts WHERE client_id = ? AND status = 0 AND receipt_date < ?rangeStart), 0)
  - COALESCE((SELECT SUM(sr.total_returned_amount) FROM sales_returns sr JOIN sales_invoices si ON si.id = sr.invoice_id WHERE si.client_id = ? AND sr.status = 0 AND sr.return_date < ?rangeStart), 0)
AS opening_balance
```

## R7: PDF Empty Report Handling

**Decision**: Always generate a valid PDF even for empty data. Include header, date range, and "لا توجد بيانات" centered message.

**Rationale**: FR-045 explicitly requires this. Users may generate PDFs for empty periods for record-keeping purposes. A failed generation would be confusing.

All NEEDS CLARIFICATION markers resolved. No remaining unknowns.
