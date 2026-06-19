import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/core/database/app_database.dart';
import 'package:motaz_app_flutter/core/database/enums/enums.dart';
import 'package:motaz_app_flutter/features/returns/presentation/return_list_screen.dart';

void main() {
  testWidgets(
    'ReturnCompactCardContent fits narrow mobile width without overflow',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(360, 720);
      tester.view.devicePixelRatio = 1;

      final now = DateTime(2026, 6, 2);
      final ret = SalesReturn(
        id: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        localRef: 'RET-t001-999',
        invoiceId: 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12',
        returnDate: now,
        totalReturnedAmount: 987654321,
        note: 'Very long return note that should be ellipsized safely',
        status: RecordStatus.ACTIVE,
        createdAt: now,
        updatedAt: now,
        deviceId: 'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a13',
        rowVersion: 1,
        syncStatus: SyncStatus.PENDING,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: ReturnCompactCardContent(
                      ret: ret,
                      isVoided: false,
                      returnRef: 'RET-t001-999-with-extra-reference-text',
                      invoiceRef: 'INV-t001-999-with-extra-reference-text',
                      onShowAuditTrail: () {},
                      onVoid: () {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(ReturnCompactCardContent), findsOneWidget);
    },
  );
}
