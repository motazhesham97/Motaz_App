import 'package:drift/drift.dart';

import '../enums/sync_status.dart';
import 'devices.dart';
import 'free_samples.dart';
import 'products.dart';

class FreeSampleLines extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();
  TextColumn get sampleId =>
      text().withLength(min: 36, max: 36).references(FreeSamples, #id)();
  TextColumn get productId =>
      text().withLength(min: 36, max: 36).references(Products, #id)();
  IntColumn get quantity => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get deviceId =>
      text().withLength(min: 36, max: 36).references(Devices, #id)();
  IntColumn get rowVersion => integer().withDefault(const Constant(1))();
  IntColumn get syncStatus => intEnum<SyncStatus>()();

  @override
  Set<Column> get primaryKey => {id};
}

Index get idxFreeSampleLineSample => Index(
  'idx_free_sample_line_sample',
  'CREATE INDEX idx_free_sample_line_sample ON free_sample_lines(sample_id)',
);

Index get idxFreeSampleLineProduct => Index(
  'idx_free_sample_line_product',
  'CREATE INDEX idx_free_sample_line_product ON free_sample_lines(product_id)',
);
