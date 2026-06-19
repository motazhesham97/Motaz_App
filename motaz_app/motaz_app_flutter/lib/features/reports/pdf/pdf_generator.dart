import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/storage/app_export_directories.dart';

class PdfGenerator {
  static Future<String?> shareOrPrint(pw.Document doc, String fileName) async {
    final bytes = await doc.save();
    if (AppExportDirectories.isMobilePlatform) {
      return AppExportDirectories.saveReportBytes(
        fileName: fileName,
        bytes: bytes,
      );
    }

    final savedPath = await FilePicker.platform.saveFile(
      dialogTitle: 'حفظ تقرير PDF',
      fileName: AppExportDirectories.sanitizeFileName(
        fileName,
        fallback: 'report.pdf',
      ),
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (savedPath == null) return null;

    final targetPath = p.extension(savedPath).isEmpty
        ? '$savedPath.pdf'
        : savedPath;
    final target = File(targetPath);
    await target.parent.create(recursive: true);
    await target.writeAsBytes(bytes, flush: true);
    return target.path;
  }

  static void showSavedSnackBar(
    BuildContext context,
    String? savedPath, {
    String label = 'التقرير',
  }) {
    final message = savedPath == null || savedPath.isEmpty
        ? 'تم إلغاء حفظ $label'
        : 'تم حفظ $label:\n$savedPath';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static Future<void> printDoc(pw.Document doc) async {
    await Printing.layoutPdf(onLayout: (_) => doc.save());
  }
}
