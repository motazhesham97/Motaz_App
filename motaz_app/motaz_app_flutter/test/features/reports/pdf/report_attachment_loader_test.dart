import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/core/database/app_database.dart';
import 'package:motaz_app_flutter/core/database/enums/enums.dart';
import 'package:motaz_app_flutter/features/attachments/application/document_attachment_reader.dart';
import 'package:motaz_app_flutter/features/reports/pdf/report_attachment_loader.dart';

class _StalledClient implements HttpClient {
  bool closed = false;
  @override
  Duration? connectionTimeout;
  @override
  Future<HttpClientRequest> getUrl(Uri url) =>
      Completer<HttpClientRequest>().future;
  @override
  void close({bool force = false}) => closed = force;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MemoryReader extends DocumentAttachmentReader {
  _MemoryReader(super.db, this.bytes);
  final Uint8List bytes;
  @override
  Future<List<Uint8List>> loadImages({
    required ParentEntityType parentEntityType,
    required String parentEntityId,
    int limit = 3,
    int maxBytes = 8 * 1024 * 1024,
    Duration timeout = const Duration(seconds: 8),
    void Function()? onSkipped,
  }) async => [bytes];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'stalled attachment HTTP is aborted by a deadline without a real network',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      const id = '00000000-0000-4000-8000-000000000001';
      final now = DateTime(2026);
      await db
          .into(db.devices)
          .insert(
            DevicesCompanion.insert(
              id: id,
              deviceName: 'Test',
              platform: DevicePlatform.ANDROID,
              deviceCode: 'test',
              createdAt: now,
              lastActiveAt: now,
            ),
          );
      await db
          .into(db.attachmentMetadata)
          .insert(
            AttachmentMetadataCompanion.insert(
              id: id,
              parentEntityType: ParentEntityType.RECEIPT,
              parentEntityId: id,
              storageReference: 'test',
              secureUrl: const Value('https://example.invalid/image'),
              fileType: 'image/png',
              createdAt: now,
              updatedAt: now,
              deviceId: id,
            ),
          );
      final client = _StalledClient();
      var skipped = false;
      final reader = DocumentAttachmentReader(
        db,
        httpClientFactory: () => client,
      );

      final images = await reader.loadImages(
        parentEntityType: ParentEntityType.RECEIPT,
        parentEntityId: id,
        timeout: const Duration(milliseconds: 200),
        onSkipped: () => skipped = true,
      );

      expect(images, isEmpty);
      expect(client.closed, isTrue);
      expect(skipped, isTrue);
    },
  );

  test(
    'report images are downsampled and a document image budget is enforced',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawRect(
        const ui.Rect.fromLTWH(0, 0, 1024, 768),
        ui.Paint()..color = const ui.Color(0xff228855),
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(1024, 768);
      final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      image.dispose();
      picture.dispose();
      final loader = ReportAttachmentLoader(
        _MemoryReader(db, png.buffer.asUint8List()),
        maxImages: 1,
      );

      final images = await loader.loadImages(
        parentEntityType: ParentEntityType.RECEIPT,
        parentEntityId: 'first',
        maxDimension: 256,
      );
      final buffer = await ui.ImmutableBuffer.fromUint8List(images.single);
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      expect(descriptor.width, 256);
      expect(descriptor.height, 192);
      descriptor.dispose();
      buffer.dispose();
      expect(
        await loader.loadImages(
          parentEntityType: ParentEntityType.RECEIPT,
          parentEntityId: 'second',
        ),
        isEmpty,
      );
      expect(loader.warning, isNotNull);
    },
  );
}
