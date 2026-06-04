import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/enums/audit_operation.dart';
import '../../../core/database/enums/parent_entity_type.dart';
import '../../../core/database/enums/record_status.dart';
import '../../../core/database/enums/sync_outbox_status.dart';
import '../../../features/returns/data/return_repository.dart';
import 'follow_up_task.dart';

class FollowUpRepository {
  FollowUpRepository(this._db, this._returnRepository);

  final AppDatabase _db;
  final ReturnRepository _returnRepository;
  final _uuid = const Uuid();

  Stream<List<FollowUpTask>> watchTasks() {
    return _db
        .customSelect(
          'SELECT 1 AS marker',
          readsFrom: {
            _db.clients,
            _db.products,
            _db.salesInvoices,
            _db.salesInvoiceLines,
            _db.receipts,
            _db.receiptAllocations,
            _db.salesReturns,
            _db.salesReturnLines,
          },
        )
        .watch()
        .asyncMap((_) => loadTasks());
  }

  Future<List<FollowUpTask>> loadTasks() async {
    final tasks = <FollowUpTask>[];
    tasks.addAll(await _loadCreditLimitTasks());
    tasks.addAll(await _loadInvoiceGapTasks());
    tasks.addAll(await _loadExpiredProductTasks());
    tasks.sort((a, b) {
      final priority = b.priority.compareTo(a.priority);
      if (priority != 0) return priority;
      return a.clientName.compareTo(b.clientName);
    });
    return tasks;
  }

  Future<void> renewProductionDate({
    required String invoiceLineId,
    required DateTime productionDate,
    required String deviceId,
  }) async {
    final row = await _db
        .customSelect(
          'SELECT * FROM sales_invoice_lines WHERE id = ? LIMIT 1',
          variables: [Variable(invoiceLineId)],
        )
        .getSingleOrNull();
    if (row == null) {
      throw StateError('Invoice line not found');
    }

    final now = DateTime.now();
    final createdAt = _readDate(row, 'created_at') ?? now;

    await _db.transaction(() async {
      await _db.customStatement(
        'UPDATE sales_invoice_lines '
        'SET production_date = ?, updated_at = ? '
        'WHERE id = ?',
        [
          productionDate.millisecondsSinceEpoch ~/ 1000,
          now.millisecondsSinceEpoch ~/ 1000,
          invoiceLineId,
        ],
      );

      final payload = jsonEncode({
        'id': invoiceLineId,
        'invoiceId': row.data['invoice_id'],
        'productId': row.data['product_id'],
        'quantity': row.data['quantity'],
        'unitPrice': row.data['unit_price'],
        'lineTotal': row.data['line_total'],
        'productionDate': productionDate.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      });

      await _db
          .into(_db.syncOutbox)
          .insert(
            SyncOutboxCompanion.insert(
              id: _uuid.v4(),
              entityType: ParentEntityType.SALES_INVOICE_LINE,
              entityId: invoiceLineId,
              operation: AuditOperation.UPDATE,
              payload: payload,
              rowVersion: 1,
              deviceId: deviceId,
              createdAt: now,
              status: Value(SyncOutboxStatus.PENDING),
            ),
          );
    });
  }

  Future<SalesReturn> createExpiredProductReturn({
    required String invoiceLineId,
    required String deviceId,
  }) async {
    final line = await (_db.select(
      _db.salesInvoiceLines,
    )..where((t) => t.id.equals(invoiceLineId))).getSingleOrNull();
    if (line == null) {
      throw StateError('Invoice line not found');
    }

    final returnedQuantity = await _returnRepository
        .getReturnedQuantityForInvoiceLine(invoiceLineId);
    final availableQuantity = line.quantity - returnedQuantity;
    if (availableQuantity <= 0) {
      throw StateError('No remaining quantity available for return');
    }

    final product = await (_db.select(
      _db.products,
    )..where((t) => t.id.equals(line.productId))).getSingleOrNull();
    final note = product == null
        ? 'مرتجع تلقائي من مهمة متابعة منتج منتهي الصلاحية'
        : 'مرتجع تلقائي من مهمة متابعة صلاحية المنتج: ${product.name}';

    return _returnRepository.create(
      invoiceId: line.invoiceId,
      returnDate: DateTime.now(),
      note: note,
      lines: [
        (
          invoiceLineId: invoiceLineId,
          returnedQuantity: availableQuantity,
          returnedAmount: availableQuantity * line.unitPrice,
        ),
      ],
      deviceId: deviceId,
    );
  }

