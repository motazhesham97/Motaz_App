import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../app_identity.dart';
import '../logging/app_logger.dart';
import 'enums/enums.dart';
import 'tables/devices.dart';
import 'tables/sync_outbox.dart';
import 'tables/sync_cursor.dart';
import 'tables/products.dart';
import 'tables/clients.dart';
import 'tables/sales_invoices.dart';
import 'tables/sales_invoice_lines.dart';
import 'tables/receipts.dart';
import 'tables/receipt_allocations.dart';
import 'tables/expenses.dart';
import 'tables/sales_returns.dart';
import 'tables/sales_return_lines.dart';
import 'tables/attachment_metadata.dart';
import 'tables/local_attachment_staging.dart';
import 'tables/audit_events.dart';
import 'tables/conflict_logs.dart';
import 'tables/monthly_distributions.dart';
import 'tables/party_adjustments.dart';
import 'tables/beneficiaries.dart';
import 'tables/free_samples.dart';
import 'tables/free_sample_lines.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Devices,
    SyncOutbox,
    SyncCursor,
    Products,
    Clients,
    SalesInvoices,
    SalesInvoiceLines,
    Receipts,
    ReceiptAllocations,
    Expenses,
    SalesReturns,
    SalesReturnLines,
    AttachmentMetadata,
    LocalAttachmentStaging,
    AuditEvents,
    ConflictLogs,
    MonthlyDistributions,
    PartyAdjustments,
    Beneficiaries,
    FreeSamples,
    FreeSampleLines,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  factory AppDatabase.connect() {
    return AppDatabase(_openConnection());
  }

  @override
  int get schemaVersion => 12;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        final dbFolder = await getApplicationDocumentsDirectory();
        final dbFile = File(
          p.join(dbFolder.path, AppIdentity.databaseFileName),
        );
        final backupFile = File(
          p.join(dbFolder.path, '${AppIdentity.databaseFileName}.backup'),
        );
        if (dbFile.existsSync()) {
          await dbFile.copy(backupFile.path);
        }
        try {
          if (from < 2) {
            await m.createTable(products);
            await m.createTable(clients);
            await m.createTable(salesInvoices);
            await m.createTable(salesInvoiceLines);
            await m.createTable(receipts);
            await m.createTable(receiptAllocations);
            await m.createTable(expenses);
            await m.createIndex(idxExpenseDate);
            await m.createIndex(idxExpenseCategory);
            await m.createIndex(idxExpenseStatus);
            await m.createTable(salesReturns);
            await m.createTable(salesReturnLines);
            await m.createTable(attachmentMetadata);
            await m.createIndex(idxAttachmentParent);
            await m.createTable(localAttachmentStaging);
            await m.createTable(auditEvents);
            await m.createTable(conflictLogs);
          }
          if (from < 3) {
            await m.addColumn(products, products.unit);
            await m.addColumn(products, products.sku);
            await m.addColumn(clients, clients.email);
            await m.addColumn(clients, clients.address);
          }
          if (from < 4) {
            await m.createTable(monthlyDistributions);
          }
          if (from < 5) {
            await m.createIndex(idxOutboxStatus);
          }
          if (from < 6) {
            await customStatement('''
CREATE TABLE monthly_distributions_new (
  id TEXT NOT NULL CHECK (length(id) >= 36 AND length(id) <= 36),
  year INTEGER NOT NULL,
  month INTEGER NOT NULL,
  net_profit INTEGER NOT NULL,
  owner_share INTEGER NOT NULL,
  partner_share INTEGER NOT NULL,
  margin_share INTEGER NOT NULL,
  status INTEGER NOT NULL DEFAULT 0,
  void_reason TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  device_id TEXT NOT NULL CHECK (length(device_id) >= 36 AND length(device_id) <= 36) REFERENCES devices (id),
  row_version INTEGER NOT NULL DEFAULT 1,
  sync_status INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
''');
            await customStatement('''
INSERT INTO monthly_distributions_new (
  id,
  year,
  month,
  net_profit,
  owner_share,
  partner_share,
  margin_share,
  status,
  void_reason,
  created_at,
  updated_at,
  device_id,
  row_version,
  sync_status
)
SELECT
  id,
  year,
  month,
  net_profit,
  owner_share,
  partner_share,
  margin_share,
  status,
  void_reason,
  created_at,
  updated_at,
  device_id,
  row_version,
  sync_status
FROM monthly_distributions;
''');
            await customStatement('DROP TABLE monthly_distributions');
            await customStatement(
              'ALTER TABLE monthly_distributions_new RENAME TO monthly_distributions',
            );
            await m.createIndex(idxDistributionYearMonth);
            await m.createIndex(idxDistributionStatus);
          }
          if (from < 7) {
            await m.addColumn(devices, devices.nextReceiptSequence);
            await m.addColumn(devices, devices.nextReturnSequence);
            await m.addColumn(receipts, receipts.localRef);
            await m.addColumn(salesReturns, salesReturns.localRef);

            await customStatement('''
UPDATE receipts
SET local_ref = 'REC-' || (
  SELECT device_code FROM devices WHERE devices.id = receipts.device_id
) || '-' || printf('%03d', rowid)
WHERE local_ref IS NULL OR local_ref = '';
''');
            await customStatement('''
UPDATE sales_returns
SET local_ref = 'RET-' || (
  SELECT device_code FROM devices WHERE devices.id = sales_returns.device_id
) || '-' || printf('%03d', rowid)
WHERE local_ref IS NULL OR local_ref = '';
''');
            await customStatement('''
UPDATE devices
SET next_receipt_sequence = COALESCE((
  SELECT COUNT(*) + 1 FROM receipts WHERE receipts.device_id = devices.id
), 1),
next_return_sequence = COALESCE((
  SELECT COUNT(*) + 1 FROM sales_returns WHERE sales_returns.device_id = devices.id
), 1);
''');
            await customStatement(
              'CREATE UNIQUE INDEX IF NOT EXISTS receipts_local_ref_unique '
              'ON receipts(local_ref)',
            );
            await customStatement(
              'CREATE UNIQUE INDEX IF NOT EXISTS sales_returns_local_ref_unique '
              'ON sales_returns(local_ref)',
            );
          }
          if (from >= 3 && from < 8) {
            final columnExists = await customSelect(
              "SELECT COUNT(*) AS count FROM pragma_table_info('products') "
              "WHERE name = 'cost_price'",
            ).getSingle();
            if (columnExists.read<int>('count') > 0) {
              await customStatement(
                'ALTER TABLE products DROP COLUMN cost_price',
              );
            }
          }
          if (from < 9) {
            await m.addColumn(receipts, receipts.officialNo);
            await m.addColumn(salesReturns, salesReturns.officialNo);
          }
          if (from < 10) {
            await m.createTable(partyAdjustments);
            await m.createIndex(idxPartyAdjustmentParty);
            await m.createIndex(idxPartyAdjustmentDate);
            await m.createIndex(idxPartyAdjustmentStatus);
          }
          if (from < 11) {
            await m.addColumn(devices, devices.nextSampleSequence);
            await m.createTable(beneficiaries);
            await m.createIndex(idxBeneficiaryDisplayName);
            await m.createIndex(idxBeneficiarySourceClient);
            await m.createTable(freeSamples);
            await m.createIndex(idxFreeSampleBeneficiary);
            await m.createIndex(idxFreeSampleDate);
            await m.createIndex(idxFreeSampleStatus);
            await m.createTable(freeSampleLines);
            await m.createIndex(idxFreeSampleLineSample);
            await m.createIndex(idxFreeSampleLineProduct);
            await customStatement('''
INSERT OR IGNORE INTO beneficiaries (
  id,
  display_name,
  phone,
  source_client_id,
  is_active,
  created_at,
  updated_at,
  device_id,
  row_version,
  sync_status
)
SELECT
  id,
  display_name,
  phone,
  id,
  is_active,
  created_at,
  updated_at,
  device_id,
  1,
  0
FROM clients;
''');
          }
          if (from < 12) {
            await m.addColumn(clients, clients.creditLimit);
            await m.addColumn(clients, clients.invoiceCheckIntervalDays);
            await m.addColumn(products, products.shelfLifeDays);
            await m.addColumn(
              salesInvoiceLines,
              salesInvoiceLines.productionDate,
            );
          }
          if (backupFile.existsSync()) {
            await backupFile.delete();
          }
        } catch (e) {
          AppLogger.database.severe('Migration from v$from to v$to failed: $e');
          rethrow;
        }
      },
    );
  }
}

