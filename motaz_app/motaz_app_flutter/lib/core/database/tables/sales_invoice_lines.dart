import 'package:drift/drift.dart';
import 'sales_invoices.dart';
import 'products.dart';

@TableIndex(name: 'idx_invoice_line_invoice', columns: {#invoiceId})
class SalesInvoiceLines extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();
  TextColumn get invoiceId => text().withLength(min: 36, max: 36).references(SalesInvoices, #id)();
  TextColumn get productId => text().withLength(min: 36, max: 36).references(Products, #id)();
  IntColumn get quantity => integer()();
  IntColumn get unitPrice => integer()();
  IntColumn get lineTotal => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
