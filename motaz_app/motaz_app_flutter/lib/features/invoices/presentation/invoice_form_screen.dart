import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/device_service.dart';
import '../../../core/database/enums/parent_entity_type.dart';
import '../../../core/utils/money_formatter.dart';
import '../../attachments/application/document_attachment_service.dart';
import '../../attachments/presentation/document_photo_field.dart';
import '../../clients/application/client_providers.dart';
import '../../products/application/product_providers.dart';
import '../application/invoice_providers.dart';

class InvoiceFormScreen extends ConsumerStatefulWidget {
  const InvoiceFormScreen({
    super.key,
    this.existingInvoice,
    this.existingLines,
    this.hasReceipts = false,
    this.hasReturns = false,
    this.collectedAmount = 0,
  });

  final SalesInvoice? existingInvoice;
  final List<SalesInvoiceLine>? existingLines;
  final bool hasReceipts;
  final bool hasReturns;
  final int collectedAmount;

  @override
  ConsumerState<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends ConsumerState<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  Client? _selectedClient;
  final _clientNameController = TextEditingController();
  final _clientFocusNode = FocusNode();
  final _productSearchController = TextEditingController();
  final _productSearchFocusNode = FocusNode();
  String _quickProductQuery = '';
  DateTime _invoiceDate = DateTime.now();
  final List<_LineItem> _lines = [];
  final _discountController = TextEditingController();
  final _paidAmountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _attachmentPath;
  String? _loadedAttachmentPath;
  bool _saving = false;

  bool get _isEditing => widget.existingInvoice != null;
  bool get _isReturnsConstrained => widget.hasReturns;
  bool get _isReceiptsConstrained => widget.hasReceipts && !widget.hasReturns;

  int get _subtotal {
    var sum = 0;
    for (final line in _lines) {
      final qty = line.quantity ?? 0;
      final price = line.unitPrice ?? 0;
      sum += qty * price;
    }
    return sum;
  }

  int get _discount {
    final text = _discountController.text.trim();
    if (text.isEmpty) return 0;
    final parsed = double.tryParse(text);
    if (parsed == null) return 0;
    return (parsed * 100).round();
  }

  int get _total => _subtotal - _discount;

  int get _paidAmount {
    final text = _paidAmountController.text.trim();
    if (text.isEmpty) return 0;
    final parsed = double.tryParse(text);
    if (parsed == null) return 0;
    return (parsed * 100).round();
  }

