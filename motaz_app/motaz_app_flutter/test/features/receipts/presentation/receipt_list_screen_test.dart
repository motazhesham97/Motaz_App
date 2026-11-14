import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/core/connectivity/connectivity_provider.dart';
import 'package:motaz_app_flutter/core/database/app_database.dart';
import 'package:motaz_app_flutter/core/database/database_provider.dart';
import 'package:motaz_app_flutter/core/database/enums/enums.dart';
import 'package:motaz_app_flutter/core/utils/document_reference_formatter.dart';
import 'package:motaz_app_flutter/features/attachments/application/document_attachment_service.dart';
import 'package:motaz_app_flutter/features/receipts/application/receipt_providers.dart';
import 'package:motaz_app_flutter/features/receipts/data/receipt_repository.dart';
import 'package:motaz_app_flutter/features/receipts/presentation/receipt_list_screen.dart';
import 'package:motaz_app_flutter/features/sync/application/sync_providers.dart';
import 'package:motaz_app_flutter/features/sync/domain/sync_state.dart';

Receipt _receipt(ReceiptType type, String number) => Receipt(
  id: number,
  localRef: 'REC-t001-$number',
  officialNo: number,
  receiptType: type,
  clientId: 'client',
  amount: 100000,
  receiptDate: DateTime(2026, 1, 1),
  status: RecordStatus.ACTIVE,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
  deviceId: 'device',
  rowVersion: 1,
  syncStatus: SyncStatus.PENDING,
);

void main() {
  testWidgets(
    'paper receipt list excludes internal invoice payments and preserves paper photo entry',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final paper = _receipt(ReceiptType.GENERAL, '2');
      final payment = _receipt(ReceiptType.INVOICE_LINKED, '1');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            receiptListProvider.overrideWith(
              (ref) => Stream.value([paper, payment]),
            ),
            receiptRepositoryProvider.overrideWithValue(_Receipts(db)),
            documentAttachmentServiceProvider.overrideWithValue(_NoPhotos(db)),
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
          child: const MaterialApp(
            locale: Locale('ar'),
            supportedLocales: [Locale('ar')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: ReceiptListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(receiptDisplayRef(paper.localRef, officialNo: '2')),
        findsOneWidget,
      );
      expect(
        find.text(receiptDisplayRef(payment.localRef, officialNo: '1')),
        findsNothing,
      );
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text('إضافة سند قبض'), findsOneWidget);
      expect(find.text('إضافة صورة السند'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}

class _Receipts extends ReceiptRepository {
  _Receipts(super.db);

  @override
  Future<Map<String, String>> getClientNamesByReceiptId() async => {
    '1': 'متجر',
    '2': 'متجر',
  };
}

class _NoPhotos extends DocumentAttachmentService {
  _NoPhotos(super.db);

  @override
  Future<String?> recoverLostDocumentPhoto() async => null;
}
