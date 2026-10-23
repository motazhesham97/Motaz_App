import 'dart:convert';

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
import 'package:motaz_app_flutter/features/expenses/application/expense_providers.dart';
import 'package:motaz_app_flutter/features/expenses/data/expense_repository.dart';
import 'package:motaz_app_flutter/features/expenses/presentation/expense_form_screen.dart';
import 'package:motaz_app_flutter/features/sync/application/sync_providers.dart';
import 'package:motaz_app_flutter/features/sync/domain/sync_state.dart';

const _deviceId = '00000000-0000-4000-8000-000000000011';

Expense _expense(ExpenseCategory category, String note) => Expense(
  id: '00000000-0000-4000-8000-000000000012',
  category: category,
  amount: 400000,
  expenseDate: DateTime(2026, 8, 11),
  note: note,
  status: RecordStatus.ACTIVE,
  createdAt: DateTime(2026, 8, 11),
  updatedAt: DateTime(2026, 8, 11),
  deviceId: _deviceId,
  rowVersion: 1,
  syncStatus: SyncStatus.PENDING,
);

void main() {
  late AppDatabase db;

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
            deviceName: 'Expense test device',
            platform: DevicePlatform.ANDROID,
            deviceCode: 't011',
            createdAt: DateTime(2026, 8, 1),
            lastActiveAt: DateTime(2026, 8, 1),
          ),
        );
  });
  tearDown(() => db.close());

  Future<void> pumpForm(
    WidgetTester tester, {
    List<Expense> expenses = const [],
    Expense? existingExpense,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          deviceServiceProvider.overrideWithValue(_LocalDevice(db)),
          expenseListProvider.overrideWith((ref) => Stream.value(expenses)),
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
        child: MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          initialRoute: '/expenses',
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () => Navigator.pushNamed(context, '/expenses'),
                child: const Text('فتح المصروفات'),
              ),
            ),
          ),
          routes: {
            '/expenses': (_) => ExpenseFormScreen(
              isSectionEntry: true,
              existingExpense: existingExpense,
            ),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder input(String label) => find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label,
  );

  Future<void> selectDate(WidgetTester tester, DateTime date) async {
    final field = find.ancestor(
      of: find.text('تاريخ المصروف'),
      matching: find.byType(InputDecorator),
    );
    await tester.ensureVisible(field);
    await tester.tap(field);
    await tester.pumpAndSettle();
    final calendar = find.byType(CalendarDatePicker);
    // Exercise our dialog result handling, not Flutter's calendar navigation.
    tester.widget<CalendarDatePicker>(calendar).onDateChanged(date);
    await tester.pump();
    final confirm = MaterialLocalizations.of(
      tester.element(calendar),
    ).okButtonLabel;
    await tester.tap(find.widgetWithText(TextButton, confirm));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'opens expense entry first and keeps history category filtering available',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pumpForm(
        tester,
        expenses: [
          _expense(ExpenseCategory.OPERATIONAL, 'نقل الشوكولاتة'),
          _expense(ExpenseCategory.PRODUCTION, 'علب التغليف'),
        ],
      );
      expect(find.text('المبلغ *'), findsOneWidget);
      expect(find.text('تاريخ المصروف'), findsOneWidget);
      expect(find.text('نقل الشوكولاتة'), findsNothing);

      await tester.tap(find.widgetWithText(OutlinedButton, 'سجل المصروفات'));
      await tester.pumpAndSettle();
      expect(find.text('نقل الشوكولاتة'), findsOneWidget);
      expect(find.text('علب التغليف'), findsOneWidget);
      await tester.tap(find.byTooltip('بحث'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<ExpenseCategory>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إنتاجي').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'بحث'));
      await tester.pumpAndSettle();
      expect(find.text('علب التغليف'), findsOneWidget);
      expect(find.text('نقل الشوكولاتة'), findsNothing);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('المبلغ *'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'saves repeated offline expenses locally using the selected date and category',
    (tester) async {
      await pumpForm(tester);
      await selectDate(tester, DateTime(2026, 8, 11));
      await tester.tap(find.byType(DropdownButtonFormField<ExpenseCategory>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إنتاجي').last);
      await tester.pumpAndSettle();

      for (var index = 1; index <= 2; index++) {
        await tester.enterText(input('ملاحظة'), 'تغليف الدفعة $index');
        await tester.enterText(input('المبلغ *'), '12.50');
        final save = find.widgetWithText(FilledButton, 'حفظ');
        await tester.ensureVisible(save);
        await tester.runAsync(() async {
          await tester.tap(save);
          await db
              .select(db.expenses)
              .watch()
              .firstWhere((rows) => rows.length == index);
        });
        await tester.pumpAndSettle();

        expect(find.text('تم حفظ المصروف'), findsOneWidget);
        expect(find.text('2026-08-11'), findsOneWidget);
        expect(
          tester.widget<TextField>(input('ملاحظة')).controller!.text,
          isEmpty,
        );
        expect(
          tester.widget<TextField>(input('المبلغ *')).controller!.text,
          isEmpty,
        );
        expect(
          tester
              .state<FormFieldState<ExpenseCategory>>(
                find.byType(DropdownButtonFormField<ExpenseCategory>),
              )
              .value,
          ExpenseCategory.PRODUCTION,
        );
        ScaffoldMessenger.of(tester.element(save)).removeCurrentSnackBar();
        await tester.pumpAndSettle();
      }

      final expenses = await db.select(db.expenses).get();
      expect(expenses, hasLength(2));
      for (final expense in expenses) {
        expect(expense.expenseDate, DateTime(2026, 8, 11));
        expect(expense.category, ExpenseCategory.PRODUCTION);
        expect(expense.amount, 1250);
        expect(expense.syncStatus, SyncStatus.PENDING);
      }
      final outbox = await db.select(db.syncOutbox).get();
      expect(outbox, hasLength(2));
      for (final operation in outbox) {
        expect(operation.entityType, ParentEntityType.EXPENSE);
        expect(operation.status, SyncOutboxStatus.PENDING);
        final payload = jsonDecode(operation.payload) as Map<String, dynamic>;
        expect(
          DateTime.parse(payload['expenseDate'] as String),
          DateTime(2026, 8, 11),
        );
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'keeps the date after history and resets it only after leaving the section',
    (tester) async {
      await pumpForm(tester);
      await selectDate(tester, DateTime(2026, 8, 11));
      await tester.tap(find.widgetWithText(OutlinedButton, 'سجل المصروفات'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('إضافة مصروف'));
      await tester.pumpAndSettle();
      expect(find.text('2026-08-11'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('فتح المصروفات'), findsOneWidget);
      await tester.tap(find.text('فتح المصروفات'));
      await tester.pumpAndSettle();

      final now = DateTime.now();
      final today =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      expect(find.text(today), findsOneWidget);
      expect(find.text('2026-08-11'), findsNothing);
      expect(await db.select(db.expenses).get(), isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'editing updates the existing expense and still closes after saving',
    (tester) async {
      final existing = await ExpenseRepository(db).create(
        category: ExpenseCategory.OPERATIONAL,
        amount: 400000,
        expenseDate: DateTime(2026, 8, 11),
        note: 'نقل الشوكولاتة',
        deviceId: _deviceId,
      );
      await pumpForm(tester, existingExpense: existing);
      expect(find.text('تعديل مصروف'), findsOneWidget);
      expect(find.text('سجل المصروفات'), findsNothing);
      await selectDate(tester, DateTime(2026, 8, 12));
      await tester.enterText(input('المبلغ *'), '30');
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'حفظ'));
      await tester.runAsync(() async {
        await tester.tap(find.widgetWithText(FilledButton, 'حفظ'));
        await db
            .select(db.expenses)
            .watch()
            .firstWhere((rows) => rows.single.amount == 3000);
      });
      await tester.pumpAndSettle();

      expect(find.text('فتح المصروفات'), findsOneWidget);
      final saved = await db.select(db.expenses).getSingle();
      expect(saved.id, existing.id);
      expect(saved.expenseDate, DateTime(2026, 8, 12));
      expect(saved.amount, 3000);
      expect(saved.syncStatus, SyncStatus.PENDING);
      final operations = await db.select(db.syncOutbox).get();
      expect(operations, hasLength(2));
      expect(
        operations.where((row) => row.operation == AuditOperation.UPDATE),
        hasLength(1),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}

class _LocalDevice extends DeviceService {
  _LocalDevice(super.db) : _db = db;

  final AppDatabase _db;

  @override
  Future<Device> ensureCurrentDevice() => _db.select(_db.devices).getSingle();
}
