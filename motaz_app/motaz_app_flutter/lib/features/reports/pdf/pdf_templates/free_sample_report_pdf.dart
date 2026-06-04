import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/utils/document_reference_formatter.dart';
import '../../../free_samples/data/free_sample_repository.dart';
import '../pdf_styles.dart';

class FreeSampleReportPdf {
  static pw.Document generate(
    PdfStyles styles, {
    required List<FreeSampleSummary> rows,
    required String filterLabel,
  }) {
    final doc = styles.createDocument();
    final totalQuantity = rows.fold<int>(
      0,
      (sum, row) => sum + row.totalQuantity,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        textDirection: pw.TextDirection.rtl,
        build: (context) => [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Text(
                  'تقرير العينات المجانية',
                  style: styles.titleStyle,
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  filterLabel,
                  style: styles.bodyStyle,
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 14),
                if (rows.isEmpty)
                  pw.Center(
                    child: pw.Text(
                      'لا توجد عينات مجانية',
                      style: styles.headerStyle,
                    ),
                  )
                else ...[
                  _table(styles, rows),
                  pw.SizedBox(height: 10),
                  pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text(
                      'إجمالي العدد: $totalQuantity',
                      style: pw.TextStyle(
                        font: styles.boldFont,
                        fontSize: 11,
                        color: PdfStyles.primaryColor,
                      ),
                    ),
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

  static pw.Widget _table(PdfStyles styles, List<FreeSampleSummary> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.6),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.1),
        1: pw.FlexColumnWidth(1.35),
        2: pw.FlexColumnWidth(1.7),
        3: pw.FlexColumnWidth(3.1),
        4: pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfStyles.primaryColor),
          children: [
            _header(styles, 'الرقم'),
            _header(styles, 'التاريخ'),
            _header(styles, 'المستفيد'),
            _header(styles, 'المنتجات'),
            _header(styles, 'العدد'),
          ],
        ),
        for (final row in rows)
          pw.TableRow(
            children: [
              _cell(
                styles,
                freeSampleDisplayRef(
                  row.sample.localRef,
                  officialNo: row.sample.officialNo,
                ),
              ),
              _cell(styles, _formatDate(row.sample.sampleDate)),
              _cell(styles, row.beneficiaryName),
              _cell(styles, _productsText(row)),
              _cell(styles, row.totalQuantity.toString()),
            ],
          ),
      ],
    );
  }

  static pw.Widget _header(PdfStyles styles, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      child: pw.Text(
        text,
        style: styles.tableHeaderStyle,
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _cell(PdfStyles styles, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      child: pw.Text(
        text,
        style: styles.tableCellStyle,
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static String _productsText(FreeSampleSummary row) {
    return row.lines
        .map((line) => '${line.productName}: ${line.quantity}')
        .join(' | ');
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
