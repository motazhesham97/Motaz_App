import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../../../core/database/enums/parent_entity_type.dart';
import '../../attachments/application/document_attachment_reader.dart';

class ReportAttachmentLoader {
  ReportAttachmentLoader(
    this.reader, {
    this.maxImages = 60,
    this.maxBytes = 12 * 1024 * 1024,
    this.budget = const Duration(seconds: 20),
  });

  final DocumentAttachmentReader reader;
  final int maxImages;
  final int maxBytes;
  final Duration budget;
  final _elapsed = Stopwatch()..start();
  int _count = 0;
  int _bytes = 0;
  int _lookups = 0;
  bool _incomplete = false;

  String? get warning => _incomplete
      ? 'قد لا يتضمن التقرير كل الصور بسبب حدود الحجم أو تعذر تحميلها. جميع المبالغ مدرجة.'
      : null;

  Future<List<Uint8List>> loadImages({
    required ParentEntityType parentEntityType,
    required String parentEntityId,
    int limit = 1,
    int maxDimension = 800,
  }) async {
    final remaining = budget - _elapsed.elapsed;
    if (remaining <= Duration.zero ||
        _count >= maxImages ||
        _bytes >= maxBytes ||
        _lookups++ >= 120) {
      _incomplete = true;
      return [];
    }
    final result = <Uint8List>[];
    try {
      final images = await reader.loadImages(
        parentEntityType: parentEntityType,
        parentEntityId: parentEntityId,
        limit: math.min(limit, maxImages - _count),
        maxBytes: 8 * 1024 * 1024,
        timeout: remaining < const Duration(seconds: 3)
            ? remaining
            : const Duration(seconds: 3),
        onSkipped: () => _incomplete = true,
      );
      for (final bytes in images) {
        final time = budget - _elapsed.elapsed;
        if (time <= Duration.zero) {
          throw TimeoutException('Attachment budget exceeded');
        }
        try {
          final thumbnail = await _thumbnail(bytes, maxDimension).timeout(time);
          if (_bytes + thumbnail.length > maxBytes) {
            _incomplete = true;
            break;
          }
          result.add(thumbnail);
          _bytes += thumbnail.length;
          _count++;
        } catch (_) {
          _incomplete = true;
        }
      }
    } catch (_) {
      _incomplete = true;
    }
    return result;
  }

  static Future<Uint8List> _thumbnail(Uint8List bytes, int edge) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    ui.Image? image;
    try {
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      if (descriptor.width * descriptor.height > 40 * 1000 * 1000) {
        throw StateError('Attachment exceeds pixel budget');
      }
      final scale = math.min(
        1.0,
        edge / math.max(descriptor.width, descriptor.height),
      );
      codec = await descriptor.instantiateCodec(
        targetWidth: math.max(1, (descriptor.width * scale).round()),
        targetHeight: math.max(1, (descriptor.height * scale).round()),
      );
      image = (await codec.getNextFrame()).image;
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) {
        throw StateError('Could not encode thumbnail');
      }
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } finally {
      image?.dispose();
      codec?.dispose();
      descriptor?.dispose();
      buffer.dispose();
    }
  }
}
