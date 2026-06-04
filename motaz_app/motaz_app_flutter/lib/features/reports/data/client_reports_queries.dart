import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/enums/record_status.dart';
import '../../../core/utils/date_range.dart';
import 'report_models.dart';

class ClientReportsQueries {
  ClientReportsQueries(this._db);

  final AppDatabase _db;

  Future<ClientReceivablesReportData> getReceivablesReport({
    required DateRange range,
    String? clientId,
    String? clientName,
  }) async {
    final whereClient = clientId == null ? '' : 'AND c.id = ?';
    final variables = <Variable>[
      Variable(RecordStatus.ACTIVE.index),
      Variable<DateTime>(range.start),
      Variable<DateTime>(range.end),
      Variable(RecordStatus.ACTIVE.index),
      Variable<DateTime>(range.start),
      Variable<DateTime>(range.end),
      Variable(RecordStatus.ACTIVE.index),
      Variable<DateTime>(range.start),
      Variable<DateTime>(range.end),
      if (clientId != null) Variable(clientId),
    ];

    final rows = await _db.customSelect(
      '''
SELECT
  c.id AS client_id,
  c.display_name AS client_name,
  COALESCE(inv.total_invoiced, 0) AS total_invoiced,
  COALESCE(pay.total_paid, 0) AS total_paid,
  COALESCE(ret.total_returned, 0) AS total_returned,
  COALESCE(inv.total_invoiced, 0)
    - COALESCE(pay.total_paid, 0)
    - COALESCE(ret.total_returned, 0) AS remaining_balance
FROM clients c
LEFT JOIN (
  SELECT client_id, SUM(total) AS total_invoiced
  FROM sales_invoices
  WHERE status = ? AND invoice_date >= ? AND invoice_date < ?
  GROUP BY client_id
) inv ON inv.client_id = c.id
LEFT JOIN (
  SELECT client_id, SUM(amount) AS total_paid
  FROM receipts
  WHERE status = ? AND receipt_date >= ? AND receipt_date < ?
  GROUP BY client_id
) pay ON pay.client_id = c.id
LEFT JOIN (
  SELECT si.client_id, SUM(sr.total_returned_amount) AS total_returned
  FROM sales_returns sr
  JOIN sales_invoices si ON si.id = sr.invoice_id
  WHERE sr.status = ? AND sr.return_date >= ? AND sr.return_date < ?
  GROUP BY si.client_id
) ret ON ret.client_id = c.id
WHERE (
  COALESCE(inv.total_invoiced, 0) != 0
  OR COALESCE(pay.total_paid, 0) != 0
  OR COALESCE(ret.total_returned, 0) != 0
  OR COALESCE(inv.total_invoiced, 0)
    - COALESCE(pay.total_paid, 0)
    - COALESCE(ret.total_returned, 0) != 0
)
$whereClient
ORDER BY remaining_balance DESC, c.display_name ASC
''',
      variables: variables,
    ).get();

    final reportRows = rows
        .map(
          (row) => ReceivablesRow(
            clientId: row.read<String>('client_id'),
            clientName: row.read<String>('client_name'),
            totalInvoiced: row.read<int>('total_invoiced'),
            totalPaid: row.read<int>('total_paid'),
            totalReturned: row.read<int>('total_returned'),
            remainingBalance: row.read<int>('remaining_balance'),
          ),
        )
        .toList();

    return ClientReceivablesReportData(
      dateRange: range,
      filterLabel: clientName == null || clientName.trim().isEmpty
          ? 'كل العملاء'
          : clientName.trim(),
      rows: reportRows,
      totalInvoiced: reportRows.fold(0, (sum, row) => sum + row.totalInvoiced),
      totalPaid: reportRows.fold(0, (sum, row) => sum + row.totalPaid),
      totalReturned: reportRows.fold(0, (sum, row) => sum + row.totalReturned),
      totalRemaining: reportRows.fold(
        0,
        (sum, row) => sum + row.remainingBalance,
      ),
    );
  }