Future<void> deleteLocalDatabase() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final dbPath = p.join(dbFolder.path, AppIdentity.databaseFileName);
  final legacyDbPath = p.join(
    dbFolder.path,
    AppIdentity.legacyDatabaseFileName,
  );
  final files = [
    File(dbPath),
    File('$dbPath-shm'),
    File('$dbPath-wal'),
    File('$dbPath-journal'),
    File('$dbPath.backup'),
    File(legacyDbPath),
    File('$legacyDbPath-shm'),
    File('$legacyDbPath-wal'),
    File('$legacyDbPath-journal'),
    File('$legacyDbPath.backup'),
  ];

  for (final file in files) {
    await _deleteFileWithRetry(file);
  }
}

Future<void> _deleteFileWithRetry(File file) async {
  for (var attempt = 0; attempt < 5; attempt++) {
    if (!await file.exists()) {
      return;
    }

    try {
      await file.delete();
      return;
    } on FileSystemException catch (error) {
      if (attempt == 4) {
        AppLogger.database.severe('Failed to delete ${file.path}: $error');
        rethrow;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    await _migrateLegacyDatabaseFile(dbFolder);
    final file = File(p.join(dbFolder.path, AppIdentity.databaseFileName));
    return NativeDatabase.createInBackground(
      file,
      setup: (rawDb) {
        rawDb.execute('PRAGMA foreign_keys = ON');
      },
    );
  });
}

Future<void> _migrateLegacyDatabaseFile(Directory dbFolder) async {
  final currentPath = p.join(dbFolder.path, AppIdentity.databaseFileName);
  final legacyPath = p.join(dbFolder.path, AppIdentity.legacyDatabaseFileName);
  final currentExists = await File(currentPath).exists();
  final legacyExists = await File(legacyPath).exists();
  if (currentExists || !legacyExists) {
    return;
  }

  await File(legacyPath).rename(currentPath);
  for (final suffix in ['-shm', '-wal', '-journal', '.backup']) {
    final legacySidecar = File('$legacyPath$suffix');
    if (await legacySidecar.exists()) {
      await legacySidecar.rename('$currentPath$suffix');
    }
  }
}
