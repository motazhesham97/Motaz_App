import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_client/motaz_app_client.dart' as server;
import 'package:motaz_app_flutter/core/database/app_database.dart';
import 'package:motaz_app_flutter/core/database/device_service.dart';
import 'package:motaz_app_flutter/core/database/enums/device_platform.dart';
import 'package:motaz_app_flutter/core/database/enums/parent_entity_type.dart';
import 'package:motaz_app_flutter/core/database/enums/sync_status.dart';
import 'package:motaz_app_flutter/features/sync/application/attachment_uploader.dart';

AppDatabase _createInMemoryDatabase() {
  return AppDatabase(NativeDatabase.memory());
}

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late Device device;

  const deviceId = '11111111-1111-4111-8111-111111111111';
  const invoiceId = '22222222-2222-4222-8222-222222222222';
  const stagingId = '33333333-3333-4333-8333-333333333333';
  const metadataId = '44444444-4444-4444-8444-444444444444';

  setUp(() async {
    db = _createInMemoryDatabase();
    tempDir = Directory.systemTemp.createTempSync(
      'fastika-attachment-uploader-test-',
    );

    final now = DateTime(2026, 6, 14, 12);
    await db
        .into(db.devices)
        .insert(
          DevicesCompanion.insert(
            id: deviceId,
            deviceName: 'Test device',
            platform: DevicePlatform.WINDOWS,
            deviceCode: 'T001',
            createdAt: now,
            lastActiveAt: now,
          ),
        );
    device = await (db.select(
      db.devices,
    )..where((table) => table.id.equals(deviceId))).getSingle();
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('AttachmentUploader', () {
    test(
      'uploads pending local attachment and confirms it with deviceId',
      () async {
        final photo = File('${tempDir.path}/invoice-photo.jpg');
        await photo.writeAsBytes([1, 2, 3, 4]);
        final createdAt = DateTime.now().subtract(const Duration(minutes: 1));
        server.AttachmentUploadRequest? capturedApprovalRequest;
        File? capturedUploadFile;
        String? capturedUploadUrl;
        String? capturedUploadPreset;
        String? capturedUploadFileType;
        server.AttachmentConfirmRequest? capturedConfirmRequest;

        await db
            .into(db.localAttachmentStaging)
            .insert(
              LocalAttachmentStagingCompanion.insert(
                id: stagingId,
                parentEntityType: ParentEntityType.SALES_INVOICE,
                parentEntityId: invoiceId,
                localFilePath: photo.path,
                fileType: 'image/jpeg',
                fileSize: const Value(4),
                uploadStatus: const Value('PENDING'),
                createdAt: createdAt,
                updatedAt: createdAt,
              ),
            );

        final uploader = AttachmentUploader(
          db: db,
          serverClient: server.Client('http://server.invalid/'),
          deviceService: DeviceService(db),
          ensureCurrentDevice: () async => device,
          requestUploadApproval: (request) async {
            capturedApprovalRequest = request;
            return server.AttachmentUploadApproval(
              approved: true,
              uploadUrl: 'https://uploads.example.test',
              uploadPreset: 'preset-1',
            );
          },
          upload: (file, uploadUrl, uploadPreset, fileType) async {
            capturedUploadFile = file;
            capturedUploadUrl = uploadUrl;
            capturedUploadPreset = uploadPreset;
            capturedUploadFileType = fileType;
            return (
              publicId: 'fastika/invoice-photo',
              secureUrl: 'https://cdn.example.test/invoice-photo.jpg',
            );
          },
          confirmUpload: (request) async {
            capturedConfirmRequest = request;
            return server.AttachmentConfirmResponse(
              success: true,
              attachmentMetadataId: metadataId,
            );
          },
        );

        await uploader.processPending();

        final staging = await (db.select(
          db.localAttachmentStaging,
        )..where((table) => table.id.equals(stagingId))).getSingle();
        final metadata = await (db.select(
          db.attachmentMetadata,
        )..where((table) => table.id.equals(metadataId))).getSingle();

        expect(capturedApprovalRequest?.parentEntityType, 'SALES_INVOICE');
        expect(capturedApprovalRequest?.parentEntityId, invoiceId);
        expect(capturedApprovalRequest?.fileType, 'image/jpeg');
        expect(capturedApprovalRequest?.fileSize, 4);
        expect(capturedUploadFile?.path, photo.path);
        expect(capturedUploadUrl, 'https://uploads.example.test');
        expect(capturedUploadPreset, 'preset-1');
        expect(capturedUploadFileType, 'image/jpeg');
        expect(capturedConfirmRequest?.deviceId, deviceId);
        expect(capturedConfirmRequest?.publicId, 'fastika/invoice-photo');
        expect(staging.uploadStatus, 'UPLOADED');
        expect(metadata.parentEntityType, ParentEntityType.SALES_INVOICE);
        expect(metadata.parentEntityId, invoiceId);
        expect(metadata.storageReference, 'fastika/invoice-photo');
        expect(
          metadata.secureUrl,
          'https://cdn.example.test/invoice-photo.jpg',
        );
        expect(metadata.deviceId, deviceId);
        expect(metadata.syncStatus, SyncStatus.SYNCED);
      },
    );

    test(
      'marks pending attachment failed when upload approval is rejected',
      () async {
        final photo = File('${tempDir.path}/rejected-photo.jpg');
        await photo.writeAsBytes([1, 2, 3]);
        final createdAt = DateTime.now().subtract(const Duration(minutes: 1));
        var uploadCalled = false;

        await db
            .into(db.localAttachmentStaging)
            .insert(
              LocalAttachmentStagingCompanion.insert(
                id: stagingId,
                parentEntityType: ParentEntityType.RECEIPT,
                parentEntityId: invoiceId,
                localFilePath: photo.path,
                fileType: 'text/plain',
                fileSize: const Value(3),
                uploadStatus: const Value('PENDING'),
                createdAt: createdAt,
                updatedAt: createdAt,
              ),
            );

        final uploader = AttachmentUploader(
          db: db,
          serverClient: server.Client('http://server.invalid/'),
          deviceService: DeviceService(db),
          ensureCurrentDevice: () async => device,
          requestUploadApproval: (_) async => server.AttachmentUploadApproval(
            approved: false,
            rejectionReason: 'File type is not allowed',
          ),
          upload: (_, _, _, _) async {
            uploadCalled = true;
            return (
              publicId: 'should-not-upload',
              secureUrl: 'https://cdn.example.test/should-not-upload.jpg',
            );
          },
          confirmUpload: (_) async => server.AttachmentConfirmResponse(
            success: true,
            attachmentMetadataId: metadataId,
          ),
        );

        await uploader.processPending();

        final staging = await (db.select(
          db.localAttachmentStaging,
        )..where((table) => table.id.equals(stagingId))).getSingle();

        expect(uploadCalled, isFalse);
        expect(staging.uploadStatus, 'FAILED');
      },
    );
  });
}
