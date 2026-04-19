import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/utils/money_formatter.dart';
import '../../data/report_models.dart';
import '../pdf_styles.dart';

class ClientStatementPdf {
  static pw.Document generate(PdfStyles styles, ClientStatementData data) {
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
                pw.Text('كشف حساب عميل', style: styles.titleStyle),
                pw.SizedBox(height: 8),
                pw.Text(data.clientName, style: styles.headerStyle),
                pw.SizedBox(height: 4),
                pw.Text(
                  '${_formatDate(data.dateRange.start)} - ${_formatDate(data.dateRange.end)}',
                  style: styles.bodyStyle,
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      formatMoneyPlain(data.openingBalance),
                      style: pw.TextStyle(font: styles.boldFont, fontSize: 11),
                    ),
                    pw.Text(
                      'رصيد افتتاحي',
                      style: pw.TextStyle(font: styles.boldFont, fontSize: 11),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                if (data.entries.isEmpty)
                  pw.Center(
                    child: pw.Text(
                      'لا توجد حركات',
                      style: styles.headerStyle,
                    ),
                  )
                else
                  pw.TableHelper.fromTextArray(
                    headers: ['التاريخ', 'النوع', 'المرجع', 'المبلغ', 'الرصيد'],
                    data: data.entries.map((e) => [
                          _formatDate(e.date),
                          _typeLabel(e.type),
                          e.reference,
                          formatMoneyPlain(e.amount),
                          formatMoneyPlain(e.runningBalance),
                        ]).toList(),
                    headerStyle: styles.tableHeaderStyle,
                    cellStyle: styles.tableCellStyle,
                    headerDecoration: const pw.BoxDecoration(
                      color: PdfColors.blue700,
                    ),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(1.5),
                      1: const pw.FlexColumnWidth(1.2),
                      2: const pw.FlexColumnWidth(1.5),
                      3: const pw.FlexColumnWidth(1.5),
                      4: const pw.FlexColumnWidth(1.5),
                    },
                  ),
                pw.SizedBox(height: 16),
                pw.Divider(),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      formatMoneyPlain(data.closingBalance),
                      style: pw.TextStyle(
                        font: styles.boldFont,
                        fontSize: 13,
                        color: data.closingBalance < 0
                            ? PdfColors.red
                            : PdfColors.green,
                      ),
                    ),
                    pw.Text(
                      data.closingBalance >= 0 ? 'رصيد مدين' : 'رصيد دائن',
                      style: pw.TextStyle(
                        font: styles.boldFont,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return doc;
  }

  static String _typeLabel(StatementEntryType type) => switch (type) {
        StatementEntryType.invoice => 'فاتورة',
        StatementEntryType.receipt => 'سند قبض',
        StatementEntryType.returnItem => 'مرتجع',
      };

  static String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}