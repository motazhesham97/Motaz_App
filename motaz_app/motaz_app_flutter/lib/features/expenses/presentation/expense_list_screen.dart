import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/device_service.dart';
import '../../../core/database/enums/parent_entity_type.dart';
import '../../../core/database/enums/record_status.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/audit_trail_sheet.dart';
import '../application/expense_providers.dart';
import 'expense_form_screen.dart' show ExpenseFormScreen, categoryLabel;

class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() =>
      _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = query.trim();
        });
      }
    });
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _formatMoney(int minorUnits) {
    return '${(minorUnits / 100).toStringAsFixed(2)} ر.ي.';
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
      final device =
          await ref.read(deviceServiceProvider).ensureCurrentDevice();
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
    final expensesAsync = _searchQuery.isEmpty
        ? ref.watch(expenseListProvider)
        : ref.watch(expenseSearchProvider(_searchQuery));

    return AppDrawerScaffold(
      title: 'المصروفات',
      currentRoute: '/expenses',
      child: Scaffold(
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'بحث...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            Expanded(
              child: expensesAsync.when(
                data: (expenses) {
                  if (expenses.isEmpty) {
                    return const Center(
                      child: Text('لا توجد مصروفات'),
                    );
                  }
                  return ListView.builder(
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      final expense = expenses[index];
                      final isVoided =
                          expense.status == RecordStatus.VOIDED;

                      return Opacity(
                        opacity: isVoided ? 0.6 : 1.0,
                        child: ListTile(
                          title: Text(categoryLabel(expense.category)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_formatMoney(expense.amount)} - ${_formatDate(expense.expenseDate)}',
                              ),
                              if (expense.note != null &&
                                  expense.note!.isNotEmpty)
                                Text(
                                  expense.note!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.history, size: 20),
                                tooltip: 'سجل التعديلات',
                                onPressed: () {
                                  showAuditTrailSheet(context, ref, ParentEntityType.EXPENSE, expense.id);
                                },
                              ),
                              if (isVoided)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.red.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'ملغى',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                )
                              else
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  onSelected: (value) {
                                    if (value == 'void') {
                                      _showVoidDialog(expense);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'void',
                                      child: Text('إلغاء المصروف'),
                                    ),
                                  ],
                                ),
                            ],
                          ),
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
                        ),
                      );
                    },
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, stack) =>
                    Center(child: Text('خطأ: $error')),
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
}
