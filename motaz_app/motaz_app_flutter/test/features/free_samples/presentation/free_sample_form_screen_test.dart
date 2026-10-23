import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/core/connectivity/connectivity_provider.dart';
import 'package:motaz_app_flutter/core/database/app_database.dart';
import 'package:motaz_app_flutter/core/database/database_provider.dart';
import 'package:motaz_app_flutter/core/database/device_service.dart';
import 'package:motaz_app_flutter/core/database/enums/enums.dart';
import 'package:motaz_app_flutter/features/free_samples/data/beneficiary_repository.dart';
import 'package:motaz_app_flutter/features/free_samples/presentation/free_sample_form_screen.dart';
import 'package:motaz_app_flutter/features/sync/application/sync_providers.dart';
import 'package:motaz_app_flutter/features/sync/domain/sync_state.dart';

const _deviceId = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
const _productNames = [
  'شوكولاتة دبي كبير',
  'شوكولاتة دبي صغير',
  'شوكولاتة دبي بيضاء',
  'شوكولاتة دبي داكنة',
  'شوكولاتة دبي بندق',
  'شوكولاتة دبي فستق',
  'شوكولاتة دبي كراميل',
  'شوكولاتة دبي لوز',
  'شوكولاتة دبي قهوة',
  'شوكولاتة دبي هدية',
];
final _now = DateTime(2026, 10, 1, 10);

