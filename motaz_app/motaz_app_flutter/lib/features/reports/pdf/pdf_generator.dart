import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/storage/app_export_directories.dart';
import 'report_pdf_renderer.dart';
import 'pdf_worker.dart';

export 'report_pdf_renderer.dart' show PdfReportRequest, PdfReportKind;
export 'report_attachment_loader.dart';

class PdfGenerator {
  static Future<Uint8List> renderBytes(Object report) async {
    final bytes = switch (report) {
      PdfReportRequest request => await ReportPdfRenderer.render(request),
      pw.Document document => await PdfWorker.run(
        _saveDocument,
        document,
        timeout: const Duration(seconds: 45),
      ),
      _ => throw ArgumentError('Unsupported PDF report'),
    };
    if (bytes.length > 24 * 1024 * 1024) {
      throw StateError('PDF exceeds 24 MB');
    }
    return bytes;
  }

  static Future<Uint8List> _saveDocument(pw.Document document) =>
      document.save();

  static Future<String?> shareOrPrint(Object report, String fileName) async {
    final bytes = await renderBytes(report);
    if (AppExportDirectories.isMobilePlatform) {
      return AppExportDirectories.saveReportBytes(
        fileName: fileName,
        bytes: bytes,
      ).timeout(const Duration(seconds: 30));
    }

    final savedPath = await FilePicker.platform
        .saveFile(
          dialogTitle: 'حفظ تقرير PDF',
          fileName: AppExportDirectories.sanitizeFileName(
            fileName,
            fallback: 'report.pdf',
          ),
          type: FileType.custom,
          allowedExtensions: const ['pdf'],
        )
        .timeout(const Duration(minutes: 2));
    if (savedPath == null) {
      return null;
    }

    final targetPath = p.extension(savedPath).isEmpty
        ? '$savedPath.pdf'
        : savedPath;
    final target = File(targetPath);
    await target.parent
        .create(recursive: true)
        .timeout(const Duration(seconds: 10));
    await target
        .writeAsBytes(bytes, flush: true)
        .timeout(const Duration(seconds: 30));
    return target.path;
  }

  static void showSavedSnackBar(
    BuildContext context,
    String? savedPath, {
    String label = 'التقرير',
    String? warning,
  }) {
    final message = savedPath == null || savedPath.isEmpty
        ? 'تم إلغاء حفظ $label'
        : 'تم حفظ $label:\n$savedPath';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(warning == null ? message : '$message\n$warning')),
    );
  }

  static void showExportError(BuildContext context, Object error) {
    final message = error is TimeoutException
        ? 'انتهت مهلة تصدير التقرير. جرّب فترة أقصر ثم أعد المحاولة.'
        : 'تعذر تصدير التقرير. جرّب فترة أقصر وتحقق من مساحة التخزين.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  static Future<void> printDoc(Object report) async {
    final bytes = await renderBytes(report);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
    ).timeout(const Duration(minutes: 2));
  }
}
