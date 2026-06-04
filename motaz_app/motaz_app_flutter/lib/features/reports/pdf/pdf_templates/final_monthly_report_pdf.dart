import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/utils/money_formatter.dart';
import '../../data/report_models.dart';
import '../pdf_styles.dart';

class FinalMonthlyReportPdf {
  static pw.Document generate(PdfStyles styles, FinalMonthlyReportData data) {
    final doc = styles.createDocument();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (context) => [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Center(
                  child: pw.Text(
                    '${_monthName(data.month)} ${data.year}',
                    style: pw.TextStyle(
                      font: styles.boldFont,
                      fontSize: 20,
                      color: PdfStyles.primaryColor,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                _sectionTitle(styles, 'التكلفة'),
                _inlineFormula(
                  styles,
                  [
                    'التشغيلية = ${_money(data.operationalExpenses)}',
                    'الإنتاجية = ${_money(data.productionExpenses)}',
                  ],
                  data.totalCost,
                ),
                pw.SizedBox(height: 16),
                _sectionTitle(styles, 'المبيعات'),
                if (data.productSales.isEmpty)
                  pw.Text(
                    'لا توجد مبيعات في هذا الشهر',
                    style: styles.bodyStyle,
                  )
                else
                  ...data.productSales.map((row) {
                    final prefix = row == data.productSales.first ? '' : '+ ';
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Text(
                        '$prefix${row.quantity} ${row.productName} = ${_money(row.totalSales)}',
                        style: styles.bodyStyle,
                      ),
                    );
                  }),
                pw.SizedBox(height: 6),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text('المجموع = ', style: _bold(styles)),
                    _amountBox(styles, data.totalSales),
                  ],
                ),
                pw.SizedBox(height: 16),
                _sectionTitle(styles, 'الأرباح'),
                _inlineFormula(
                  styles,
                  [
                    'المبيعات = ${_money(data.totalSales)}',
                    'التكلفة = ${_money(data.totalCost)}',
                  ],
                  data.profit,
                  operatorLabel: '-',
                ),
                pw.SizedBox(height: 18),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Container(
                    width: 260,
                    height: 1,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.SizedBox(height: 12),
                _sectionTitle(styles, 'السلف والسحبيات'),
                ...data.partyRows.map((row) => _partyLine(styles, row)),
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 1.2, color: PdfColors.grey700),
              ],
            ),
          ),
        ],
      ),
    );

    return doc;
  }

  static pw.Widget _sectionTitle(PdfStyles styles, String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text('* $title:', style: styles.headerStyle),
    );
  }

  static pw.Widget _inlineFormula(
    PdfStyles styles,
    List<String> parts,
    int result, {
    String operatorLabel = '+',
  }) {
    return pw.Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: pw.WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < parts.length; i++) ...[
          if (i > 0) pw.Text(operatorLabel, style: _bold(styles)),
          pw.Text(parts[i], style: styles.bodyStyle),
        ],
        pw.Text('=', style: _bold(styles)),
        _amountBox(styles, result),
      ],
    );
  }

  static pw.Widget _partyLine(PdfStyles styles, FinalReportPartyRow row) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Wrap(
        spacing: 5,
        runSpacing: 5,
        crossAxisAlignment: pw.WrapCrossAlignment.center,
        children: [
          pw.Text('- ${row.partyName}:', style: _bold(styles)),
          pw.Text('ربح: ${_money(row.profitShare)}', style: styles.bodyStyle),
          pw.Text('-', style: _bold(styles)),
          pw.Text(
            'سحبيات: ${_money(row.withdrawals)}',
            style: styles.bodyStyle,
          ),
          pw.Text('=', style: _bold(styles)),
          pw.Text(_signed(row.afterWithdrawals), style: styles.bodyStyle),
          pw.Text('+ سداد: ${_money(row.repayments)}', style: styles.bodyStyle),
          pw.Text(
            '+ الرصيد السابق: ${_signed(row.openingBalance)}',
            style: styles.bodyStyle,
          ),
          pw.Text('=', style: _bold(styles)),
          _amountBox(styles, row.closingBalance),
        ],
      ),
    );
  }

  static pw.Widget _amountBox(PdfStyles styles, int amount) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: pw.BoxDecoration(
        color: amount < 0
            ? const PdfColor.fromInt(0xFFFFE5E5)
            : PdfStyles.secondaryLightColor,
        border: pw.Border.all(
          color: amount < 0 ? PdfColors.red600 : PdfStyles.secondaryColor,
          width: 1,
        ),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        _signed(amount),
        style: pw.TextStyle(
          font: styles.boldFont,
          fontSize: 10,
          color: amount < 0 ? PdfColors.red700 : PdfStyles.primaryColor,
        ),
      ),
    );
  }

  static pw.TextStyle _bold(PdfStyles styles) {
    return pw.TextStyle(font: styles.boldFont, fontSize: 10);
  }

  static String _money(int value) => formatMoneyPlain(value);

  static String _signed(int value) {
    if (value < 0) return '(${formatMoneyPlain(value)})';
    return formatMoneyPlain(value);
  }

  static String _monthName(int month) {
    return switch (month) {
      1 => 'يناير',
      2 => 'فبراير',
      3 => 'مارس',
      4 => 'أبريل',
      5 => 'مايو',
      6 => 'يونيو',
      7 => 'يوليو',
      8 => 'أغسطس',
      9 => 'سبتمبر',
      10 => 'أكتوبر',
      11 => 'نوفمبر',
      _ => 'ديسمبر',
    };
  }
}
