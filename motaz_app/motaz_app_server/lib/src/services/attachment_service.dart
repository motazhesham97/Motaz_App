import 'package:serverpod/serverpod.dart';

import '../generated/audit_event.dart';
import '../generated/attachment_metadata.dart';
import '../generated/enums/audit_operation.dart';
import '../generated/enums/parent_entity_type.dart';

class AttachmentService {
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
      return 'File type "$fileType" is not allowed. Allowed: ${allowedFileTypes.join(", ")}';
    }
    if (fileSize > maxFileSize) {
      return 'File size ${fileSize}b exceeds maximum of ${maxFileSize}b (10MB)';
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
  ) async {
    final now = DateTime.now().toUtc();

    final metadata = AttachmentMetadata(
      parentEntityType: ParentEntityType.values.firstWhere(
        (e) => e.name == parentEntityType,
        orElse: () => ParentEntityType.SALES_INVOICE,
      ),
      parentEntityId: UuidValue(parentEntityId),
      storageReference: publicId,
      secureUrl: secureUrl,
      fileType: fileType,
      fileSize: fileSize,
      createdAt: now,
      updatedAt: now,
      deviceId: const UuidValue('00000000-0000-0000-0000-000000000000'),
    );

    final inserted = await AttachmentMetadata.db.insertRow(session, metadata);

    final auditEvent = AuditEvent(
      entityType: ParentEntityType.values.firstWhere(
        (e) => e.name == parentEntityType,
        orElse: () => ParentEntityType.SALES_INVOICE,
      ),
      entityId: UuidValue(parentEntityId),
      operation: AuditOperation.CREATE,
      diffData: '{"attachmentId":"${inserted.id}","publicId":"$publicId"}',
      deviceId: const UuidValue('00000000-0000-0000-0000-000000000000'),
      createdAt: now,
    );
    await AuditEvent.db.insertRow(session, auditEvent);

    return inserted;
  }
}
