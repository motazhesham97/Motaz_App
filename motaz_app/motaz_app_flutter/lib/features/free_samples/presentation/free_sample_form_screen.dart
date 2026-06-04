import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/device_service.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../products/application/product_providers.dart';
import '../application/free_sample_providers.dart';
import '../data/free_sample_repository.dart';

class FreeSampleFormScreen extends ConsumerStatefulWidget {
  const FreeSampleFormScreen({super.key, this.sampleId});

  final String? sampleId;

  @override
  ConsumerState<FreeSampleFormScreen> createState() =>
      _FreeSampleFormScreenState();
}

class _FreeSampleFormScreenState extends ConsumerState<FreeSampleFormScreen> {
  final _productController = TextEditingController();
  final _noteController = TextEditingController();
  final _lines = <FreeSampleDraftLine>[];
  Beneficiary? _loadedBeneficiary;
  DateTime? _loadedDate;
  String _productQuery = '';
  bool _isLoading = false;

  bool get _isEditMode => widget.sampleId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      Future.microtask(_loadForEdit);
    }
  }

  @override
  void dispose() {
    _productController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool _matchesWordPrefix(String value, String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return value
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .any((word) => word.startsWith(normalized));
  }

  Future<void> _loadForEdit() async {
    final sampleId = widget.sampleId;
    if (sampleId == null) return;
    setState(() => _isLoading = true);
    final data = await ref
        .read(freeSampleRepositoryProvider)
        .getForEdit(
          sampleId,
        );
    if (!mounted) return;
    if (data == null) {
      _showMessage('لم يتم العثور على العينة');
      context.go('/free-samples');
      return;
    }
    setState(() {
      _lines
        ..clear()
        ..addAll(data.lines);
      _noteController.text = data.sample.note ?? '';
      _loadedBeneficiary = data.beneficiary;
      _loadedDate = data.sample.sampleDate;
      _isLoading = false;
    });
  }

  void _addProduct(Product product) {
    final existingIndex = _lines.indexWhere(
      (line) => line.product.id == product.id,
    );
    setState(() {
      if (existingIndex >= 0) {
        final existing = _lines[existingIndex];
        _lines[existingIndex] = FreeSampleDraftLine(
          product: existing.product,
          quantity: existing.quantity + 1,
        );
      } else {
        _lines.add(FreeSampleDraftLine(product: product, quantity: 1));
      }
      _productController.clear();
      _productQuery = '';
    });
  }

  Future<void> _editQuantity(int index) async {
    if (index < 0 || index >= _lines.length) return;
    final line = _lines[index];
    final quantity = await showDialog<int>(
      context: context,
      builder: (_) => _QuantityEditDialog(
        productName: line.product.name,
        initialQuantity: line.quantity,
      ),
    );
    if (quantity == null) return;
    FocusManager.instance.primaryFocus?.unfocus();
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || index >= _lines.length) return;
    setState(() {
      _lines[index] = FreeSampleDraftLine(
        product: line.product,
        quantity: quantity,
      );
    });
  }

  Future<void> _quickAddProduct() async {
    final Device device;
    try {
      device = await ref.read(deviceServiceProvider).ensureCurrentDevice();
    } catch (error) {
      _showMessage(error.toString());
      return;
    }
    if (!mounted) return;

    final nameController = TextEditingController(text: _productQuery.trim());
    final unitController = TextEditingController(text: 'حبة');
    final product = await showDialog<Product>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إضافة منتج'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'اسم المنتج'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(labelText: 'الوحدة'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                FocusScope.of(context).unfocus();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) Navigator.pop(context);
                });
              },
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final focusScope = FocusScope.of(context);
                final navigator = Navigator.of(context);
                final now = DateTime.now();
                final saved = await ref
                    .read(productRepositoryProvider)
                    .createAndReturn(
                      ProductsCompanion.insert(
                        id: '',
                        name: name,
                        defaultSalePrice: 0,
                        description: const Value(null),
                        unit: Value(
                          unitController.text.trim().isEmpty
                              ? null
                              : unitController.text.trim(),
                        ),
                        sku: const Value(null),
                        isActive: const Value(true),
                        createdAt: now,
                        updatedAt: now,
                        deviceId: device.id,
                      ),
                    );
                focusScope.unfocus();
                await WidgetsBinding.instance.endOfFrame;
                if (navigator.mounted) navigator.pop(saved);
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
    if (product != null) _addProduct(product);
  }

  Future<void> _openSaveDialog() async {
    if (_lines.isEmpty) {
      _showMessage('أضف منتجا واحدا على الأقل');
      return;
    }

    final Device device;
    try {
      device = await ref.read(deviceServiceProvider).ensureCurrentDevice();
    } catch (error) {
      _showMessage(error.toString());
      return;
    }
    if (!mounted) return;

    final beneficiaries = await ref
        .read(beneficiaryRepositoryProvider)
        .watchAll()
        .first;
    if (!mounted) return;

    final beneficiaryController = TextEditingController(
      text: _loadedBeneficiary?.displayName ?? '',
    );
    var selectedDate = _loadedDate ?? DateTime.now();
    Beneficiary? selectedBeneficiary = _loadedBeneficiary;
    var beneficiaryQuery = beneficiaryController.text;
    var creatingBeneficiary = false;

    final saveRequest = await showDialog<_FreeSampleSaveRequest>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final suggestions = beneficiaryQuery.trim().isEmpty
                ? <Beneficiary>[]
                : beneficiaries
                      .where(
                        (beneficiary) => _matchesWordPrefix(
                          beneficiary.displayName,
                          beneficiaryQuery,
                        ),
                      )
                      .take(6)
                      .toList();
            final exactExists = beneficiaries.any(
              (beneficiary) =>
                  beneficiary.displayName.trim().toLowerCase() ==
                  beneficiaryQuery.trim().toLowerCase(),
            );

            return AlertDialog(
              title: Text(_isEditMode ? 'تحديث العينة' : 'حفظ العينة'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: beneficiaryController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'اسم المستفيد',
                        prefixIcon: Icon(Icons.person_search_rounded),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          beneficiaryQuery = value;
                          selectedBeneficiary = null;
                        });
                      },
                    ),
                    if (suggestions.isNotEmpty)
                      ...suggestions.map(
                        (beneficiary) => ListTile(
                          title: Text(beneficiary.displayName),
                          onTap: () {
                            setDialogState(() {
                              selectedBeneficiary = beneficiary;
                              beneficiaryQuery = beneficiary.displayName;
                              beneficiaryController.text =
                                  beneficiary.displayName;
                            });
                          },
                        ),
                      ),
                    if (beneficiaryQuery.trim().isNotEmpty &&
                        !exactExists &&
                        selectedBeneficiary == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'هذا المستفيد غير موجود',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: creatingBeneficiary
                                  ? null
                                  : () async {
                                      setDialogState(() {
                                        creatingBeneficiary = true;
                                      });
                                      try {
                                        final beneficiary = await ref
                                            .read(beneficiaryRepositoryProvider)
                                            .createAndReturn(
                                              displayName: beneficiaryQuery,
                                              deviceId: device.id,
                                            );
                                        if (!context.mounted) return;
                                        setDialogState(() {
                                          selectedBeneficiary = beneficiary;
                                          beneficiaryQuery =
                                              beneficiary.displayName;
                                          beneficiaryController.text =
                                              beneficiary.displayName;
                                          creatingBeneficiary = false;
                                        });
                                      } catch (error) {
                                        if (!context.mounted) return;
                                        setDialogState(() {
                                          creatingBeneficiary = false;
                                        });
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(error.toString()),
                                          ),
                                        );
                                      }
                                    },
                              icon: const Icon(Icons.add),
                              label: const Text('أضف المستفيد'),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(selectedDate.year - 10),
                          lastDate: DateTime(selectedDate.year + 1),
                        );
                        if (!context.mounted) return;
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_month_rounded),
                      label: Text(_formatDate(selectedDate)),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: creatingBeneficiary
                      ? null
                      : () async {
                          final navigator = Navigator.of(context);
                          FocusScope.of(context).unfocus();
                          await Future<void>.delayed(
                            const Duration(milliseconds: 260),
                          );
                          if (navigator.mounted) navigator.pop();
                        },
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: selectedBeneficiary == null || creatingBeneficiary
                      ? null
                      : () async {
                          final beneficiary = selectedBeneficiary;
                          if (beneficiary == null) return;
                          final navigator = Navigator.of(context);
                          FocusScope.of(context).unfocus();
                          await Future<void>.delayed(
                            const Duration(milliseconds: 260),
                          );
                          if (!navigator.mounted) return;
                          navigator.pop(
                            _FreeSampleSaveRequest(
                              beneficiary: beneficiary,
                              sampleDate: selectedDate,
                            ),
                          );
                        },
                  child: creatingBeneficiary
                      ? const SizedBox(
                          width: 18,
                          height: 18,
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

    if (saveRequest != null && mounted) {
      setState(() => _isLoading = true);
      try {
        final sampleId = widget.sampleId;
        if (sampleId == null) {
          await ref
              .read(freeSampleRepositoryProvider)
              .create(
                beneficiaryId: saveRequest.beneficiary.id,
                sampleDate: saveRequest.sampleDate,
                lines: _lines,
                deviceId: device.id,
                note: _noteController.text,
              );
        } else {
          await ref
              .read(freeSampleRepositoryProvider)
              .update(
                sampleId: sampleId,
                beneficiaryId: saveRequest.beneficiary.id,
                sampleDate: saveRequest.sampleDate,
                lines: _lines,
                deviceId: device.id,
                note: _noteController.text,
              );
        }
      } catch (error) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showMessage(error.toString());
        return;
      }
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (_isEditMode) {
        _showMessage('تم تحديث العينة المجانية بنجاح');
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return;
        context.go('/free-samples');
        return;
      }
      setState(() {
        _lines.clear();
        _noteController.clear();
      });
      _showMessage('تم حفظ العينة المجانية بنجاح');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = ref
        .watch(productListProvider)
        .maybeWhen(
          data: (rows) => rows.where((product) => product.isActive).toList(),
          orElse: () => <Product>[],
        );
    final suggestions = _productQuery.trim().isEmpty
        ? <Product>[]
        : products
              .where(
                (product) => _matchesWordPrefix(product.name, _productQuery),
              )
              .take(6)
              .toList();
    final productExists = products.any(
      (product) =>
          product.name.trim().toLowerCase() ==
          _productQuery.trim().toLowerCase(),
    );

    return AppDrawerScaffold(
      title: _isEditMode ? 'تعديل عينة مجانية' : 'إضافة عينة مجانية',
      currentRoute: '/free-samples',
      leading: IconButton(
        icon: const BackButtonIcon(),
        onPressed: () => context.go('/free-samples'),
      ),
      child: Scaffold(
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          TextField(
                            controller: _productController,
                            decoration: const InputDecoration(
                              labelText: 'ادخل اسم المنتج',
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (value) {
                              setState(() => _productQuery = value);
                            },
                          ),
                          if (suggestions.isNotEmpty)
                            Card(
                              margin: const EdgeInsets.only(top: 8),
                              child: Column(
                                children: suggestions
                                    .map(
                                      (product) => ListTile(
                                        title: Text(product.name),
                                        subtitle: Text(product.unit ?? ''),
                                        onTap: () => _addProduct(product),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          if (_productQuery.trim().isNotEmpty &&
                              suggestions.isEmpty &&
                              !productExists)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'هذا المنتج غير موجود، هل تريد إضافته؟',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                      ),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: _quickAddProduct,
                                    icon: const Icon(Icons.add),
                                    label: const Text('أضف المنتج'),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 20),
                          if (_lines.isEmpty)
                            const Center(
                              child: Text('لم تتم إضافة منتجات بعد'),
                            )
                          else
                            Card(
                              child: Column(
                                children: [
                                  const ListTile(
                                    title: Row(
                                      children: [
                                        Expanded(child: Text('المنتج')),
                                        SizedBox(
                                          width: 90,
                                          child: Text('العدد'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(height: 1),
                                  ...List.generate(_lines.length, (index) {
                                    final line = _lines[index];
                                    return InkWell(
                                      onDoubleTap: () => _editQuantity(index),
                                      onLongPress: () => _editQuantity(index),
                                      child: ListTile(
                                        title: Text(line.product.name),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(line.quantity.toString()),
                                            IconButton(
                                              onPressed: () {
                                                setState(
                                                  () => _lines.removeAt(index),
                                                );
                                              },
                                              icon: const Icon(
                                                Icons.delete_outline,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _noteController,
                            minLines: 2,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'ملاحظة',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _lines.isEmpty
                                  ? null
                                  : () => setState(() => _lines.clear()),
                              child: const Text('مسح'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: _openSaveDialog,
                              child: const Text('حفظ'),
                            ),
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

class _FreeSampleSaveRequest {
  const _FreeSampleSaveRequest({
    required this.beneficiary,
    required this.sampleDate,
  });

  final Beneficiary beneficiary;
  final DateTime sampleDate;
}

class _QuantityEditDialog extends StatefulWidget {
  const _QuantityEditDialog({
    required this.productName,
    required this.initialQuantity,
  });

  final String productName;
  final int initialQuantity;

  @override
  State<_QuantityEditDialog> createState() => _QuantityEditDialogState();
}

class _QuantityEditDialogState extends State<_QuantityEditDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialQuantity.toString(),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value <= 0) return;
    final navigator = Navigator.of(context);
    FocusScope.of(context).unfocus();
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    navigator.pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.productName),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'العدد'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () {
            FocusManager.instance.primaryFocus?.unfocus();
            Navigator.of(context).pop();
          },
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('تم'),
        ),
      ],
    );
  }
}
