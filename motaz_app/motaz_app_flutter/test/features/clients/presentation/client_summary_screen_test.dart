import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/core/database/app_database.dart';
import 'package:motaz_app_flutter/core/database/enums/enums.dart';
import 'package:motaz_app_flutter/features/clients/application/client_providers.dart';
import 'package:motaz_app_flutter/features/clients/data/client_repository.dart';
import 'package:motaz_app_flutter/features/clients/presentation/client_summary_screen.dart';

void main() {
  testWidgets(
    'client history displays official and pending returns alongside invoices and receipts',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = AppDatabase(
        NativeDatabase.memory(
          setup: (rawDb) => rawDb.execute('PRAGMA foreign_keys = ON'),
        ),
      );
      addTearDown(db.close);
      final repo = ClientRepository(db);
      const deviceId = '00000000-0000-4000-8000-000000000031';
      const invoiceId = '00000000-0000-4000-8000-000000000032';
      final now = DateTime(2026, 8, 11);
      await db
          .into(db.devices)
          .insert(
            DevicesCompanion.insert(
              id: deviceId,
              deviceName: 'Client history test',
              platform: DevicePlatform.ANDROID,
              deviceCode: 't031',
              createdAt: now,
              lastActiveAt: now,
            ),
          );
      final client = await repo.createAndReturn(
        const ClientsCompanion(
          displayName: Value('بقالة الشوكولاتة'),
          deviceId: Value(deviceId),
        ),
      );
      await db
          .into(db.salesInvoices)
          .insert(
            SalesInvoicesCompanion.insert(
              id: invoiceId,
              localRef: 'INV-t031-1',
              officialNo: const Value('40'),
              clientId: client.id,
              invoiceDate: now,
              total: 250000,
              createdAt: now,
              updatedAt: now,
              deviceId: deviceId,
            ),
          );
      await db
          .into(db.receipts)
          .insert(
            ReceiptsCompanion.insert(
              id: '00000000-0000-4000-8000-000000000033',
              localRef: const Value('REC-t031-1'),
              officialNo: const Value('9'),
              receiptType: ReceiptType.GENERAL,
              clientId: client.id,
              amount: 50000,
              receiptDate: DateTime(2026, 8, 12),
              createdAt: now,
              updatedAt: now,
              deviceId: deviceId,
            ),
          );
      for (var index = 0; index < 2; index++) {
        await db
            .into(db.salesReturns)
            .insert(
              SalesReturnsCompanion.insert(
                id: '00000000-0000-4000-8000-00000000003${index + 4}',
                localRef: Value('RET-t031-$index'),
                officialNo: Value(index == 0 ? '7' : null),
                invoiceId: invoiceId,
                returnDate: DateTime(2026, 8, 13 + index),
                totalReturnedAmount: index == 0 ? 20000 : 10000,
                createdAt: now,
                updatedAt: now,
                deviceId: deviceId,
              ),
            );
      }

      await tester.pumpWidget(
        ProviderScope(
          overrides: [clientRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: ClientSummaryScreen(client: client),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('مرتجع رقم 7'), findsOneWidget);
      expect(find.text('مرتجع رقم قيد الترقيم'), findsOneWidget);
      expect(find.text('الفاتورة رقم 40'), findsOneWidget);
      expect(find.text('سند قبض رقم 9'), findsOneWidget);
      expect(find.text('200.00 ر.ي.'), findsOneWidget);
      expect(find.text('100.00 ر.ي.'), findsOneWidget);
      expect(find.text('1700.00 ر.ي.'), findsOneWidget);
      expect(find.byIcon(Icons.assignment_return_outlined), findsNWidgets(2));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
