import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/device_service.dart';
import '../../../core/database/enums/expense_category.dart';
import '../application/expense_providers.dart';

String categoryLabel(ExpenseCategory cat) {
  switch (cat) {
    case ExpenseCategory.OWNER_DRAW:
      return 'سحب مالك';
    case ExpenseCategory.PARTNER_DRAW:
      return 'سحب شريك';
    case ExpenseCategory.MARGIN_DRAW:
      return 'سحب هامش';
    case ExpenseCategory.OPERATIONAL:
      return 'تشغيلي';
    case ExpenseCategory.PRODUCTION:
      return 'إنتاج';
  }
}

class ExpenseFormScreen extends ConsumerStatefulWidget {
  const ExpenseFormScreen({super.key, this.existingExpense});

  final Expense? existingExpense;

  @override
  ConsumerState<ExpenseFormScreen> createState() =>
      _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  ExpenseCategory _category = ExpenseCategory.OPERATIONAL;
  DateTime _expenseDate = DateTime.now();
  bool _saving = false;

  bool get _isEditing => widget.existingExpense != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final e = widget.existingExpense!;
      _category = e.category;
      _amountController.text = (e.amount / 100).toStringAsFixed(2);
      _noteController.text = e.note ?? '';
      _expenseDate = e.expenseDate;
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _expenseDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_saving) return;

    final amountText = _amountController.text.trim();
    final parsed = double.tryParse(amountText);
    if (parsed == null || parsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('المبلغ يجب أن يكون أكبر من صفر')),
      );
      return;
    }
    final amount = (parsed * 100).round();

    setState(() => _saving = true);

    try {
      final device =
          await ref.read(deviceServiceProvider).ensureCurrentDevice();
      if (!mounted) return;

      final repo = ref.read(expenseRepositoryProvider);
      final note = _noteController.text.trim();

      if (_isEditing) {
        await repo.update(
          id: widget.existingExpense!.id,
          category: _category,
          amount: amount,
          expenseDate: _expenseDate,
          note: note.isEmpty ? null : note,
          deviceId: device.id,
        );
      } else {
        await repo.create(
          category: _category,
          amount: amount,
          expenseDate: _expenseDate,
          note: note.isEmpty ? null : note,
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل مصروف' : 'إضافة مصروف'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCategoryDropdown(),
              const SizedBox(height: 12),
              _buildAmountField(),
              const SizedBox(height: 12),
              _buildDateField(),
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

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<ExpenseCategory>(
      initialValue: _category,
      decoration: const InputDecoration(
        labelText: 'التصنيف *',
      ),
      items: ExpenseCategory.values.map((cat) {
        return DropdownMenuItem(
          value: cat,
          child: Text(categoryLabel(cat)),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _category = value);
        }
      },
      validator: (value) {
        if (value == null) return 'يرجى اختيار التصنيف';
        return null;
      },
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
        if (v == null || v.trim().isEmpty) return 'المبلغ مطلوب';
        final parsed = double.tryParse(v.trim());
        if (parsed == null) return 'أدخل رقم صحيح';
        if (parsed <= 0) return 'المبلغ يجب أن يكون أكبر من صفر';
        return null;
      },
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'تاريخ المصروف',
          suffixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          '${_expenseDate.year}-${_expenseDate.month.toString().padLeft(2, '0')}-${_expenseDate.day.toString().padLeft(2, '0')}',
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
