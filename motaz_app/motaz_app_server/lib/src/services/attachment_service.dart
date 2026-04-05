import 'package:serverpod/serverpod.dart';

import '../generated/audit_event.dart';
import '../generated/attachment_metadata.dart';
import '../generated/enums/audit_operation.dart';
import '../generated/enums/parent_entity_type.dart';

class AttachmentService {
  static ParentEntityType? _parseParentEntityType(String name) {
    for (final e in ParentEntityType.values) {
      if (e.name == name) return e;
    }
    return null;
  }

  static const int maxFileSize = 10 * 1024 * 1024;
  static const Set<String> allowedFileTypes = {
    'image/jpeg',
    'image/png',
    'application/pdf',
  };

  static String? validateUploadRequest(
    String parentEntityType,
    String parentEntityId,
    String fileType,
    int fileSize,
  ) {
    if (!allowedFileTypes.contains(fileType)) {
      return 'File type "' + fileType + '" is not allowed. Allowed: ' + allowedFileTypes.join(', ');
    }
    if (fileSize > maxFileSize) {
      return 'File size ' + fileSize.toString() + 'b exceeds maximum of ' + maxFileSize.toString() + 'b (10MB)';
    }
    return null;
  }

  static Future<({String uploadUrl, String uploadPreset})> generateSignedUploadUrl(
    Session session,
    String parentEntityType,
    String parentEntityId,
  ) async {
    final uploadUrl = const String.fromEnvironment(
      'CLOUDINARY_UPLOAD_URL',
      defaultValue: 'https://api.cloudinary.com/v1_1/demo/auto/upload',
    );
    final uploadPreset = const String.fromEnvironment(
      'CLOUDINARY_UPLOAD_PRESET',
      defaultValue: 'unsigned_preset',
    );
    return (uploadUrl: uploadUrl, uploadPreset: uploadPreset);
  }

  static Future<AttachmentMetadata> confirmUpload(
    Session session,
    String parentEntityType,
    String parentEntityId,
    String publicId,
    String secureUrl,
    String fileType,
    int fileSize,
    String deviceId,
  ) async {
    final now = DateTime.now().toUtc();

    final parsedType = _parseParentEntityType(parentEntityType);
    if (parsedType == null) {
      throw ArgumentError('Unknown parent entity type: ' + parentEntityType);
    }

    final metadata = AttachmentMetadata(
      parentEntityType: parsedType,
      parentEntityId: UuidValue(parentEntityId),
      storageReference: publicId,
      secureUrl: secureUrl,
      fileType: fileType,
      fileSize: fileSize,
      createdAt: now,
      updatedAt: now,
      deviceId: UuidValue(deviceId),
    );

    final inserted = await AttachmentMetadata.db.insertRow(session, metadata);

    final auditEvent = AuditEvent(
      entityType: parsedType,
      entityId: UuidValue(parentEntityId),
      operation: AuditOperation.CREATE,
      diffData: '{"attachmentId":"' + inserted.id.toString() + '","publicId":"' + publicId + '"}',
      deviceId: UuidValue(deviceId),
      createdAt: now,
    );
    await AuditEvent.db.insertRow(session, auditEvent);

    return inserted;
  }
}
