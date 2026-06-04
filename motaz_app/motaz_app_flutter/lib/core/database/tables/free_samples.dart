import 'package:drift/drift.dart';

import '../enums/record_status.dart';
import '../enums/sync_status.dart';
import 'beneficiaries.dart';
import 'devices.dart';

class FreeSamples extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();
  TextColumn get localRef => text().withLength(min: 1, max: 255).unique()();
  TextColumn get officialNo => text().nullable().unique()();
  TextColumn get beneficiaryId =>
      text().withLength(min: 36, max: 36).references(Beneficiaries, #id)();
  DateTimeColumn get sampleDate => dateTime()();
  TextColumn get note => text().nullable()();
  IntColumn get status => intEnum<RecordStatus>()();
  TextColumn get voidReason => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get deviceId =>
      text().withLength(min: 36, max: 36).references(Devices, #id)();
  IntColumn get rowVersion => integer().withDefault(const Constant(1))();
  IntColumn get syncStatus => intEnum<SyncStatus>()();

  @override
  Set<Column> get primaryKey => {id};
}

Index get idxFreeSampleBeneficiary => Index(
  'idx_free_sample_beneficiary',
  'CREATE INDEX idx_free_sample_beneficiary ON free_samples(beneficiary_id)',
);

Index get idxFreeSampleDate => Index(
  'idx_free_sample_date',
  'CREATE INDEX idx_free_sample_date ON free_samples(sample_date)',
);

Index get idxFreeSampleStatus => Index(
  'idx_free_sample_status',
  'CREATE INDEX idx_free_sample_status ON free_samples(status)',
);
