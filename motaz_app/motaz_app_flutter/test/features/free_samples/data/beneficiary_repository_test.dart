import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/core/database/app_database.dart';
import 'package:motaz_app_flutter/core/database/enums/enums.dart';
import 'package:motaz_app_flutter/features/free_samples/data/beneficiary_repository.dart';

const _deviceId = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
final _now = DateTime(2026, 10, 1, 10);

void main() {
  late AppDatabase db;
  late BeneficiaryRepository repository;

  setUp(() async {
    db = AppDatabase(
      NativeDatabase.memory(
        setup: (rawDb) => rawDb.execute('PRAGMA foreign_keys = ON'),
      ),
    );
    repository = BeneficiaryRepository(db);
    await db
        .into(db.devices)
        .insert(
          DevicesCompanion.insert(
            id: _deviceId,
            deviceName: 'Sample test device',
            platform: DevicePlatform.ANDROID,
            deviceCode: 't001',
            createdAt: _now,
            lastActiveAt: _now,
          ),
        );
  });

  tearDown(() => db.close());

  test(
    'searches beneficiary names by multiple word prefixes and excludes inactive records',
    () async {
      final saved = await repository.createAndReturn(
        displayName: 'مركز ضمران سنتر',
        deviceId: _deviceId,
      );
      final inactive = await repository.createAndReturn(
        displayName: 'مركز ضمران قديم',
        deviceId: _deviceId,
      );
      await db
          .update(db.beneficiaries)
          .replace(
            inactive.copyWith(isActive: false),
          );

      for (final query in ['مركز ض', '  مركز   ضمران سنتر  ', 'سنتر ض']) {
        final matches = await repository.search(query);
        expect(matches.map((row) => row.id), [saved.id], reason: query);
      }
      expect(await repository.search('غير موجود'), isEmpty);
      expect(await repository.search('   '), isEmpty);
    },
  );

  test(
    'returns every matching beneficiary without truncating the result list',
    () async {
      for (var index = 1; index <= 14; index++) {
        await repository.createAndReturn(
          displayName: 'مستفيد عينات ${index.toString().padLeft(2, '0')}',
          deviceId: _deviceId,
        );
      }

      final matches = await repository.search('مستفيد عين');

      expect(matches, hasLength(14));
      expect(matches.first.displayName, 'مستفيد عينات 01');
      expect(matches.last.displayName, 'مستفيد عينات 14');
    },
  );

  test(
    'reuses an existing beneficiary when only name spacing differs',
    () async {
      final original = await repository.createAndReturn(
        displayName: 'مركز   ضمران سنتر',
        deviceId: _deviceId,
      );

      final reused = await repository.createAndReturn(
        displayName: '  مركز ضمران   سنتر  ',
        deviceId: _deviceId,
      );

      expect(reused.id, original.id);
      expect((await repository.findByName('مركز ضمران سنتر'))?.id, original.id);
      expect(await db.select(db.beneficiaries).get(), hasLength(1));
      final outbox = await db.select(db.syncOutbox).get();
      expect(outbox, hasLength(1));
      expect(outbox.single.entityId, original.id);
      expect(outbox.single.status, SyncOutboxStatus.PENDING);
    },
  );
}