  Future<List<FollowUpTask>> _loadCreditLimitTasks() async {
    final rows = await _db
        .customSelect(
          '''
SELECT *
FROM (
  SELECT
    c.id AS client_id,
    c.display_name AS client_name,
    c.credit_limit AS credit_limit,
    COALESCE((
      SELECT SUM(total)
      FROM sales_invoices
      WHERE client_id = c.id AND status = ?
    ), 0)
    - COALESCE((
      SELECT SUM(amount)
      FROM receipts
      WHERE client_id = c.id AND status = ?
    ), 0)
    - COALESCE((
      SELECT SUM(sr.total_returned_amount)
      FROM sales_returns sr
      INNER JOIN sales_invoices si ON si.id = sr.invoice_id
      WHERE si.client_id = c.id AND sr.status = ?
    ), 0) AS balance
  FROM clients c
  WHERE c.is_active = 1
    AND c.credit_limit IS NOT NULL
    AND c.credit_limit > 0
) ranked
WHERE balance >= credit_limit
''',
          variables: [
            Variable(RecordStatus.ACTIVE.index),
            Variable(RecordStatus.ACTIVE.index),
            Variable(RecordStatus.ACTIVE.index),
          ],
        )
        .get();

    return rows.map((row) {
      final clientName = row.read<String>('client_name');
      final balance = row.read<int>('balance');
      final limit = row.read<int>('credit_limit');
      return FollowUpTask(
        type: FollowUpTaskType.creditLimit,
        clientId: row.read<String>('client_id'),
        clientName: clientName,
        title: 'تنبيه رصيد عميل',
        message:
            '$clientName وصل إلى حد الرصيد المتبقي. الرصيد الحالي ${_money(balance)} والحد ${_money(limit)}.',
        priority: 3,
        amount: balance,
        limit: limit,
      );
    }).toList();
  }

  Future<List<FollowUpTask>> _loadInvoiceGapTasks() async {
    final rows = await _db
        .customSelect(
          '''
SELECT
  c.id AS client_id,
  c.display_name AS client_name,
  c.invoice_check_interval_days AS interval_days,
  MAX(si.invoice_date) AS last_invoice_date
FROM clients c
LEFT JOIN sales_invoices si
  ON si.client_id = c.id AND si.status = ?
WHERE c.is_active = 1
  AND c.invoice_check_interval_days IS NOT NULL
  AND c.invoice_check_interval_days > 0
GROUP BY c.id, c.display_name, c.invoice_check_interval_days
''',
          variables: [Variable(RecordStatus.ACTIVE.index)],
        )
        .get();

    final now = DateTime.now();
    final tasks = <FollowUpTask>[];
    for (final row in rows) {
      final lastInvoiceDate = _readDate(row, 'last_invoice_date');
      final intervalDays = row.read<int>('interval_days');
      final days = lastInvoiceDate == null
          ? intervalDays
          : now.difference(lastInvoiceDate).inDays;
      if (days < intervalDays) continue;

      final clientName = row.read<String>('client_name');
      final message = lastInvoiceDate == null
          ? '$clientName لا توجد له فاتورة، ومدة المتابعة المحددة $intervalDays يوم.'
          : '$clientName مر على آخر فاتورة له $days يوم. راجع البضاعة معه أو تواصل معه.';
      tasks.add(
        FollowUpTask(
          type: FollowUpTaskType.invoiceGap,
          clientId: row.read<String>('client_id'),
          clientName: clientName,
          title: 'متابعة عميل بدون فاتورة جديدة',
          message: message,
          priority: 2,
          daysCount: days,
        ),
      );
    }
    return tasks;
  }

