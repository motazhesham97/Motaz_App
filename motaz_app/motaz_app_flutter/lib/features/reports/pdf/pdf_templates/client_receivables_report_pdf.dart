import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/utils/money_formatter.dart';
import '../../data/report_models.dart';
import '../pdf_styles.dart';

class ClientReceivablesReportPdf {
  static pw.Document generate(
    PdfStyles styles,
    ClientReceivablesReportData data,
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
                  'تقرير المبالغ المتبقية عند العملاء',
                  style: styles.titleStyle,
                ),
                pw.SizedBox(height: 8),
                pw.Text(data.filterLabel, style: styles.bodyStyle),
                pw.SizedBox(height: 16),
                if (data.rows.isEmpty)
                  pw.Center(
                    child: pw.Text('لا توجد نتائج', style: styles.headerStyle),
                  )
                else ...[
                  pw.TableHelper.fromTextArray(
                    headers: [
                      'العميل',
                      'إجمالي الفواتير',
                      'المدفوع',
                      'المرتجع',
                      'المتبقي',
                    ],
                    data: data.rows
                        .map(
                          (row) => [
                            row.clientName,
                            formatMoneyPlain(row.totalInvoiced),
                            formatMoneyPlain(row.totalPaid),
                            formatMoneyPlain(row.totalReturned),
                            formatMoneyPlain(row.remainingBalance),
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
                      1: const pw.FlexColumnWidth(1.4),
                      2: const pw.FlexColumnWidth(1.4),
                      3: const pw.FlexColumnWidth(1.4),
                      4: const pw.FlexColumnWidth(1.4),
                    },
                  ),
                  pw.SizedBox(height: 20),
                  pw.Divider(),
                  _summaryRow(styles, 'إجمالي المتبقي', data.totalRemaining),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return doc;
  }

  static pw.Widget _summaryRow(PdfStyles styles, String label, int amount) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(formatMoneyPlain(amount), style: styles.headerStyle),
        pw.Text(label, style: styles.headerStyle),
      ],
    );
  }
}
