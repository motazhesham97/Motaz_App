import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfStyles {
  static const primaryColor = PdfColor.fromInt(0xFF657F66);
  static const secondaryColor = PdfColor.fromInt(0xFFF8B97E);
  static const secondaryLightColor = PdfColor.fromInt(0xFFFDEAD8);

  PdfStyles._({
    required this.regularFont,
    required this.boldFont,
    this.warning,
  });

  final pw.Font regularFont;
  final pw.Font boldFont;
  final String? warning;

  static Future<(ByteData, ByteData)> loadFontData() async => (
    await rootBundle.load('assets/fonts/Cairo-Regular.ttf'),
    await rootBundle.load('assets/fonts/Cairo-Bold.ttf'),
  );

  factory PdfStyles.fromFontData(
    (ByteData, ByteData) data, {
    String? warning,
  }) => PdfStyles._(
    regularFont: pw.Font.ttf(data.$1),
    boldFont: pw.Font.ttf(data.$2),
    warning: warning,
  );

  static Future<PdfStyles> load() async {
    return PdfStyles.fromFontData(await loadFontData());
  }

  pw.MultiPage multiPage({
    required pw.BuildListCallback build,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
    pw.EdgeInsetsGeometry? margin,
    pw.TextDirection textDirection = pw.TextDirection.rtl,
  }) => pw.MultiPage(
    build: build,
    pageFormat: pageFormat,
    margin: margin,
    textDirection: textDirection,
    maxPages: 200,
    header: (context) {
      // MultiPage's own retry limit is assert-only, including in release builds.
      if (context.pageNumber > 200) {
        throw StateError(
          'Report exceeds 200 pages; choose a shorter date range',
        );
      }
      return context.pageNumber == 1 && warning != null
          ? pw.Text(warning!, style: bodyStyle)
          : pw.SizedBox(height: 0);
    },
  );

  pw.TextStyle get bodyStyle => pw.TextStyle(font: regularFont, fontSize: 10);
  pw.TextStyle get headerStyle =>
      pw.TextStyle(font: boldFont, fontSize: 14, color: primaryColor);
  pw.TextStyle get titleStyle =>
      pw.TextStyle(font: boldFont, fontSize: 18, color: primaryColor);
  pw.TextStyle get tableHeaderStyle =>
      pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColors.white);
  pw.TextStyle get tableCellStyle =>
      pw.TextStyle(font: regularFont, fontSize: 9);

  pw.Document createDocument() {
    return _ReportDocument(
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
    );
  }
}

class _ReportDocument extends pw.Document {
  _ReportDocument({required pw.ThemeData theme}) : super(theme: theme);

  final _pending = <(pw.Page, int?)>[];

  @override
  void addPage(pw.Page page, {int? index}) => _pending.add((page, index));

  @override
  Future<Uint8List> save({bool enableEventLoopBalancing = false}) async {
    // Legacy report callers also defer layout until the export worker saves.
    for (final (page, index) in _pending) {
      super.addPage(page, index: index);
    }
    _pending.clear();
    return super.save(enableEventLoopBalancing: enableEventLoopBalancing);
  }
}
