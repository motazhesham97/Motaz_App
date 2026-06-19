import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../app_identity.dart';

class AppExportDirectories {
  const AppExportDirectories._();

  static const _channel = MethodChannel('fastika/export_files');
  static const backupFolderName = 'backup';
  static const reportsFolderName = 'reports';

  static bool get isMobilePlatform => switch (Platform.operatingSystem) {
    'android' || 'ios' => true,
    _ => false,
  };

  static Future<void> ensureAll() async {
    if (Platform.isAndroid) {
      await _ensureAndroidDirectory(backupFolderName);
      await _ensureAndroidDirectory(reportsFolderName);
      return;
    }

    await backupDirectory();
    await reportsDirectory();
  }

  static Future<Directory> backupDirectory() {
    return _childDirectory(backupFolderName);
  }

  static Future<Directory> reportsDirectory() {
    return _childDirectory(reportsFolderName);
  }

  static Future<File> createReportFile(String fileName) async {
    final reports = await reportsDirectory();
    return _availableFile(reports, fileName, fallbackName: 'report.pdf');
  }

  static Future<File> createBackupFile(String fileName) async {
    final backups = await backupDirectory();
    return _availableFile(backups, fileName, fallbackName: 'Fastika_data.db');
  }

  static Future<String> saveReportBytes({
    required String fileName,
    required Uint8List bytes,
  }) async {
    return _saveBytes(
      folderName: reportsFolderName,
      fileName: fileName,
      bytes: bytes,
      mimeType: 'application/pdf',
      fallbackName: 'report.pdf',
    );
  }

  static Future<String> saveBackupBytes({
    required String fileName,
    required Uint8List bytes,
  }) async {
    return _saveBytes(
      folderName: backupFolderName,
      fileName: fileName,
      bytes: bytes,
      mimeType: 'application/octet-stream',
      fallbackName: 'Fastika_data.db',
    );
  }

  static String sanitizeFileName(
    String fileName, {
    String fallback = 'export',
  }) {
    final sanitized = fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .replaceAll(RegExp(r'^[_. ]+|[_. ]+$'), '');
    return sanitized.isEmpty ? fallback : sanitized;
  }

  static Future<Directory> _childDirectory(String name) async {
    final root = await _appDirectory();
    final child = Directory(p.join(root.path, name));
    await child.create(recursive: true);
    return child;
  }

  static Future<void> _ensureAndroidDirectory(String folderName) async {
    await _channel.invokeMethod<String>('ensureDirectory', {
      'folderName': folderName,
    });
  }

  static Future<String> _saveBytes({
    required String folderName,
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    required String fallbackName,
  }) async {
    final safeName = sanitizeFileName(fileName, fallback: fallbackName);
    if (Platform.isAndroid) {
      final savedPath = await _channel.invokeMethod<String>('saveFile', {
        'folderName': folderName,
        'fileName': safeName,
        'mimeType': mimeType,
        'bytes': bytes,
      });
      if (savedPath == null || savedPath.isEmpty) {
        throw StateError('تعذر حفظ الملف في مجلد Fastika العام');
      }
      return savedPath;
    }

    final target = folderName == reportsFolderName
        ? await createReportFile(safeName)
        : await createBackupFile(safeName);
    await target.writeAsBytes(bytes, flush: true);
    return target.path;
  }

  static Future<Directory> _appDirectory() async {
    if (Platform.isAndroid) {
      final publicRoot = Directory(
        p.join('/storage/emulated/0', AppIdentity.backupFolderName),
      );
      try {
        await publicRoot.create(recursive: true);
        return publicRoot;
      } catch (_) {
        final external = await getExternalStorageDirectory();
        if (external != null) {
          final fallback = Directory(
            p.join(external.path, AppIdentity.backupFolderName),
          );
          await fallback.create(recursive: true);
          return fallback;
        }
      }
    }

    final documents = await getApplicationDocumentsDirectory();
    final appFolder = Directory(
      p.join(documents.path, AppIdentity.backupFolderName),
    );
    await appFolder.create(recursive: true);
    return appFolder;
  }

  static Future<File> _availableFile(
    Directory directory,
    String fileName, {
    required String fallbackName,
  }) async {
    final safeName = sanitizeFileName(fileName, fallback: fallbackName);
    final candidate = File(p.join(directory.path, safeName));
    if (!await candidate.exists()) return candidate;

    final stamp = _fileStamp(DateTime.now());
    final extension = p.extension(safeName);
    final baseName = p.basenameWithoutExtension(safeName);
    return File(p.join(directory.path, '${baseName}_$stamp$extension'));
  }

  static String _fileStamp(DateTime now) {
    return '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
  }
}
