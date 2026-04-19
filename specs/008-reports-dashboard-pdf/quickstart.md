# Quickstart: Reports, Statements, Dashboard & PDF

**Branch**: `008-reports-dashboard-pdf`
**Date**: 2026-04-19

## Prerequisites

- Flutter 3.32+ and Dart 3.8+ installed
- All prior phases (001–007) implemented and passing
- Existing database schema with all transactional tables populated

## Setup

### 1. Install New Dependencies

```bash
cd motaz_app/motaz_app_flutter
flutter pub add pdf printing
flutter pub get
```

### 2. Bundle Arabic Font

Download Cairo TTF files from Google Fonts and place them in:

```
motaz_app/motaz_app_flutter/assets/fonts/Cairo-Regular.ttf
motaz_app/motaz_app_flutter/assets/fonts/Cairo-Bold.ttf
```

Register in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/config.json
    - assets/fonts/Cairo-Regular.ttf
    - assets/fonts/Cairo-Bold.ttf
```

### 3. Development Workflow

```bash
# Run the app
cd motaz_app/motaz_app_flutter
flutter run

# Run tests
flutter test

# Analyze code
dart analyze
```

## Key Files

| File | Purpose |
|------|---------|
| `core/utils/date_range.dart` | Shared date range model with quick filter factories |
| `core/utils/money_formatter.dart` | Shared YER formatting helper |
| `features/dashboard/data/dashboard_queries.dart` | All 9 dashboard KPI queries |
| `features/reports/data/report_queries.dart` | All 8 report SQL queries |
| `features/reports/data/client_statement_queries.dart` | Client statement query |
| `features/reports/pdf/pdf_generator.dart` | PDF generation orchestrator |
| `features/reports/pdf/pdf_styles.dart` | Arabic font and RTL styles |
| `features/reports/presentation/reports_hub_screen.dart` | Reports navigation hub |

## Testing a Report

1. Open the app and navigate to "التقارير" from the drawer
2. Select any report type from the hub
3. Use the date range picker or quick filters
4. Verify data displays correctly
5. Tap "تصدير PDF" to generate a PDF
6. Verify Arabic text renders correctly in RTL

## Testing the Dashboard

1. Navigate to "لوحة التحكم" from the drawer
2. Verify all 9 KPI cards show correct values:
   - صافي مبيعات اليوم (Today Net Sales)
   - صافي مبيعات الشهر (This Month Net Sales)
   - صافي ربح الشهر (This Month Net Profit)
   - إجمالي المستحقات (Outstanding Receivables)
   - رصيد المالك (Owner Balance)
   - رصيد الشريك (Partner Balance)
   - رصيد الهامش (Margin Balance)
   - ملخص مصروفات الشهر (Expense Summary)
   - آخر الأنشطة (Recent Activity Feed)
