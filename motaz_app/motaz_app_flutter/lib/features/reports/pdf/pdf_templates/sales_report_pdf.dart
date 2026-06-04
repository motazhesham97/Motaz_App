import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/utils/money_formatter.dart';
import '../../../../core/utils/date_range.dart';
import '../../../../core/utils/document_reference_formatter.dart';
import '../../data/report_models.dart';
import '../pdf_styles.dart';

class SalesReportPdf {
  static pw.Document generate(
    PdfStyles styles,
    SalesReportSummary data,
    DateRange range,
  ) {
    final doc = styles.createDocument();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (context) => [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('تقرير المبيعات', style: styles.titleStyle),
                pw.SizedBox(height: 8),
                pw.Text(
                  '${_formatDate(range.start)} - ${_formatDate(range.end)}',
                  style: styles.bodyStyle,
                ),
                pw.SizedBox(height: 16),
                if (data.rows.isEmpty)
                  pw.Center(
                    child: pw.Text(
                      'لا توجد بيانات',
                      style: styles.headerStyle,
                    ),
                  )
                else ...[
                  pw.TableHelper.fromTextArray(
                    headers: [
                      'المرجع',
                      'العميل',
                      'التاريخ',
                      'الإجمالي',
                      'الخصم',
                    ],
                    data: data.rows
                        .map(
                          (r) => [
                            invoiceDisplayRef(r.localRef),
                            r.clientName,
                            _formatDate(r.invoiceDate),
                            formatMoneyPlain(r.total),
                            formatMoneyPlain(r.discount),
                          ],
                        )
                        .toList(),
                    headerStyle: styles.tableHeaderStyle,
                    cellStyle: styles.tableCellStyle,
                    headerDecoration: const pw.BoxDecoration(
                      color: PdfStyles.primaryColor,
                    ),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(1.5),
                      1: const pw.FlexColumnWidth(2.5),
                      2: const pw.FlexColumnWidth(1.5),
                      3: const pw.FlexColumnWidth(1.5),
                      4: const pw.FlexColumnWidth(1.5),
                    },
                  ),
                  pw.SizedBox(height: 20),
                  pw.Divider(),
                  pw.SizedBox(height: 8),
                  _summaryRow(styles, 'إجمالي المبيعات', data.grossSales),
                  _summaryRow(styles, 'الخصومات', -data.totalDiscounts),
                  _summaryRow(styles, 'المرتجعات', -data.totalReturns),
                  pw.Divider(),
                  _summaryRow(styles, 'صافي المبيعات', data.netSales),
                  ..._attachmentsSection(styles, data),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return doc;
  }

  static List<pw.Widget> _attachmentsSection(
    PdfStyles styles,
    SalesReportSummary data,
  ) {
    final rows = data.rows.where((row) => row.attachmentImages.isNotEmpty);
    if (rows.isEmpty) return const [];

    return [
      pw.SizedBox(height: 16),
      pw.Text('صور الفواتير', style: styles.headerStyle),
      pw.SizedBox(height: 8),
      ...rows.map((row) {
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 10),
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '${invoiceDisplayRef(row.localRef)} - ${row.clientName} - ${_formatDate(row.invoiceDate)}',
                style: pw.TextStyle(font: styles.boldFont, fontSize: 10),
              ),
              pw.SizedBox(height: 6),
              pw.Wrap(
                spacing: 8,
                runSpacing: 8,
                children: row.attachmentImages.map((bytes) {
                  return pw.Container(
                    width: 120,
                    height: 90,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Image(
                      pw.MemoryImage(bytes),
                      fit: pw.BoxFit.cover,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }),
    ];
  }

  static pw.Widget _summaryRow(PdfStyles styles, String label, int amount) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            formatMoneyPlain(amount),
            style: pw.TextStyle(
              font: styles.boldFont,
              fontSize: 11,
              color: amount < 0 ? PdfColors.red : PdfColors.black,
            ),
          ),
          pw.Text(
            label,
            style: pw.TextStyle(font: styles.boldFont, fontSize: 11),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
