import 'package:drift/drift.dart';

import '../enums/sync_status.dart';
import 'clients.dart';
import 'devices.dart';

class Beneficiaries extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();
  TextColumn get displayName => text().withLength(min: 1, max: 255)();
  TextColumn get phone => text().nullable()();
  TextColumn get sourceClientId =>
      text().withLength(min: 36, max: 36).nullable().references(Clients, #id)();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get deviceId =>
      text().withLength(min: 36, max: 36).references(Devices, #id)();
  IntColumn get rowVersion => integer().withDefault(const Constant(1))();
  IntColumn get syncStatus => intEnum<SyncStatus>()();

  @override
  Set<Column> get primaryKey => {id};
}

Index get idxBeneficiaryDisplayName => Index(
  'idx_beneficiary_display_name',
  'CREATE INDEX idx_beneficiary_display_name ON beneficiaries(display_name)',
);

Index get idxBeneficiarySourceClient => Index(
  'idx_beneficiary_source_client',
  'CREATE INDEX idx_beneficiary_source_client ON beneficiaries(source_client_id)',
);
