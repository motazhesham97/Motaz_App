import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_client/motaz_app_client.dart';

void main() {
  group('Attachment endpoint protocol contract', () {
    test('upload approval request keeps parent and file fields', () {
      final request = AttachmentUploadRequest(
        parentEntityType: 'SALES_INVOICE',
        parentEntityId: 'invoice-1',
        fileType: 'image/jpeg',
        fileSize: 2048,
      );

      final json = request.toJson();

      expect(json, {
        '__className__': 'AttachmentUploadRequest',
        'parentEntityType': 'SALES_INVOICE',
        'parentEntityId': 'invoice-1',
        'fileType': 'image/jpeg',
        'fileSize': 2048,
      });

      final roundTrip = AttachmentUploadRequest.fromJson(json);
      expect(roundTrip.parentEntityType, request.parentEntityType);
      expect(roundTrip.parentEntityId, request.parentEntityId);
      expect(roundTrip.fileType, request.fileType);
      expect(roundTrip.fileSize, request.fileSize);
    });

    test(
      'upload approval response separates approval from rejection shape',
      () {
        final approvedJson = AttachmentUploadApproval(
          approved: true,
          uploadUrl: 'https://uploads.example.test',
          uploadPreset: 'preset-1',
        ).toJson();

        expect(approvedJson, {
          '__className__': 'AttachmentUploadApproval',
          'approved': true,
          'uploadUrl': 'https://uploads.example.test',
          'uploadPreset': 'preset-1',
        });
        expect(approvedJson, isNot(contains('rejectionReason')));

        final rejectedJson = AttachmentUploadApproval(
          approved: false,
          rejectionReason: 'File type is not allowed',
        ).toJson();

        expect(rejectedJson, {
          '__className__': 'AttachmentUploadApproval',
          'approved': false,
          'rejectionReason': 'File type is not allowed',
        });
        expect(rejectedJson, isNot(contains('uploadUrl')));
        expect(rejectedJson, isNot(contains('uploadPreset')));
      },
    );

    test('confirm upload request includes deviceId used by the server', () {
      final request = AttachmentConfirmRequest(
        parentEntityType: 'RECEIPT',
        parentEntityId: 'receipt-1',
        publicId: 'fastika/receipt-1',
        secureUrl: 'https://cdn.example.test/receipt-1.jpg',
        fileType: 'image/jpeg',
        fileSize: 4096,
        deviceId: 'device-1',
      );

      final json = request.toJson();

      expect(json, {
        '__className__': 'AttachmentConfirmRequest',
        'parentEntityType': 'RECEIPT',
        'parentEntityId': 'receipt-1',
        'publicId': 'fastika/receipt-1',
        'secureUrl': 'https://cdn.example.test/receipt-1.jpg',
        'fileType': 'image/jpeg',
        'fileSize': 4096,
        'deviceId': 'device-1',
      });

      final roundTrip = AttachmentConfirmRequest.fromJson(json);
      expect(roundTrip.deviceId, 'device-1');
      expect(roundTrip.publicId, request.publicId);
      expect(roundTrip.secureUrl, request.secureUrl);
    });

    test('confirm upload response omits unused optional fields', () {
      final successJson = AttachmentConfirmResponse(
        success: true,
        attachmentMetadataId: 'attachment-1',
      ).toJson();

      expect(successJson, {
        '__className__': 'AttachmentConfirmResponse',
        'success': true,
        'attachmentMetadataId': 'attachment-1',
      });
      expect(successJson, isNot(contains('errorMessage')));

      final failureJson = AttachmentConfirmResponse(
        success: false,
        errorMessage: 'Authentication required',
      ).toJson();

      expect(failureJson, {
        '__className__': 'AttachmentConfirmResponse',
        'success': false,
        'errorMessage': 'Authentication required',
      });
      expect(failureJson, isNot(contains('attachmentMetadataId')));
    });
  });
}
