import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/device_service.dart';
import '../../../core/database/enums/parent_entity_type.dart';
import '../../../core/database/enums/record_status.dart';
import '../../../core/utils/document_reference_formatter.dart';
import '../../attachments/application/document_attachment_reader.dart';
import '../application/invoice_providers.dart';
import '../../clients/application/client_providers.dart';
import '../../receipts/presentation/receipt_form_screen.dart';
import 'invoice_form_screen.dart';

class InvoiceDetailScreen extends ConsumerStatefulWidget {
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  final String invoiceId;

  @override
  ConsumerState<InvoiceDetailScreen> createState() =>
      _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  SalesInvoice? _invoice;
  List<SalesInvoiceLine> _lines = [];
  List<Receipt> _receipts = [];
  Client? _client;
  int _collectedAmount = 0;
  int _returnAmount = 0;
  int _remainingBalance = 0;
  bool _hasReceipts = false;
  bool _hasReturns = false;
  bool _loading = true;
  Map<String, String> _productNames = {};
  List<Uint8List> _attachmentImages = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final repo = ref.read(invoiceRepositoryProvider);
    final clientRepo = ref.read(clientRepositoryProvider);
    try {
      final invoice = await repo.getById(widget.invoiceId);
      final lines = await repo.getLinesForInvoice(widget.invoiceId);
      final receipts = await repo.getReceiptsForInvoice(widget.invoiceId);
      final collected = await repo.getCollectedAmount(widget.invoiceId);
      final returned = await repo.getActiveReturnTotal(widget.invoiceId);
      final remaining = await repo.getRemainingBalance(widget.invoiceId);
      final hasR = await repo.hasActiveReceipts(widget.invoiceId);
      final hasRet = await repo.hasActiveReturns(widget.invoiceId);
      final attachments = await ref
          .read(documentAttachmentReaderProvider)
          .loadImages(
            parentEntityType: ParentEntityType.SALES_INVOICE,
            parentEntityId: widget.invoiceId,
          );

      Client? client;
      try {
        client = await clientRepo.getById(invoice.clientId);
      } catch (_) {
        client = null;
      }

      final db = ref.read(appDatabaseProvider);
      final products = await (db.select(db.products)).get();
      final pMap = {for (final p in products) p.id: p.name};

      if (mounted) {
        setState(() {
          _invoice = invoice;
          _lines = lines;
          _receipts = receipts;
          _collectedAmount = collected;
          _returnAmount = returned;
          _remainingBalance = remaining;
          _hasReceipts = hasR;
          _hasReturns = hasRet;
          _client = client;
          _productNames = pMap;
          _attachmentImages = attachments;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _formatMoney(int minorUnits) {
    return '${(minorUnits / 100).toStringAsFixed(2)} ر.ي.';
  }

  Future<void> _voidInvoice(String reason) async {
    final device = await ref.read(deviceServiceProvider).ensureCurrentDevice();
    final repo = ref.read(invoiceRepositoryProvider);
    await repo.voidInvoice(widget.invoiceId, reason, device.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إلغاء الفاتورة')),
      );
      _loadData();
    }
  }

  Future<void> _showVoidDialog() async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إلغاء الفاتورة'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'سبب الإلغاء *',
            hintText: 'أدخل سبب الإلغاء',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('تراجع'),
          ),
          TextButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('سبب الإلغاء مطلوب')),
                );
                return;
              }
              Navigator.of(context).pop(true);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('إلغاء الفاتورة'),
          ),
        ],
      ),
    );

    final reason = reasonController.text.trim();
    reasonController.dispose();

    if (confirmed == true && reason.isNotEmpty) {
      _voidInvoice(reason);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الفاتورة')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final invoice = _invoice!;
    final isActive = invoice.status == RecordStatus.ACTIVE;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          invoiceDisplayRef(invoice.localRef, officialNo: invoice.officialNo),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'معلومات الفاتورة',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (_client != null)
                      Text('العميل: ${_client!.displayName}'),
                    Text(
                      'التاريخ: ${invoice.invoiceDate.year}-${invoice.invoiceDate.month.toString().padLeft(2, '0')}-${invoice.invoiceDate.day.toString().padLeft(2, '0')}',
                    ),
                    if (invoice.note != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('ملاحظة: ${invoice.note}'),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('الحالة: '),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'نشطة',
                              style: TextStyle(color: Colors.green),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'ملغية${invoice.voidReason != null ? ' - ${invoice.voidReason}' : ''}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'البنود',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ..._lines.map(_buildInvoiceLine),
                    if (invoice.discount > 0) ...[
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('الخصم:'),
                            Text(_formatMoney(invoice.discount)),
                          ],
                        ),
                      ),
                    ],
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'الإجمالي:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            _formatMoney(invoice.total),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'المدفوعات والمرتجعات',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (_receipts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('لا توجد دفعات'),
                      )
                    else
                      ..._receipts.map(
                        (r) => ListTile(
                          dense: true,
                          title: Text(
                            receiptDisplayRef(
                              r.localRef,
                              officialNo: r.officialNo,
                            ),
                          ),
                          subtitle: Text(
                            '${_formatMoney(r.amount)} - ${r.receiptDate.year}-${r.receiptDate.month.toString().padLeft(2, '0')}-${r.receiptDate.day.toString().padLeft(2, '0')}',
                          ),
                        ),
                      ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('المحصل:'),
                          Text(_formatMoney(_collectedAmount)),
                        ],
                      ),
                    ),
                    if (_returnAmount > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('المرتجع:'),
                            Text(
                              _formatMoney(_returnAmount),
                              style: const TextStyle(color: Colors.orange),
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('المبلغ المتبقي:'),
                          Text(
                            _formatMoney(_remainingBalance),
                            style: TextStyle(
                              color: _remainingBalance > 0
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_attachmentImages.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildAttachmentSection(),
            ],
            if (isActive) ...[
              const SizedBox(height: 16),
              _buildActionButtons(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceLine(SalesInvoiceLine line) {
    final name = _productNames[line.productId] ?? 'منتج غير معروف';
    return InvoiceLineCard(
      line: line,
      productName: name,
      formatMoney: _formatMoney,
    );
  }

  Widget _buildAttachmentSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'صورة الفاتورة',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ..._attachmentImages.map(
              (bytes) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(bytes, fit: BoxFit.contain),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final buttons = <Widget>[
      OutlinedButton.icon(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InvoiceFormScreen(
                existingInvoice: _invoice,
                existingLines: _lines,
                hasReceipts: _hasReceipts,
                hasReturns: _hasReturns,
                collectedAmount: _collectedAmount,
              ),
            ),
          );
          if (mounted) _loadData();
        },
        icon: const Icon(Icons.edit),
        label: const Text('تعديل'),
      ),
      OutlinedButton.icon(
        onPressed: () {
          context.go('/returns/create?invoiceId=${widget.invoiceId}');
        },
        icon: const Icon(Icons.assignment_return),
        label: const Text('إنشاء مرتجع'),
      ),
      if (_remainingBalance > 0)
        OutlinedButton.icon(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReceiptFormScreen(
                  invoiceId: widget.invoiceId,
                  clientId: _invoice!.clientId,
                  maxAmount: _remainingBalance,
                ),
              ),
            );
            if (mounted) _loadData();
          },
          icon: const Icon(Icons.add_card),
          label: const Text('إضافة دفعة'),
        ),
      OutlinedButton.icon(
        onPressed: _showVoidDialog,
        icon: const Icon(Icons.cancel),
        label: const Text('إلغاء الفاتورة'),
        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
      ),
    ];

    return InvoiceDetailActionButtonsLayout(buttons: buttons);
  }
}

class InvoiceLineCard extends StatelessWidget {
  const InvoiceLineCard({
    super.key,
    required this.line,
    required this.productName,
    required this.formatMoney,
  });

  final SalesInvoiceLine line;
  final String productName;
  final String Function(int minorUnits) formatMoney;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                productName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  Text('الكمية: ${line.quantity}'),
                  Text('السعر: ${formatMoney(line.unitPrice)}'),
                  Text(
                    'الإجمالي: ${formatMoney(line.lineTotal)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InvoiceDetailActionButtonsLayout extends StatelessWidget {
  const InvoiceDetailActionButtonsLayout({super.key, required this.buttons});

  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final button in buttons) ...[
                SizedBox(height: 48, child: button),
                if (button != buttons.last) const SizedBox(height: 8),
              ],
            ],
          );
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            for (final button in buttons)
              SizedBox(width: 190, height: 46, child: button),
          ],
        );
      },
    );
  }
}
