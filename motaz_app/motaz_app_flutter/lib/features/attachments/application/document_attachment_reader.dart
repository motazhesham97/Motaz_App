import 'dart:io';
import 'dart:typed_data';

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
  DocumentAttachmentReader(this._db);

  final AppDatabase _db;

  Future<List<Uint8List>> loadImages({
    required ParentEntityType parentEntityType,
    required String parentEntityId,
    int limit = 3,
  }) async {
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
          "AND file_type LIKE 'image/%'",
          variables: [
            Variable<int>(parentEntityType.index),
            Variable<String>(parentEntityId),
            Variable<int>(parentEntityType.index),
            Variable<String>(parentEntityId),
          ],
        )
        .get();

    final images = <Uint8List>[];
    final seen = <String>{};
    for (final row in rows) {
      if (images.length >= limit) break;

      final localPath = row.data['local_path'] as String?;
      if (localPath != null && seen.add(localPath)) {
        final file = File(localPath);
        if (await file.exists()) {
          images.add(await file.readAsBytes());
          continue;
        }
      }

      final remoteUrl = row.data['remote_url'] as String?;
      if (remoteUrl != null && remoteUrl.isNotEmpty && seen.add(remoteUrl)) {
        final bytes = await _fetchRemoteImage(remoteUrl);
        if (bytes != null) {
          images.add(bytes);
        }
      }
    }
    return images;
  }

  Future<Uint8List?> _fetchRemoteImage(String url) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final chunks = <int>[];
      await for (final chunk in response) {
        chunks.addAll(chunk);
      }
      return Uint8List.fromList(chunks);
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}
