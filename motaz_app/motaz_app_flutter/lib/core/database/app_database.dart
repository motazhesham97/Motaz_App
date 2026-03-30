import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
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
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  factory AppDatabase.connect() {
    return AppDatabase(_openConnection());
  }

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
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
    return NativeDatabase.createInBackground(file);
  });
}
