import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motaz_app_flutter/core/database/app_database.dart';
import 'package:motaz_app_flutter/core/database/enums/enums.dart';
import 'package:motaz_app_flutter/core/utils/date_range.dart';
import 'package:motaz_app_flutter/features/invoices/data/invoice_repository.dart';
import 'package:motaz_app_flutter/features/reports/data/report_queries.dart';
import 'package:motaz_app_flutter/features/dashboard/data/dashboard_queries.dart';
import 'package:motaz_app_flutter/features/party_balances/data/party_balance_calculator.dart';
import 'package:motaz_app_flutter/features/profit_distribution/data/profit_engine.dart';

AppDatabase _createInMemoryDatabase() {
  return AppDatabase(
    NativeDatabase.memory(
      setup: (rawDb) {
        rawDb.execute('PRAGMA foreign_keys = ON');
      },
    ),
  );
}

const _deviceId = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
const _clientId = 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12';
const _productId = 'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a13';
final _now = DateTime(2026, 1, 1, 10);
final _januaryRange = DateRange.custom(DateTime(2026, 1, 1), DateTime(2026, 2));

Future<void> _seedDependencies(AppDatabase db) async {
  await db
      .into(db.devices)
      .insert(
        DevicesCompanion(
          id: const Value(_deviceId),
          deviceName: const Value('Test Device'),
          platform: const Value(DevicePlatform.ANDROID),
          deviceCode: const Value('t001'),
          createdAt: Value(_now),
          lastActiveAt: Value(_now),
        ),
      );
  await db
      .into(db.clients)
      .insert(
        ClientsCompanion(
          id: const Value(_clientId),
          displayName: const Value('Test Client'),
          createdAt: Value(_now),
          updatedAt: Value(_now),
          deviceId: const Value(_deviceId),
        ),
      );
  await db
      .into(db.products)
      .insert(
        ProductsCompanion(
          id: const Value(_productId),
          name: const Value('Test Product'),
          defaultSalePrice: const Value(35825000),
          createdAt: Value(_now),
          updatedAt: Value(_now),
          deviceId: const Value(_deviceId),
        ),
      );
}

Future<void> _seedDiscountedInvoice(AppDatabase db) async {
  await InvoiceRepository(db).create(
    clientId: _clientId,
    invoiceDate: DateTime(2026, 1, 20),
    discount: 125000,
    note: 'discounted invoice',
    lines: const [
      SalesInvoiceLinesCompanion(
        productId: Value(_productId),
        quantity: Value(1),
        unitPrice: Value(35825000),
      ),
    ],
    paidAmount: 0,
    deviceId: _deviceId,
  );
}

void main() {
  late AppDatabase db;
  late ReportQueries reports;

  setUp(() async {
    db = _createInMemoryDatabase();
    reports = ReportQueries(db);
    await _seedDependencies(db);
    await _seedDiscountedInvoice(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ReportQueries invoice discounts', () {
    test(
      'today dashboard sales do not subtract an already applied discount',
      () async {
        await db
            .update(db.salesInvoices)
            .write(SalesInvoicesCompanion(invoiceDate: Value(DateTime.now())));
        final dashboard = DashboardQueries(
          db,
          ProfitEngine(db),
          PartyBalanceCalculator(db),
        );
        expect(await dashboard.getTodayNetSales(), 35700000);
      },
    );
    test(
      'monthly reports carry losses and subtract returns while custom periods stay operating-only',
      () async {
        await db
            .into(db.expenses)
            .insert(
              ExpensesCompanion.insert(
                id: 'd0eebc99-9c0b-4ef8-bb6d-6bb9bd380a14',
                category: ExpenseCategory.OPERATIONAL,
                amount: 40000000,
                expenseDate: DateTime(2025, 12, 10),
                createdAt: _now,
                updatedAt: _now,
                deviceId: _deviceId,
              ),
            );
        final invoice = await db.select(db.salesInvoices).getSingle();
        await db
            .into(db.salesReturns)
            .insert(
              SalesReturnsCompanion.insert(
                id: 'e0eebc99-9c0b-4ef8-bb6d-6bb9bd380a15',
                localRef: const Value('RET-test'),
                invoiceId: invoice.id,
                returnDate: DateTime(2026, 1, 21),
                totalReturnedAmount: 1000000,
                createdAt: _now,
                updatedAt: _now,
                deviceId: _deviceId,
              ),
            );
        final queueBefore = (await db.select(db.syncOutbox).get()).length;
        final monthly = await reports.getProfitReport(_januaryRange);
        final finalReport = await reports.getFinalMonthlyReport(
          year: 2026,
          month: 1,
        );
        expect(monthly.netProfit, -5300000);
        expect(monthly.monthlyProfit!.currentMonthLoss, 0);
        expect(monthly.monthlyProfit!.carriedLossIn, -40000000);
        expect(monthly.distribution!.ownerShare, 0);
        expect(finalReport.returns, 1000000);
        expect(finalReport.profit, monthly.netProfit);
        final partial = await reports.getProfitReport(
          DateRange.custom(DateTime(2026, 1, 15), DateTime(2026, 2)),
        );
        expect(partial.netProfit, 34700000);
        expect(partial.monthlyProfit, isNull);
        expect((await db.select(db.syncOutbox).get()).length, queueBefore);
        expect(await db.select(db.monthlyDistributions).get(), isEmpty);
      },
    );
    test('sales report subtracts invoice discounts only once', () async {
      final summary = await reports.getSalesReport(_januaryRange);

      expect(summary.rows.single.total, 35700000);
      expect(summary.rows.single.discount, 125000);
      expect(summary.grossSales, 35825000);
      expect(summary.totalDiscounts, 125000);
      expect(summary.totalReturns, 0);
      expect(summary.netSales, 35700000);
    });

    test(
      'profit report uses gross sales before discount and net sales after it',
      () async {
        final data = await reports.getProfitReport(_januaryRange);

        expect(data.grossSales, 35825000);
        expect(data.discounts, 125000);
        expect(data.returns, 0);
        expect(data.netSales, 35700000);
        expect(data.netProfit, 35700000);
      },
    );

    test('final monthly report totals sales after invoice discounts', () async {
      final data = await reports.getFinalMonthlyReport(year: 2026, month: 1);

      expect(data.productSales.single.totalSales, 35825000);
      expect(data.totalSales, 35700000);
      expect(data.profit, 35700000);
    });
  });
}
