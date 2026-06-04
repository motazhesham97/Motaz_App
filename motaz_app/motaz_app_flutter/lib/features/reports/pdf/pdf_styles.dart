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
  });

  final pw.Font regularFont;
  final pw.Font boldFont;

  static Future<PdfStyles> load() async {
    final regularData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
    return PdfStyles._(
      regularFont: pw.Font.ttf(regularData),
      boldFont: pw.Font.ttf(boldData),
    );
  }

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
    return pw.Document(
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
    );
  }
}
