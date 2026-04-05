import 'dart:io';
import 'dart:math';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:motaz_app_client/motaz_app_client.dart' as server;

import '../../../core/database/app_database.dart' hide Client;
import '../../../core/database/device_service.dart';
import '../../../core/logging/app_logger.dart';

class AttachmentUploader {
  AttachmentUploader({
    required AppDatabase db,
    required server.Client serverClient,
    required DeviceService deviceService,
  }) : _db = db, _serverClient = serverClient, _deviceService = deviceService;

  final AppDatabase _db;
  final server.Client _serverClient;
  final DeviceService _deviceService;
  final Map<String, int> _retryCounts = {};
  static const int maxRetryCount = 5;

  Future<void> processPending() async {
    final pending = await (_db.select(_db.localAttachmentStaging)
          ..where((t) => t.uploadStatus.equals('PENDING'))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    for (final entry in pending) {
      await _processEntry(entry);
    }
  }

  Future<void> _processEntry(LocalAttachmentStagingData entry) async {
    final now = DateTime.now();
    final retryCount = _retryCounts[entry.id] ?? 0;
    if (retryCount > 0) {
      final nextRetryAt = entry.createdAt.add(_computeCumulativeDelay(retryCount));
      if (now.isBefore(nextRetryAt)) return;
    }

    await (_db.update(_db.localAttachmentStaging)
          ..where((t) => t.id.equals(entry.id)))
        .write(LocalAttachmentStagingCompanion(
      uploadStatus: Value('IN_PROGRESS'),
    ));

    try {
      final approvalRequest = server.AttachmentUploadRequest(
        parentEntityType: entry.parentEntityType.name,
        parentEntityId: entry.parentEntityId,
        fileType: entry.fileType,
        fileSize: entry.fileSize ?? 0,
      );
      final approval = await _serverClient.attachment.requestUploadApproval(approvalRequest);

      if (!approval.approved) {
        AppLogger.database.warning('Upload approval rejected: ' + (approval.rejectionReason ?? 'unknown'));
        await _markFailed(entry.id);
        return;
      }

      final file = File(entry.localFilePath);
      if (!await file.exists()) {
        AppLogger.database.warning('File not found: ' + entry.localFilePath);
        await _markFailed(entry.id);
        return;
      }

      final publicId = await _uploadToCloudinary(
        file,
        approval.uploadUrl ?? 'https://api.cloudinary.com/v1_1/demo/auto/upload',
        approval.uploadPreset ?? 'unsigned_preset',
        entry.fileType,
      );

    final secureUrl = 'https://res.cloudinary.com/demo/image/upload/' + publicId;

    final device = await _deviceService.currentDevice();
    final deviceId = device?.id ?? '00000000-0000-0000-0000-000000000000';
    final confirmRequest = server.AttachmentConfirmRequest(
      parentEntityType: entry.parentEntityType.name,
      parentEntityId: entry.parentEntityId,
      publicId: publicId,
      secureUrl: secureUrl,
      fileType: entry.fileType,
      fileSize: entry.fileSize ?? 0,
      deviceId: deviceId,
    );
    final confirmResponse = await _serverClient.attachment.confirmUpload(confirmRequest);

      if (confirmResponse.success) {
        await (_db.update(_db.localAttachmentStaging)
              ..where((t) => t.id.equals(entry.id)))
            .write(LocalAttachmentStagingCompanion(
          uploadStatus: Value('UPLOADED'),
          updatedAt: Value(now),
        ));
        AppLogger.database.info('Attachment uploaded: ' + entry.id);
      } else {
        AppLogger.database.warning('Upload confirm failed: ' + (confirmResponse.errorMessage ?? 'unknown'));
        await _markFailed(entry.id);
      }
  } catch (e) {
    AppLogger.database.warning('Attachment upload error for ' + entry.id + ': ' + e.toString());
    _retryCounts[entry.id] = retryCount + 1;
    await _markFailedWithRetry(entry.id, entry.createdAt);
  }
}

  Future<String> _uploadToCloudinary(
    File file,
    String uploadUrl,
    String uploadPreset,
    String fileType,
  ) async {
    final client = HttpClient();
    final uri = Uri.parse(uploadUrl);
    final request = await client.postUrl(uri);
    request.headers.set(HttpHeaders.contentTypeHeader, 'multipart/form-data; boundary=FlutterBoundary');

    final bytes = await file.readAsBytes();
    final fileName = file.uri.pathSegments.last;
    final body = <int>[];
    body.addAll(utf8.encode('--FlutterBoundary\r\n'));
    body.addAll(utf8.encode('Content-Disposition: form-data; name="file"; filename="' + fileName + '"\r\n'));
    body.addAll(utf8.encode('Content-Type: ' + fileType + '\r\n\r\n'));
    body.addAll(bytes);
    body.addAll(utf8.encode('\r\n--FlutterBoundary\r\n'));
    body.addAll(utf8.encode('Content-Disposition: form-data; name="upload_preset"\r\n\r\n'));
    body.addAll(utf8.encode(uploadPreset));
    body.addAll(utf8.encode('\r\n--FlutterBoundary--\r\n'));

    request.contentLength = body.length;
    request.add(body);

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    client.close();

    final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
    return decoded['public_id'] as String? ?? 'unknown';
  }

  Future<void> _markFailed(String id) async {
    await (_db.update(_db.localAttachmentStaging)
          ..where((t) => t.id.equals(id)))
        .write(LocalAttachmentStagingCompanion(
      uploadStatus: Value('FAILED'),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<void> _markFailedWithRetry(String id, DateTime createdAt) async {
    final existing = await (_db.select(_db.localAttachmentStaging)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (existing == null) return;
    // simple retry: reset to PENDING (retry count tracked via createdAt delay)
    await (_db.update(_db.localAttachmentStaging)
          ..where((t) => t.id.equals(id)))
        .write(LocalAttachmentStagingCompanion(
      uploadStatus: Value('PENDING'),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Duration _computeCumulativeDelay(int retryCount) {
    var totalSeconds = 0;
    for (int i = 1; i <= retryCount; i++) {
      totalSeconds += pow(2, i).toInt();
    }
    final jitterFactor = 0.8 + Random().nextDouble() * 0.4;
    final seconds = (totalSeconds * jitterFactor).round();
    return Duration(seconds: seconds.clamp(1, 32));
  }
}
