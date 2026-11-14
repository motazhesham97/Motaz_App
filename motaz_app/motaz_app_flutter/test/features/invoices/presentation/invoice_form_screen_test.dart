import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:motaz_app_flutter/core/database/app_database.dart';
import 'package:motaz_app_flutter/core/database/database_provider.dart';
import 'package:motaz_app_flutter/core/database/device_service.dart';
import 'package:motaz_app_flutter/core/database/enums/enums.dart';
import 'package:motaz_app_flutter/features/attachments/application/document_attachment_service.dart';
import 'package:motaz_app_flutter/features/clients/application/client_providers.dart';
import 'package:motaz_app_flutter/features/invoices/data/invoice_repository.dart';
import 'package:motaz_app_flutter/features/invoices/presentation/invoice_form_screen.dart';
import 'package:motaz_app_flutter/features/invoices/presentation/invoice_detail_screen.dart';
import 'package:motaz_app_flutter/features/products/application/product_providers.dart';
import 'package:motaz_app_flutter/features/profit_distribution/application/profit_providers.dart';
import 'package:motaz_app_flutter/features/receipts/data/receipt_repository.dart';
import 'package:motaz_app_flutter/shared/widgets/app_drawer.dart';

final _product = Product(
  id: '00000000-0000-4000-8000-000000000001',
  name: 'شوكولاتة دبي كلاسيك',
  defaultSalePrice: 80000,
  sku: 'P01',
  isActive: true,
  createdAt: DateTime(2026, 8, 1),
  updatedAt: DateTime(2026, 8, 1),
  deviceId: '00000000-0000-4000-8000-000000000002',
  rowVersion: 1,
  syncStatus: SyncStatus.PENDING,
);

