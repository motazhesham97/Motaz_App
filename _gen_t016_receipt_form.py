#!/usr/bin/env python3
"""Generate receipt_form_screen.dart for T016"""

content = '''import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/device_service.dart';
import '../../clients/application/client_providers.dart';
import '../application/receipt_providers.dart';

class ReceiptFormScreen extends ConsumerStatefulWidget {
  const ReceiptFormScreen({
    super.key,
    this.invoiceId,
    this.clientId,
    this.maxAmount,
  });

  final String? invoiceId;
  final String? clientId;
  final int? maxAmount;

  @override
  ConsumerState<ReceiptFormScreen> createState() =>
      _ReceiptFormScreenState();
}

class _ReceiptFormScreenState extends ConsumerState<ReceiptFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _receiptDate = DateTime.now();
  Client? _selectedClient;
  bool _saving = false;
  bool _loadingClient = true;

  bool get _isInvoiceLinked => widget.invoiceId != null;

  int get _amount {
    final text = _amountController.text.trim();
    if (text.isEmpty) return 0;
    final parsed = double.tryParse(text);
    if (parsed == null) return 0;
    return (parsed * 100).round();
  }

  @override
  void initState() {
    super.initState();
    if (_isInvoiceLinked && widget.clientId != null) {
      _loadClient();
    } else {
      _loadingClient = false;
    }
  }

  Future<void> _loadClient() async {
    try {
      final client = await ref
          .read(clientRepositoryProvider)
          .getById(widget.clientId!);
      if (mounted) {
        setState(() {
          _selectedClient = client;
          _loadingClient = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingClient = false);
      }
    }
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
      initialDate: _receiptDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _receiptDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_saving) return;

    if (!_isInvoiceLinked && _selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار العميل')),
      );
      return;
    }

    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('المبلغ يجب أن يكون أكبر من صفر')),
      );
      return;
    }

    if (_isInvoiceLinked && widget.maxAmount != null && _amount > widget.maxAmount!) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('المبلغ لا يمكن أن يتجاوز ${((widget.maxAmount!) /100).toStringAsFixed(2)} ر.ي.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final device =
          await ref.read(deviceServiceProvider).ensureCurrentDevice();
      if (!mounted) return;

      final repo = ref.read(receiptRepositoryProvider);

      if (_isInvoiceLinked) {
        await repo.createInvoiceLinked(
          clientId: widget.clientId!,
          invoiceId: widget.invoiceId!,
          amount: _amount,
          receiptDate: _receiptDate,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          deviceId: device.id,
        );
      } else {
        await repo.createGeneral(
          clientId: _selectedClient!.id,
          amount: _amount,
          receiptDate: _receiptDate,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          deviceId: device.id,
        );
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
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingClient) {
      return Scaffold(
        appBar: AppBar(title: const Text('إضافة دفعة')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isInvoiceLinked
            ? 'إضافة دفعة مرتبطة بفاتورة'
            : 'إضافة دفعة عامة'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildClientField(),
              const SizedBox(height: 12),
              _buildDateField(),
              const SizedBox(height: 12),
              _buildAmountField(),
              if (_isInvoiceLinked && widget.maxAmount != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'الحد الأقصى: ${(widget.maxAmount! / 100).toStringAsFixed(2)} ر.ي.',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
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

  Widget _buildClientField() {
    if (_isInvoiceLinked) {
      return InputDecorator(
        decoration: const InputDecoration(
          labelText: 'العميل',
        ),
        child: Text(_selectedClient?.displayName ?? '---'),
      );
    }

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

  Widget _buildDateField() {
    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'تاريخ الدفعة',
          suffixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          '${_receiptDate.year}-${_receiptDate.month.toString().padLeft(2, '0')}-${_receiptDate.day.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      decoration: const InputDecoration(
        labelText: 'المبلغ *',
        suffixText: 'ر.ي.',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return 'المبلغ مطلوب';
        }
        final parsed = double.tryParse(v.trim());
        if (parsed == null) {
          return 'أدخل رقم صحيح';
        }
        if (parsed <= 0) {
          return 'المبلغ يجب أن يكون أكبر من صفر';
        }
        return null;
      },
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
'''

output_path = 'D:/Motaz_App2/motaz_app/motaz_app_flutter/lib/features/receipts/presentation/receipt_form_screen.dart'

with open(output_path, 'w', encoding='utf-8', newline='\n') as f:
    f.write(content)

print(f'Written to {output_path}')