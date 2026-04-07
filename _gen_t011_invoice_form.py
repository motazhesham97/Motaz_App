#!/usr/bin/env python3
"""Generate invoice_form_screen.dart for T011 (create mode)"""

import os

content = '''import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/device_service.dart';
import '../../clients/application/client_providers.dart';
import '../../products/application/product_providers.dart';
import '../application/invoice_providers.dart';
import '../data/invoice_repository.dart';

class InvoiceFormScreen extends ConsumerStatefulWidget {
  const InvoiceFormScreen({super.key});

  @override
  ConsumerState<InvoiceFormScreen> createState() =>
      _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends ConsumerState<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  Client? _selectedClient;
  DateTime _invoiceDate = DateTime.now();
  final List<_LineItem> _lines = [];
  final _discountController = TextEditingController();
  final _paidAmountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _saving = false;

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

  void _addLine() {
    setState(() {
      _lines.add(_LineItem(
        productId: null,
        productName: null,
        quantity: 1,
        unitPrice: null,
      ));
    });
  }

  void _removeLine(int index) {
    setState(() {
      _lines.removeAt(index);
    });
  }

  Future<void> _selectClient() async {
    final clients = await ref.read(clientListProvider.future);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر العميل'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: clients.length,
            itemBuilder: (context, index) {
              final client = clients[index];
              return ListTile(
                title: Text(client.displayName),
                subtitle: client.phone != null ? Text(client.phone!) : null,
                onTap: () {
                  setState(() {
                    _selectedClient = client;
                  });
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_saving) return;

    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار العميل')),
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
      if (line.productId == null || line.quantity == null || line.unitPrice == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('السطر ${i + 1} غير مكتمل')),
        );
        return;
      }
    }

    if (_discount > _subtotal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الخصم لا يمكن أن يتجاوز الإجمالي الفرعي')),
      );
      return;
    }

    if (_paidAmount > _total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('المبلغ المدفوع لا يمكن أن يتجاوز الإجمالي')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final device =
          await ref.read(deviceServiceProvider).ensureCurrentDevice();
      if (!mounted) return;

      final lines = _lines.map((line) {
        return SalesInvoiceLinesCompanion(
          productId: Value(line.productId!),
          quantity: Value(line.quantity!),
          unitPrice: Value(line.unitPrice!),
          lineTotal: Value(line.quantity! * line.unitPrice!),
        );
      }).toList();

      final repo = ref.read(invoiceRepositoryProvider);
      await repo.create(
        clientId: _selectedClient!.id,
        invoiceDate: _invoiceDate,
        discount: _discount,
        note: _noteController.text.trim(),
        lines: lines,
        paidAmount: _paidAmount,
        deviceId: device.id,
      );

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
  void dispose() {
    _discountController.dispose();
    _paidAmountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء فاتورة'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildClientSelector(),
              const SizedBox(height: 12),
              _buildDateSelector(),
              const SizedBox(height: 16),
              _buildLinesSection(),
              const SizedBox(height: 16),
              _buildTotalsSection(),
              const SizedBox(height: 12),
              _buildNoteField(),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
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

  Widget _buildClientSelector() {
    return InkWell(
      onTap: _selectClient,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'العميل *',
          suffixIcon: Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          _selectedClient?.displayName ?? 'اضغط للاختيار',
          style: TextStyle(
            color: _selectedClient == null ? Colors.grey : null,
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'تاريخ الفاتورة',
          suffixIcon: Icon(Icons.calendar_today),
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
                  child: _buildProductAutocomplete(line, index),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    initialValue: line.quantity?.toString() ?? '1',
                    decoration: const InputDecoration(
                      labelText: 'الكمية',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final parsed = int.tryParse(v);
                      setState(() {
                        _lines[index] = _lines[index].copyWith(quantity: parsed);
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
                    decoration: const InputDecoration(
                      labelText: 'سعر الوحدة',
                      suffixText: 'ر.ي.',
                      isDense: true,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) {
                      final parsed = double.tryParse(v);
                      setState(() {
                        _lines[index] = _lines[index].copyWith(
                          unitPrice: parsed != null ? (parsed * 100).round() : null,
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
          ],
        ),
      ),
    );
  }

  Widget _buildProductAutocomplete(_LineItem line, int index) {
    return Autocomplete<Product>(
      displayStringForOption: (p) => p.name,
      optionsBuilder: (textEditingValue) async {
        final query = textEditingValue.text.trim();
        if (query.isEmpty) return [];
        final products = await ref.read(activeProductSearchProvider(query).future);
        return products.where((p) => p.isActive).toList();
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
        controller.text = line.productName ?? '';
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'المنتج',
            isDense: true,
          ),
          validator: (v) {
            if (_lines[index].productId == null && v != null && v.isNotEmpty) {
              return 'اختر منتج صحيح';
            }
            return null;
          },
        );
      },
    );
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
              decoration: const InputDecoration(
                labelText: 'الخصم',
                suffixText: 'ر.ي.',
                isDense: true,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                const Text('الإجمالي:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '${(_total / 100).toStringAsFixed(2)} ر.ي.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            TextFormField(
              controller: _paidAmountController,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteField() {
    return TextFormField(
      controller: _noteController,
      decoration: const InputDecoration(
        labelText: 'ملاحظة',
        alignLabelWithHint: true,
      ),
      maxLines: 3,
    );
  }
}

class _LineItem {
  final String? productId;
  final String? productName;
  final int? quantity;
  final int? unitPrice;

  _LineItem({
    this.productId,
    this.productName,
    this.quantity,
    this.unitPrice,
  });

  _LineItem copyWith({
    String? productId,
    String? productName,
    int? quantity,
    int? unitPrice,
  }) {
    return _LineItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }
}
'''

output_path = 'D:/Motaz_App2/motaz_app/motaz_app_flutter/lib/features/invoices/presentation/invoice_form_screen.dart'

with open(output_path, 'w', encoding='utf-8', newline='\n') as f:
    f.write(content)

print(f'Written to {output_path}')