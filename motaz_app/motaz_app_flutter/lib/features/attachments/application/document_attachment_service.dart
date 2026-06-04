import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/enums/parent_entity_type.dart';

final documentAttachmentServiceProvider = Provider<DocumentAttachmentService>((
  ref,
) {
  return DocumentAttachmentService(ref.watch(appDatabaseProvider));
});

class DocumentAttachmentService {
  DocumentAttachmentService(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();
  final _picker = ImagePicker();

  bool get canCaptureDocumentPhoto {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  Future<String?> captureDocumentPhoto(BuildContext context) async {
    if (!canCaptureDocumentPhoto) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('التقاط الصورة غير متوفر على هذا الجهاز'),
          ),
        );
      }
      return null;
    }

    final lostPath = await recoverLostDocumentPhoto();
    if (lostPath != null) return lostPath;

    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 90,
    );
    if (picked == null) return null;

    return _persistPickedFile(picked);
  }

  Future<String?> recoverLostDocumentPhoto() async {
    if (!canCaptureDocumentPhoto) return null;

    final response = await _picker.retrieveLostData();
    if (response.isEmpty || response.files == null || response.files!.isEmpty) {
      return null;
    }

    return _persistPickedFile(response.files!.first);
  }

  Future<String> _persistPickedFile(XFile picked) async {
    final appDir = await getApplicationDocumentsDirectory();
    final attachmentDir = Directory(p.join(appDir.path, 'document_photos'));
    await attachmentDir.create(recursive: true);

    final targetPath = p.join(attachmentDir.path, '${_uuid.v4()}.jpg');
    await File(picked.path).copy(targetPath);
    return targetPath;
  }

  Future<void> stagePhoto({
    required ParentEntityType parentEntityType,
    required String parentEntityId,
    required String localFilePath,
  }) async {
    final file = File(localFilePath);
    if (!await file.exists()) return;

    final now = DateTime.now();
    await _db
        .into(_db.localAttachmentStaging)
        .insert(
          LocalAttachmentStagingCompanion.insert(
            id: _uuid.v4(),
            parentEntityType: parentEntityType,
            parentEntityId: parentEntityId,
            localFilePath: localFilePath,
            fileType: 'image/jpeg',
            fileSize: Value(await file.length()),
            uploadStatus: const Value('PENDING'),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<String?> loadLatestLocalPhotoPath({
    required ParentEntityType parentEntityType,
    required String parentEntityId,
  }) async {
    final rows = await _db
        .customSelect(
          'SELECT local_file_path AS local_path '
          'FROM local_attachment_staging '
          'WHERE parent_entity_type = ? AND parent_entity_id = ? '
          "AND upload_status IN ('PENDING', 'IN_PROGRESS', 'UPLOADED') "
          'ORDER BY created_at DESC '
          'LIMIT 5',
          variables: [
            Variable<int>(parentEntityType.index),
            Variable<String>(parentEntityId),
          ],
        )
        .get();

    for (final row in rows) {
      final path = row.data['local_path'] as String?;
      if (path == null) continue;
      if (await File(path).exists()) return path;
    }
    return null;
  }
}
