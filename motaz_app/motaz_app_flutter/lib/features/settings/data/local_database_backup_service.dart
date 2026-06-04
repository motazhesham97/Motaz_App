import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/app_identity.dart';
import '../../../core/database/app_database.dart';

class LocalDatabaseBackupService {
  LocalDatabaseBackupService(this._db);

  static const _databaseFileName = AppIdentity.databaseFileName;
  static const _pendingImportFileName = 'Fastika.db.pending-import';
  static const _restoreReconcileMarkerFileName = 'Fastika.db.restore-reconcile';

  final AppDatabase _db;

  static Future<void> applyPendingImportIfAny() async {
    final pendingFile = await _pendingImportFile();
    if (!await pendingFile.exists()) return;

    final dbFile = await _databaseFile();
    final backupPath = await _createSafetyBackup(
      dbFile,
      'before-pending-import',
    );
    try {
      await _deleteSidecarFiles(dbFile.path);
      await pendingFile.copy(dbFile.path);
      await pendingFile.delete();
      await (await _restoreReconcileMarkerFile()).writeAsString(
        DateTime.now().toIso8601String(),
        flush: true,
      );
    } catch (_) {
      if (backupPath != null) {
        await File(backupPath).copy(dbFile.path);
      }
      rethrow;
    }
  }

  static Future<Directory> ensureBackupDirectory() async {
    final appFolder = Directory(
      p.join((await _backupBaseDirectory()).path, AppIdentity.backupFolderName),
    );
    final backupFolder = Directory(p.join(appFolder.path, 'backup'));
    await backupFolder.create(recursive: true);
    return backupFolder;
  }

  Future<String?> exportDatabase() async {
    await _db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');

    final source = await _databaseFile();
    if (!await source.exists()) {
      throw StateError('ملف قاعدة البيانات المحلية غير موجود');
    }

    final fileName = _backupFileName(DateTime.now());
    final bytes = await source.readAsBytes();

    if (Platform.isAndroid || Platform.isIOS) {
      final backupFolder = await ensureBackupDirectory();
      final target = File(p.join(backupFolder.path, fileName));
      await target.writeAsBytes(bytes, flush: true);
      return target.path;
    }

    final savedPath = await FilePicker.platform.saveFile(
      dialogTitle: 'حفظ نسخة قاعدة البيانات المحلية',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['db'],
    );
    if (savedPath == null) return null;

    final targetPath = p.extension(savedPath).isEmpty
        ? '$savedPath.db'
        : savedPath;
    final target = File(targetPath);
    await target.parent.create(recursive: true);
    await target.writeAsBytes(bytes, flush: true);
    return target.path;
  }

  Future<ImportDatabaseResult> importDatabase() async {
    final picked = await FilePicker.platform.pickFiles(
      dialogTitle: 'اختر ملف قاعدة البيانات المحلية',
      type: FileType.custom,
      allowedExtensions: const ['db', 'sqlite', 'backup'],
      withData: true,
    );
    final file = picked?.files.single;
    if (file == null) {
      return const ImportDatabaseResult.cancelled();
    }

    final bytes = file.bytes ?? await _readPickedFile(file.path);
    if (bytes == null || bytes.isEmpty) {
      throw StateError('تعذر قراءة ملف قاعدة البيانات المحدد');
    }
    if (!_hasSqliteHeader(bytes)) {
      throw StateError('الملف المحدد ليس ملف قاعدة بيانات SQLite صالح');
    }

    final pendingFile = await _pendingImportFile();
    await pendingFile.writeAsBytes(bytes, flush: true);

    return ImportDatabaseResult.imported(
      importedName: file.name,
      pendingImportPath: pendingFile.path,
      restartRequired: true,
    );
  }

  Future<List<int>?> _readPickedFile(String? path) async {
    if (path == null) return null;
    final file = File(path);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  static Future<String?> _createSafetyBackup(
    File dbFile,
    String suffix,
  ) async {
    if (!await dbFile.exists()) return null;
    final backupFile = File(
      '${dbFile.path}.${_backupStamp(DateTime.now())}.$suffix',
    );
    await dbFile.copy(backupFile.path);
    return backupFile.path;
  }

  bool _hasSqliteHeader(List<int> bytes) {
    const sqliteHeader = [
      83,
      81,
      76,
      105,
      116,
      101,
      32,
      102,
      111,
      114,
      109,
      97,
      116,
      32,
      51,
      0,
    ];
    if (bytes.length < sqliteHeader.length) return false;
    for (var i = 0; i < sqliteHeader.length; i++) {
      if (bytes[i] != sqliteHeader[i]) return false;
    }
    return true;
  }

  static Future<File> _databaseFile() async {
    final folder = await getApplicationDocumentsDirectory();
    return File(p.join(folder.path, _databaseFileName));
  }

  static Future<File> _pendingImportFile() async {
    final folder = await getApplicationDocumentsDirectory();
    return File(p.join(folder.path, _pendingImportFileName));
  }

  static Future<bool> hasRestoreReconcileMarker() async {
    return (await _restoreReconcileMarkerFile()).exists();
  }

  static Future<void> clearRestoreReconcileMarker() async {
    final marker = await _restoreReconcileMarkerFile();
    if (await marker.exists()) {
      await marker.delete();
    }
  }

  static Future<File> _restoreReconcileMarkerFile() async {
    final folder = await getApplicationDocumentsDirectory();
    return File(p.join(folder.path, _restoreReconcileMarkerFileName));
  }

  static Future<Directory> _backupBaseDirectory() async {
    if (Platform.isAndroid) {
      final external = await getExternalStorageDirectory();
      if (external != null) return external;
    }
    return getApplicationDocumentsDirectory();
  }

  static Future<void> _deleteSidecarFiles(String dbPath) async {
    for (final path in ['$dbPath-shm', '$dbPath-wal', '$dbPath-journal']) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  String _backupFileName(DateTime now) {
    return 'Fastika_data ${_backupDisplayStamp(now)}.db';
  }

  static String _backupStamp(DateTime now) {
    return '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
  }

  static String _backupDisplayStamp(DateTime now) {
    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')} '
        '(${now.hour.toString().padLeft(2, '0')}：'
        '${now.minute.toString().padLeft(2, '0')})';
  }
}

class ImportDatabaseResult {
  const ImportDatabaseResult._({
    required this.imported,
    this.importedName,
    this.safetyBackupPath,
    this.pendingImportPath,
    required this.restartRequired,
  });

  const ImportDatabaseResult.cancelled()
    : this._(imported: false, restartRequired: false);

  const ImportDatabaseResult.imported({
    required String importedName,
    String? safetyBackupPath,
    String? pendingImportPath,
    bool restartRequired = false,
  }) : this._(
         imported: true,
         importedName: importedName,
         safetyBackupPath: safetyBackupPath,
         pendingImportPath: pendingImportPath,
         restartRequired: restartRequired,
       );

  final bool imported;
  final String? importedName;
  final String? safetyBackupPath;
  final String? pendingImportPath;
  final bool restartRequired;
}
