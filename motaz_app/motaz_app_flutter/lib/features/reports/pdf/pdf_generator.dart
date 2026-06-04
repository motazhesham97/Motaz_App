import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfGenerator {
  static Future<void> shareOrPrint(pw.Document doc, String fileName) async {
    final bytes = await doc.save();
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  static Future<void> printDoc(pw.Document doc) async {
    await Printing.layoutPdf(onLayout: (_) => doc.save());
  }
}
