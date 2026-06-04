import 'package:drift/drift.dart';
import 'package:motaz_app_client/motaz_app_client.dart' as server;

import '../../../core/database/app_database.dart' hide Client;
import '../../../core/logging/app_logger.dart';

class ServerDatabaseBindingService {
  ServerDatabaseBindingService({
    required AppDatabase db,
    required server.Client serverClient,
  }) : _db = db,
       _serverClient = serverClient;

  final AppDatabase _db;
  final server.Client _serverClient;

  static const _metadataTable = 'local_app_metadata';
  static const _fingerprintKey = 'server_fingerprint';
  static const serverFingerprintUnboundLocalDataCode =
      'SERVER_FINGERPRINT_UNBOUND_LOCAL_DATA';
  static const serverFingerprintChangedCode = 'SERVER_FINGERPRINT_CHANGED';

  static bool isServerFingerprintChangedMessage(String? message) {
    return (message?.startsWith(serverFingerprintChangedCode) ?? false) ||
        (message?.startsWith(serverFingerprintUnboundLocalDataCode) ?? false);
  }

  Future<ServerDatabaseBindingResult> validate() async {
    await _ensureMetadataTable();
    final remoteFingerprint = await _serverClient.health
        .serverFingerprint()
        .timeout(const Duration(seconds: 20));
    final localFingerprint = await _readMetadata(_fingerprintKey);

    if (localFingerprint == null) {
      if (await _hasLocalBusinessData()) {
        final message =
            'تم إيقاف المزامنة لأن قاعدة البيانات المحلية فيها بيانات، '
            'لكنها غير مربوطة ببصمة سيرفر محفوظة. صفّر القاعدة المحلية إذا '
            'كان فرع نيون هو المصدر الصحيح، أو أضف إجراء ربط صريح قبل المزامنة.';
        final codedMessage = '$serverFingerprintUnboundLocalDataCode: $message';
        AppLogger.sync.warning(codedMessage);
        return ServerDatabaseBindingResult.blocked(codedMessage);
      }

      await _writeMetadata(_fingerprintKey, remoteFingerprint);
      AppLogger.sync.info('Bound local database to server fingerprint.');
      return const ServerDatabaseBindingResult.allowed();
    }

    if (localFingerprint != remoteFingerprint) {
      final message =
          'تم إيقاف المزامنة لأن بصمة قاعدة السيرفر تغيرت. هذا يعني غالبا '
          'أنك غيرت فرع نيون أو قاعدة البيانات. صفّر المحلي للسحب من الفرع '
          'الجديد، أو نفذ دمج/ترحيل مقصود قبل تشغيل المزامنة.';
      final codedMessage = '$serverFingerprintChangedCode: $message';
      AppLogger.sync.warning(codedMessage);
      return ServerDatabaseBindingResult.blocked(codedMessage);
    }

    return const ServerDatabaseBindingResult.allowed();
  }

  Future<void> resetLocalDataAndBindToCurrentServer() async {
    await _ensureMetadataTable();
    final remoteFingerprint = await _serverClient.health
        .serverFingerprint()
        .timeout(const Duration(seconds: 20));

    await _db.transaction(() async {
      for (final tableName in _resetDeleteOrder) {
        await _db.customStatement('DELETE FROM "$tableName"');
      }
      await _db.customStatement('DELETE FROM $_metadataTable');
      await _writeMetadata(_fingerprintKey, remoteFingerprint);
    });

    _notifyResetTables();
    AppLogger.sync.info('Local database was reset for current server.');
  }

  Future<void> _ensureMetadataTable() async {
    await _db.customStatement('''
CREATE TABLE IF NOT EXISTS $_metadataTable (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at INTEGER NOT NULL
);
''');
  }

  Future<String?> _readMetadata(String key) async {
    final row = await _db
        .customSelect(
          'SELECT value FROM $_metadataTable WHERE key = ? LIMIT 1',
          variables: [Variable.withString(key)],
        )
        .getSingleOrNull();
    return row?.read<String>('value');
  }

  Future<void> _writeMetadata(String key, String value) async {
    await _db.customStatement(
      'INSERT INTO $_metadataTable (key, value, updated_at) '
      'VALUES (?, ?, ?) '
      'ON CONFLICT(key) DO UPDATE SET '
      'value = excluded.value, updated_at = excluded.updated_at',
      [
        key,
        value,
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ],
    );
  }

  Future<bool> _hasLocalBusinessData() async {
    for (final tableName in _businessTables) {
      final row = await _db
          .customSelect(
            'SELECT EXISTS(SELECT 1 FROM "$tableName" LIMIT 1) AS has_rows',
          )
          .getSingle();
      final hasRows = row.read<int>('has_rows') == 1;
      if (hasRows) return true;
    }
    return false;
  }

  void _notifyResetTables() {
    _db.notifyUpdates({
      for (final tableName in _resetNotifyTables)
        TableUpdate(tableName, kind: UpdateKind.delete),
    });
  }

  static const _businessTables = [
    'products',
    'clients',
    'sales_invoices',
    'sales_invoice_lines',
    'receipts',
    'receipt_allocations',
    'expenses',
    'sales_returns',
    'sales_return_lines',
    'attachment_metadata',
    'monthly_distributions',
    'party_adjustments',
    'beneficiaries',
    'free_samples',
    'free_sample_lines',
  ];

  static const _resetDeleteOrder = [
    'local_attachment_staging',
    'attachment_metadata',
    'sales_return_lines',
    'sales_returns',
    'receipt_allocations',
    'receipts',
    'free_sample_lines',
    'free_samples',
    'sales_invoice_lines',
    'sales_invoices',
    'party_adjustments',
    'monthly_distributions',
    'expenses',
    'beneficiaries',
    'clients',
    'products',
    'audit_events',
    'conflict_logs',
    'sync_outbox',
    'sync_cursor',
    'devices',
  ];

  static const _resetNotifyTables = [
    ..._resetDeleteOrder,
  ];
}

class ServerDatabaseBindingResult {
  const ServerDatabaseBindingResult._({
    required this.allowed,
    this.message,
  });

  const ServerDatabaseBindingResult.allowed() : this._(allowed: true);

  const ServerDatabaseBindingResult.blocked(String message)
    : this._(allowed: false, message: message);

  final bool allowed;
  final String? message;
}
