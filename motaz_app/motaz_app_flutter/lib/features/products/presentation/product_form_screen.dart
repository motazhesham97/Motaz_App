import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/device_service.dart';
import '../application/product_providers.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.existingProduct});

  final Product? existingProduct;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _unitController = TextEditingController();
  final _skuController = TextEditingController();
  final _shelfLifeDaysController = TextEditingController();
  bool _saving = false;

  bool get _isEditing => widget.existingProduct != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existingProduct;
    if (p != null) {
      _nameController.text = p.name;
      _descriptionController.text = p.description ?? '';
      _priceController.text = (p.defaultSalePrice / 100).toStringAsFixed(2);
      _unitController.text = p.unit ?? '';
      _skuController.text = p.sku ?? '';
      _shelfLifeDaysController.text = p.shelfLifeDays?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    _skuController.dispose();
    _shelfLifeDaysController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_saving) return;

    final name = _nameController.text.trim();
    final repo = ref.read(productRepositoryProvider);

    final taken = await repo.isNameTaken(
      name,
      excludeId: _isEditing ? widget.existingProduct!.id : null,
    );
    if (!mounted) return;
    if (taken) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اسم المنتج مستخدم بالفعل')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final device = await ref
          .read(deviceServiceProvider)
          .ensureCurrentDevice();
      if (!mounted) return;

      final salePrice = (double.parse(_priceController.text.trim()) * 100)
          .round();
      final desc = _descriptionController.text.trim();
      final unit = _unitController.text.trim();
      final sku = _skuController.text.trim();
      final shelfLifeText = _shelfLifeDaysController.text.trim();
      final shelfLifeDays = shelfLifeText.isEmpty
          ? null
          : int.parse(shelfLifeText);

      final companion = ProductsCompanion(
        name: Value(name),
        description: Value(desc.isEmpty ? null : desc),
        defaultSalePrice: Value(salePrice),
        unit: Value(unit.isEmpty ? null : unit),
        sku: Value(sku.isEmpty ? null : sku),
        shelfLifeDays: Value(shelfLifeDays),
        deviceId: Value(device.id),
      );

      if (_isEditing) {
        await repo.update(widget.existingProduct!.id, companion);
      } else {
        await repo.create(companion);
      }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل منتج' : 'إضافة منتج'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المنتج *',
                  hintText: 'مثال: عصير مانجو',
                ),
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'اسم المنتج مطلوب';
                  }
                  if (v.trim().length > 200) {
                    return 'اسم المنتج طويل جدا';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'الوصف'),
                maxLines: 3,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'سعر البيع *',
                  hintText: '500.00',
                  suffixText: 'ر.ي.',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'سعر البيع مطلوب';
                  }
                  final parsed = double.tryParse(v.trim());
                  if (parsed == null) return 'أدخل رقم صحيح';
                  if (parsed < 0) return 'السعر لا يمكن أن يكون سالبا';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(
                  labelText: 'الوحدة',
                  hintText: 'قطعة، كيلو، لتر',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _skuController,
                decoration: const InputDecoration(labelText: 'رمز SKU'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _shelfLifeDaysController,
                decoration: const InputDecoration(
                  labelText: 'صلاحية المنتج بالأيام',
                  hintText: 'اتركه فارغا إذا كان بدون انتهاء',
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                validator: (v) {
                  final text = v?.trim() ?? '';
                  if (text.isEmpty) return null;
                  final parsed = int.tryParse(text);
                  if (parsed == null) return 'أدخل عدد أيام صحيح';
                  if (parsed <= 0) return 'الصلاحية يجب أن تكون أكبر من صفر';
                  return null;
                },
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
                    : const Text('حفظ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
