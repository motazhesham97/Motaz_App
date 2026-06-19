import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/core/database/app_database.dart';
import 'package:motaz_app_flutter/features/invoices/presentation/invoice_detail_screen.dart';

void main() {
  testWidgets(
    'invoice line card shows product, quantity, price, and total on mobile',
    (tester) async {
      final now = DateTime(2026, 6, 2, 10);
      final line = SalesInvoiceLine(
        id: 'line-1',
        invoiceId: 'invoice-1',
        productId: 'product-1',
        quantity: 12,
        unitPrice: 150000,
        lineTotal: 1800000,
        createdAt: now,
        updatedAt: now,
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
                child: InvoiceLineCard(
                  line: line,
                  productName:
                      'شوكولاتة دبي كبير باسم طويل لاختبار عرض بند الفاتورة',
                  formatMoney: (minorUnits) =>
                      '${(minorUnits / 100).toStringAsFixed(2)} ر.ي.',
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining('شوكولاتة دبي كبير'), findsOneWidget);
      expect(find.text('الكمية: 12'), findsOneWidget);
      expect(find.text('السعر: 1500.00 ر.ي.'), findsOneWidget);
      expect(find.text('الإجمالي: 18000.00 ر.ي.'), findsOneWidget);
    },
  );
}
