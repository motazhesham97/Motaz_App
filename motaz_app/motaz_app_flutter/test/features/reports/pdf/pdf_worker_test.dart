import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/features/reports/pdf/pdf_worker.dart';
import 'package:motaz_app_flutter/core/utils/date_range.dart';
import 'package:motaz_app_flutter/core/database/enums/expense_category.dart';
import 'package:motaz_app_flutter/features/reports/data/report_models.dart';
import 'package:motaz_app_flutter/features/reports/pdf/report_pdf_renderer.dart';
import 'package:motaz_app_flutter/features/reports/pdf/pdf_generator.dart';
import 'package:motaz_app_flutter/features/reports/pdf/pdf_styles.dart';
import 'package:pdf/widgets.dart' as pw;

int _neverFinishes(int input) {
  while (true) {
    input++;
  }
}

int _double(int input) => input * 2;

int _legacyBuilds = 0;
List<pw.Widget> _legacyPage(pw.Context context) {
  _legacyBuilds++;
  return [pw.Text('Legacy report layout')];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'CPU-bound PDF work times out without blocking UI timers or later exports',
    () async {
      var ticks = 0;
      final timer = Timer.periodic(
        const Duration(milliseconds: 5),
        (_) => ticks++,
      );
      try {
        await expectLater(
          PdfWorker.run(
            _neverFinishes,
            0,
            timeout: const Duration(milliseconds: 150),
          ),
          throwsA(isA<TimeoutException>()),
        );
        expect(ticks, greaterThan(0));
        expect(await PdfWorker.run(_double, 21), 42);
      } finally {
        timer.cancel();
      }
    },
  );

  test(
    'real Arabic report data and bundled fonts render in the worker',
    () async {
      final bytes = await ReportPdfRenderer.render(
        PdfReportRequest(
          PdfReportKind.statement,
          ClientStatementData(
            clientName: 'عميل',
            dateRange: DateRange.custom(
              DateTime(2026, 1, 1),
              DateTime(2026, 2),
            ),
            openingBalance: 0,
            closingBalance: 0,
            entries: [],
          ),
        ),
      );
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(1000));
    },
  );

  test(
    'large sales reports paginate through the background export path',
    () async {
      final bytes = await ReportPdfRenderer.render(
        PdfReportRequest(
          PdfReportKind.sales,
          SalesReportSummary(
            rows: List.generate(
              120,
              (index) => SalesReportRow(
                invoiceId: '$index',
                localRef: 'INV-$index',
                clientName: 'عميل',
                invoiceDate: DateTime(2026, 1, 1),
                total: 100,
                discount: 0,
              ),
            ),
            grossSales: 12000,
            totalDiscounts: 0,
            totalReturns: 0,
            netSales: 12000,
          ),
          range: DateRange.custom(DateTime(2026, 1, 1), DateTime(2026, 2)),
        ),
      );
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    },
  );

  test(
    'many expenses on one day do not form one unbreakable table row',
    () async {
      final bytes = await ReportPdfRenderer.render(
        PdfReportRequest(
          PdfReportKind.expenses,
          ExpenseReportData(
            rows: List.generate(
              120,
              (index) => ExpenseReportRow(
                id: '$index',
                category: ExpenseCategory.OPERATIONAL,
                categoryLabel: 'تشغيلية',
                expenseDate: DateTime(2026, 1, 1),
                amount: 100,
                note: 'مصروف يومي $index',
              ),
            ),
            totalAmount: 12000,
            filterLabel: 'يناير',
          ),
        ),
        timeout: const Duration(seconds: 5),
      );
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    },
  );

  test(
    'legacy Document callers defer layout and save to the worker too',
    () async {
      _legacyBuilds = 0;
      final styles = await PdfStyles.load();
      final document = styles.createDocument();
      document.addPage(styles.multiPage(build: _legacyPage));
      expect(_legacyBuilds, 0);

      final bytes = await PdfGenerator.renderBytes(document);

      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(_legacyBuilds, 0);
    },
  );
}
