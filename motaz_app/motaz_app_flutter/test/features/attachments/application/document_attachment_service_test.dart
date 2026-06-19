import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/core/database/app_database.dart';
import 'package:motaz_app_flutter/core/database/enums/parent_entity_type.dart';
import 'package:motaz_app_flutter/features/attachments/application/document_attachment_service.dart';

AppDatabase _createInMemoryDatabase() {
  return AppDatabase(NativeDatabase.memory());
}

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late DocumentAttachmentService service;
  const invoiceId = '11111111-1111-4111-8111-111111111111';
  const receiptId = '22222222-2222-4222-8222-222222222222';

  setUp(() {
    db = _createInMemoryDatabase();
    tempDir = Directory.systemTemp.createTempSync('fastika-attachments-test-');
    service = DocumentAttachmentService(db);
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('DocumentAttachmentService local staging', () {
    test('stages existing photo and loads latest local photo path', () async {
      final photo = File('${tempDir.path}/invoice-photo.jpg');
      await photo.writeAsBytes([1, 2, 3, 4]);

      await service.stagePhoto(
        parentEntityType: ParentEntityType.SALES_INVOICE,
        parentEntityId: invoiceId,
        localFilePath: photo.path,
      );

      final rows = await db.select(db.localAttachmentStaging).get();
      final loadedPath = await service.loadLatestLocalPhotoPath(
        parentEntityType: ParentEntityType.SALES_INVOICE,
        parentEntityId: invoiceId,
      );

      expect(rows, hasLength(1));
      expect(rows.single.parentEntityType, ParentEntityType.SALES_INVOICE);
      expect(rows.single.parentEntityId, invoiceId);
      expect(rows.single.localFilePath, photo.path);
      expect(rows.single.fileType, 'image/jpeg');
      expect(rows.single.fileSize, 4);
      expect(rows.single.uploadStatus, 'PENDING');
      expect(loadedPath, photo.path);
    });

    test(
      'loadLatestLocalPhotoPath skips missing newer file and returns existing staged file',
      () async {
        final existingPhoto = File('${tempDir.path}/existing-photo.jpg');
        final missingPhoto = File('${tempDir.path}/missing-photo.jpg');
        await existingPhoto.writeAsBytes([9, 8, 7]);
        final now = DateTime(2026, 6, 14, 12);

        await db
            .into(db.localAttachmentStaging)
            .insert(
              LocalAttachmentStagingCompanion.insert(
                id: '33333333-3333-4333-8333-333333333333',
                parentEntityType: ParentEntityType.RECEIPT,
                parentEntityId: receiptId,
                localFilePath: existingPhoto.path,
                fileType: 'image/jpeg',
                fileSize: const Value(3),
                uploadStatus: const Value('UPLOADED'),
                createdAt: now,
                updatedAt: now,
              ),
            );
        await db
            .into(db.localAttachmentStaging)
            .insert(
              LocalAttachmentStagingCompanion.insert(
                id: '44444444-4444-4444-8444-444444444444',
                parentEntityType: ParentEntityType.RECEIPT,
                parentEntityId: receiptId,
                localFilePath: missingPhoto.path,
                fileType: 'image/jpeg',
                fileSize: const Value(5),
                uploadStatus: const Value('PENDING'),
                createdAt: now.add(const Duration(minutes: 1)),
                updatedAt: now.add(const Duration(minutes: 1)),
              ),
            );

        final loadedPath = await service.loadLatestLocalPhotoPath(
          parentEntityType: ParentEntityType.RECEIPT,
          parentEntityId: receiptId,
        );

        expect(loadedPath, existingPhoto.path);
      },
    );
  });
}
