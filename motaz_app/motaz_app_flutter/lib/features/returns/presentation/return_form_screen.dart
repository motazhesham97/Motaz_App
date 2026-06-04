import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/device_service.dart';
import '../../../core/database/enums/parent_entity_type.dart';
import '../../../core/database/enums/record_status.dart';
import '../../../core/utils/document_reference_formatter.dart';
import '../../../features/attachments/application/document_attachment_service.dart';
import '../../../features/attachments/presentation/document_photo_field.dart';
import '../../../features/invoices/application/invoice_providers.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../application/return_providers.dart';

class ReturnFormScreen extends ConsumerStatefulWidget {
  const ReturnFormScreen({super.key, this.invoiceId});

  final String? invoiceId;

  @override
  ConsumerState<ReturnFormScreen> createState() => _ReturnFormScreenState();
}

class _ReturnFormScreenState extends ConsumerState<ReturnFormScreen> {
  String? _selectedInvoiceId;
  DateTime _returnDate = DateTime.now();
  final _noteController = TextEditingController();
  final Map<String, _ReturnLineEntry> _lineEntries = {};
  bool _loading = false;
  bool _saving = false;
  String? _attachmentPath;

  List<SalesInvoiceLine> _invoiceLines = [];
  Map<String, Product> _products = {};
  SalesInvoice? _selectedInvoice;
  String? _selectedInvoiceClientName;

