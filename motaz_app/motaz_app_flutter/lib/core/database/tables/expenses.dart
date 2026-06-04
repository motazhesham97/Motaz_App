import 'package:drift/drift.dart';
import '../enums/sync_status.dart';
import '../enums/record_status.dart';
import '../enums/expense_category.dart';
import 'devices.dart';

@TableIndex(name: 'idx_expense_date', columns: {#expenseDate})
@TableIndex(name: 'idx_expense_category', columns: {#category})
@TableIndex(name: 'idx_expense_status', columns: {#status})
class Expenses extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();
  IntColumn get category => intEnum<ExpenseCategory>()();
  IntColumn get amount => integer()();
  DateTimeColumn get expenseDate => dateTime()();
  TextColumn get note => text().nullable()();
  IntColumn get status =>
      intEnum<RecordStatus>().withDefault(const Constant(0))();
  TextColumn get voidReason => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get deviceId =>
      text().withLength(min: 36, max: 36).references(Devices, #id)();
  IntColumn get rowVersion => integer().withDefault(const Constant(1))();
  IntColumn get syncStatus =>
      intEnum<SyncStatus>().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
