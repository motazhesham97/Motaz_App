import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
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

part 'app_database.g.dart';

@DriftDatabase(tables: [
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
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  factory AppDatabase.connect() {
    return AppDatabase(_openConnection());
  }

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        final dbFolder = await getApplicationDocumentsDirectory();
        final dbFile = File(p.join(dbFolder.path, 'motaz_app.db'));
        final backupFile = File(p.join(dbFolder.path, 'motaz_app.db.backup'));
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
            await m.addColumn(products, products.costPrice);
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
  final file = File(p.join(dbFolder.path, 'motaz_app.db'));
  if (await file.exists()) {
    await file.delete();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'motaz_app.db'));
    return NativeDatabase.createInBackground(file, setup: (rawDb) {
      rawDb.execute('PRAGMA foreign_keys = ON');
    });
  });
}
