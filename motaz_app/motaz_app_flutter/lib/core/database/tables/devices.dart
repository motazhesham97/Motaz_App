import 'package:drift/drift.dart';
import '../enums/device_platform.dart';

class Devices extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();
  TextColumn get deviceName => text().withLength(min: 1, max: 255)();
  IntColumn get platform => intEnum<DevicePlatform>()();
  TextColumn get deviceCode => text().withLength(min: 4, max: 4).unique()();
  IntColumn get nextInvoiceSequence =>
      integer().withDefault(const Constant(1))();
  IntColumn get nextReceiptSequence =>
      integer().withDefault(const Constant(1))();
  IntColumn get nextReturnSequence =>
      integer().withDefault(const Constant(1))();
  IntColumn get nextSampleSequence =>
      integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastActiveAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