  Future<List<FollowUpTask>> _loadExpiredProductTasks() async {
    final rows = await _db
        .customSelect(
          '''
SELECT *
FROM (
  SELECT
    sil.id AS line_id,
    sil.invoice_id AS invoice_id,
    sil.product_id AS product_id,
    sil.quantity AS quantity,
    sil.unit_price AS unit_price,
    sil.quantity - COALESCE((
      SELECT SUM(srl.returned_quantity)
      FROM sales_return_lines srl
      INNER JOIN sales_returns line_sr ON line_sr.id = srl.return_id
      WHERE srl.invoice_line_id = sil.id AND line_sr.status = ?
    ), 0) AS remaining_quantity,
    sil.production_date AS production_date,
    si.local_ref AS invoice_ref,
    si.total
      - COALESCE((
        SELECT SUM(ra.allocated_amount)
        FROM receipt_allocations ra
        INNER JOIN receipts r ON r.id = ra.receipt_id
        WHERE ra.invoice_id = si.id AND r.status = ?
      ), 0)
      - COALESCE((
        SELECT SUM(total_returned_amount)
        FROM sales_returns
        WHERE invoice_id = si.id AND status = ?
      ), 0) AS remaining_balance,
    c.id AS client_id,
    c.display_name AS client_name,
    p.name AS product_name,
    p.shelf_life_days AS shelf_life_days
  FROM sales_invoice_lines sil
  INNER JOIN sales_invoices si ON si.id = sil.invoice_id
  INNER JOIN clients c ON c.id = si.client_id
  INNER JOIN products p ON p.id = sil.product_id
  WHERE si.status = ?
    AND p.shelf_life_days IS NOT NULL
    AND p.shelf_life_days > 0
    AND sil.production_date IS NOT NULL
) line_status
WHERE remaining_balance > 0
  AND remaining_quantity > 0
''',
          variables: [
            Variable(RecordStatus.ACTIVE.index),
            Variable(RecordStatus.ACTIVE.index),
            Variable(RecordStatus.ACTIVE.index),
            Variable(RecordStatus.ACTIVE.index),
          ],
        )
        .get();

    final now = DateTime.now();
    final tasks = <FollowUpTask>[];
    for (final row in rows) {
      final productionDate = _readDate(row, 'production_date');
      if (productionDate == null) continue;
      final shelfLifeDays = row.read<int>('shelf_life_days');
      final expiryDate = productionDate.add(Duration(days: shelfLifeDays));
      final expiredDays = now.difference(expiryDate).inDays;
      if (expiredDays < 0) continue;

      final clientName = row.read<String>('client_name');
      final productName = row.read<String>('product_name');
      final invoiceRef = row.read<String>('invoice_ref');
      tasks.add(
        FollowUpTask(
          type: FollowUpTaskType.expiredProduct,
          clientId: row.read<String>('client_id'),
          clientName: clientName,
          title: 'منتج منتهي الصلاحية عند عميل',
          message:
              '$productName في فاتورة $invoiceRef للعميل $clientName انتهت صلاحيته منذ ${expiredDays + 1} يوم.',
          priority: 4,
          daysCount: expiredDays + 1,
          invoiceId: row.read<String>('invoice_id'),
          invoiceRef: invoiceRef,
          invoiceLineId: row.read<String>('line_id'),
          productId: row.read<String>('product_id'),
          productName: productName,
          quantity: row.read<int>('remaining_quantity'),
          unitPrice: row.read<int>('unit_price'),
          amount:
              row.read<int>('remaining_quantity') * row.read<int>('unit_price'),
          productionDate: productionDate,
          expiryDate: expiryDate,
        ),
      );
    }
    return tasks;
  }

  DateTime? _readDate(QueryRow row, String column) {
    final value = row.data[column];
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _money(int minorUnits) {
    return (minorUnits / 100).toStringAsFixed(2);
  }
}
