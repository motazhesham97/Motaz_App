import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/core/database/enums/enums.dart';
import 'package:motaz_app_flutter/features/reports/data/report_models.dart';
import 'package:motaz_app_flutter/features/reports/presentation/client_statement_screen.dart';

void main() {
  testWidgets(
    'statement labels invoice payments without calling them paper receipts',
    (tester) async {
      final entry = ClientStatementEntry(
        entityId: 'payment',
        parentEntityType: ParentEntityType.RECEIPT,
        type: StatementEntryType.receipt,
        isInvoicePayment: true,
        date: DateTime(2026, 1, 1),
        reference: 'الفاتورة رقم 123',
        amount: 1500000,
        runningBalance: -500000,
      );
      for (final width in [360.0, 900.0]) {
        tester.view.physicalSize = Size(width, 720);
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ClientStatementEntryCard(entry: entry),
            ),
          ),
        );
        expect(find.text('دفعة على فاتورة'), findsOneWidget);
        expect(find.text('سند قبض'), findsNothing);
        expect(find.text('الفاتورة رقم 123'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    },
  );

  testWidgets(
    'ClientStatementEntryCard fits narrow mobile width without overflow',
    (tester) async {
      addTearDown(
        () => tester.view.resetPhysicalSize(),
      );
      tester.view.physicalSize = const Size(360, 720);
      tester.view.devicePixelRatio = 1;

      final entry = ClientStatementEntry(
        entityId: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        parentEntityType: ParentEntityType.SALES_INVOICE,
        type: StatementEntryType.invoice,
        date: DateTime(2026, 1, 31),
        reference: 'INV-t001-999 / very long customer statement reference',
        amount: 987654321,
        runningBalance: 1234567890,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: ClientStatementEntryCard(entry: entry),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(ClientStatementEntryCard), findsOneWidget);
      expect(find.text('فاتورة'), findsOneWidget);
    },
  );
}