  Future<ClientProductSalesReportData> getClientProductSalesReport({
    required String clientId,
    required String clientName,
    required DateRange range,
    String? productQuery,
  }) async {
    final rows = await _db
        .customSelect(
          '''
SELECT
  movements.product_id AS product_id,
  p.name AS product_name,
  COALESCE(SUM(movements.sold_quantity), 0) AS total_quantity_sold,
  COALESCE(SUM(movements.returned_quantity), 0) AS total_quantity_returned,
  COALESCE(SUM(movements.sold_quantity), 0)
    - COALESCE(SUM(movements.returned_quantity), 0) AS net_quantity,
  COALESCE(SUM(movements.sales_amount), 0) AS total_sales,
  COALESCE(SUM(movements.return_amount), 0) AS total_returns,
  COALESCE(SUM(movements.sales_amount), 0)
    - COALESCE(SUM(movements.return_amount), 0) AS net_sales
FROM (
  SELECT
    sil.product_id AS product_id,
    sil.quantity AS sold_quantity,
    0 AS returned_quantity,
    sil.line_total AS sales_amount,
    0 AS return_amount
  FROM sales_invoice_lines sil
  JOIN sales_invoices si ON si.id = sil.invoice_id
  WHERE si.status = ?
    AND si.client_id = ?
    AND si.invoice_date >= ?
    AND si.invoice_date < ?
  UNION ALL
  SELECT
    sil.product_id AS product_id,
    0 AS sold_quantity,
    srl.returned_quantity AS returned_quantity,
    0 AS sales_amount,
    srl.returned_amount AS return_amount
  FROM sales_return_lines srl
  JOIN sales_returns sr ON sr.id = srl.return_id
  JOIN sales_invoice_lines sil ON sil.id = srl.invoice_line_id
  JOIN sales_invoices si ON si.id = sr.invoice_id
  WHERE sr.status = ?
    AND si.client_id = ?
    AND sr.return_date >= ?
    AND sr.return_date < ?
) movements
JOIN products p ON p.id = movements.product_id
GROUP BY movements.product_id, p.name
ORDER BY net_sales DESC, p.name ASC
''',
          variables: [
            Variable(RecordStatus.ACTIVE.index),
            Variable(clientId),
            Variable<DateTime>(range.start),
            Variable<DateTime>(range.end),
            Variable(RecordStatus.ACTIVE.index),
            Variable(clientId),
            Variable<DateTime>(range.start),
            Variable<DateTime>(range.end),
          ],
        )
        .get();

    final query = productQuery?.trim().toLowerCase() ?? '';
    final reportRows = rows
        .map(
          (row) => ClientProductSalesRow(
            productId: row.read<String>('product_id'),
            productName: row.read<String>('product_name'),
            totalQuantitySold: row.read<int>('total_quantity_sold'),
            totalQuantityReturned: row.read<int>('total_quantity_returned'),
            netQuantity: row.read<int>('net_quantity'),
            totalSales: row.read<int>('total_sales'),
            totalReturns: row.read<int>('total_returns'),
            netSales: row.read<int>('net_sales'),
          ),
        )
        .where(
          (row) => query.isEmpty || _matchesWordPrefix(row.productName, query),
        )
        .toList();

    return ClientProductSalesReportData(
      clientId: clientId,
      clientName: clientName,
      dateRange: range,
      filterLabel: query.isEmpty ? 'كل المنتجات' : query,
      rows: reportRows,
      totalQuantitySold: reportRows.fold(
        0,
        (sum, row) => sum + row.totalQuantitySold,
      ),
      totalQuantityReturned: reportRows.fold(
        0,
        (sum, row) => sum + row.totalQuantityReturned,
      ),
      netQuantity: reportRows.fold(0, (sum, row) => sum + row.netQuantity),
      totalSales: reportRows.fold(0, (sum, row) => sum + row.totalSales),
      totalReturns: reportRows.fold(0, (sum, row) => sum + row.totalReturns),
      netSales: reportRows.fold(0, (sum, row) => sum + row.netSales),
    );
  }

  bool _matchesWordPrefix(String value, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return true;
    final terms = normalizedQuery.split(RegExp(r'\s+'));
    final words = value
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    return terms.every((term) => words.any((word) => word.startsWith(term)));
  }
}