void main() {
  late AppDatabase db;

  setUp(
    () => db = AppDatabase(
      NativeDatabase.memory(
        setup: (rawDb) => rawDb.execute('PRAGMA foreign_keys = ON'),
      ),
    ),
  );
  tearDown(() => db.close());

  Future<void> pumpForm(
    WidgetTester tester, {
    bool inShell = false,
    List<Client> clients = const [],
    Stream<List<Product>>? products,
    SalesInvoice? existingInvoice,
    List<SalesInvoiceLine>? existingLines,
  }) async {
    final router = inShell
        ? GoRouter(
            initialLocation: '/invoices',
            routes: [
              ShellRoute(
                builder: (_, _, child) => AppShell(child: child),
                routes: [
                  GoRoute(
                    path: '/invoices',
                    builder: (_, _) => const InvoiceFormScreen(),
                  ),
                ],
              ),
            ],
          )
        : null;
    if (router != null) addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          deviceServiceProvider.overrideWithValue(_LocalDevice(db)),
          productListProvider.overrideWith(
            (ref) => products ?? Stream.value([_product]),
          ),
          activeClientListProvider.overrideWith((ref) => Stream.value(clients)),
          documentAttachmentServiceProvider.overrideWithValue(_NoPhotos(db)),
          settlementReviewProvider.overrideWith((ref) async => []),
        ],
        child: router != null
            ? MaterialApp.router(
                locale: const Locale('ar'),
                supportedLocales: const [Locale('ar')],
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                routerConfig: router,
              )
            : MaterialApp(
                locale: const Locale('ar'),
                supportedLocales: const [Locale('ar')],
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                home: InvoiceFormScreen(
                  existingInvoice: existingInvoice,
                  existingLines: existingLines,
                ),
              ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<SalesInvoice> seedEditableInvoice() async {
    final now = DateTime(2026, 8, 1);
    await db
        .into(db.devices)
        .insert(
          DevicesCompanion.insert(
            id: _product.deviceId,
            deviceName: 'Invoice edit test device',
            platform: DevicePlatform.ANDROID,
            deviceCode: 't001',
            createdAt: now,
            lastActiveAt: now,
          ),
        );
    await db.into(db.products).insert(_product);
    await db
        .into(db.clients)
        .insert(
          ClientsCompanion.insert(
            id: '00000000-0000-4000-8000-000000000003',
            displayName: 'الملكة أروى',
            createdAt: now,
            updatedAt: now,
            deviceId: _product.deviceId,
          ),
        );
    return InvoiceRepository(db).create(
      clientId: '00000000-0000-4000-8000-000000000003',
      invoiceDate: now,
      discount: 0,
      note: '',
      lines: [
        SalesInvoiceLinesCompanion(
          productId: Value(_product.id),
          quantity: const Value(1),
          unitPrice: const Value(1350000),
        ),
      ],
      paidAmount: 1125000,
      deviceId: _product.deviceId,
    );
  }

  testWidgets(
    'quick invoice creates a missing client locally without losing invoice data',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await seedEditableInvoice();
      await pumpForm(tester, clients: await db.select(db.clients).get());
      await tester.enterText(find.byType(TextField).first, 'P01');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, _product.name));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'حفظ'));
      await tester.pumpAndSettle();
      final paid = find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextFormField),
          )
          .at(1);
      await tester.ensureVisible(paid);
      await tester.enterText(paid, '500');
      final client = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'ادخل اسم العميل',
      );
      await tester.ensureVisible(client);
      await tester.enterText(client, 'بقالة دبي الجديدة');
      await tester.pumpAndSettle();
      expect(
        find.text('هذا العميل غير موجود. هل تريد إضافته؟'),
        findsOneWidget,
      );
      final add = find.widgetWithText(TextButton, 'إضافة عميل جديد');
      await tester.ensureVisible(add);
      await tester.tap(add);
      await tester.pumpAndSettle();
      final phone = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'الهاتف',
      );
      await tester.enterText(phone, '777123456');
      final create = find.descendant(
        of: find.byType(AlertDialog).last,
        matching: find.widgetWithText(FilledButton, 'حفظ'),
      );
      await tester.ensureVisible(create);
      await tester.tap(create);
      await tester.pumpAndSettle();

      final created = (await db.select(db.clients).get()).singleWhere(
        (row) => row.displayName == 'بقالة دبي الجديدة',
      );
      expect(created.syncStatus, SyncStatus.PENDING);
      expect(
        tester.widget<TextField>(client).controller!.text,
        created.displayName,
      );
      expect(find.text('هذا العميل غير موجود. هل تريد إضافته؟'), findsNothing);
      expect(tester.widget<TextFormField>(paid).controller!.text, '500');
      final save = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'حفظ'),
      );
      await tester.runAsync(() async {
        await tester.ensureVisible(save);
        await tester.tap(save);
        await db
            .select(db.salesInvoices)
            .watch()
            .firstWhere((rows) => rows.length == 2);
      });
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      final invoice = (await db.select(db.salesInvoices).get()).singleWhere(
        (row) => row.clientId == created.id,
      );
      expect(invoice.total, 80000);
      expect(
        (await InvoiceRepository(
          db,
        ).getLinesForInvoice(invoice.id)).single.quantity,
        1,
      );
      expect(
        (await InvoiceRepository(
          db,
        ).getReceiptsForInvoice(invoice.id)).single.amount,
        50000,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'invoice details distinguish an incoming settlement from full received money on mobile',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final source = await seedEditableInvoice();
      final repo = InvoiceRepository(db);
      final lines = await repo.getLinesForInvoice(source.id);
      await repo.update(
        id: source.id,
        clientId: source.clientId,
        invoiceDate: source.invoiceDate,
        discount: 0,
        note: null,
        lines: [
          SalesInvoiceLinesCompanion(
            productId: Value(_product.id),
            quantity: const Value(1),
            unitPrice: const Value(1350000),
          ),
        ],
        paidAmount: 1850000,
        deviceId: _product.deviceId,
      );
      final next = await repo.create(
        clientId: source.clientId,
        invoiceDate: DateTime(2026, 8, 2),
        discount: 0,
        note: '',
        lines: [
          SalesInvoiceLinesCompanion(
            productId: Value(lines.single.productId),
            quantity: const Value(1),
            unitPrice: const Value(1350000),
          ),
        ],
        paidAmount: 0,
        deviceId: _product.deviceId,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(home: InvoiceDetailScreen(invoiceId: next.id)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('تسوية من دفعة فاتورة أخرى'), findsOneWidget);
      expect(find.textContaining('المدفوع: 18500.00'), findsOneWidget);
      expect(
        find.textContaining('المخصص لهذه الفاتورة: 5000.00'),
        findsOneWidget,
      );
      expect(find.text('لا توجد دفعات'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('invoice edits accept overpayment as customer credit', (
    tester,
  ) async {
    final invoice = await seedEditableInvoice();
    await pumpForm(
      tester,
      clients: await db.select(db.clients).get(),
      existingInvoice: invoice,
      existingLines: await InvoiceRepository(db).getLinesForInvoice(invoice.id),
    );
    final paid = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.labelText == 'المبلغ المدفوع',
    );
    await tester.ensureVisible(paid);
    await tester.enterText(paid, '15000');
    FocusManager.instance.primaryFocus?.unfocus();
    final save = find.widgetWithText(FilledButton, 'حفظ');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect((await db.select(db.receipts).getSingle()).amount, 1500000);
    expect(await InvoiceRepository(db).getRemainingBalance(invoice.id), 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'invoice edit loads the current paid amount from local linked receipts',
    (tester) async {
      final invoice = await seedEditableInvoice();
      final lines = await InvoiceRepository(db).getLinesForInvoice(invoice.id);

      await pumpForm(
        tester,
        clients: await db.select(db.clients).get(),
        existingInvoice: invoice,
        existingLines: lines,
      );

      final paid = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'المبلغ المدفوع',
      );
      expect(paid, findsOneWidget);
      expect(tester.widget<TextField>(paid).controller!.text, '11250.00');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'saving invoice edits updates the selected client and paid amount together',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final invoice = await seedEditableInvoice();
      await db
          .into(db.clients)
          .insert(
            ClientsCompanion.insert(
              id: '00000000-0000-4000-8000-000000000004',
              displayName: 'بقالة طيبة',
              createdAt: invoice.createdAt,
              updatedAt: invoice.updatedAt,
              deviceId: _product.deviceId,
            ),
          );
      await pumpForm(
        tester,
        clients: await db.select(db.clients).get(),
        existingInvoice: invoice,
        existingLines: await InvoiceRepository(
          db,
        ).getLinesForInvoice(invoice.id),
      );
      final client = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'العميل *',
      );
      await tester.ensureVisible(client);
      await tester.enterText(client, 'بقالة طيبة');
      await tester.pumpAndSettle();
      final paid = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'المبلغ المدفوع',
      );
      await tester.ensureVisible(paid);
      await tester.enterText(paid, '10000');
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      final save = find.widgetWithText(FilledButton, 'حفظ');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      final updatedInvoice = await db.select(db.salesInvoices).getSingle();
      final receipt = await db.select(db.receipts).getSingle();
      expect(updatedInvoice.clientId, '00000000-0000-4000-8000-000000000004');
      expect(receipt.clientId, updatedInvoice.clientId);
      expect(receipt.amount, 1000000);
      expect(receipt.syncStatus, SyncStatus.PENDING);
      expect(
        await InvoiceRepository(db).getRemainingBalance(invoice.id),
        350000,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'invoice edit can save an unchanged existing overpayment without losing client credit',
    (tester) async {
      final invoice = await seedEditableInvoice();
      final invoices = InvoiceRepository(db);
      final receipt = (await invoices.getReceiptsForInvoice(invoice.id)).single;
      await ReceiptRepository(db).updateReceipt(
        id: receipt.id,
        clientId: invoice.clientId,
        amount: 1500000,
        receiptDate: invoice.invoiceDate,
        deviceId: _product.deviceId,
      );
      await pumpForm(
        tester,
        clients: await db.select(db.clients).get(),
        existingInvoice: invoice,
        existingLines: await invoices.getLinesForInvoice(invoice.id),
      );
      final paid = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'المبلغ المدفوع',
      );
      expect(tester.widget<TextField>(paid).controller!.text, '15000.00');

      final save = find.widgetWithText(FilledButton, 'حفظ');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect((await invoices.getById(invoice.id)).rowVersion, 2);
      expect((await db.select(db.receipts).getSingle()).amount, 1500000);
      expect(await invoices.getCollectedAmount(invoice.id), 1350000);
      expect(await invoices.getRemainingBalance(invoice.id), 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'selecting a product clears suggestions and dismisses the search keyboard',
    (tester) async {
      await pumpForm(tester);
      final search = find.byType(TextField).first;
      await tester.enterText(search, 'شوكولاتة د');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, _product.name), findsOneWidget);

      await tester.tap(find.widgetWithText(ListTile, _product.name));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(search);
      expect(field.controller!.text, isEmpty);
      expect(field.focusNode!.hasFocus, isFalse);
      expect(tester.testTextInput.isVisible, isFalse);
      expect(find.widgetWithText(ListTile, _product.name), findsNothing);
      expect(find.text(_product.name), findsOneWidget);
      expect(find.text('الإجمالي : 800.00 ريال'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'product search waits for initial local data without retyping the query',
    (tester) async {
      final products = StreamController<List<Product>>();
      addTearDown(products.close);
      await pumpForm(tester, products: products.stream);
      final search = find.byType(TextField).first;

      await tester.enterText(search, 'P01');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, _product.name), findsNothing);
      products.add([_product]);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ListTile, _product.name), findsOneWidget);
      await tester.tap(find.widgetWithText(ListTile, _product.name));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(search).controller!.text, isEmpty);
      expect(tester.widget<TextField>(search).focusNode!.hasFocus, isFalse);
      expect(find.widgetWithText(ListTile, _product.name), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'keyboard overlays the invoice instead of squeezing its product table',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await pumpForm(tester);
      final search = find.byType(TextField).first;
      await tester.enterText(search, 'P01');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, _product.name));
      await tester.pumpAndSettle();
      final table = find.byType(SingleChildScrollView).first;
      final originalTable = tester.getRect(table);

      await tester.showKeyboard(search);
      tester.view.viewInsets = const FakeViewPadding(bottom: 350);
      await tester.pumpAndSettle();

      expect(tester.getRect(table), originalTable);
      expect(find.text(_product.name), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'can add the same product again and reset without stale suggestions',
    (tester) async {
      await pumpForm(tester);
      final search = find.byType(TextField).first;
      for (var index = 0; index < 2; index++) {
        await tester.enterText(search, 'P01');
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ListTile, _product.name));
        await tester.pumpAndSettle();
        await tester.showKeyboard(search);
        await tester.pumpAndSettle();
        expect(find.widgetWithText(ListTile, _product.name), findsNothing);
      }
      expect(find.text('الإجمالي : 1600.00 ريال'), findsOneWidget);

      await tester.enterText(search, 'منتج غير موجود');
      await tester.pumpAndSettle();
      expect(find.text('أضف المنتج'), findsOneWidget);
      await tester.tap(find.widgetWithText(OutlinedButton, 'مسح'));
      await tester.pumpAndSettle();

      expect(find.text('أضف المنتج'), findsNothing);
      expect(find.text(_product.name), findsNothing);
      expect(tester.widget<TextField>(search).controller!.text, isEmpty);
      expect(tester.widget<TextField>(search).focusNode!.hasFocus, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'app shell also preserves invoice space when the keyboard opens',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await pumpForm(tester, inShell: true);
      final invoice = find.byType(InvoiceFormScreen);
      final originalRect = tester.getRect(invoice);

      await tester.showKeyboard(find.byType(TextField).first);
      tester.view.viewInsets = const FakeViewPadding(bottom: 350);
      await tester.pumpAndSettle();

      expect(tester.getRect(invoice), originalRect);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'saving an overpaid quick invoice keeps credit and resets search without stale suggestions',
    (tester) async {
      final now = DateTime(2026, 8, 1);
      await db
          .into(db.devices)
          .insert(
            DevicesCompanion.insert(
              id: _product.deviceId,
              deviceName: 'Invoice test device',
              platform: DevicePlatform.ANDROID,
              deviceCode: 't001',
              createdAt: now,
              lastActiveAt: now,
            ),
          );
      await db.into(db.products).insert(_product);
      await db
          .into(db.clients)
          .insert(
            ClientsCompanion.insert(
              id: '00000000-0000-4000-8000-000000000003',
              displayName: 'بقالة الاختبار',
              createdAt: now,
              updatedAt: now,
              deviceId: _product.deviceId,
            ),
          );
      final client = await db.select(db.clients).getSingle();
      await pumpForm(tester, clients: [client]);
      final search = find.byType(TextField).first;
      await tester.enterText(search, 'P01');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, _product.name));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'حفظ'));
      await tester.pumpAndSettle();
      final paid = find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextFormField),
          )
          .at(1);
      await tester.ensureVisible(paid);
      await tester.enterText(paid, '1500');
      await tester.pumpAndSettle();
      expect(find.text('فائض لتسوية الحساب'), findsOneWidget);
      final clientInput = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'ادخل اسم العميل',
      );
      await tester.ensureVisible(clientInput);
      await tester.pumpAndSettle();
      await tester.enterText(clientInput, client.displayName);
      await tester.pumpAndSettle();

      final save = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'حفظ'),
      );
      await tester.runAsync(() async {
        await tester.tap(save);
        await db
            .select(db.salesInvoices)
            .watch()
            .firstWhere((rows) => rows.length == 1);
      });
      await tester.pumpAndSettle();
      // Advance the existing dialog's 450 ms controller-disposal delay.
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.widget<TextField>(search).controller!.text, isEmpty);
      expect(tester.widget<TextField>(search).focusNode!.hasFocus, isFalse);
      expect(tester.testTextInput.isVisible, isFalse);
      expect(find.text(_product.name), findsNothing);
      expect(
        (await db.select(db.salesInvoices).getSingle()).syncStatus,
        SyncStatus.PENDING,
      );
      expect(await db.select(db.syncOutbox).get(), isNotEmpty);
      expect((await db.select(db.receipts).getSingle()).amount, 150000);
      expect(
        await InvoiceRepository(db).getRemainingBalance(
          (await db.select(db.salesInvoices).getSingle()).id,
        ),
        0,
      );
      await tester.showKeyboard(search);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, _product.name), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}

class _NoPhotos extends DocumentAttachmentService {
  _NoPhotos(super.db);

  @override
  Future<String?> recoverLostDocumentPhoto() async => null;
}

class _LocalDevice extends DeviceService {
  _LocalDevice(super.db) : _db = db;

  final AppDatabase _db;

  @override
  Future<Device> ensureCurrentDevice() => _db.select(_db.devices).getSingle();
}
