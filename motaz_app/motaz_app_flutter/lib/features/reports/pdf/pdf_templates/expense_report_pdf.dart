import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/database/enums/expense_category.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../data/report_models.dart';
import '../pdf_styles.dart';

class ExpenseReportPdf {
  static pw.Document generate(PdfStyles styles, ExpenseReportData data) {
    final doc = styles.createDocument();
    final groups = _groupByDate(data.rows);
    final totals = _ExpenseTotals.fromRows(data.rows);

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
                  'كشف المصروفات',
                  style: styles.titleStyle,
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  data.filterLabel,
                  style: styles.bodyStyle,
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 14),
                if (data.rows.isEmpty)
                  pw.Center(
                    child: pw.Text(
                      'لا توجد مصروفات',
                      style: styles.headerStyle,
                    ),
                  )
                else
                  _expenseTable(styles, groups, totals),
              ],
            ),
          ),
        ],
      ),
    );

    return doc;
  }

  static pw.Widget _expenseTable(
    PdfStyles styles,
    List<_ExpenseDayGroup> groups,
    _ExpenseTotals totals,
  ) {
    return pw.Table(
      border: pw.TableBorder(
        top: const pw.BorderSide(color: PdfColors.grey600, width: 0.7),
        bottom: const pw.BorderSide(color: PdfColors.grey600, width: 0.7),
        left: const pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        right: const pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        horizontalInside: const pw.BorderSide(
          color: PdfColors.grey300,
          width: 0.5,
        ),
        verticalInside: const pw.BorderSide(
          color: PdfColors.grey300,
          width: 0.5,
        ),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.15),
        1: pw.FlexColumnWidth(2.25),
        2: pw.FlexColumnWidth(2.25),
        3: pw.FlexColumnWidth(3.15),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfStyles.primaryColor),
          children: [
            _headerCell(styles, 'التاريخ'),
            _headerCell(styles, 'التشغيلية'),
            _headerCell(styles, 'الإنتاجية'),
            _headerCell(styles, 'السحبيات'),
          ],
        ),
        for (final group in groups)
          pw.TableRow(
            children: [
              _dateCell(styles, group.date),
              _entriesCell(styles, group.operational),
              _entriesCell(styles, group.production),
              _drawsCell(styles, group.draws),
            ],
          ),
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfStyles.secondaryLightColor),
          children: [
            _summarySpacer(),
            _categorySummaryCell(styles, totals.operational),
            _categorySummaryCell(styles, totals.production),
            _drawSummaryCell(styles, totals),
          ],
        ),
      ],
    );
  }

  static pw.Widget _headerCell(PdfStyles styles, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: pw.Text(
        text,
        style: styles.tableHeaderStyle,
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _dateCell(PdfStyles styles, DateTime date) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: pw.Directionality(
        textDirection: pw.TextDirection.ltr,
        child: pw.Text(
          _formatDate(date),
          style: pw.TextStyle(font: styles.boldFont, fontSize: 9),
          textAlign: pw.TextAlign.center,
        ),
      ),
    );
  }

  static pw.Widget _entriesCell(PdfStyles styles, List<ExpenseReportRow> rows) {
    return _tableCell(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          for (final row in rows) ...[
            _expenseLine(
              styles,
              note: _noteFor(row),
              amount: row.amount,
              noteColor: PdfColors.grey900,
              amountColor: PdfColors.green800,
            ),
            if (row != rows.last) pw.SizedBox(height: 3),
          ],
        ],
      ),
    );
  }

  static pw.Widget _drawsCell(PdfStyles styles, List<ExpenseReportRow> rows) {
    return _tableCell(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          for (final row in rows) ...[
            _drawLine(styles, row),
            if (row != rows.last) pw.SizedBox(height: 3),
          ],
        ],
      ),
    );
  }

  static pw.Widget _expenseLine(
    PdfStyles styles, {
    required String note,
    required int amount,
    required PdfColor noteColor,
    required PdfColor amountColor,
  }) {
    return pw.RichText(
      textDirection: pw.TextDirection.rtl,
      text: pw.TextSpan(
        style: pw.TextStyle(font: styles.regularFont, fontSize: 8.8),
        children: [
          pw.TextSpan(
            text: note,
            style: pw.TextStyle(color: noteColor),
          ),
          const pw.TextSpan(text: ': '),
          pw.TextSpan(
            text: _formatAmount(amount),
            style: pw.TextStyle(font: styles.boldFont, color: amountColor),
          ),
        ],
      ),
    );
  }

  static pw.Widget _drawLine(PdfStyles styles, ExpenseReportRow row) {
    return pw.RichText(
      textDirection: pw.TextDirection.rtl,
      text: pw.TextSpan(
        style: pw.TextStyle(font: styles.regularFont, fontSize: 8.8),
        children: [
          pw.TextSpan(
            text: _partyLabel(row.category),
            style: pw.TextStyle(
              font: styles.boldFont,
              color: _partyColor(row.category),
            ),
          ),
          const pw.TextSpan(text: ' -> '),
          pw.TextSpan(
            text: _noteFor(row),
            style: const pw.TextStyle(color: PdfColors.grey900),
          ),
          const pw.TextSpan(text: ': '),
          pw.TextSpan(
            text: _formatAmount(row.amount),
            style: pw.TextStyle(font: styles.boldFont, color: PdfColors.red700),
          ),
        ],
      ),
    );
  }

  static pw.Widget _summarySpacer() {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      child: pw.SizedBox(height: 1),
    );
  }

  static pw.Widget _categorySummaryCell(PdfStyles styles, int total) {
    return _tableCell(
      pw.Text(
        '- المجموع: ${_formatAmount(total)}',
        style: pw.TextStyle(font: styles.boldFont, fontSize: 9),
      ),
    );
  }

  static pw.Widget _drawSummaryCell(PdfStyles styles, _ExpenseTotals totals) {
    return _tableCell(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            'التفاصيل:',
            style: pw.TextStyle(font: styles.boldFont, fontSize: 9),
          ),
          pw.SizedBox(height: 3),
          _summaryLine(styles, 'معتز', totals.partnerDraw, PdfColors.teal700),
          _summaryLine(styles, 'امي', totals.ownerDraw, PdfStyles.primaryColor),
          _summaryLine(
            styles,
            'الهامش',
            totals.marginDraw,
            PdfColors.orange800,
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            '- المجموع الكلي: ${_formatAmount(totals.totalDraws)}',
            style: pw.TextStyle(font: styles.boldFont, fontSize: 9),
          ),
        ],
      ),
    );
  }

  static pw.Widget _summaryLine(
    PdfStyles styles,
    String label,
    int amount,
    PdfColor color,
  ) {
    return pw.RichText(
      textDirection: pw.TextDirection.rtl,
      text: pw.TextSpan(
        style: pw.TextStyle(font: styles.regularFont, fontSize: 8.8),
        children: [
          const pw.TextSpan(text: '-'),
          pw.TextSpan(
            text: label,
            style: pw.TextStyle(font: styles.boldFont, color: color),
          ),
          const pw.TextSpan(text: ': '),
          pw.TextSpan(text: _formatAmount(amount)),
        ],
      ),
    );
  }

  static pw.Widget _tableCell(pw.Widget child) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: child,
    );
  }

  static List<_ExpenseDayGroup> _groupByDate(List<ExpenseReportRow> rows) {
    final sortedRows = [...rows]
      ..sort((a, b) => a.expenseDate.compareTo(b.expenseDate));
    final groups = <String, _ExpenseDayGroup>{};

    for (final row in sortedRows) {
      final date = DateTime(
        row.expenseDate.year,
        row.expenseDate.month,
        row.expenseDate.day,
      );
      final key = _formatDate(date);
      final group = groups.putIfAbsent(key, () => _ExpenseDayGroup(date));
      switch (row.category) {
        case ExpenseCategory.OPERATIONAL:
          group.operational.add(row);
        case ExpenseCategory.PRODUCTION:
          group.production.add(row);
        case ExpenseCategory.OWNER_DRAW:
        case ExpenseCategory.PARTNER_DRAW:
        case ExpenseCategory.MARGIN_DRAW:
          group.draws.add(row);
      }
    }

    return groups.values.toList();
  }

  static String _noteFor(ExpenseReportRow row) {
    final note = row.note?.trim();
    if (note != null && note.isNotEmpty) {
      return note;
    }
    return row.categoryLabel;
  }

  static String _partyLabel(ExpenseCategory category) {
    return switch (category) {
      ExpenseCategory.OWNER_DRAW => 'امي',
      ExpenseCategory.PARTNER_DRAW => 'معتز',
      ExpenseCategory.MARGIN_DRAW => 'الهامش',
      ExpenseCategory.OPERATIONAL => 'التشغيلية',
      ExpenseCategory.PRODUCTION => 'الإنتاجية',
    };
  }

  static PdfColor _partyColor(ExpenseCategory category) {
    return switch (category) {
      ExpenseCategory.OWNER_DRAW => PdfStyles.primaryColor,
      ExpenseCategory.PARTNER_DRAW => PdfColors.teal700,
      ExpenseCategory.MARGIN_DRAW => PdfColors.orange800,
      ExpenseCategory.OPERATIONAL => PdfColors.grey900,
      ExpenseCategory.PRODUCTION => PdfColors.grey900,
    };
  }

  static String _formatAmount(int amount) {
    return '${formatMoneyPlain(amount)} ريال';
  }

  static String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

