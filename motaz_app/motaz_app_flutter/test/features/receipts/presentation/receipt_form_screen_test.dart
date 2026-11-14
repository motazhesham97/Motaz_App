import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/core/database/app_database.dart';
import 'package:motaz_app_flutter/core/database/database_provider.dart';
import 'package:motaz_app_flutter/core/database/device_service.dart';
import 'package:motaz_app_flutter/core/database/enums/enums.dart';
import 'package:motaz_app_flutter/features/attachments/application/document_attachment_service.dart';
import 'package:motaz_app_flutter/features/invoices/data/invoice_repository.dart';
import 'package:motaz_app_flutter/features/invoices/presentation/invoice_form_screen.dart';
import 'package:motaz_app_flutter/features/receipts/presentation/receipt_form_screen.dart';

const _deviceId = '00000000-0000-4000-8000-000000000001';
const _oldClientId = '00000000-0000-4000-8000-000000000002';
const _clientId = '00000000-0000-4000-8000-000000000003';
const _productId = '00000000-0000-4000-8000-000000000004';

void main() {
  testWidgets(
    'linked receipt opens its invoice editor and reloads the corrected client and payment',
    (tester) async {
      final db = AppDatabase(
        NativeDatabase.memory(
          setup: (rawDb) => rawDb.execute('PRAGMA foreign_keys = ON'),
        ),
      );
      addTearDown(db.close);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final now = DateTime(2026, 8, 1);
      await db
          .into(db.devices)
          .insert(
            DevicesCompanion.insert(
              id: _deviceId,
              deviceName: 'Receipt test device',
              platform: DevicePlatform.ANDROID,
              deviceCode: 't001',
              createdAt: now,
              lastActiveAt: now,
            ),
          );
      for (final (id, name) in [
        (_oldClientId, 'الملكة أروى'),
        (_clientId, 'بقالة طيبة'),
      ]) {
        await db
            .into(db.clients)
            .insert(
              ClientsCompanion.insert(
                id: id,
                displayName: name,
                createdAt: now,
                updatedAt: now,
                deviceId: _deviceId,
              ),
            );
      }
      await db
          .into(db.products)
          .insert(
            ProductsCompanion.insert(
              id: _productId,
              name: 'شوكولاتة دبي',
              defaultSalePrice: 1350000,
              createdAt: now,
              updatedAt: now,
              deviceId: _deviceId,
            ),
          );
      final invoices = InvoiceRepository(db);
      final invoice = await invoices.create(
        clientId: _oldClientId,
        invoiceDate: now,
        discount: 0,
        note: '',
        lines: const [
          SalesInvoiceLinesCompanion(
            productId: Value(_productId),
            quantity: Value(1),
            unitPrice: Value(1350000),
          ),
        ],
        paidAmount: 1125000,
        deviceId: _deviceId,
      );
      final receipt = (await invoices.getReceiptsForInvoice(invoice.id)).single;
      await (db.update(db.salesInvoices)..where((t) => t.id.equals(invoice.id)))
          .write(const SalesInvoicesCompanion(clientId: Value(_clientId)));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            deviceServiceProvider.overrideWithValue(_Device(db)),
            documentAttachmentServiceProvider.overrideWithValue(_NoPhotos(db)),
          ],
          child: MaterialApp(
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: ReceiptFormScreen(existingReceipt: receipt),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('تعديل دفعة على فاتورة'), findsOneWidget);
      expect(find.text('إضافة صورة السند'), findsNothing);
      expect(find.text('بقالة طيبة'), findsOneWidget);
      expect(find.text('الملكة أروى'), findsNothing);
      await tester.tap(find.byTooltip('تعديل الفاتورة المرتبطة'));
      await tester.pumpAndSettle();
      expect(find.byType(InvoiceFormScreen), findsOneWidget);
      final paid = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'المبلغ المدفوع',
      );
      await tester.ensureVisible(paid);
      await tester.enterText(paid, '10000');
      FocusManager.instance.primaryFocus?.unfocus();
      final save = find.widgetWithText(FilledButton, 'حفظ');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(find.byType(InvoiceFormScreen), findsNothing);
      expect(find.text('بقالة طيبة'), findsOneWidget);
      final amount = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'المبلغ *',
      );
      expect(tester.widget<TextField>(amount).controller!.text, '10000.00');
      final updated = await db.select(db.receipts).getSingle();
      expect(updated.id, receipt.id);
      expect(updated.clientId, _clientId);
      expect(updated.amount, 1000000);
      expect(updated.syncStatus, SyncStatus.PENDING);
      await tester.ensureVisible(amount);
      await tester.enterText(amount, '9500');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      final manuallyUpdated = await db.select(db.receipts).getSingle();
      expect(manuallyUpdated.id, receipt.id);
      expect(manuallyUpdated.clientId, _clientId);
      expect(manuallyUpdated.amount, 950000);
      expect(await invoices.getRemainingBalance(invoice.id), 400000);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}

class _Device extends DeviceService {
  _Device(super.db) : _db = db;
  final AppDatabase _db;

  @override
  Future<Device> ensureCurrentDevice() => _db.select(_db.devices).getSingle();
}

class _NoPhotos extends DocumentAttachmentService {
  _NoPhotos(super.db);

  @override
  Future<String?> recoverLostDocumentPhoto() async => null;
}
