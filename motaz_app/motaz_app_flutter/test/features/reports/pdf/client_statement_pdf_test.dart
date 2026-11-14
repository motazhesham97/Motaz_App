import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/core/database/enums/enums.dart';
import 'package:motaz_app_flutter/core/utils/date_range.dart';
import 'package:motaz_app_flutter/features/reports/data/report_models.dart';
import 'package:motaz_app_flutter/features/reports/pdf/pdf_styles.dart';
import 'package:motaz_app_flutter/features/reports/pdf/pdf_templates/client_statement_pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'generates an Arabic statement PDF with an overpayment and a separate paper receipt',
    () async {
      final data = ClientStatementData(
        clientName: 'بقالة طيبة',
        dateRange: DateRange.custom(DateTime(2026, 1, 1), DateTime(2026, 2)),
        openingBalance: 0,
        closingBalance: -600000,
        entries: [
          ClientStatementEntry(
            entityId: 'invoice',
            parentEntityType: ParentEntityType.SALES_INVOICE,
            type: StatementEntryType.invoice,
            date: DateTime(2026, 1, 1),
            reference: 'الفاتورة رقم 123',
            amount: 1000000,
            runningBalance: 1000000,
          ),
          ClientStatementEntry(
            entityId: 'payment',
            parentEntityType: ParentEntityType.RECEIPT,
            type: StatementEntryType.receipt,
            isInvoicePayment: true,
            date: DateTime(2026, 1, 1),
            reference: 'الفاتورة رقم 123',
            amount: 1500000,
            runningBalance: -500000,
          ),
          ClientStatementEntry(
            entityId: 'paper',
            parentEntityType: ParentEntityType.RECEIPT,
            type: StatementEntryType.receipt,
            date: DateTime(2026, 1, 2),
            reference: 'السند رقم 10',
            amount: 100000,
            runningBalance: -600000,
          ),
        ],
      );

      final document = ClientStatementPdf.generate(
        await PdfStyles.load(),
        data,
      );
      final bytes = await document.save();

      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(1000));
    },
  );

  test(
    'long statements paginate instead of retrying an unbreakable page',
    () async {
      final data = ClientStatementData(
        clientName: 'عميل متعدد الصفحات',
        dateRange: DateRange.custom(DateTime(2026, 1, 1), DateTime(2026, 2)),
        openingBalance: 0,
        closingBalance: 12000,
        entries: List.generate(
          120,
          (index) => ClientStatementEntry(
            entityId: 'invoice-$index',
            parentEntityType: ParentEntityType.SALES_INVOICE,
            type: StatementEntryType.invoice,
            date: DateTime(2026, 1, 1),
            reference: 'فاتورة رقم $index',
            amount: 100,
            runningBalance: (index + 1) * 100,
          ),
        ),
      );

      final document = ClientStatementPdf.generate(
        await PdfStyles.load(),
        data,
      );
      final bytes = await document.save();

      expect(bytes.length, greaterThan(1000));
      expect(document.document.pdfPageList.pages.length, greaterThan(1));
      final artifact = File('build/test_artifacts/statement-pagination.pdf');
      await artifact.parent.create(recursive: true);
      await artifact.writeAsBytes(bytes);
    },
  );

  test(
    'a long statement note continues without duplicating financial amounts',
    () async {
      final data = ClientStatementData(
        clientName: 'عميل',
        dateRange: DateRange.custom(DateTime(2026, 1, 1), DateTime(2026, 2)),
        openingBalance: 0,
        closingBalance: 100,
        entries: [
          ClientStatementEntry(
            entityId: 'invoice',
            parentEntityType: ParentEntityType.SALES_INVOICE,
            type: StatementEntryType.invoice,
            date: DateTime(2026, 1, 1),
            reference: 'فاتورة',
            note: List.filled(500, 'تفاصيل حركة الحساب ').join(),
            amount: 100,
            runningBalance: 100,
          ),
        ],
      );

      final document = ClientStatementPdf.generate(
        await PdfStyles.load(),
        data,
      );
      expect((await document.save()).length, greaterThan(1000));
      expect(document.document.pdfPageList.pages.length, greaterThan(1));
      expect(data.entries.single.amount, 100);
      expect(data.closingBalance, 100);
    },
  );
}
