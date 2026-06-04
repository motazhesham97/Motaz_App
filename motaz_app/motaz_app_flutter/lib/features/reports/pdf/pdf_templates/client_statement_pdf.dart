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
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Center(
                  child: pw.Text(
                    'كشف حساب العميل: ${data.clientName}',
                    style: styles.titleStyle,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Center(
                  child: pw.Text(
                    'في الفترة: ${_formatDate(data.dateRange.start)} : ${_formatDate(data.dateRange.end)}',
                    style: styles.headerStyle,
                  ),
                ),
                pw.SizedBox(height: 16),
                _statementTable(styles, data),
              ],
            ),
          ),
        ],
      ),
    );

    return doc;
  }

  static pw.Widget _statementTable(PdfStyles styles, ClientStatementData data) {
    final tableRows = <pw.TableRow>[
      _headerRow(styles),
      _openingRow(styles, data),
      ...data.entries.asMap().entries.map((entry) {
        return _entryRow(styles, entry.key + 1, entry.value);
      }),
      _totalsRow(styles, data),
      _netRow(styles, data),
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfStyles.primaryColor, width: 0.7),
      columnWidths: const {
        0: pw.FixedColumnWidth(34),
        1: pw.FlexColumnWidth(3.2),
        2: pw.FlexColumnWidth(1.4),
        3: pw.FlexColumnWidth(1.4),
        4: pw.FlexColumnWidth(1.4),
        5: pw.FlexColumnWidth(1.1),
        6: pw.FlexColumnWidth(1.2),
      },
      children: tableRows,
    );
  }

  static pw.TableRow _headerRow(PdfStyles styles) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: PdfStyles.primaryColor),
      children: [
        _headerCell(styles, 'م'),
        _headerCell(styles, 'البيان'),
        _headerCell(styles, 'مبلغ له (مدفوع)'),
        _headerCell(styles, 'مبلغ عليه'),
        _headerCell(styles, 'الرصيد'),
        _headerCell(styles, 'الصورة'),
        _headerCell(styles, 'التاريخ'),
      ],
    );
  }

  static pw.TableRow _openingRow(PdfStyles styles, ClientStatementData data) {
    final previousDate = data.dateRange.start.subtract(const Duration(days: 1));
    final debit = data.openingBalance > 0 ? data.openingBalance : 0;
    final credit = data.openingBalance < 0 ? data.openingBalance.abs() : 0;
    return pw.TableRow(
      children: [
        _cell(styles, ''),
        _cell(styles, 'ما سبق حتى: ${_formatDate(previousDate)}'),
        _moneyCell(styles, credit, PdfColors.green700),
        _moneyCell(styles, debit, PdfColors.red700),
        _balanceCell(styles, data.openingBalance),
        _cell(styles, '-'),
        _cell(styles, ''),
      ],
    );
  }

  static pw.TableRow _entryRow(
    PdfStyles styles,
    int index,
    ClientStatementEntry entry,
  ) {
    final debit = entry.type == StatementEntryType.invoice ? entry.amount : 0;
    final credit = entry.type == StatementEntryType.invoice ? 0 : entry.amount;
    return pw.TableRow(
      children: [
        _cell(styles, index.toString()),
        _cell(styles, _statementText(entry)),
        _moneyCell(styles, credit, PdfColors.green700),
        _moneyCell(styles, debit, PdfColors.red700),
        _balanceCell(styles, entry.runningBalance),
        _imageCell(entry),
        _cell(styles, _formatDate(entry.date)),
      ],
    );
  }

  static pw.TableRow _totalsRow(PdfStyles styles, ClientStatementData data) {
    final totalDebit =
        (data.openingBalance > 0 ? data.openingBalance : 0) +
        data.entries
            .where((entry) => entry.type == StatementEntryType.invoice)
            .fold<int>(0, (sum, entry) => sum + entry.amount);
    final totalCredit =
        (data.openingBalance < 0 ? data.openingBalance.abs() : 0) +
        data.entries
            .where((entry) => entry.type != StatementEntryType.invoice)
            .fold<int>(0, (sum, entry) => sum + entry.amount);

    return pw.TableRow(
      decoration: pw.BoxDecoration(color: PdfStyles.secondaryLightColor),
      children: [
        _cell(styles, ''),
        _cell(styles, 'الإجمالي', bold: true),
        _moneyCell(styles, totalCredit, PdfColors.green700, bold: true),
        _moneyCell(styles, totalDebit, PdfColors.red700, bold: true),
        _balanceCell(styles, data.closingBalance),
        _cell(styles, ''),
        _cell(styles, ''),
      ],
    );
  }

  static pw.TableRow _netRow(PdfStyles styles, ClientStatementData data) {
    final isDebit = data.closingBalance >= 0;
    final netAmount = data.closingBalance.abs();
    return pw.TableRow(
      children: [
        _cell(styles, ''),
        _cell(
          styles,
          'المبلغ الصافي: ${isDebit ? '(عليه)' : '(له)'}',
          bold: true,
        ),
        isDebit
            ? _cell(styles, '')
            : _moneyCell(styles, netAmount, PdfColors.green700, bold: true),
        isDebit
            ? _moneyCell(styles, netAmount, PdfColors.red700, bold: true)
            : _cell(styles, ''),
        _cell(styles, ''),
        _cell(styles, ''),
        _cell(styles, ''),
      ],
    );
  }

  static pw.Widget _headerCell(PdfStyles styles, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: styles.tableHeaderStyle,
      ),
    );
  }

  static pw.Widget _cell(
    PdfStyles styles,
    String text, {
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          font: bold ? styles.boldFont : styles.regularFont,
          fontSize: 8,
        ),
      ),
    );
  }

  static pw.Widget _moneyCell(
    PdfStyles styles,
    int amount,
    PdfColor color, {
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        amount == 0 ? '0' : formatMoneyPlain(amount),
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          font: bold ? styles.boldFont : styles.regularFont,
          fontSize: 8,
          color: color,
        ),
      ),
    );
  }

  static pw.Widget _balanceCell(PdfStyles styles, int balance) {
    final isDebit = balance >= 0;
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        '${formatMoneyPlain(balance.abs())} ${isDebit ? 'عليه' : 'له'}',
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          font: styles.boldFont,
          fontSize: 8,
          color: isDebit ? PdfColors.red700 : PdfColors.green700,
        ),
      ),
    );
  }

  static pw.Widget _imageCell(ClientStatementEntry entry) {
    if (entry.attachmentImages.isEmpty) {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(5),
        child: pw.Text('-', textAlign: pw.TextAlign.center),
      );
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.all(3),
      child: pw.Center(
        child: pw.Container(
          width: 50,
          height: 36,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
          ),
          child: pw.Image(
            pw.MemoryImage(entry.attachmentImages.first),
            fit: pw.BoxFit.cover,
          ),
        ),
      ),
    );
  }

  static String _statementText(ClientStatementEntry entry) {
    final note = entry.note == null || entry.note!.trim().isEmpty
        ? ''
        : ' - ${entry.note!.trim()}';
    return '${_typeLabel(entry.type)}: ${entry.reference}$note';
  }

  static String _typeLabel(StatementEntryType type) => switch (type) {
    StatementEntryType.invoice => 'فاتورة',
    StatementEntryType.receipt => 'سند',
    StatementEntryType.returnItem => 'مرتجع',
  };

  static String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
