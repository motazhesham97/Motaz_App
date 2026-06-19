import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/core/database/app_database.dart';
import 'package:motaz_app_flutter/core/database/enums/enums.dart';
import 'package:motaz_app_flutter/features/invoices/presentation/invoice_list_screen.dart';

void main() {
  testWidgets(
    'compact invoice card opens return menu without mobile layout overflow',
    (tester) async {
      var returnCalls = 0;
      final now = DateTime(2026, 6, 2, 10);
      final invoice = SalesInvoice(
        id: 'invoice-1',
        localRef: 'INV-MOBILE-LONG-REFERENCE-0000000001',
        officialNo: 'OFFICIAL-NUMBER-VERY-LONG-0000000001',
        clientId: 'client-1',
        invoiceDate: now,
        discount: 0,
        total: 1000000000,
        note: 'note',
        status: RecordStatus.ACTIVE,
        createdAt: now,
        updatedAt: now,
        deviceId: 'device-1',
        rowVersion: 1,
        syncStatus: SyncStatus.SYNCED,
      );

      await tester.binding.setSurfaceSize(const Size(360, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(8),
                child: InvoiceCard(
                  invoice: invoice,
                  clientName: 'عميل باسم طويل جدا لاختبار ضغط بطاقة الفاتورة',
                  formattedDate: '2026-06-02',
                  isCompact: true,
                  onOpen: () {},
                  onAudit: () {},
                  onReturn: () {
                    returnCalls += 1;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('إنشاء مرتجع'), findsOneWidget);

      await tester.tap(find.text('إنشاء مرتجع'));
      await tester.pumpAndSettle();

      expect(returnCalls, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