  void _selectAllControllerText(TextEditingController controller) {
    if (controller.text.isEmpty) return;
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
  }

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _populateFromExisting();
      unawaited(_loadExistingInvoicePhoto());
    }
    unawaited(_recoverLostInvoicePhoto());
  }

  void _populateFromExisting() {
    final invoice = widget.existingInvoice!;
    final lines = widget.existingLines ?? [];

    _invoiceDate = invoice.invoiceDate;
    _noteController.text = invoice.note ?? '';
    _discountController.text = (invoice.discount / 100).toStringAsFixed(2);

    for (final line in lines) {
      _lines.add(
        _LineItem(
          productId: line.productId,
          productName: null,
          quantity: line.quantity,
          unitPrice: line.unitPrice,
          productionDate: line.productionDate,
        ),
      );
    }

    _loadClientAndProducts();
  }

  Future<void> _loadClientAndProducts() async {
    final invoice = widget.existingInvoice!;
    try {
      final client = await ref
          .read(clientRepositoryProvider)
          .getById(invoice.clientId);
      if (mounted) {
        setState(() {
          _selectedClient = client;
          _clientNameController.text = client.displayName;
        });
      }
    } catch (_) {}

    final db = ref.read(appDatabaseProvider);
    final products = await (db.select(db.products)).get();
    final pMap = {for (final p in products) p.id: p.name};

    if (mounted) {
      setState(() {
        for (int i = 0; i < _lines.length; i++) {
          final line = _lines[i];
          _lines[i] = line.copyWith(productName: pMap[line.productId]);
        }
      });
    }
  }

  void _addLine() {
    setState(() {
      _lines.add(
        _LineItem(
          productId: null,
          productName: null,
          quantity: 1,
          unitPrice: null,
          productionDate: null,
        ),
      );
    });
  }

  void _removeLine(int index) {
    setState(() {
      _lines.removeAt(index);
    });
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
    return terms.every(
      (term) => words.any((word) => word.startsWith(term)),
    );
  }

  void _addProductToInvoice(Product product) {
    setState(() {
      final existingIndex = _lines.indexWhere(
        (line) => line.productId == product.id,
      );
      if (existingIndex >= 0) {
        final line = _lines[existingIndex];
        _lines[existingIndex] = line.copyWith(
          quantity: (line.quantity ?? 0) + 1,
          unitPrice: line.unitPrice ?? product.defaultSalePrice,
        );
      } else {
        _lines.add(
          _LineItem(
            productId: product.id,
            productName: product.name,
            quantity: 1,
            unitPrice: product.defaultSalePrice,
            productionDate: null,
          ),
        );
      }
      _productSearchController.clear();
      _quickProductQuery = '';
    });
    _productSearchFocusNode.requestFocus();
  }

  Future<void> _addProductFromSearchText() async {
    final query = _productSearchController.text.trim();
    if (query.isEmpty) return;

    final products = await ref.read(productListProvider.future);
    final normalized = query.toLowerCase();
    Product? match;
    for (final product in products) {
      final sku = product.sku?.toLowerCase() ?? '';
      if (product.isActive &&
          (product.name.trim().toLowerCase() == normalized ||
              sku == normalized)) {
        match = product;
        break;
      }
    }
    if (match == null) {
      for (final product in products) {
        final sku = product.sku?.toLowerCase() ?? '';
        if (product.isActive &&
            (_matchesWordPrefix(product.name, query) ||
                sku.startsWith(normalized))) {
          match = product;
          break;
        }
      }
    }

    if (!mounted) return;
    if (match == null) {
      setState(() => _quickProductQuery = query);
      return;
    }
    _addProductToInvoice(match);
  }

  Future<void> _selectDate() async {
    if (_isReturnsConstrained) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: _invoiceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _invoiceDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectLineProductionDate(int index) async {
    if (index < 0 || index >= _lines.length) return;
    final current = _lines[index].productionDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        _lines[index] = _lines[index].copyWith(productionDate: picked);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_saving) return;

    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('هذا العميل غير مسجل أو غير موجود')),
      );
      return;
    }

    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب إضافة سطر واحد على الأقل')),
      );
      return;
    }

    for (int i = 0; i < _lines.length; i++) {
      final line = _lines[i];
      if (line.productId == null ||
          line.quantity == null ||
          line.unitPrice == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('السطر ${i + 1} غير مكتمل')),
        );
        return;
      }
    }

    if (_discount > _subtotal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الخصم لا يمكن أن يتجاوز الإجمالي الفرعي'),
        ),
      );
      return;
    }

    if (!_isEditing && _paidAmount > _total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('المبلغ المدفوع لا يمكن أن يتجاوز الإجمالي'),
        ),
      );
      return;
    }

    if (_isEditing &&
        _isReceiptsConstrained &&
        _total < widget.collectedAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'الإجمالي لا يمكن أن يقل عن ${(widget.collectedAmount / 100).toStringAsFixed(2)} ر.ي.',
          ),
        ),
      );
      return;
    }

    if (_isEditing && _isReturnsConstrained) {
      await _saveNoteOnly();
      return;
    }

    setState(() => _saving = true);

    try {
      final device = await ref
          .read(deviceServiceProvider)
          .ensureCurrentDevice();
      if (!mounted) return;

      final lines = _lines.map((line) {
        return SalesInvoiceLinesCompanion(
          productId: Value(line.productId!),
          quantity: Value(line.quantity!),
          unitPrice: Value(line.unitPrice!),
          lineTotal: Value(line.quantity! * line.unitPrice!),
          productionDate: Value(line.productionDate),
        );
      }).toList();

      final repo = ref.read(invoiceRepositoryProvider);
      late final String invoiceId;

      if (_isEditing) {
        await repo.update(
          id: widget.existingInvoice!.id,
          clientId: _selectedClient!.id,
          invoiceDate: _invoiceDate,
          discount: _discount,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          lines: lines,
          deviceId: device.id,
        );
        invoiceId = widget.existingInvoice!.id;
      } else {
        final created = await repo.create(
          clientId: _selectedClient!.id,
          invoiceDate: _invoiceDate,
          discount: _discount,
          note: _noteController.text.trim(),
          lines: lines,
          paidAmount: _paidAmount,
          deviceId: device.id,
        );
        invoiceId = created.id;
      }

      await _stageInvoicePhoto(invoiceId);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveNoteOnly() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final device = await ref
          .read(deviceServiceProvider)
          .ensureCurrentDevice();
      if (!mounted) return;

      final repo = ref.read(invoiceRepositoryProvider);
      final note = _noteController.text.trim();
      await repo.updateNote(
        widget.existingInvoice!.id,
        note.isEmpty ? null : note,
        device.id,
      );

      await _stageInvoicePhoto(widget.existingInvoice!.id);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _captureInvoicePhoto() async {
    final path = await ref
        .read(documentAttachmentServiceProvider)
        .captureDocumentPhoto(context);
    if (path != null && mounted) {
      setState(() => _attachmentPath = path);
    }
  }

  Future<void> _recoverLostInvoicePhoto() async {
    final path = await ref
        .read(documentAttachmentServiceProvider)
        .recoverLostDocumentPhoto();
    if (path != null && mounted && _attachmentPath == null) {
      setState(() => _attachmentPath = path);
    }
  }

  Future<void> _loadExistingInvoicePhoto() async {
    final invoice = widget.existingInvoice;
    if (invoice == null) return;
    final path = await ref
        .read(documentAttachmentServiceProvider)
        .loadLatestLocalPhotoPath(
          parentEntityType: ParentEntityType.SALES_INVOICE,
          parentEntityId: invoice.id,
        );
    if (path != null && mounted && _attachmentPath == null) {
      setState(() {
        _attachmentPath = path;
        _loadedAttachmentPath = path;
      });
    }
  }

  Future<void> _stageInvoicePhoto(String invoiceId) async {
    final path = _attachmentPath;
    if (path == null) return;
    if (path == _loadedAttachmentPath) return;
    await ref
        .read(documentAttachmentServiceProvider)
        .stagePhoto(
          parentEntityType: ParentEntityType.SALES_INVOICE,
          parentEntityId: invoiceId,
          localFilePath: path,
        );
  }

  @override
  void dispose() {
    _discountController.dispose();
    _paidAmountController.dispose();
    _noteController.dispose();
    _clientNameController.dispose();
    _clientFocusNode.dispose();
    _productSearchController.dispose();
    _productSearchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(activeClientListProvider);
    if (!_isEditing) {
      return _buildQuickInvoiceScaffold();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل فاتورة' : 'إنشاء فاتورة'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isReturnsConstrained)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'لا يمكن تعديل الحقول المالية بسبب وجود مرتجعات',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              if (_isReceiptsConstrained)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'الحد الأدنى للإجمالي: ${(widget.collectedAmount / 100).toStringAsFixed(2)} ر.ي.',
                    style: const TextStyle(color: Colors.blue),
                  ),
                ),
              _buildClientSelector(),
              const SizedBox(height: 12),
              _buildDateSelector(),
              const SizedBox(height: 16),
              if (!_isReturnsConstrained)
                _buildLinesSection()
              else
                _buildLinesSectionReadOnly(),
              const SizedBox(height: 16),
              if (!_isReturnsConstrained)
                _buildTotalsSection()
              else
                _buildTotalsSectionReadOnly(),
              if (!_isEditing) ...[
                const SizedBox(height: 12),
                _buildPaidAmountField(),
              ],
              const SizedBox(height: 12),
              _buildNoteField(),
              const SizedBox(height: 12),
              DocumentPhotoField(
                label: 'إضافة صورة الفاتورة',
                localPath: _attachmentPath,
                onCapture: _captureInvoicePhoto,
                onRemove: () => setState(() => _attachmentPath = null),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.surface,
                        ),
                      )
                    : Text(_isReturnsConstrained ? 'حفظ الملاحظة' : 'حفظ'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickInvoiceScaffold() {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('فاتورة بيع جديدة'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildQuickProductSearch(primary),
                ],
              ),
            ),
            Expanded(
              child: _lines.isEmpty
                  ? const SizedBox.shrink()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                      child: _buildQuickLinesTable(primary),
                    ),
            ),
            _buildQuickBottomBar(primary),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickProductSearch(Color primary) {
    return RawAutocomplete<Product>(
      textEditingController: _productSearchController,
      focusNode: _productSearchFocusNode,
      displayStringForOption: (product) => product.name,
      optionsBuilder: (textEditingValue) async {
        final query = textEditingValue.text.trim();
        if (query.isEmpty) return const Iterable<Product>.empty();
        final normalized = query.toLowerCase();
        final products = await ref.read(productListProvider.future);
        return products.where((product) {
          final sku = product.sku?.toLowerCase() ?? '';
          return product.isActive &&
              (_matchesWordPrefix(product.name, query) ||
                  sku.startsWith(normalized));
        });
      },
      onSelected: (product) {
        _addProductToInvoice(product);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _productSearchController.clear();
        });
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        final showMissingPrompt = _shouldShowQuickMissingProductPrompt();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              focusNode: focusNode,
              selectAllOnFocus: true,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22),
              decoration: InputDecoration(
                hintText: 'ادخل اسم منتج أو صنف بالفاتورة',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide(color: primary, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide(color: primary, width: 1.5),
                ),
              ),
              onChanged: (value) {
                setState(() => _quickProductQuery = value.trim());
              },
              onSubmitted: (_) => _addProductFromSearchText(),
            ),
            if (showMissingPrompt)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'هذا المنتج غير موجود هل تريد إضافته؟',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showQuickProductDialog(
                        _quickProductQuery,
                        null,
                      ),
                      icon: const Icon(Icons.add_box_rounded),
                      label: const Text('أضف المنتج'),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(4),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260, maxWidth: 520),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final product = options.elementAt(index);
                  return ListTile(
                    title: Text(
                      product.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20),
                    ),
                    subtitle: product.sku == null
                        ? null
                        : Text(product.sku!, textAlign: TextAlign.center),
                    onTap: () => onSelected(product),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  bool _shouldShowQuickMissingProductPrompt() {
    final query = _quickProductQuery.trim();
    if (query.length < 2) return false;
    final products = ref.watch(productListProvider).value ?? const <Product>[];
    final normalized = query.toLowerCase();
    return !products.any((product) {
      final sku = product.sku?.toLowerCase() ?? '';
      return product.isActive &&
          (product.name.trim().toLowerCase() == normalized ||
              _matchesWordPrefix(product.name, query) ||
              sku == normalized ||
              sku.startsWith(normalized));
    });
  }

  Widget _buildQuickLinesTable(Color primary) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Column(
        children: [
          Container(
            color: primary,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'المنتج',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.surface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'الكمية',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.surface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'السعر',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.surface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ..._lines.asMap().entries.map((entry) {
            final index = entry.key;
            final line = entry.value;
            return GestureDetector(
              onLongPress: () => _showLineEditDialog(index),
              onDoubleTap: () => _showLineEditDialog(index),
              child: Dismissible(
                key: ValueKey('${line.productId}-$index'),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red.shade50,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.red),
                ),
                onDismissed: (_) => _removeLine(index),
                child: Container(
                  color: index.isEven
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : Theme.of(context).colorScheme.surface,
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 18,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          line.productName ?? 'منتج',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${line.quantity ?? 0}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          formatMoneyPlain(line.unitPrice ?? 0),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuickBottomBar(Color primary) {
    return Material(
      elevation: 8,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border.symmetric(
                    horizontal: BorderSide(color: primary, width: 1.2),
                  ),
                ),
                child: Text(
                  'الإجمالي : ${formatMoneyPlain(_subtotal)} ريال',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: _resetQuickInvoiceForm,
                      child: const Text('مسح', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: _lines.isEmpty || _saving
                          ? null
                          : _showQuickSaveDialog,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'حفظ',
                              style: TextStyle(fontSize: 20),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showLineEditDialog(int index) async {
    if (index < 0 || index >= _lines.length) return;
    final line = _lines[index];
    final quantityController = TextEditingController(
      text: (line.quantity ?? 1).toString(),
    );
    final priceController = TextEditingController(
      text: ((line.unitPrice ?? 0) / 100).toStringAsFixed(2),
    );
    final quantityFocusNode = FocusNode();
    final priceFocusNode = FocusNode();
    DateTime? productionDate = line.productionDate;
    _LineEditResult? result;
    var disposed = false;
    var selectQuantityOnTap = true;
    var selectPriceOnTap = true;

    void selectAll(TextEditingController controller) {
      if (disposed || controller.text.isEmpty) return;
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );
    }

    void selectAllAfterFrame(
      FocusNode focusNode,
      TextEditingController controller,
    ) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (disposed || !focusNode.hasFocus) return;
        selectAll(controller);
      });
    }

    quantityFocusNode.addListener(() {
      if (quantityFocusNode.hasFocus) {
        selectQuantityOnTap = false;
        selectAllAfterFrame(quantityFocusNode, quantityController);
      } else {
        selectQuantityOnTap = true;
      }
    });
    priceFocusNode.addListener(() {
      if (priceFocusNode.hasFocus) {
        selectPriceOnTap = false;
        selectAllAfterFrame(priceFocusNode, priceController);
      } else {
        selectPriceOnTap = true;
      }
    });

    try {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                title: Text(
                  line.productName ?? 'منتج',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                content: InvoiceLineEditDialogContent(
                  quantityController: quantityController,
                  priceController: priceController,
                  quantityFocusNode: quantityFocusNode,
                  priceFocusNode: priceFocusNode,
                  productionDate: productionDate,
                  formatDate: _formatDate,
                  onQuantityTap: () {
                    if (!selectQuantityOnTap) return;
                    selectQuantityOnTap = false;
                    selectAll(quantityController);
                  },
                  onPriceTap: () {
                    if (!selectPriceOnTap) return;
                    selectPriceOnTap = false;
                    selectAll(priceController);
                  },
                  onPickProductionDate: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: productionDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (!context.mounted || picked == null) {
                      return;
                    }
                    setDialogState(() => productionDate = picked);
                  },
                  onClearProductionDate: () =>
                      setDialogState(() => productionDate = null),
                ),
                actionsAlignment: MainAxisAlignment.spaceBetween,
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('غلق'),
                  ),
                  FilledButton(
                    onPressed: () {
                      final quantity = int.tryParse(
                        quantityController.text.trim(),
                      );
                      final price = double.tryParse(
                        priceController.text.trim(),
                      );
                      if (quantity == null || quantity <= 0 || price == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('أدخل كمية وسعر صحيحين'),
                          ),
                        );
                        return;
                      }
                      result = _LineEditResult(
                        quantity: quantity,
                        unitPrice: (price * 100).round(),
                        productionDate: productionDate,
                      );
                      Navigator.of(context).pop();
                    },
                    child: const Text('تم'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      disposed = true;
      await Future<void>.delayed(const Duration(milliseconds: 450));
      quantityFocusNode.dispose();
      priceFocusNode.dispose();
      quantityController.dispose();
      priceController.dispose();
    }

    final editResult = result;
    if (!mounted || editResult == null) return;
    if (index < 0 || index >= _lines.length) return;
    setState(() {
      _lines[index] = _lines[index].copyWith(
        quantity: editResult.quantity,
        unitPrice: editResult.unitPrice,
        productionDate: editResult.productionDate,
        clearProductionDate: editResult.productionDate == null,
      );
    });
  }

  Future<void> _showQuickSaveDialog() async {
    if (_lines.isEmpty) return;
    final dialogFormKey = GlobalKey<FormState>();
    final dialogClientController = TextEditingController(
      text: _clientNameController.text,
    );
    final dialogClientFocusNode = FocusNode();
    _paidAmountController.text = (_total / 100).toStringAsFixed(2);
    var saving = false;
    var dialogOpen = true;
    var resetAfterDialogCloses = false;

    Future<void> save(
      BuildContext dialogContext,
      StateSetter setDialogState,
    ) async {
      if (!dialogFormKey.currentState!.validate()) return;
      if (_selectedClient == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('هذا العميل غير مسجل أو غير موجود')),
        );
        return;
      }
      if (saving) return;
      dialogClientFocusNode.unfocus();
      FocusManager.instance.primaryFocus?.unfocus();
      setDialogState(() => saving = true);
      final dialogNavigator = Navigator.of(dialogContext);
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      try {
        await _saveQuickInvoice();
        if (!mounted) return;
        dialogOpen = false;
        resetAfterDialogCloses = true;
        dialogNavigator.pop();
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('تم حفظ الفاتورة بنجاح')),
        );
      } catch (e) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      } finally {
        if (dialogOpen) {
          setDialogState(() => saving = false);
        }
      }
    }

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              final screenSize = MediaQuery.sizeOf(context);
              final dialogWidth = screenSize.width >= 640
                  ? 560.0
                  : (screenSize.width - 48).clamp(280.0, 560.0);
              final maxContentHeight = screenSize.height * 0.68;
              final compactDialog = screenSize.width < 480;
              final remaining = _total - _paidAmount;
              final status = remaining <= 0 ? 'فاتورة مسددة' : 'فاتورة بالأجل';
              return AlertDialog(
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'فاتورة البيع',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      status,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: remaining <= 0 ? Colors.green : Colors.red,
                        fontSize: compactDialog ? 20 : 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                content: Form(
                  key: dialogFormKey,
                  child: SizedBox(
                    width: dialogWidth,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: maxContentHeight),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildDialogMoneyRow(
                              label: 'خصم على الفاتورة',
                              controller: _discountController,
                              color: Colors.red,
                              onChanged: (_) => setDialogState(() {}),
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (text.isEmpty) return null;
                                final parsed = double.tryParse(text);
                                if (parsed == null) return 'أدخل رقم صحيح';
                                if ((parsed * 100).round() > _subtotal) {
                                  return 'الخصم أكبر من إجمالي الفاتورة';
                                }
                                return null;
                              },
                            ),
                            _buildReadOnlyDialogRow(
                              label: 'إجمالي الفاتورة',
                              value: formatMoneyPlain(_total),
                            ),
                            _buildDialogMoneyRow(
                              label: 'المبلغ المدفوع',
                              controller: _paidAmountController,
                              color: Colors.red,
                              onChanged: (_) => setDialogState(() {}),
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (text.isEmpty) return null;
                                final parsed = double.tryParse(text);
                                if (parsed == null) return 'أدخل رقم صحيح';
                                if ((parsed * 100).round() > _total) {
                                  return 'المبلغ المدفوع أكبر من الإجمالي';
                                }
                                return null;
                              },
                            ),
                            _buildReadOnlyDialogRow(
                              label: 'المبلغ المتبقي',
                              value: formatMoneyPlain(remaining),
                            ),
                            const SizedBox(height: 12),
                            _buildDialogDateField(setDialogState),
                            const Divider(height: 28),
                            _buildDialogClientSelector(
                              setDialogState,
                              controller: dialogClientController,
                              focusNode: dialogClientFocusNode,
                            ),
                            if (_selectedClient != null) ...[
                              const SizedBox(height: 10),
                              FutureBuilder<int>(
                                future: ref
                                    .read(clientRepositoryProvider)
                                    .getOutstandingBalance(_selectedClient!.id),
                                builder: (context, snapshot) {
                                  final balance = snapshot.data ?? 0;
                                  final isDebit = balance >= 0;
                                  return _buildReadOnlyDialogRow(
                                    label: 'حساب سابق',
                                    value:
                                        '${formatMoneyPlain(balance.abs())} ${isDebit ? '(عليه)' : '(له)'}',
                                    valueColor: isDebit
                                        ? Colors.red
                                        : Colors.green,
                                  );
                                },
                              ),
                            ],
                            const SizedBox(height: 12),
                            DocumentPhotoField(
                              label: 'إضافة صورة الفاتورة',
                              localPath: _attachmentPath,
                              onCapture: () async {
                                await _captureInvoicePhoto();
                                if (dialogContext.mounted) {
                                  setDialogState(() {});
                                }
                              },
                              onRemove: () {
                                setState(() => _attachmentPath = null);
                                setDialogState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                actionsOverflowDirection: VerticalDirection.down,
                actionsOverflowAlignment: OverflowBarAlignment.center,
                actionsAlignment: MainAxisAlignment.spaceBetween,
                actions: [
                  TextButton(
                    onPressed: saving
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: const Text('غلق'),
                  ),
                  FilledButton(
                    onPressed: saving
                        ? null
                        : () => save(dialogContext, setDialogState),
                    child: saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('حفظ'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      dialogOpen = false;
      await Future<void>.delayed(const Duration(milliseconds: 450));
      dialogClientFocusNode.dispose();
      dialogClientController.dispose();
      if (mounted && resetAfterDialogCloses) {
        _resetQuickInvoiceForm();
      }
    }
  }

  Widget _buildDialogMoneyRow({
    required String label,
    required TextEditingController controller,
    required Color color,
    required ValueChanged<String> onChanged,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;
          final labelText = Text(
            label,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: compact ? 16 : 20,
              fontWeight: FontWeight.bold,
            ),
          );
          final field = TextFormField(
            controller: controller,
            selectAllOnFocus: true,
            onTap: () => _selectAllControllerText(controller),
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            style: TextStyle(
              color: color,
              fontSize: compact ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
            onChanged: onChanged,
            validator: validator,
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                labelText,
                const SizedBox(height: 8),
                field,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: field),
              const SizedBox(width: 12),
              SizedBox(width: 140, child: labelText),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReadOnlyDialogRow({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;
          final labelText = Text(
            label,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 16 : 20,
              fontWeight: FontWeight.bold,
            ),
          );
          final valueBox = InputDecorator(
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
            child: Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: valueColor,
                fontSize: compact ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                labelText,
                const SizedBox(height: 8),
                valueBox,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: valueBox),
              const SizedBox(width: 12),
              SizedBox(width: 140, child: labelText),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDialogDateField(StateSetter setDialogState) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _invoiceDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          setState(() => _invoiceDate = picked);
          setDialogState(() {});
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(labelText: 'تاريخ الفاتورة'),
        child: Text(
          '${_invoiceDate.year}-${_invoiceDate.month.toString().padLeft(2, '0')}-${_invoiceDate.day.toString().padLeft(2, '0')}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  Widget _buildDialogClientSelector(
    StateSetter setDialogState, {
    required TextEditingController controller,
    required FocusNode focusNode,
  }) {
    final clients =
        ref.read(activeClientListProvider).value ?? const <Client>[];
    return RawAutocomplete<Client>(
      textEditingController: controller,
      focusNode: focusNode,
      displayStringForOption: (client) => client.displayName,
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.trim();
        if (query.isEmpty) return const Iterable<Client>.empty();
        if (_selectedClient?.displayName.trim() == query) {
          return const Iterable<Client>.empty();
        }
        final normalized = query.toLowerCase();
        return clients.where((client) {
          final phone = client.phone?.toLowerCase() ?? '';
          final code = client.clientCode?.toLowerCase() ?? '';
          return _matchesWordPrefix(client.displayName, query) ||
              phone.startsWith(normalized) ||
              code.startsWith(normalized);
        });
      },
      onSelected: (client) {
        setState(() {
          _selectedClient = client;
          _clientNameController.text = client.displayName;
          controller.text = client.displayName;
        });
        focusNode.unfocus();
        setDialogState(() {});
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                focusNode: focusNode,
                selectAllOnFocus: true,
                textAlign: TextAlign.center,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: const InputDecoration(
                  hintText: 'ادخل اسم العميل',
                  isDense: true,
                ),
                onChanged: (value) {
                  final normalized = value.trim().toLowerCase();
                  Client? exactMatch;
                  for (final client in clients) {
                    if (client.displayName.trim().toLowerCase() == normalized) {
                      exactMatch = client;
                      break;
                    }
                  }
                  _clientNameController.text = value;
                  setState(() => _selectedClient = exactMatch);
                  setDialogState(() {});
                },
                validator: (_) {
                  if (_selectedClient == null) {
                    return 'هذا العميل غير مسجل أو غير موجود';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 18),
            const SizedBox(
              width: 150,
              child: Text(
                'اسم العميل',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220, maxWidth: 420),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final client = options.elementAt(index);
                  return ListTile(
                    title: Text(client.displayName, textAlign: TextAlign.right),
                    subtitle: client.phone == null
                        ? null
                        : Text(client.phone!, textAlign: TextAlign.right),
                    onTap: () => onSelected(client),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveQuickInvoice() async {
    if (_saving) return;
    if (_selectedClient == null) {
      throw StateError('هذا العميل غير مسجل أو غير موجود');
    }
    if (_lines.isEmpty) {
      throw StateError('يجب إضافة منتج واحد على الأقل');
    }
    if (_discount > _subtotal) {
      throw StateError('الخصم لا يمكن أن يتجاوز إجمالي الفاتورة');
    }
    if (_paidAmount > _total) {
      throw StateError('المبلغ المدفوع لا يمكن أن يتجاوز إجمالي الفاتورة');
    }

    setState(() => _saving = true);
    try {
      final device = await ref
          .read(deviceServiceProvider)
          .ensureCurrentDevice();
      final lines = _lines.map((line) {
        return SalesInvoiceLinesCompanion(
          productId: Value(line.productId!),
          quantity: Value(line.quantity ?? 1),
          unitPrice: Value(line.unitPrice ?? 0),
          lineTotal: Value((line.quantity ?? 1) * (line.unitPrice ?? 0)),
          productionDate: Value(line.productionDate),
        );
      }).toList();

      final created = await ref
          .read(invoiceRepositoryProvider)
          .create(
            clientId: _selectedClient!.id,
            invoiceDate: _invoiceDate,
            discount: _discount,
            note: _noteController.text.trim(),
            lines: lines,
            paidAmount: _paidAmount,
            deviceId: device.id,
          );
      await _stageInvoicePhoto(created.id);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _resetQuickInvoiceForm() {
    setState(() {
      _selectedClient = null;
      _clientNameController.clear();
      _productSearchController.clear();
      _lines.clear();
      _discountController.clear();
      _paidAmountController.clear();
      _noteController.clear();
      _attachmentPath = null;
      _loadedAttachmentPath = null;
      _invoiceDate = DateTime.now();
    });
    _productSearchFocusNode.requestFocus();
  }

  Widget _buildClientSelector() {
    final isDisabled = _isEditing && _isReturnsConstrained;
    final clients =
        ref.watch(activeClientListProvider).value ?? const <Client>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RawAutocomplete<Client>(
          textEditingController: _clientNameController,
          focusNode: _clientFocusNode,
          displayStringForOption: (client) => client.displayName,
          optionsBuilder: (textEditingValue) {
            final query = textEditingValue.text.trim();
            if (query.isEmpty) return const Iterable<Client>.empty();
            if (_selectedClient?.displayName.trim() == query) {
              return const Iterable<Client>.empty();
            }
            final normalized = query.toLowerCase();
            return clients.where((client) {
              final name = client.displayName.toLowerCase();
              final phone = client.phone?.toLowerCase() ?? '';
              final code = client.clientCode?.toLowerCase() ?? '';
              return name.startsWith(normalized) ||
                  phone.startsWith(normalized) ||
                  code.startsWith(normalized);
            });
          },
          onSelected: (client) {
            setState(() {
              _selectedClient = client;
              _clientNameController.text = client.displayName;
            });
            _clientFocusNode.unfocus();
          },
          fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              enabled: !isDisabled,
              selectAllOnFocus: true,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: const InputDecoration(
                labelText: 'العميل *',
                hintText: 'اكتب اسم العميل',
                prefixIcon: Icon(Icons.person_search_rounded),
              ),
              onChanged: (value) {
                final normalized = value.trim().toLowerCase();
                Client? exactMatch;
                for (final client in clients) {
                  if (client.displayName.trim().toLowerCase() == normalized) {
                    exactMatch = client;
                    break;
                  }
                }
                if (exactMatch != null) {
                  setState(() => _selectedClient = exactMatch);
                  return;
                }
                final selected = _selectedClient;
                if (selected != null &&
                    selected.displayName.trim() != value.trim()) {
                  setState(() => _selectedClient = null);
                } else {
                  setState(() {});
                }
              },
              validator: (_) {
                if (_selectedClient == null) {
                  return 'هذا العميل غير مسجل أو غير موجود';
                }
                return null;
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final client = options.elementAt(index);
                      return ListTile(
                        title: Text(client.displayName),
                        subtitle: client.phone != null
                            ? Text(client.phone!)
                            : client.clientCode != null
                            ? Text(client.clientCode!)
                            : null,
                        onTap: () => onSelected(client),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        if (!isDisabled) _buildMissingClientPrompt(),
      ],
    );
  }

  Widget _buildMissingClientPrompt() {
    final typedName = _clientNameController.text.trim();
    final selectedName = _selectedClient?.displayName.trim();
    final clients = ref.watch(clientListProvider).value ?? const <Client>[];
    final normalized = typedName.toLowerCase();
    final hasSuggestion = clients.any((client) {
      final name = client.displayName.toLowerCase();
      final phone = client.phone?.toLowerCase() ?? '';
      final code = client.clientCode?.toLowerCase() ?? '';
      return name.startsWith(normalized) ||
          phone.startsWith(normalized) ||
          code.startsWith(normalized);
    });
    final showPrompt =
        typedName.length >= 2 &&
        !hasSuggestion &&
        (selectedName == null || selectedName != typedName);

    if (!showPrompt) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'هذا العميل غير موجود. هل تريد إضافته؟',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          TextButton.icon(
            onPressed: () => _showQuickClientDialog(typedName),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('إضافة عميل جديد'),
          ),
        ],
      ),
    );
  }

  Future<void> _showQuickClientDialog(String initialName) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: initialName);
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();
    final noteController = TextEditingController();
    final codeController = TextEditingController();
    var saving = false;
    var dialogOpen = true;

    Future<void> save(StateSetter setDialogState) async {
      if (!formKey.currentState!.validate()) return;
      if (saving) return;

      final phone = phoneController.text.trim();
      final email = emailController.text.trim();
      final address = addressController.text.trim();
      final note = noteController.text.trim();
      final code = codeController.text.trim();

      if (phone.isEmpty &&
          email.isEmpty &&
          address.isEmpty &&
          note.isEmpty &&
          code.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('أدخل وسيلة تعريف واحدة على الأقل للعميل'),
          ),
        );
        return;
      }

      setDialogState(() => saving = true);
      try {
        final device = await ref
            .read(deviceServiceProvider)
            .ensureCurrentDevice();
        final client = await ref
            .read(clientRepositoryProvider)
            .createAndReturn(
              ClientsCompanion(
                displayName: Value(nameController.text.trim()),
                phone: Value(phone.isEmpty ? null : phone),
                email: Value(email.isEmpty ? null : email),
                address: Value(address.isEmpty ? null : address),
                note: Value(note.isEmpty ? null : note),
                clientCode: Value(code.isEmpty ? null : code),
                deviceId: Value(device.id),
              ),
            );
        if (!mounted) return;
        setState(() {
          _selectedClient = client;
          _clientNameController.text = client.displayName;
        });
        dialogOpen = false;
        Navigator.of(context).pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      } finally {
        if (dialogOpen) {
          setDialogState(() => saving = false);
        }
      }
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('إضافة عميل جديد'),
              content: Form(
                key: formKey,
                child: SizedBox(
                  width: 520,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'اسم العميل *',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'اسم العميل مطلوب';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: phoneController,
                          decoration: const InputDecoration(
                            labelText: 'الهاتف',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: 'البريد الإلكتروني',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: addressController,
                          decoration: const InputDecoration(
                            labelText: 'العنوان',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: codeController,
                          decoration: const InputDecoration(
                            labelText: 'رمز العميل',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: noteController,
                          decoration: const InputDecoration(
                            labelText: 'ملاحظة',
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.of(context).pop(),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: saving ? null : () => save(setDialogState),
                  child: saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );

    dialogOpen = false;
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    noteController.dispose();
    codeController.dispose();
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _isReturnsConstrained ? null : _selectDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'تاريخ الفاتورة',
          suffixIcon: _isReturnsConstrained
              ? null
              : const Icon(Icons.calendar_today),
        ),
        child: Text(
          '${_invoiceDate.year}-${_invoiceDate.month.toString().padLeft(2, '0')}-${_invoiceDate.day.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }

  Widget _buildLinesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'تفاصيل الفاتورة',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._lines.asMap().entries.map((entry) {
          final index = entry.key;
          return _buildLineItem(index);
        }),
        OutlinedButton.icon(
          onPressed: _addLine,
          icon: const Icon(Icons.add),
          label: const Text('إضافة سطر'),
        ),
      ],
    );
  }

  Widget _buildLinesSectionReadOnly() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'تفاصيل الفاتورة',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._lines.map(
          (line) => ListTile(
            dense: true,
            title: Text(line.productName ?? 'منتج'),
            subtitle: Text(
              '${line.quantity ?? 0} × ${((line.unitPrice ?? 0) / 100).toStringAsFixed(2)} ر.ي.',
            ),
            trailing: Text(
              '${((line.quantity ?? 0) * (line.unitPrice ?? 0) / 100).toStringAsFixed(2)} ر.ي.',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLineItem(int index) {
    final line = _lines[index];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildProductAutocomplete(line, index),
                      _buildMissingProductPrompt(line, index),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    initialValue: line.quantity?.toString() ?? '1',
                    selectAllOnFocus: true,
                    decoration: const InputDecoration(
                      labelText: 'الكمية',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final parsed = int.tryParse(v);
                      setState(() {
                        _lines[index] = _lines[index].copyWith(
                          quantity: parsed,
                        );
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: line.unitPrice != null
                        ? (line.unitPrice! / 100).toStringAsFixed(2)
                        : '',
                    selectAllOnFocus: true,
                    decoration: const InputDecoration(
                      labelText: 'سعر الوحدة',
                      suffixText: 'ر.ي.',
                      isDense: true,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (v) {
                      final parsed = double.tryParse(v);
                      setState(() {
                        _lines[index] = _lines[index].copyWith(
                          unitPrice: parsed != null
                              ? (parsed * 100).round()
                              : null,
                        );
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: Text(
                    'الإجمالي: ${((line.quantity ?? 0) * (line.unitPrice ?? 0) / 100).toStringAsFixed(2)} ر.ي.',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeLine(index),
                ),
              ],
            ),
            const SizedBox(height: 8),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'تاريخ إنتاج هذا المنتج',
                isDense: true,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      line.productionDate == null
                          ? 'غير محدد'
                          : _formatDate(line.productionDate!),
                    ),
                  ),
                  IconButton(
                    tooltip: 'اختيار تاريخ',
                    icon: const Icon(Icons.calendar_today_rounded),
                    onPressed: () => _selectLineProductionDate(index),
                  ),
                  IconButton(
                    tooltip: 'مسح التاريخ',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: line.productionDate == null
                        ? null
                        : () => setState(() {
                            _lines[index] = _lines[index].copyWith(
                              clearProductionDate: true,
                            );
                          }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductAutocomplete(_LineItem line, int index) {
    return RawAutocomplete<Product>(
      displayStringForOption: (p) => p.name,
      optionsBuilder: (textEditingValue) async {
        final query = textEditingValue.text.trim();
        if (query.isEmpty) return const Iterable<Product>.empty();
        final products = await ref.read(productListProvider.future);
        final normalized = query.toLowerCase();
        return products.where((product) {
          final name = product.name.toLowerCase();
          final sku = product.sku?.toLowerCase() ?? '';
          return product.isActive &&
              (name.startsWith(normalized) || sku.startsWith(normalized));
        });
      },
      onSelected: (product) {
        setState(() {
          _lines[index] = _lines[index].copyWith(
            productId: product.id,
            productName: product.name,
            unitPrice: product.defaultSalePrice,
          );
        });
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        if (controller.text != line.productName) {
          controller.text = line.productName ?? '';
          controller.selection = TextSelection.collapsed(
            offset: controller.text.length,
          );
        }
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          selectAllOnFocus: true,
          decoration: const InputDecoration(
            labelText: 'المنتج',
            isDense: true,
          ),
          onChanged: (value) {
            final normalized = value.trim().toLowerCase();
            Product? exactMatch;
            final products = ref.read(productListProvider).value ?? const [];
            for (final product in products) {
              if (product.isActive &&
                  product.name.trim().toLowerCase() == normalized) {
                exactMatch = product;
                break;
              }
            }
            final selectedProduct = exactMatch;
            if (selectedProduct != null) {
              setState(() {
                _lines[index] = _lines[index].copyWith(
                  productId: selectedProduct.id,
                  productName: selectedProduct.name,
                  unitPrice: selectedProduct.defaultSalePrice,
                );
              });
              return;
            }
            setState(() {
              _lines[index] = _lines[index].copyWith(
                productName: value,
                clearProduct: true,
              );
            });
          },
          validator: (v) {
            if (_lines[index].productId == null && v != null && v.isNotEmpty) {
              return 'اختر منتجا موجودا أو أضف المنتج الجديد';
            }
            return null;
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, optionIndex) {
                  final product = options.elementAt(optionIndex);
                  return ListTile(
                    title: Text(product.name),
                    subtitle: product.sku != null
                        ? Text(product.sku!)
                        : product.unit != null
                        ? Text(product.unit!)
                        : null,
                    trailing: Text(
                      '${(product.defaultSalePrice / 100).toStringAsFixed(2)} ر.ي.',
                    ),
                    onTap: () => onSelected(product),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMissingProductPrompt(_LineItem line, int index) {
    final typedName = line.productName?.trim() ?? '';
    if (typedName.length < 2 || line.productId != null) {
      return const SizedBox.shrink();
    }

    final products = ref.watch(productListProvider).value ?? const <Product>[];
    final normalized = typedName.toLowerCase();
    final hasSuggestion = products.any((product) {
      final name = product.name.toLowerCase();
      final sku = product.sku?.toLowerCase() ?? '';
      return product.isActive &&
          (name.startsWith(normalized) || sku.startsWith(normalized));
    });
    if (hasSuggestion) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'هذا المنتج غير موجود. هل تريد إضافته؟',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          TextButton.icon(
            onPressed: () => _showQuickProductDialog(typedName, index),
            icon: const Icon(Icons.add_box_rounded),
            label: const Text('إضافة منتج جديد'),
          ),
        ],
      ),
    );
  }

  Future<void> _showQuickProductDialog(
    String initialName,
    int? lineIndex,
  ) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: initialName);
    final descriptionController = TextEditingController();
    final salePriceController = TextEditingController();
    final unitController = TextEditingController();
    final skuController = TextEditingController();
    final shelfLifeDaysController = TextEditingController();
    var saving = false;
    var dialogOpen = true;

    Future<void> save(StateSetter setDialogState) async {
      if (!formKey.currentState!.validate()) return;
      if (saving) return;

      final name = nameController.text.trim();
      final repo = ref.read(productRepositoryProvider);
      final taken = await repo.isNameTaken(name);
      if (!mounted) return;
      if (taken) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('اسم المنتج مستخدم بالفعل')),
        );
        return;
      }

      setDialogState(() => saving = true);
      try {
        final device = await ref
            .read(deviceServiceProvider)
            .ensureCurrentDevice();
        final salePrice = (double.parse(salePriceController.text.trim()) * 100)
            .round();
        final description = descriptionController.text.trim();
        final unit = unitController.text.trim();
        final sku = skuController.text.trim();
        final shelfLifeText = shelfLifeDaysController.text.trim();
        final shelfLifeDays = shelfLifeText.isEmpty
            ? null
            : int.parse(shelfLifeText);

        final product = await repo.createAndReturn(
          ProductsCompanion(
            name: Value(name),
            description: Value(description.isEmpty ? null : description),
            defaultSalePrice: Value(salePrice),
            unit: Value(unit.isEmpty ? null : unit),
            sku: Value(sku.isEmpty ? null : sku),
            shelfLifeDays: Value(shelfLifeDays),
            deviceId: Value(device.id),
          ),
        );
        if (!mounted) return;
        if (lineIndex == null) {
          _addProductToInvoice(product);
          dialogOpen = false;
          Navigator.of(context).pop();
          return;
        }
        if (lineIndex >= _lines.length) {
          dialogOpen = false;
          Navigator.of(context).pop();
          return;
        }
        setState(() {
          _lines[lineIndex] = _lines[lineIndex].copyWith(
            productId: product.id,
            productName: product.name,
            unitPrice: product.defaultSalePrice,
          );
        });
        dialogOpen = false;
        Navigator.of(context).pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      } finally {
        if (dialogOpen) {
          setDialogState(() => saving = false);
        }
      }
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('إضافة منتج جديد'),
              content: Form(
                key: formKey,
                child: SizedBox(
                  width: 520,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'اسم المنتج *',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'اسم المنتج مطلوب';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: salePriceController,
                          decoration: const InputDecoration(
                            labelText: 'سعر البيع *',
                            suffixText: 'ر.ي.',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'سعر البيع مطلوب';
                            }
                            final parsed = double.tryParse(value.trim());
                            if (parsed == null) return 'أدخل رقم صحيح';
                            if (parsed < 0) return 'السعر لا يكون سالبا';
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: unitController,
                          decoration: const InputDecoration(
                            labelText: 'الوحدة',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: skuController,
                          decoration: const InputDecoration(
                            labelText: 'رمز SKU',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: shelfLifeDaysController,
                          decoration: const InputDecoration(
                            labelText: 'صلاحية المنتج بالأيام',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) return null;
                            final parsed = int.tryParse(text);
                            if (parsed == null) return 'أدخل عدد أيام صحيح';
                            if (parsed <= 0) {
                              return 'الصلاحية يجب أن تكون أكبر من صفر';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: descriptionController,
                          decoration: const InputDecoration(labelText: 'الوصف'),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.of(context).pop(),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: saving ? null : () => save(setDialogState),
                  child: saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );

    dialogOpen = false;
    nameController.dispose();
    descriptionController.dispose();
    salePriceController.dispose();
    unitController.dispose();
    skuController.dispose();
    shelfLifeDaysController.dispose();
  }

  Widget _buildTotalsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الإجمالي الفرعي:'),
                Text('${(_subtotal / 100).toStringAsFixed(2)} ر.ي.'),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _discountController,
              selectAllOnFocus: true,
              decoration: const InputDecoration(
                labelText: 'الخصم',
                suffixText: 'ر.ي.',
                isDense: true,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final parsed = double.tryParse(v.trim());
                if (parsed == null) return 'أدخل رقم صحيح';
                if ((parsed * 100).round() > _subtotal) {
                  return 'الخصم لا يمكن أن يتجاوز الإجمالي الفرعي';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'الإجمالي:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${(_total / 100).toStringAsFixed(2)} ر.ي.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsSectionReadOnly() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الإجمالي الفرعي:'),
                Text('${(_subtotal / 100).toStringAsFixed(2)} ر.ي.'),
              ],
            ),
            if (widget.existingInvoice != null &&
                widget.existingInvoice!.discount > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('الخصم:'),
                  Text(
                    '${(widget.existingInvoice!.discount / 100).toStringAsFixed(2)} ر.ي.',
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'الإجمالي:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${(_total / 100).toStringAsFixed(2)} ر.ي.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaidAmountField() {
    return TextFormField(
      controller: _paidAmountController,
      selectAllOnFocus: true,
      onTap: () => _selectAllControllerText(_paidAmountController),
      decoration: const InputDecoration(
        labelText: 'المبلغ المدفوع',
        suffixText: 'ر.ي.',
        isDense: true,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return null;
        final parsed = double.tryParse(v.trim());
        if (parsed == null) return 'أدخل رقم صحيح';
        if (parsed < 0) return 'المبلغ لا يمكن أن يكون سالباً';
        if ((parsed * 100).round() > _total) {
          return 'المبلغ لا يمكن أن يتجاوز الإجمالي';
        }
        return null;
      },
    );
  }

  Widget _buildNoteField() {
    return TextFormField(
      controller: _noteController,
      selectAllOnFocus: true,
      decoration: const InputDecoration(
        labelText: 'ملاحظة',
        alignLabelWithHint: true,
      ),
      maxLines: 3,
    );
  }
}

class InvoiceLineEditDialogContent extends StatelessWidget {
  const InvoiceLineEditDialogContent({
    super.key,
    required this.quantityController,
    required this.priceController,
    required this.quantityFocusNode,
    required this.priceFocusNode,
    required this.productionDate,
    required this.formatDate,
    required this.onQuantityTap,
    required this.onPriceTap,
    required this.onPickProductionDate,
    required this.onClearProductionDate,
  });

  final TextEditingController quantityController;
  final TextEditingController priceController;
  final FocusNode quantityFocusNode;
  final FocusNode priceFocusNode;
  final DateTime? productionDate;
  final String Function(DateTime date) formatDate;
  final VoidCallback onQuantityTap;
  final VoidCallback onPriceTap;
  final VoidCallback onPickProductionDate;
  final VoidCallback onClearProductionDate;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    final availableHeight = (screenSize.height - keyboardHeight).clamp(
      240.0,
      screenSize.height,
    );

    return SizedBox(
      width: 420,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: (availableHeight * 0.42).clamp(180.0, 420.0),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: quantityController,
                focusNode: quantityFocusNode,
                selectAllOnFocus: true,
                onTap: onQuantityTap,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'الكمية'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: priceController,
                focusNode: priceFocusNode,
                selectAllOnFocus: true,
                onTap: onPriceTap,
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'سعر البيع'),
              ),
              const SizedBox(height: 14),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'تاريخ إنتاج هذا المنتج',
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        productionDate == null
                            ? 'غير محدد'
                            : formatDate(productionDate!),
                      ),
                    ),
                    IconButton(
                      tooltip: 'اختيار تاريخ',
                      icon: const Icon(Icons.calendar_today_rounded),
                      onPressed: onPickProductionDate,
                    ),
                    IconButton(
                      tooltip: 'مسح التاريخ',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: productionDate == null
                          ? null
                          : onClearProductionDate,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LineEditResult {
  const _LineEditResult({
    required this.quantity,
    required this.unitPrice,
    required this.productionDate,
  });

  final int quantity;
  final int unitPrice;
  final DateTime? productionDate;
}

class _LineItem {
  final String? productId;
  final String? productName;
  final int? quantity;
  final int? unitPrice;
  final DateTime? productionDate;

  _LineItem({
    this.productId,
    this.productName,
    this.quantity,
    this.unitPrice,
    this.productionDate,
  });

  _LineItem copyWith({
    String? productId,
    String? productName,
    int? quantity,
    int? unitPrice,
    bool clearProduct = false,
    DateTime? productionDate,
    bool clearProductionDate = false,
  }) {
    return _LineItem(
      productId: clearProduct ? null : productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      productionDate: clearProductionDate
          ? null
          : productionDate ?? this.productionDate,
    );
  }
}
