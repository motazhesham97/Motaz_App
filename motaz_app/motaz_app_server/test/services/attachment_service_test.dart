import 'package:motaz_app_server/src/services/attachment_service.dart';
import 'package:test/test.dart';

void main() {
  group('AttachmentService upload validation', () {
    test('accepts supported image and PDF file types within size limit', () {
      for (final fileType in AttachmentService.allowedFileTypes) {
        final error = AttachmentService.validateUploadRequest(
          'SALES_INVOICE',
          'invoice-1',
          fileType,
          AttachmentService.maxFileSize,
        );

        expect(error, isNull, reason: '$fileType should be accepted');
      }
    });

    test('rejects unsupported file types before upload approval', () {
      final error = AttachmentService.validateUploadRequest(
        'SALES_INVOICE',
        'invoice-1',
        'text/plain',
        128,
      );

      expect(error, isNotNull);
      expect(error, contains('File type "text/plain" is not allowed'));
      expect(error, contains('image/jpeg'));
      expect(error, contains('image/png'));
      expect(error, contains('application/pdf'));
    });

    test('rejects files larger than the maximum allowed size', () {
      final oversized = AttachmentService.maxFileSize + 1;

      final error = AttachmentService.validateUploadRequest(
        'RECEIPT',
        'receipt-1',
        'image/jpeg',
        oversized,
      );

      expect(error, isNotNull);
      expect(error, contains('exceeds maximum'));
      expect(error, contains('10MB'));
    });
  });
}
