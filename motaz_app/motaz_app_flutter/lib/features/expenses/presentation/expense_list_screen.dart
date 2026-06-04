import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/device_service.dart';
import '../../../core/database/enums/expense_category.dart';
import '../../../core/database/enums/parent_entity_type.dart';
import '../../../core/database/enums/record_status.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/audit_trail_sheet.dart';
import '../../reports/data/report_models.dart';
import '../../reports/pdf/pdf_generator.dart';
import '../../reports/pdf/pdf_styles.dart';
import '../../reports/pdf/pdf_templates/expense_report_pdf.dart';
import '../application/expense_providers.dart';
import 'expense_form_screen.dart' show ExpenseFormScreen, categoryLabel;

enum _ExpenseSearchMode { category, date }

class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  bool _showSearchPanel = false;
  bool _isExporting = false;
  _ExpenseSearchMode _searchMode = _ExpenseSearchMode.category;
  ExpenseCategory? _draftCategory;
  DateTime? _draftDate;
  ExpenseCategory? _appliedCategory;
  DateTime? _appliedDate;
  ExpenseCategory? _advancedCategory;
  DateTime? _advancedFromDate;
  DateTime? _advancedToDate;

  bool get _hasActiveFilter =>
      _appliedCategory != null ||
      _appliedDate != null ||
      _advancedCategory != null;

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  List<Expense> _filterExpenses(List<Expense> expenses) {
    final advancedCategory = _advancedCategory;
    final fromDate = _advancedFromDate;
    final toDate = _advancedToDate;
    if (advancedCategory != null && fromDate != null && toDate != null) {
      return expenses.where((expense) {
        return expense.category == advancedCategory &&
            !expense.expenseDate.isBefore(_dateOnly(fromDate)) &&
            expense.expenseDate.isBefore(
              _dateOnly(toDate).add(const Duration(days: 1)),
            );
      }).toList();
    }

    final category = _appliedCategory;
    if (category != null) {
      return expenses.where((expense) => expense.category == category).toList();
    }

    final date = _appliedDate;
    if (date != null) {
      return expenses
          .where((expense) => _sameDate(expense.expenseDate, date))
          .toList();
    }

    return expenses;
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int _totalAmount(List<Expense> expenses) {
    return expenses.fold<int>(0, (sum, expense) => sum + expense.amount);
  }

  void _applySearch() {
    setState(() {
      _advancedCategory = null;
      _advancedFromDate = null;
      _advancedToDate = null;
      if (_searchMode == _ExpenseSearchMode.category) {
        _appliedCategory = _draftCategory;
        _appliedDate = null;
      } else {
        _appliedDate = _draftDate;
        _appliedCategory = null;
      }
    });
  }

  void _clearSearch() {
    setState(() {
      _draftCategory = null;
      _draftDate = null;
      _appliedCategory = null;
      _appliedDate = null;
      _advancedCategory = null;
      _advancedFromDate = null;
      _advancedToDate = null;
    });
  }

  Future<void> _pickQuickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _draftDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null && mounted) {
      setState(() => _draftDate = picked);
    }
  }

  Future<DateTime?> _pickDialogDate(DateTime? initialDate) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1),
    );
  }

  Future<void> _showAdvancedSearchDialog() async {
    ExpenseCategory? category = _advancedCategory ?? _draftCategory;
    DateTime? fromDate = _advancedFromDate;
    DateTime? toDate = _advancedToDate;

    final applied = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final canSearch =
                category != null &&
                fromDate != null &&
                toDate != null &&
                !toDate!.isBefore(fromDate!);
            return AlertDialog(
              title: const Text('بحث متقدم'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<ExpenseCategory>(
                    initialValue: category,
                    decoration: const InputDecoration(labelText: 'التصنيف *'),
                    items: ExpenseCategory.values.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(categoryLabel(cat)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() => category = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await _pickDialogDate(fromDate);
                      if (picked != null) {
                        setDialogState(() => fromDate = picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_month),
                    label: Text(
                      fromDate == null
                          ? 'من تاريخ *'
                          : 'من ${_formatDate(fromDate!)}',
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await _pickDialogDate(toDate ?? fromDate);
                      if (picked != null) {
                        setDialogState(() => toDate = picked);
                      }
                    },
                    icon: const Icon(Icons.event),
                    label: Text(
                      toDate == null
                          ? 'إلى تاريخ *'
                          : 'إلى ${_formatDate(toDate!)}',
                    ),
                  ),
                  if (fromDate != null &&
                      toDate != null &&
                      toDate!.isBefore(fromDate!))
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'تاريخ النهاية يجب أن يكون بعد تاريخ البداية',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('إلغاء'),
                ),
                FilledButton.icon(
                  onPressed: canSearch
                      ? () => Navigator.of(context).pop(true)
                      : null,
                  icon: const Icon(Icons.search),
                  label: const Text('بحث'),
                ),
              ],
            );
          },
        );
      },
    );

    if (applied == true && mounted) {
      setState(() {
        _advancedCategory = category;
        _advancedFromDate = fromDate;
        _advancedToDate = toDate;
        _appliedCategory = null;
        _appliedDate = null;
        _draftCategory = null;
        _draftDate = null;
      });
    }
  }

  Future<void> _exportPdf(List<Expense> expenses) async {
    setState(() => _isExporting = true);
    try {
      final styles = await PdfStyles.load();
      final doc = ExpenseReportPdf.generate(styles, _buildReportData(expenses));
      await PdfGenerator.shareOrPrint(doc, 'expense_report.pdf');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  ExpenseReportData _buildReportData(List<Expense> expenses) {
    return ExpenseReportData(
      rows: expenses.map(_toReportRow).toList(),
      totalAmount: _totalAmount(expenses),
      filterLabel: _activeFilterLabel(),
    );
  }

  ExpenseReportRow _toReportRow(Expense expense) {
    return ExpenseReportRow(
      id: expense.id,
      category: expense.category,
      categoryLabel: categoryLabel(expense.category),
      expenseDate: expense.expenseDate,
      amount: expense.amount,
      note: expense.note,
    );
  }

  String _activeFilterLabel() {
    final advancedCategory = _advancedCategory;
    if (advancedCategory != null &&
        _advancedFromDate != null &&
        _advancedToDate != null) {
      return '${categoryLabel(advancedCategory)} من ${_formatDate(_advancedFromDate!)} إلى ${_formatDate(_advancedToDate!)}';
    }
    final category = _appliedCategory;
    if (category != null) return 'التصنيف: ${categoryLabel(category)}';
    final date = _appliedDate;
    if (date != null) return 'تاريخ الصرف: ${_formatDate(date)}';
    return 'كل المصروفات';
  }

  Future<void> _showVoidDialog(Expense expense) async {
    final reasonController = TextEditingController();
    String reasonText = '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إلغاء المصروف'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('هل أنت متأكد من إلغاء هذا المصروف؟'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'سبب الإلغاء *',
                hintText: 'أدخل سبب الإلغاء',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('تراجع'),
          ),
          TextButton(
            onPressed: () {
              final text = reasonController.text.trim();
              if (text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('سبب الإلغاء مطلوب')),
                );
                return;
              }
              reasonText = text;
              Navigator.of(context).pop(true);
            },
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
    reasonController.dispose();

    if (confirmed == true) {
      await _voidExpense(expense, reasonText);
    }
  }

  Future<void> _voidExpense(Expense expense, String reason) async {
    try {
      final device = await ref
          .read(deviceServiceProvider)
          .ensureCurrentDevice();
      final repo = ref.read(expenseRepositoryProvider);
      await repo.voidExpense(expense.id, reason, device.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إلغاء المصروف')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expenseListProvider);

    return AppDrawerScaffold(
      title: 'المصروفات',
      currentRoute: '/expenses',
      child: Scaffold(
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildActiveSearchSummary()),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'بحث',
                        onPressed: () {
                          setState(() => _showSearchPanel = !_showSearchPanel);
                        },
                        icon: Icon(
                          _showSearchPanel ? Icons.close : Icons.search,
                        ),
                      ),
                    ],
                  ),
                  if (_showSearchPanel) ...[
                    const SizedBox(height: 10),
                    _buildSearchPanel(),
                  ],
                ],
              ),
            ),
            Expanded(
              child: expensesAsync.when(
                data: (expenses) {
                  final filteredExpenses = _filterExpenses(expenses);
                  if (filteredExpenses.isEmpty) {
                    return Center(
                      child: Text(
                        _hasActiveFilter
                            ? 'لا توجد مصروفات مطابقة للبحث'
                            : 'لا توجد مصروفات',
                      ),
                    );
                  }

                  return Column(
                    children: [
                      if (_hasActiveFilter)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'الإجمالي: ${formatMoney(_totalAmount(filteredExpenses))}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              FilledButton.icon(
                                onPressed: _isExporting
                                    ? null
                                    : () => _exportPdf(filteredExpenses),
                                icon: _isExporting
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.surface,
                                        ),
                                      )
                                    : const Icon(Icons.picture_as_pdf),
                                label: Text(
                                  _isExporting ? 'جاري...' : 'تصدير PDF',
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(child: _buildExpenseList(filteredExpenses)),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('خطأ: $error')),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ExpenseFormScreen(),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildActiveSearchSummary() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.centerRight,
      child: Text(_activeFilterLabel(), overflow: TextOverflow.ellipsis),
    );
  }

  Widget _buildSearchPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<_ExpenseSearchMode>(
              segments: const [
                ButtonSegment(
                  value: _ExpenseSearchMode.category,
                  icon: Icon(Icons.category_rounded),
                  label: Text('التصنيف'),
                ),
                ButtonSegment(
                  value: _ExpenseSearchMode.date,
                  icon: Icon(Icons.calendar_month),
                  label: Text('تاريخ الصرف'),
                ),
              ],
              selected: {_searchMode},
              onSelectionChanged: (selection) {
                setState(() {
                  _searchMode = selection.first;
                  _draftCategory = null;
                  _draftDate = null;
                });
              },
            ),
            const SizedBox(height: 12),
            if (_searchMode == _ExpenseSearchMode.category)
              _buildCategorySearchField()
            else
              _buildDateSearchField(),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed:
                      (_searchMode == _ExpenseSearchMode.category &&
                              _draftCategory == null) ||
                          (_searchMode == _ExpenseSearchMode.date &&
                              _draftDate == null)
                      ? null
                      : _applySearch,
                  icon: const Icon(Icons.search),
                  label: const Text('بحث'),
                ),
                OutlinedButton.icon(
                  onPressed: _showAdvancedSearchDialog,
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('بحث متقدم'),
                ),
                TextButton.icon(
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.clear),
                  label: const Text('مسح'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySearchField() {
    return DropdownButtonFormField<ExpenseCategory>(
      initialValue: _draftCategory,
      decoration: const InputDecoration(labelText: 'التصنيف'),
      items: ExpenseCategory.values.map((cat) {
        return DropdownMenuItem(
          value: cat,
          child: Text(categoryLabel(cat)),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _draftCategory = value);
      },
    );
  }

  Widget _buildDateSearchField() {
    return OutlinedButton.icon(
      onPressed: _pickQuickDate,
      icon: const Icon(Icons.calendar_month),
      label: Text(
        _draftDate == null ? 'اختيار تاريخ الصرف' : _formatDate(_draftDate!),
      ),
    );
  }

  Widget _buildExpenseList(List<Expense> expenses) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: expenses.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final expense = expenses[index];
        final isVoided = expense.status == RecordStatus.VOIDED;
        final note = expense.note?.trim();
        final title = note == null || note.isEmpty ? 'مصروف بدون ملاحظة' : note;

        return Opacity(
          opacity: isVoided ? 0.6 : 1.0,
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: isVoided
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExpenseFormScreen(
                            existingExpense: expense,
                          ),
                        ),
                      );
                    },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isVoided
                                ? Colors.red.withValues(alpha: 0.1)
                                : Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.money_off_rounded,
                            color: isVoided
                                ? Colors.red
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF8B97E),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Text(
                                    categoryLabel(expense.category),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    _formatDate(expense.expenseDate),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            formatMoney(expense.amount),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.history,
                                size: 20,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              tooltip: 'سجل التعديلات',
                              onPressed: () {
                                showAuditTrailSheet(
                                  context,
                                  ref,
                                  ParentEntityType.EXPENSE,
                                  expense.id,
                                );
                              },
                            ),
                            if (isVoided)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.red.shade200,
                                  ),
                                ),
                                child: const Text(
                                  'ملغى',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else
                              PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                                onSelected: (value) {
                                  if (value == 'void') {
                                    _showVoidDialog(expense);
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: 'void',
                                    child: Text('إلغاء المصروف'),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
