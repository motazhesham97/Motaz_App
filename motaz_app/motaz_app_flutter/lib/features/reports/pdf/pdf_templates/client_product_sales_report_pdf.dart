import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/utils/money_formatter.dart';
import '../../data/report_models.dart';
import '../pdf_styles.dart';

class ClientProductSalesReportPdf {
  static pw.Document generate(
    PdfStyles styles,
    ClientProductSalesReportData data,
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
                pw.Text(
                  'تقرير المنتجات المباعة لعميل',
                  style: styles.titleStyle,
                ),
                pw.SizedBox(height: 8),
                pw.Text('العميل: ${data.clientName}', style: styles.bodyStyle),
                pw.Text(data.filterLabel, style: styles.bodyStyle),
                pw.SizedBox(height: 16),
                if (data.rows.isEmpty)
                  pw.Center(
                    child: pw.Text('لا توجد نتائج', style: styles.headerStyle),
                  )
                else ...[
                  pw.TableHelper.fromTextArray(
                    headers: [
                      'المنتج',
                      'الكمية',
                      'إجمالي المبيعات',
                      'المرتجع',
                      'صافي الكمية',
                      'قيمة المرتجع',
                      'صافي المبيعات',
                    ],
                    data: data.rows
                        .map(
                          (row) => [
                            row.productName,
                            row.totalQuantitySold.toString(),
                            formatMoneyPlain(row.totalSales),
                            row.totalQuantityReturned.toString(),
                            row.netQuantity.toString(),
                            formatMoneyPlain(row.totalReturns),
                            formatMoneyPlain(row.netSales),
                          ],
                        )
                        .toList(),
                    headerStyle: styles.tableHeaderStyle,
                    cellStyle: styles.tableCellStyle,
                    headerDecoration: const pw.BoxDecoration(
                      color: PdfStyles.primaryColor,
                    ),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(3),
                      1: const pw.FlexColumnWidth(1),
                      2: const pw.FlexColumnWidth(1),
                      3: const pw.FlexColumnWidth(1),
                      4: const pw.FlexColumnWidth(1.4),
                      5: const pw.FlexColumnWidth(1.4),
                      6: const pw.FlexColumnWidth(1.4),
                    },
                  ),
                  pw.SizedBox(height: 20),
                  pw.Divider(),
                  _summaryRow(
                    styles,
                    'إجمالي الكمية',
                    data.totalQuantitySold.toString(),
                  ),
                  _summaryRow(
                    styles,
                    'إجمالي الكمية المرتجعة',
                    data.totalQuantityReturned.toString(),
                  ),
                  _summaryRow(
                    styles,
                    'صافي الكمية',
                    data.netQuantity.toString(),
                  ),
                  _summaryRow(
                    styles,
                    'إجمالي المبيعات',
                    formatMoneyPlain(data.totalSales),
                  ),
                  _summaryRow(
                    styles,
                    'إجمالي المرتجع',
                    formatMoneyPlain(data.totalReturns),
                  ),
                  _summaryRow(
                    styles,
                    'صافي المبيعات',
                    formatMoneyPlain(data.netSales),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return doc;
  }

  static pw.Widget _summaryRow(PdfStyles styles, String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(value, style: styles.headerStyle),
          pw.Text(label, style: styles.headerStyle),
        ],
      ),
    );
  }
}
