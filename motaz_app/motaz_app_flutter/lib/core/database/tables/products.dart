import 'package:drift/drift.dart';
import '../enums/sync_status.dart';
import 'devices.dart';

class Products extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get description => text().nullable()();
  IntColumn get defaultSalePrice => integer()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get deviceId => text().withLength(min: 36, max: 36).references(Devices, #id)();
  IntColumn get rowVersion => integer().withDefault(const Constant(1))();
  IntColumn get syncStatus => intEnum<SyncStatus>().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {name}
  ];
}
