import 'dart:async';
import 'dart:io';
import 'dart:typed_data' show BytesBuilder;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/enums/parent_entity_type.dart';

final documentAttachmentReaderProvider = Provider<DocumentAttachmentReader>((
  ref,
) {
  return DocumentAttachmentReader(ref.watch(appDatabaseProvider));
});

class DocumentAttachmentReader {
  DocumentAttachmentReader(this._db, {HttpClient Function()? httpClientFactory})
    : _httpClientFactory = httpClientFactory ?? HttpClient.new;

  final AppDatabase _db;
  final HttpClient Function() _httpClientFactory;

  Future<List<Uint8List>> loadImages({
    required ParentEntityType parentEntityType,
    required String parentEntityId,
    int limit = 3,
    int maxBytes = 8 * 1024 * 1024,
    Duration timeout = const Duration(seconds: 8),
    void Function()? onSkipped,
  }) async {
    if (limit <= 0) {
      return [];
    }
    final elapsed = Stopwatch()..start();
    final rows = await _db
        .customSelect(
          'SELECT local_file_path AS local_path, NULL AS remote_url '
          'FROM local_attachment_staging '
          'WHERE parent_entity_type = ? AND parent_entity_id = ? '
          "AND upload_status IN ('PENDING', 'IN_PROGRESS', 'UPLOADED') "
          'UNION ALL '
          'SELECT NULL AS local_path, secure_url AS remote_url '
          'FROM attachment_metadata '
          'WHERE parent_entity_type = ? AND parent_entity_id = ? '
          "AND file_type LIKE 'image/%' LIMIT ?",
          variables: [
            Variable<int>(parentEntityType.index),
            Variable<String>(parentEntityId),
            Variable<int>(parentEntityType.index),
            Variable<String>(parentEntityId),
            Variable<int>(limit * 3),
          ],
        )
        .get()
        .timeout(timeout);

    final images = <Uint8List>[];
    final seen = <String>{};
    for (final row in rows) {
      if (images.length >= limit) {
        break;
      }
      final remaining = timeout - elapsed.elapsed;
      if (remaining <= Duration.zero) {
        onSkipped?.call();
        break;
      }

      final localPath = row.data['local_path'] as String?;
      if (localPath != null && seen.add(localPath)) {
        final file = File(localPath);
        try {
          final bytes = await _readLocal(file, maxBytes).timeout(remaining);
          if (bytes != null) {
            images.add(bytes);
            continue;
          }
        } catch (_) {
          onSkipped?.call();
        }
        onSkipped?.call();
      }

      final remoteUrl = row.data['remote_url'] as String?;
      if (remoteUrl != null && remoteUrl.isNotEmpty && seen.add(remoteUrl)) {
        final budget = timeout - elapsed.elapsed;
        final bytes = budget <= Duration.zero
            ? null
            : await _fetchRemoteImage(remoteUrl, maxBytes, budget);
        if (bytes != null) {
          images.add(bytes);
        } else {
          onSkipped?.call();
        }
      }
    }
    return images;
  }

  Future<Uint8List?> _readLocal(File file, int maxBytes) async {
    if (!await file.exists() || await file.length() > maxBytes) {
      return null;
    }
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in file.openRead(0, maxBytes + 1)) {
      if (bytes.length + chunk.length > maxBytes) {
        return null;
      }
      bytes.add(chunk);
    }
    return bytes.takeBytes();
  }

  Future<Uint8List?> _fetchRemoteImage(
    String url,
    int maxBytes,
    Duration timeout,
  ) async {
    final client = _httpClientFactory()..connectionTimeout = timeout;
    try {
      return await (() async {
        final request = await client.getUrl(Uri.parse(url));
        final response = await request.close();
        if (response.statusCode < 200 ||
            response.statusCode >= 300 ||
            response.contentLength > maxBytes) {
          return null;
        }
        final chunks = BytesBuilder(copy: false);
        await for (final chunk in response) {
          if (chunks.length + chunk.length > maxBytes) {
            return null;
          }
          chunks.add(chunk);
        }
        return chunks.takeBytes();
      })().timeout(timeout);
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}
