import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/features/invoices/presentation/invoice_form_screen.dart';

void main() {
  testWidgets(
    'invoice line edit dialog content remains scrollable when keyboard is visible',
    (tester) async {
      final quantityController = TextEditingController(text: '3');
      final priceController = TextEditingController(text: '800.00');
      final quantityFocusNode = FocusNode();
      final priceFocusNode = FocusNode();
      var quantityTapCalls = 0;
      var clearDateCalls = 0;

      addTearDown(quantityController.dispose);
      addTearDown(priceController.dispose);
      addTearDown(quantityFocusNode.dispose);
      addTearDown(priceFocusNode.dispose);

      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 640),
              viewInsets: EdgeInsets.only(bottom: 300),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Material(
                child: Center(
                  child: AlertDialog(
                    insetPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    title: const Text(
                      'شوكولاتة دبي كبير باسم طويل',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    content: InvoiceLineEditDialogContent(
                      quantityController: quantityController,
                      priceController: priceController,
                      quantityFocusNode: quantityFocusNode,
                      priceFocusNode: priceFocusNode,
                      productionDate: DateTime(2026, 6, 2),
                      formatDate: (date) =>
                          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                      onQuantityTap: () {
                        quantityTapCalls += 1;
                      },
                      onPriceTap: () {},
                      onPickProductionDate: () {},
                      onClearProductionDate: () {
                        clearDateCalls += 1;
                      },
                    ),
                    actionsAlignment: MainAxisAlignment.spaceBetween,
                    actions: [
                      TextButton(onPressed: () {}, child: const Text('غلق')),
                      FilledButton(onPressed: () {}, child: const Text('تم')),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('الكمية'), findsOneWidget);
      expect(find.text('سعر البيع'), findsOneWidget);
      expect(find.text('2026-06-02'), findsOneWidget);

      await tester.tap(find.byType(TextField).first);
      await tester.pump();
      await tester.scrollUntilVisible(
        find.byTooltip('مسح التاريخ'),
        80,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.byTooltip('مسح التاريخ'));
      await tester.pump();

      expect(quantityTapCalls, 1);
      expect(clearDateCalls, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
