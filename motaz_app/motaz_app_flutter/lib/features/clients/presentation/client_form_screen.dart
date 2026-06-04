import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/device_service.dart';
import '../application/client_providers.dart';

class ClientFormScreen extends ConsumerStatefulWidget {
  const ClientFormScreen({super.key, this.existingClient});

  final Client? existingClient;

  @override
  ConsumerState<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends ConsumerState<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  final _clientCodeController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _invoiceCheckIntervalController = TextEditingController();
  bool _saving = false;
  bool _isActive = true;

  bool get _isEditing => widget.existingClient != null;

  @override
  void initState() {
    super.initState();
    final c = widget.existingClient;
    if (c != null) {
      _displayNameController.text = c.displayName;
      _phoneController.text = c.phone ?? '';
      _emailController.text = c.email ?? '';
      _addressController.text = c.address ?? '';
      _noteController.text = c.note ?? '';
      _clientCodeController.text = c.clientCode ?? '';
      _creditLimitController.text = c.creditLimit == null
          ? ''
          : (c.creditLimit! / 100).toStringAsFixed(2);
      _invoiceCheckIntervalController.text =
          c.invoiceCheckIntervalDays?.toString() ?? '';
      _isActive = c.isActive;
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    _clientCodeController.dispose();
    _creditLimitController.dispose();
    _invoiceCheckIntervalController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_saving) return;

    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final address = _addressController.text.trim();
    final note = _noteController.text.trim();
    final clientCode = _clientCodeController.text.trim();
    final creditLimitText = _creditLimitController.text.trim();
    final invoiceCheckIntervalText = _invoiceCheckIntervalController.text
        .trim();

    if (phone.isEmpty &&
        email.isEmpty &&
        address.isEmpty &&
        note.isEmpty &&
        clientCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يجب إدخال حقل تعريف واحد على الأقل (هاتف، بريد، عنوان، ملاحظة، أو رمز)',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final device = await ref
          .read(deviceServiceProvider)
          .ensureCurrentDevice();
      if (!mounted) return;

      final repo = ref.read(clientRepositoryProvider);
      final creditLimit = creditLimitText.isEmpty
          ? null
          : (double.parse(creditLimitText) * 100).round();
      final invoiceCheckIntervalDays = invoiceCheckIntervalText.isEmpty
          ? null
          : int.parse(invoiceCheckIntervalText);
      final companion = ClientsCompanion(
        displayName: Value(_displayNameController.text.trim()),
        phone: Value(phone.isEmpty ? null : phone),
        email: Value(email.isEmpty ? null : email),
        address: Value(address.isEmpty ? null : address),
        note: Value(note.isEmpty ? null : note),
        clientCode: Value(clientCode.isEmpty ? null : clientCode),
        creditLimit: Value(creditLimit),
        invoiceCheckIntervalDays: Value(invoiceCheckIntervalDays),
        isActive: Value(_isActive),
        deviceId: Value(device.id),
      );

      if (_isEditing) {
        await repo.update(widget.existingClient!.id, companion);
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
        title: Text(_isEditing ? 'تعديل عميل' : 'إضافة عميل'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'اسم العرض *',
                ),
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'اسم العرض مطلوب';
                  }
                  if (v.trim().length > 200) {
                    return 'اسم العرض طويل جداً';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'الهاتف',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'العنوان',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'ملاحظة',
                ),
                maxLines: 2,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _clientCodeController,
                decoration: const InputDecoration(
                  labelText: 'رمز العميل',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _creditLimitController,
                decoration: const InputDecoration(
                  labelText: 'حد التنبيه للرصيد المتبقي',
                  suffixText: 'ر.ي.',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                validator: (v) {
                  final text = v?.trim() ?? '';
                  if (text.isEmpty) return null;
                  final parsed = double.tryParse(text);
                  if (parsed == null) return 'أدخل رقم صحيح';
                  if (parsed <= 0) return 'الحد يجب أن يكون أكبر من صفر';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _invoiceCheckIntervalController,
                decoration: const InputDecoration(
                  labelText: 'مدة السماح بدون فاتورة جديدة بالأيام',
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                validator: (v) {
                  final text = v?.trim() ?? '';
                  if (text.isEmpty) return null;
                  final parsed = int.tryParse(text);
                  if (parsed == null) return 'أدخل عدد أيام صحيح';
                  if (parsed <= 0) return 'المدة يجب أن تكون أكبر من صفر';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
                contentPadding: EdgeInsets.zero,
                title: const Text('حالة العميل'),
                subtitle: Text(_isActive ? 'نشط' : 'معطل'),
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
