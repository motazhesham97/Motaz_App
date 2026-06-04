import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:motaz_app_client/motaz_app_client.dart' as server;

import '../../../core/database/app_database.dart' hide Client;
import '../../../core/database/device_service.dart';
import '../../../core/database/enums/sync_status.dart';
import '../../../core/logging/app_logger.dart';

class AttachmentUploader {
  AttachmentUploader({
    required AppDatabase db,
    required server.Client serverClient,
    required DeviceService deviceService,
  }) : _db = db,
       _serverClient = serverClient,
       _deviceService = deviceService;

  final AppDatabase _db;
  final server.Client _serverClient;
  final DeviceService _deviceService;
  final Map<String, int> _retryCounts = {};
  static const int maxRetryCount = 5;

  Future<void> processPending() async {
    final pending =
        await (_db.select(_db.localAttachmentStaging)
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
      final nextRetryAt = entry.createdAt.add(
        _computeCumulativeDelay(retryCount),
      );
      if (now.isBefore(nextRetryAt)) return;
    }

    await (_db.update(
      _db.localAttachmentStaging,
    )..where((t) => t.id.equals(entry.id))).write(
      LocalAttachmentStagingCompanion(
        uploadStatus: Value('IN_PROGRESS'),
      ),
    );

    try {
      final approvalRequest = server.AttachmentUploadRequest(
        parentEntityType: entry.parentEntityType.name,
        parentEntityId: entry.parentEntityId,
        fileType: entry.fileType,
        fileSize: entry.fileSize ?? 0,
      );
      final approval = await _serverClient.attachment.requestUploadApproval(
        approvalRequest,
      );

      if (!approval.approved) {
        AppLogger.database.warning(
          'Upload approval rejected: ${approval.rejectionReason ?? 'unknown'}',
        );
        await _markFailed(entry.id);
        return;
      }

      final uploadUrl = approval.uploadUrl;
      final uploadPreset = approval.uploadPreset;
      if (uploadUrl == null || uploadUrl.isEmpty) {
        throw StateError('Attachment upload URL is missing');
      }
      if (uploadPreset == null || uploadPreset.isEmpty) {
        throw StateError('Attachment upload preset is missing');
      }

      final file = File(entry.localFilePath);
      if (!await file.exists()) {
        AppLogger.database.warning('File not found: ${entry.localFilePath}');
        await _markFailed(entry.id);
        return;
      }

      final uploaded = await _uploadToCloudinary(
        file,
        uploadUrl,
        uploadPreset,
        entry.fileType,
      );

      final device = await _deviceService.ensureCurrentDevice();
      final deviceId = device.id;
      final confirmRequest = server.AttachmentConfirmRequest(
        parentEntityType: entry.parentEntityType.name,
        parentEntityId: entry.parentEntityId,
        publicId: uploaded.publicId,
        secureUrl: uploaded.secureUrl,
        fileType: entry.fileType,
        fileSize: entry.fileSize ?? 0,
        deviceId: deviceId,
      );
      final confirmResponse = await _serverClient.attachment.confirmUpload(
        confirmRequest,
      );

      if (confirmResponse.success) {
        final metadataId = confirmResponse.attachmentMetadataId;
        if (metadataId != null && metadataId.isNotEmpty) {
          await _db
              .into(_db.attachmentMetadata)
              .insertOnConflictUpdate(
                AttachmentMetadataCompanion(
                  id: Value(metadataId),
                  parentEntityType: Value(entry.parentEntityType),
                  parentEntityId: Value(entry.parentEntityId),
                  storageReference: Value(uploaded.publicId),
                  secureUrl: Value(uploaded.secureUrl),
                  fileType: Value(entry.fileType),
                  fileSize: Value(entry.fileSize),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                  deviceId: Value(deviceId),
                  rowVersion: const Value(1),
                  syncStatus: Value(SyncStatus.SYNCED),
                ),
              );
        }

        await (_db.update(
          _db.localAttachmentStaging,
        )..where((t) => t.id.equals(entry.id))).write(
          LocalAttachmentStagingCompanion(
            uploadStatus: Value('UPLOADED'),
            updatedAt: Value(now),
          ),
        );
        _retryCounts.remove(entry.id);
        AppLogger.database.info('Attachment uploaded: ${entry.id}');
      } else {
        AppLogger.database.warning(
          'Upload confirm failed: ${confirmResponse.errorMessage ?? 'unknown'}',
        );
        await _markFailed(entry.id);
      }
    } catch (e) {
      AppLogger.database.warning('Attachment upload error for ${entry.id}: $e');
      _retryCounts[entry.id] = retryCount + 1;
      await _markFailedWithRetry(entry.id);
    }
  }

  Future<({String publicId, String secureUrl})> _uploadToCloudinary(
    File file,
    String uploadUrl,
    String uploadPreset,
    String fileType,
  ) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse(uploadUrl);
      final request = await client.postUrl(uri);
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'multipart/form-data; boundary=FlutterBoundary',
      );

      final bytes = await file.readAsBytes();
      final fileName = file.uri.pathSegments.last;
      final body = <int>[];
      body.addAll(utf8.encode('--FlutterBoundary\r\n'));
      body.addAll(
        utf8.encode(
          'Content-Disposition: form-data; name="file"; filename="$fileName"\r\n',
        ),
      );
      body.addAll(utf8.encode('Content-Type: $fileType\r\n\r\n'));
      body.addAll(bytes);
      body.addAll(utf8.encode('\r\n--FlutterBoundary\r\n'));
      body.addAll(
        utf8.encode(
          'Content-Disposition: form-data; name="upload_preset"\r\n\r\n',
        ),
      );
      body.addAll(utf8.encode(uploadPreset));
      body.addAll(utf8.encode('\r\n--FlutterBoundary--\r\n'));

      request.contentLength = body.length;
      request.add(body);

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError(
          'Attachment upload failed with HTTP ${response.statusCode}: $responseBody',
        );
      }

      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      final publicId = decoded['public_id'] as String?;
      final secureUrl = decoded['secure_url'] as String?;
      if (publicId == null || publicId.isEmpty) {
        throw StateError('Attachment upload response missing public_id');
      }
      if (secureUrl == null || secureUrl.isEmpty) {
        throw StateError('Attachment upload response missing secure_url');
      }
      return (publicId: publicId, secureUrl: secureUrl);
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _markFailed(String id) async {
    await (_db.update(
      _db.localAttachmentStaging,
    )..where((t) => t.id.equals(id))).write(
      LocalAttachmentStagingCompanion(
        uploadStatus: Value('FAILED'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> _markFailedWithRetry(String id) async {
    final retryCount = _retryCounts[id] ?? 0;
    final status = retryCount >= maxRetryCount ? 'FAILED' : 'PENDING';
    await (_db.update(
      _db.localAttachmentStaging,
    )..where((t) => t.id.equals(id))).write(
      LocalAttachmentStagingCompanion(
        uploadStatus: Value(status),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Duration _computeCumulativeDelay(int retryCount) {
    var totalSeconds = 0;
    for (var i = 1; i <= retryCount; i++) {
      totalSeconds += pow(2, i).toInt();
    }
    final jitterFactor = 0.8 + Random().nextDouble() * 0.4;
    final seconds = (totalSeconds * jitterFactor).round();
    return Duration(seconds: seconds.clamp(1, 32));
  }
}