class _ExpenseDayGroup {
  _ExpenseDayGroup(this.date);

  final DateTime date;
  final List<ExpenseReportRow> operational = [];
  final List<ExpenseReportRow> production = [];
  final List<ExpenseReportRow> draws = [];
}

class _ExpenseTotals {
  _ExpenseTotals({
    required this.operational,
    required this.production,
    required this.ownerDraw,
    required this.partnerDraw,
    required this.marginDraw,
  });

  final int operational;
  final int production;
  final int ownerDraw;
  final int partnerDraw;
  final int marginDraw;

  int get totalDraws => ownerDraw + partnerDraw + marginDraw;

  factory _ExpenseTotals.fromRows(List<ExpenseReportRow> rows) {
    var operational = 0;
    var production = 0;
    var ownerDraw = 0;
    var partnerDraw = 0;
    var marginDraw = 0;

    for (final row in rows) {
      switch (row.category) {
        case ExpenseCategory.OPERATIONAL:
          operational += row.amount;
        case ExpenseCategory.PRODUCTION:
          production += row.amount;
        case ExpenseCategory.OWNER_DRAW:
          ownerDraw += row.amount;
        case ExpenseCategory.PARTNER_DRAW:
          partnerDraw += row.amount;
        case ExpenseCategory.MARGIN_DRAW:
          marginDraw += row.amount;
      }
    }

    return _ExpenseTotals(
      operational: operational,
      production: production,
      ownerDraw: ownerDraw,
      partnerDraw: partnerDraw,
      marginDraw: marginDraw,
    );
  }
}
