import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/enums/expense_category.dart';
import '../../../core/utils/date_range.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../expenses/application/expense_providers.dart';
import '../../expenses/presentation/expense_form_screen.dart'
    show categoryLabel;
import '../data/report_models.dart';
import '../pdf/pdf_file_names.dart';
import '../pdf/pdf_generator.dart';
import '../pdf/pdf_styles.dart';
import '../pdf/pdf_templates/expense_report_pdf.dart';
import 'widgets/date_range_picker.dart';

class ExpenseReportScreen extends ConsumerStatefulWidget {
  const ExpenseReportScreen({super.key});

  @override
  ConsumerState<ExpenseReportScreen> createState() =>
      _ExpenseReportScreenState();
}

class _ExpenseReportScreenState extends ConsumerState<ExpenseReportScreen> {
  late DateRange _selectedRange;
  ExpenseCategory? _selectedCategory;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _selectedRange = DateRange.thisMonth();
  }

  List<Expense> _filterExpenses(List<Expense> expenses) {
    return expenses.where((expense) {
      final inRange =
          !expense.expenseDate.isBefore(_selectedRange.start) &&
          expense.expenseDate.isBefore(_selectedRange.end);
      final matchesCategory =
          _selectedCategory == null || expense.category == _selectedCategory;
      return inRange && matchesCategory;
    }).toList();
  }

  int _totalAmount(List<Expense> expenses) {
    return expenses.fold<int>(0, (sum, expense) => sum + expense.amount);
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  ExpenseReportData _buildReportData(List<Expense> expenses) {
    final filterLabel = _selectedCategory == null
        ? 'كل التصنيفات من ${_formatDate(_selectedRange.start)} إلى ${_formatDate(_selectedRange.end)}'
        : '${categoryLabel(_selectedCategory!)} من ${_formatDate(_selectedRange.start)} إلى ${_formatDate(_selectedRange.end)}';

    return ExpenseReportData(
      rows: expenses.map(_toReportRow).toList(),
      totalAmount: _totalAmount(expenses),
      filterLabel: filterLabel,
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

  Future<void> _exportPdf(List<Expense> expenses) async {
    setState(() => _isExporting = true);
    try {
      final styles = await PdfStyles.load();
      final doc = ExpenseReportPdf.generate(styles, _buildReportData(expenses));
      final savedPath = await PdfGenerator.shareOrPrint(
        doc,
        PdfReportFileNames.dated('كشف المصروفات'),
      );
      if (!mounted) return;
      PdfGenerator.showSavedSnackBar(context, savedPath);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expenseListProvider);

    return AppDrawerScaffold(
      title: 'كشف المصروفات',
      currentRoute: '/reports/expenses',
      leading: IconButton(
        tooltip: 'الرجوع للتقارير',
        icon: const BackButtonIcon(),
        onPressed: () => context.go('/reports'),
      ),
      child: Scaffold(
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<ExpenseCategory?>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(labelText: 'التصنيف'),
                    items: [
                      const DropdownMenuItem<ExpenseCategory?>(
                        value: null,
                        child: Text('كل التصنيفات'),
                      ),
                      ...ExpenseCategory.values.map(
                        (category) => DropdownMenuItem<ExpenseCategory?>(
                          value: category,
                          child: Text(categoryLabel(category)),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedCategory = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  DateRangePickerWidget(
                    onRangeChanged: (range) {
                      setState(() => _selectedRange = range);
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: expensesAsync.when(
                data: (expenses) {
                  final filteredExpenses = _filterExpenses(expenses);
                  if (filteredExpenses.isEmpty) {
                    return const Center(child: Text('لا توجد مصروفات'));
                  }

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'الإجمالي: ${formatMoney(_totalAmount(filteredExpenses))}',
                                style: Theme.of(context).textTheme.titleMedium,
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
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: filteredExpenses.length,
                          itemBuilder: (context, index) {
                            final expense = filteredExpenses[index];
                            final note = expense.note?.trim();
                            final title = note == null || note.isEmpty
                                ? 'مصروف بدون ملاحظة'
                                : note;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(
                                  title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${formatMoney(expense.amount)} - ${_formatDate(expense.expenseDate)} - ${categoryLabel(expense.category)}',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('خطأ: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
