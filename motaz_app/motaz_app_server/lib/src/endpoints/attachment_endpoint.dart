import 'package:serverpod/serverpod.dart';

import '../generated/attachment_upload_request.dart';
import '../generated/attachment_upload_approval.dart';
import '../generated/attachment_confirm_request.dart';
import '../generated/attachment_confirm_response.dart';
import '../generated/device.dart';
import '../services/attachment_service.dart';

class AttachmentEndpoint extends Endpoint {
  Future<AttachmentUploadApproval> requestUploadApproval(
    Session session,
    AttachmentUploadRequest request,
  ) async {
    if (!session.isUserSignedIn) {
      return AttachmentUploadApproval(
        approved: false,
        rejectionReason: 'Authentication required',
      );
    }

    final validationError = AttachmentService.validateUploadRequest(
      request.parentEntityType,
      request.parentEntityId,
      request.fileType,
      request.fileSize,
    );

    if (validationError != null) {
      return AttachmentUploadApproval(
        approved: false,
        rejectionReason: validationError,
      );
    }

    final uploadInfo = await AttachmentService.generateSignedUploadUrl(
      session,
      request.parentEntityType,
      request.parentEntityId,
    );

    return AttachmentUploadApproval(
      approved: true,
      uploadUrl: uploadInfo.uploadUrl,
      uploadPreset: uploadInfo.uploadPreset,
    );
  }

  Future<AttachmentConfirmResponse> confirmUpload(
    Session session,
    AttachmentConfirmRequest request,
  ) async {
    if (!session.isUserSignedIn) {
      return AttachmentConfirmResponse(
        success: false,
        errorMessage: 'Authentication required',
      );
    }

    final deviceId = request.deviceId;

    try {
      final metadata = await AttachmentService.confirmUpload(
        session,
        request.parentEntityType,
        request.parentEntityId,
        request.publicId,
        request.secureUrl,
        request.fileType,
        request.fileSize,
        deviceId,
      );

      return AttachmentConfirmResponse(
        success: true,
        attachmentMetadataId: metadata.id.toString(),
      );
    } catch (e) {
      return AttachmentConfirmResponse(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }
}
