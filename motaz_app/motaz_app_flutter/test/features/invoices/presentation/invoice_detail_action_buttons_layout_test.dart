import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/features/invoices/presentation/invoice_detail_screen.dart';

void main() {
  testWidgets(
    'invoice detail action buttons stay readable on narrow mobile width',
    (tester) async {
      var tapped = 0;

      Widget button(IconData icon, String label, {Color? foregroundColor}) {
        return OutlinedButton.icon(
          onPressed: () {
            tapped += 1;
          },
          icon: Icon(icon),
          label: Text(label),
          style: foregroundColor == null
              ? null
              : OutlinedButton.styleFrom(foregroundColor: foregroundColor),
        );
      }

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
                child: InvoiceDetailActionButtonsLayout(
                  buttons: [
                    button(Icons.edit, 'تعديل'),
                    button(Icons.assignment_return, 'إنشاء مرتجع'),
                    button(Icons.add_card, 'إضافة دفعة'),
                    button(
                      Icons.cancel,
                      'إلغاء الفاتورة',
                      foregroundColor: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('تعديل'), findsOneWidget);
      expect(find.text('إنشاء مرتجع'), findsOneWidget);
      expect(find.text('إضافة دفعة'), findsOneWidget);
      expect(find.text('إلغاء الفاتورة'), findsOneWidget);

      await tester.tap(find.text('إلغاء الفاتورة'));
      await tester.pump();

      expect(tapped, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