void main() {
  late AppDatabase db;
  late Device device;

  setUp(() async {
    db = AppDatabase(
      NativeDatabase.memory(
        setup: (rawDb) => rawDb.execute('PRAGMA foreign_keys = ON'),
      ),
    );
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
    device = await db.select(db.devices).getSingle();
    await db.batch((batch) {
      batch.insertAll(db.products, [
        for (final (index, name) in _productNames.indexed)
          ProductsCompanion.insert(
            id: '00000000-0000-4000-8000-${(index + 1).toString().padLeft(12, '0')}',
            name: name,
            defaultSalePrice: 150000,
            unit: const Value('حبة'),
            createdAt: _now.add(Duration(seconds: index)),
            updatedAt: _now,
            deviceId: _deviceId,
          ),
      ]);
    });
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpForm(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          deviceServiceProvider.overrideWithValue(
            _FixedDeviceService(db, device),
          ),
          syncStateProvider.overrideWith(
            (ref) => Stream.value(const SyncState(status: SyncPhase.idle)),
          ),
          pendingCountProvider.overrideWith((ref) => Stream.value(0)),
          failedOutboxCountProvider.overrideWith((ref) => Stream.value(0)),
          unresolvedConflictCountProvider.overrideWith(
            (ref) => Stream.value(0),
          ),
          connectivityProvider.overrideWith(
            (ref) => Stream.value(ConnectivityStatus.offline),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          supportedLocales: [Locale('ar')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: FreeSampleFormScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> unmountForm(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }

  testWidgets('finds a product while typing its second word and full name', (
    tester,
  ) async {
    await pumpForm(tester);
    final search = find.widgetWithText(TextField, 'ادخل اسم المنتج');

    for (final query in ['شوكولاتة د', 'شوكولاتة دبي كبير', 'دبي كبير']) {
      await tester.enterText(search, query);
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(ListTile, _productNames.first),
        findsOneWidget,
      );
      expect(find.text('أضف المنتج'), findsNothing);
    }
    expect(tester.takeException(), isNull);
    await unmountForm(tester);
  });

  testWidgets('shows all ten matching products and selects the last result', (
    tester,
  ) async {
    await pumpForm(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'ادخل اسم المنتج'),
      'شوكولاتة',
    );
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsNWidgets(10));
    final result = find.widgetWithText(ListTile, _productNames.first);
    await tester.ensureVisible(result);
    await tester.pumpAndSettle();
    await tester.tap(result);
    await tester.pumpAndSettle();

    expect(find.text(_productNames.first), findsOneWidget);
    expect(find.text('لم تتم إضافة منتجات بعد'), findsNothing);
    expect(
      tester
          .widget<TextField>(find.widgetWithText(TextField, 'ادخل اسم المنتج'))
          .controller!
          .text,
      isEmpty,
    );
    expect(find.byType(ListTile), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await unmountForm(tester);
  });

  testWidgets(
    'finds a saved non-client beneficiary and enables exact-name saving',
    (
      tester,
    ) async {
      final beneficiary = await BeneficiaryRepository(db).createAndReturn(
        displayName: 'مركز ضمران سنتر',
        deviceId: _deviceId,
      );
      expect(beneficiary.sourceClientId, isNull);
      await pumpForm(tester);
      await tester.enterText(
        find.widgetWithText(TextField, 'ادخل اسم المنتج'),
        _productNames.first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, _productNames.first));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.widgetWithText(FilledButton, 'حفظ'));
        await BeneficiaryRepository(db).watchAll().first;
      });
      await tester.pumpAndSettle();

      final input = find.widgetWithText(TextField, 'اسم المستفيد');
      final save = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(FilledButton),
      );
      await tester.enterText(input, 'مركز ض');
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(ListTile, beneficiary.displayName),
        findsOneWidget,
      );
      expect(tester.widget<FilledButton>(save).onPressed, isNull);

      await tester.enterText(input, '  مركز   ضمران سنتر  ');
      await tester.pumpAndSettle();
      expect(find.text('أضف المستفيد'), findsNothing);
      expect(tester.widget<FilledButton>(save).onPressed, isNotNull);

      await tester.enterText(input, 'اسم آخر');
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
      expect(tester.takeException(), isNull);
      await unmountForm(tester);
    },
  );

  testWidgets(
    'creates and reuses a beneficiary across two offline sample saves',
    (
      tester,
    ) async {
      const name = 'جمعية أصدقاء الشوكولاتة';
      await pumpForm(tester);

      for (var index = 0; index < 2; index++) {
        await tester.enterText(
          find.widgetWithText(TextField, 'ادخل اسم المنتج'),
          _productNames.first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ListTile, _productNames.first));
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          await tester.tap(find.widgetWithText(FilledButton, 'حفظ'));
          await BeneficiaryRepository(db).watchAll().first;
        });
        await tester.pumpAndSettle();

        final input = find.widgetWithText(TextField, 'اسم المستفيد');
        await tester.enterText(input, index == 0 ? name : 'جمعية أص');
        await tester.pumpAndSettle();
        if (index == 0) {
          await tester.runAsync(() async {
            await tester.tap(find.text('أضف المستفيد'));
            await BeneficiaryRepository(db).watchAll().firstWhere(
              (rows) => rows.any((row) => row.displayName == name),
            );
          });
          await tester.pumpAndSettle();
          await tester.enterText(input, '');
          await tester.pumpAndSettle();
          await tester.enterText(input, 'جمعية أص');
          await tester.pumpAndSettle();
        }
        final suggestion = find.widgetWithText(ListTile, name);
        expect(suggestion, findsOneWidget);
        await tester.tap(suggestion);
        await tester.pumpAndSettle();
        expect(find.widgetWithText(ListTile, name), findsNothing);
        expect(find.text('أضف المستفيد'), findsNothing);
        final save = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(FilledButton),
        );
        expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
        await tester.runAsync(() async {
          await tester.tap(save);
          await tester.pumpAndSettle();
          await db
              .select(db.freeSamples)
              .watch()
              .firstWhere(
                (rows) => rows.length == index + 1,
              );
        });
        await tester.pumpAndSettle();
        expect(find.text('تم حفظ العينة المجانية بنجاح'), findsOneWidget);
        expect(find.text('لم تتم إضافة منتجات بعد'), findsOneWidget);
        await tester.drag(find.byType(SnackBar), const Offset(0, 200));
        await tester.pumpAndSettle();
      }

      final beneficiaries = await db.select(db.beneficiaries).get();
      final samples = await db.select(db.freeSamples).get();
      final outbox = await db.select(db.syncOutbox).get();
      expect(beneficiaries, hasLength(1));
      expect(beneficiaries.single.sourceClientId, isNull);
      expect(samples, hasLength(2));
      expect(
        samples.every((row) => row.beneficiaryId == beneficiaries.single.id),
        isTrue,
      );
      expect(
        samples.every((row) => row.syncStatus == SyncStatus.PENDING),
        isTrue,
      );
      expect(
        outbox.where((row) => row.entityType == ParentEntityType.BENEFICIARY),
        hasLength(1),
      );
      expect(
        outbox.where((row) => row.entityType == ParentEntityType.FREE_SAMPLE),
        hasLength(2),
      );
      expect(
        outbox.where(
          (row) => row.entityType == ParentEntityType.FREE_SAMPLE_LINE,
        ),
        hasLength(2),
      );
      expect(tester.takeException(), isNull);
      await unmountForm(tester);
    },
  );
}

class _FixedDeviceService extends DeviceService {
  _FixedDeviceService(super.db, this.device);

  final Device device;

  @override
  Future<Device> ensureCurrentDevice() async => device;
}