  @override
  void initState() {
    super.initState();
    _selectedInvoiceId = widget.invoiceId;
    if (_selectedInvoiceId != null) {
      _loadInvoiceData();
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadInvoiceData() async {
    if (_selectedInvoiceId == null) return;

    setState(() => _loading = true);

    try {
      final invoiceRepo = ref.read(invoiceRepositoryProvider);
      final db = ref.read(appDatabaseProvider);
      final invoice = await invoiceRepo.getById(_selectedInvoiceId!);
      final lines = await invoiceRepo.getLinesForInvoice(_selectedInvoiceId!);
      final products = await (db.select(db.products)).get();
      final client = await (db.select(
        db.clients,
      )..where((t) => t.id.equals(invoice.clientId))).getSingleOrNull();

      final returnRepo = ref.read(returnRepositoryProvider);
      final returnedQuantities = <String, int>{};
      for (final line in lines) {
        final qty = await returnRepo.getReturnedQuantityForInvoiceLine(line.id);
        returnedQuantities[line.id] = qty;
      }

      setState(() {
        _selectedInvoice = invoice;
        _selectedInvoiceClientName = client?.displayName;
        _invoiceLines = lines;
        _products = {for (final p in products) p.id: p};
        _lineEntries.clear();
        for (final line in lines) {
          final availableQty =
              line.quantity - (returnedQuantities[line.id] ?? 0);
          _lineEntries[line.id] = _ReturnLineEntry(
            invoiceLineId: line.id,
            originalQuantity: line.quantity,
            unitPrice: line.unitPrice,
            alreadyReturned: returnedQuantities[line.id] ?? 0,
            availableQuantity: availableQty,
            returnedQuantity: 0,
            returnedAmount: 0,
            selected: false,
          );
        }
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }

  String _formatMoney(int minorUnits) {
    return '${(minorUnits / 100).toStringAsFixed(2)} ر.ي.';
  }

  void _onQuantityChanged(String lineId, String value) {
    final entry = _lineEntries[lineId];
    if (entry == null) return;

    final qty = int.tryParse(value) ?? 0;
    final maxQty = entry.availableQuantity;
    final validQty = qty.clamp(0, maxQty);
    final autoAmount = validQty * entry.unitPrice;

    setState(() {
      _lineEntries[lineId] = entry.copyWith(
        returnedQuantity: validQty,
        returnedAmount: autoAmount,
      );
    });
  }

  void _onLineSelected(String lineId, bool selected) {
    final entry = _lineEntries[lineId];
    if (entry == null) return;
    final defaultQuantity = selected
        ? (entry.returnedQuantity > 0 ? entry.returnedQuantity : 1)
        : 0;
    final validQuantity = defaultQuantity.clamp(0, entry.availableQuantity);

    setState(() {
      _lineEntries[lineId] = entry.copyWith(
        selected: selected,
        returnedQuantity: validQuantity,
        returnedAmount: validQuantity * entry.unitPrice,
      );
    });
  }

  bool _canSave() {
    if (_selectedInvoiceId == null || _saving) return false;
    if (_selectedInvoice?.status != RecordStatus.ACTIVE) return false;

    final selectedLines = _lineEntries.values.where(
      (e) => e.selected && e.returnedQuantity > 0,
    );
    if (selectedLines.isEmpty) return false;

    for (final line in selectedLines) {
      if (line.returnedQuantity <= 0) return false;
      if (line.returnedAmount <= 0) return false;
      if (line.returnedQuantity > line.availableQuantity) return false;
      if (line.returnedAmount > line.returnedQuantity * line.unitPrice) {
        return false;
      }
    }

    return true;
  }

  Future<void> _save() async {
    if (!_canSave()) return;

    setState(() => _saving = true);

    try {
      final device = await ref
          .read(deviceServiceProvider)
          .ensureCurrentDevice();
      final returnRepo = ref.read(returnRepositoryProvider);

      final lines = _lineEntries.values
          .where((e) => e.selected && e.returnedQuantity > 0)
          .map(
            (e) => (
              invoiceLineId: e.invoiceLineId,
              returnedQuantity: e.returnedQuantity,
              returnedAmount: e.returnedAmount,
            ),
          )
          .toList();

      final created = await returnRepo.create(
        invoiceId: _selectedInvoiceId!,
        returnDate: _returnDate,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        lines: lines,
        deviceId: device.id,
      );

      await _stageReturnPhoto(created.id);

      if (mounted) {
        ref.invalidate(returnListProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء المرتجع بنجاح')),
        );
        context.go('/returns');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _captureReturnPhoto() async {
    final path = await ref
        .read(documentAttachmentServiceProvider)
        .captureDocumentPhoto(context);
    if (path != null && mounted) {
      setState(() => _attachmentPath = path);
    }
  }

  Future<void> _stageReturnPhoto(String returnId) async {
    final path = _attachmentPath;
    if (path == null) return;
    await ref
        .read(documentAttachmentServiceProvider)
        .stagePhoto(
          parentEntityType: ParentEntityType.SALES_RETURN,
          parentEntityId: returnId,
          localFilePath: path,
        );
  }

  Future<void> _selectInvoice() async {
    final invoices = await ref.read(invoiceRepositoryProvider).watchAll().first;
    final activeInvoices = invoices
        .where((i) => i.status == RecordStatus.ACTIVE)
        .toList();
    final db = ref.read(appDatabaseProvider);
    final clients = await (db.select(db.clients)).get();
    final clientMap = {for (final client in clients) client.id: client};

    if (!mounted) return;

    final selected = await showDialog<SalesInvoice>(
      context: context,
      builder: (context) {
        var query = '';

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredInvoices = activeInvoices.where((invoice) {
              final normalizedQuery = query.trim().toLowerCase();
              if (normalizedQuery.isEmpty) return true;
              final clientName =
                  clientMap[invoice.clientId]?.displayName.toLowerCase() ?? '';
              return invoice.localRef.toLowerCase().contains(normalizedQuery) ||
                  clientName.contains(normalizedQuery);
            }).toList();

            return AlertDialog(
              title: const Text('اختر فاتورة'),
              content: SizedBox(
                width: double.maxFinite,
                height: 460,
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'بحث برقم الفاتورة أو اسم العميل',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setDialogState(() => query = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filteredInvoices.isEmpty
                          ? const Center(child: Text('لا توجد فواتير مطابقة'))
                          : ListView.builder(
                              itemCount: filteredInvoices.length,
                              itemBuilder: (context, index) {
                                final inv = filteredInvoices[index];
                                final clientName =
                                    clientMap[inv.clientId]?.displayName ??
                                    'عميل غير معروف';
                                return ListTile(
                                  title: Text(
                                    invoiceDisplayRef(
                                      inv.localRef,
                                      officialNo: inv.officialNo,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '$clientName - ${_formatMoney(inv.total)} - ${inv.invoiceDate.year}-${inv.invoiceDate.month.toString().padLeft(2, '0')}-${inv.invoiceDate.day.toString().padLeft(2, '0')}',
                                  ),
                                  onTap: () => Navigator.of(context).pop(inv),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('إلغاء'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedInvoiceId = selected.id;
        _selectedInvoice = null;
        _selectedInvoiceClientName = clientMap[selected.clientId]?.displayName;
        _invoiceLines = [];
        _lineEntries.clear();
      });
      _loadInvoiceData();
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _returnDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _returnDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDrawerScaffold(
      title: 'إنشاء مرتجع',
      currentRoute: '/returns/create',
      leading: IconButton(
        tooltip: 'الرجوع للمرتجعات',
        icon: const BackButtonIcon(),
        onPressed: () => context.go('/returns'),
      ),
      child: Scaffold(
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInvoiceSelector(),
                    if (_selectedInvoice != null) ...[
                      const SizedBox(height: 16),
                      _buildInvoiceInfo(),
                      const SizedBox(height: 16),
                      _buildLinesSection(),
                      const SizedBox(height: 16),
                      _buildDateField(),
                      const SizedBox(height: 12),
                      _buildNoteField(),
                      const SizedBox(height: 12),
                      DocumentPhotoField(
                        label: 'إضافة صورة المرتجع',
                        localPath: _attachmentPath,
                        onCapture: _captureReturnPhoto,
                        onRemove: () => setState(() => _attachmentPath = null),
                      ),
                      const SizedBox(height: 24),
                      _buildSaveButton(),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInvoiceSelector() {
    final selectedInvoice = _selectedInvoice;
    return InkWell(
      onTap: widget.invoiceId == null ? _selectInvoice : null,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'الفاتورة',
          suffixIcon: Icon(Icons.receipt_long),
        ),
        child: selectedInvoice == null
            ? const Text('اضغط لاختيار فاتورة')
            : Text(
                '${invoiceDisplayRef(selectedInvoice.localRef, officialNo: selectedInvoice.officialNo)} - ${_selectedInvoiceClientName ?? 'عميل غير معروف'}',
              ),
      ),
    );
  }

  Widget _buildInvoiceInfo() {
    final invoice = _selectedInvoice!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('إجمالي الفاتورة: ${_formatMoney(invoice.total)}'),
            Text('العميل: ${_selectedInvoiceClientName ?? 'عميل غير معروف'}'),
            Text(
              'تاريخ الفاتورة: ${invoice.invoiceDate.year}-${invoice.invoiceDate.month.toString().padLeft(2, '0')}-${invoice.invoiceDate.day.toString().padLeft(2, '0')}',
            ),
            if (invoice.status != RecordStatus.ACTIVE)
              Text(
                invoice.status == RecordStatus.VOIDED ? 'ملغاة' : 'غير نشطة',
                style: const TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'بنود الفاتورة',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'اختر فقط البنود التي تريد إرجاعها، ثم عدل الكمية المرتجعة لكل بند.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        ..._invoiceLines.map((line) {
          final product = _products[line.productId];
          final entry = _lineEntries[line.id];
          if (entry == null) return const SizedBox.shrink();

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: entry.selected,
                        onChanged: entry.availableQuantity > 0
                            ? (v) => _onLineSelected(line.id, v ?? false)
                            : null,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product?.name ?? 'منتج غير معروف',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text('الكمية الأصلية: ${line.quantity}'),
                            Text('السعر: ${_formatMoney(line.unitPrice)}'),
                            if (entry.alreadyReturned > 0)
                              Text('المرتجع سابقاً: ${entry.alreadyReturned}'),
                            Text(
                              'المتاح للإرجاع: ${entry.availableQuantity}',
                              style: TextStyle(
                                color: entry.availableQuantity > 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (entry.selected) ...[
                    const Divider(),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            key: ValueKey(
                              'return_qty_${line.id}_${entry.selected}',
                            ),
                            decoration: const InputDecoration(
                              labelText: 'الكمية المرتجعة',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            selectAllOnFocus: true,
                            initialValue: entry.returnedQuantity.toString(),
                            onChanged: (v) => _onQuantityChanged(line.id, v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            key: ValueKey(
                              'return_amount_${line.id}_${entry.returnedAmount}',
                            ),
                            decoration: const InputDecoration(
                              labelText: 'المبلغ',
                              border: OutlineInputBorder(),
                              suffixText: 'ر.ي.',
                            ),
                            readOnly: true,
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            initialValue: (entry.returnedAmount / 100)
                                .toStringAsFixed(2),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'الحد الأقصى: ${_formatMoney(entry.returnedQuantity * entry.unitPrice)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'تاريخ المرتجع',
          suffixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          '${_returnDate.year}-${_returnDate.month.toString().padLeft(2, '0')}-${_returnDate.day.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }

  Widget _buildNoteField() {
    return TextField(
      controller: _noteController,
      decoration: const InputDecoration(
        labelText: 'ملاحظة',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
    );
  }

  Widget _buildSaveButton() {
    return FilledButton(
      onPressed: _canSave() && !_saving ? _save : null,
      child: _saving
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.surface,
              ),
            )
          : const Text('حفظ المرتجع'),
    );
  }
}

class _ReturnLineEntry {
  final String invoiceLineId;
  final int originalQuantity;
  final int unitPrice;
  final int alreadyReturned;
  final int availableQuantity;
  final int returnedQuantity;
  final int returnedAmount;
  final bool selected;

  _ReturnLineEntry({
    required this.invoiceLineId,
    required this.originalQuantity,
    required this.unitPrice,
    required this.alreadyReturned,
    required this.availableQuantity,
    required this.returnedQuantity,
    required this.returnedAmount,
    required this.selected,
  });

  _ReturnLineEntry copyWith({
    String? invoiceLineId,
    int? originalQuantity,
    int? unitPrice,
    int? alreadyReturned,
    int? availableQuantity,
    int? returnedQuantity,
    int? returnedAmount,
    bool? selected,
  }) {
    return _ReturnLineEntry(
      invoiceLineId: invoiceLineId ?? this.invoiceLineId,
      originalQuantity: originalQuantity ?? this.originalQuantity,
      unitPrice: unitPrice ?? this.unitPrice,
      alreadyReturned: alreadyReturned ?? this.alreadyReturned,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      returnedQuantity: returnedQuantity ?? this.returnedQuantity,
      returnedAmount: returnedAmount ?? this.returnedAmount,
      selected: selected ?? this.selected,
    );
  }
}
