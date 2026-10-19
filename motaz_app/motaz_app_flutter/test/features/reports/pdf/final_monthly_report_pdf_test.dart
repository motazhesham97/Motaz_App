import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/features/profit_distribution/domain/monthly_profit.dart';
import 'package:motaz_app_flutter/features/reports/data/report_models.dart';
import 'package:motaz_app_flutter/features/reports/pdf/pdf_styles.dart';
import 'package:motaz_app_flutter/features/reports/pdf/pdf_templates/final_monthly_report_pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'generates an Arabic monthly PDF with current and carried loss and zero party shares',
    () async {
      final profit = MonthlyProfit(
        year: 2026,
        month: 1,
        netSales: 1000000,
        operationalExpenses: 1000000,
        productionExpenses: 500000,
        carriedLossIn: -200000,
      );
      final data = FinalMonthlyReportData(
        year: 2026,
        month: 1,
        operationalExpenses: 1000000,
        productionExpenses: 500000,
        totalCost: 1500000,
        productSales: [
          FinalReportProductSale(
            productName: 'شوكولاتة دي كبير',
            quantity: 12,
            totalSales: 1200000,
          ),
        ],
        totalSales: 1000000,
        discounts: 200000,
        profit: profit.netProfit,
        monthlyProfit: profit,
        isApproved: true,
        partyRows: [
          for (final name in ['معتز', 'امي', 'الهامش'])
            FinalReportPartyRow(
              partyName: name,
              profitShare: 0,
              withdrawals: 0,
              afterWithdrawals: 0,
              repayments: 0,
              openingBalance: 0,
              closingBalance: 0,
            ),
        ],
      );
      final document = FinalMonthlyReportPdf.generate(
        await PdfStyles.load(),
        data,
      );
      final bytes = await document.save();
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(1000));
      final artifact = File('build/test_artifacts/monthly-loss-report.pdf');
      await artifact.parent.create(recursive: true);
      await artifact.writeAsBytes(bytes);
    },
  );
}
