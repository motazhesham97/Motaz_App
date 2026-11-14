import 'dart:async';
import 'dart:typed_data';

import '../../../core/utils/date_range.dart';
import '../../free_samples/data/free_sample_repository.dart';
import '../data/report_models.dart';
import 'pdf_styles.dart';
import 'pdf_worker.dart';
import 'pdf_templates/client_product_sales_report_pdf.dart';
import 'pdf_templates/client_receivables_report_pdf.dart';
import 'pdf_templates/client_statement_pdf.dart';
import 'pdf_templates/expense_report_pdf.dart';
import 'pdf_templates/final_monthly_report_pdf.dart';
import 'pdf_templates/free_sample_report_pdf.dart';
import 'pdf_templates/sales_report_pdf.dart';

enum PdfReportKind {
  statement,
  sales,
  expenses,
  monthly,
  receivables,
  products,
  freeSamples,
}

class PdfReportRequest {
  const PdfReportRequest(
    this.kind,
    this.data, {
    this.range,
    this.filterLabel = '',
    this.warning,
  });

  final PdfReportKind kind;
  final Object data;
  final DateRange? range;
  final String filterLabel;
  final String? warning;
}

class ReportPdfRenderer {
  static Future<Uint8List> render(
    PdfReportRequest request, {
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final fonts = await PdfStyles.loadFontData().timeout(
      const Duration(seconds: 10),
    );
    return PdfWorker.run(_render, (request, fonts), timeout: timeout);
  }

  static Future<Uint8List> _render(
    (PdfReportRequest, (ByteData, ByteData)) job,
  ) async {
    final (request, fonts) = job;
    final styles = PdfStyles.fromFontData(fonts, warning: request.warning);
    final count = switch (request.kind) {
      PdfReportKind.statement =>
        (request.data as ClientStatementData).entries.length,
      PdfReportKind.sales => (request.data as SalesReportSummary).rows.length,
      PdfReportKind.expenses => (request.data as ExpenseReportData).rows.length,
      PdfReportKind.monthly =>
        (request.data as FinalMonthlyReportData).productSales.length,
      PdfReportKind.receivables =>
        (request.data as ClientReceivablesReportData).rows.length,
      PdfReportKind.products =>
        (request.data as ClientProductSalesReportData).rows.length,
      PdfReportKind.freeSamples =>
        (request.data as List<FreeSampleSummary>).length,
    };
    if (count > 5000) {
      throw StateError('Report exceeds 5000 rows; choose a shorter date range');
    }
    final document = switch (request.kind) {
      PdfReportKind.statement => ClientStatementPdf.generate(
        styles,
        request.data as ClientStatementData,
      ),
      PdfReportKind.sales => SalesReportPdf.generate(
        styles,
        request.data as SalesReportSummary,
        request.range!,
      ),
      PdfReportKind.expenses => ExpenseReportPdf.generate(
        styles,
        request.data as ExpenseReportData,
      ),
      PdfReportKind.monthly => FinalMonthlyReportPdf.generate(
        styles,
        request.data as FinalMonthlyReportData,
      ),
      PdfReportKind.receivables => ClientReceivablesReportPdf.generate(
        styles,
        request.data as ClientReceivablesReportData,
      ),
      PdfReportKind.products => ClientProductSalesReportPdf.generate(
        styles,
        request.data as ClientProductSalesReportData,
      ),
      PdfReportKind.freeSamples => FreeSampleReportPdf.generate(
        styles,
        rows: request.data as List<FreeSampleSummary>,
        filterLabel: request.filterLabel,
      ),
    };
    final bytes = await document.save();
    if (bytes.length > 24 * 1024 * 1024) {
      throw StateError('PDF exceeds 24 MB; choose a shorter date range');
    }
    return bytes;
  }
}
