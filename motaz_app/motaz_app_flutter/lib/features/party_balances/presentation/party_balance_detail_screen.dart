import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/device_service.dart';
import '../../../core/database/enums/party_account.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../application/party_balance_providers.dart';
import '../data/party_balance_transaction.dart';

class PartyBalanceDetailScreen extends ConsumerWidget {
  const PartyBalanceDetailScreen({super.key, required this.party});

  final PartyAccount party;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(partyBalanceProvider(party));
    final transactionsAsync = ref.watch(
      partyBalanceTransactionsProvider(party),
    );

    return AppDrawerScaffold(
      title: party.displayName,
      currentRoute: '/party-balances',
      leading: IconButton(
        tooltip: 'ط·آ§ط¸â€‍ط·آ±ط·آ¬ط¸ث†ط·آ¹',
        icon: const BackButtonIcon(),
        onPressed: () => context.go('/party-balances'),
      ),
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: () async {
            _invalidateParty(ref);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              balanceAsync.when(
                data: (balance) => _BalanceHeader(
                  party: party,
                  balance: balance,
                  onAddAmount: () => _showAdjustmentDialog(context, ref),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('خطأ: $e')),
              ),
              const SizedBox(height: 24),
              Text(
                'سجل المعاملات',
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFFFFFFFF),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              transactionsAsync.when(
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: Text('لا توجد معاملات')),
                    );
                  }
                  return Column(
                    children: transactions.map((transaction) {
                      final canEdit =
                          transaction.type ==
                          PartyBalanceTransactionType.manualAddition;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _TransactionTile(
                          transaction: transaction,
                          onEdit: canEdit
                              ? () => _showAdjustmentDialog(
                                  context,
                                  ref,
                                  transaction: transaction,
                                )
                              : null,
                          onDelete: canEdit
                              ? () => _confirmDeleteAdjustment(
                                  context,
                                  ref,
                                  transaction,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('خطأ: $e')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _invalidateParty(WidgetRef ref) {
    ref.invalidate(partyBalancesProvider);
    ref.invalidate(partyBalanceProvider(party));
    ref.invalidate(partyBalanceTransactionsProvider(party));
  }

  Future<void> _showAdjustmentDialog(
    BuildContext context,
    WidgetRef ref, {
    PartyBalanceTransaction? transaction,
  }) async {
    final isEditing = transaction != null;
    final amountController = TextEditingController(
      text: isEditing
          ? (transaction.amount.abs() / 100).toStringAsFixed(2)
          : null,
    );
    final noteController = TextEditingController(text: transaction?.note ?? '');
    var selectedDate = transaction?.date ?? DateTime.now();
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                isEditing
                    ? 'تعديل مبلغ ${party.displayName}'
                    : 'إضافة مبلغ إلى ${party.displayName}',
                textAlign: TextAlign.right,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'المبلغ',
                        suffixText: 'ر.ي.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(labelText: 'ملاحظة'),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_month_rounded),
                      title: Text(_formatDate(selectedDate)),
                      subtitle: const Text('التاريخ'),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () {
                          FocusManager.instance.primaryFocus?.unfocus();
                          Navigator.of(dialogContext).pop();
                        },
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final parsed = double.tryParse(
                            amountController.text.trim(),
                          );
                          if (parsed == null || parsed <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('أدخل مبلغًا أكبر من صفر'),
                              ),
                            );
                            return;
                          }

                          setState(() => saving = true);
                          final device = await ref
                              .read(deviceServiceProvider)
                              .ensureCurrentDevice();
                          final repository = ref.read(
                            partyAdjustmentRepositoryProvider,
                          );
                          final amount = (parsed * 100).round();
                          if (isEditing) {
                            await repository.update(
                              id: transaction.id,
                              amount: amount,
                              adjustmentDate: selectedDate,
                              note: noteController.text,
                              deviceId: device.id,
                            );
                          } else {
                            await repository.create(
                              party: party,
                              amount: amount,
                              adjustmentDate: selectedDate,
                              note: noteController.text,
                              deviceId: device.id,
                            );
                          }

                          _invalidateParty(ref);
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEditing
                                      ? 'تم تعديل المبلغ'
                                      : 'تمت إضافة المبلغ',
                                ),
                              ),
                            );
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEditing ? 'حفظ' : 'إضافة'),
                ),
              ],
            );
          },
        );
      },
    );
    await Future<void>.delayed(const Duration(milliseconds: 450));
    amountController.dispose();
    noteController.dispose();
  }

  Future<void> _confirmDeleteAdjustment(
    BuildContext context,
    WidgetRef ref,
    PartyBalanceTransaction transaction,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف المبلغ؟', textAlign: TextAlign.right),
        content: const Text(
          'سيتم حذف الإضافة اليدوية من رصيد الطرف ومزامنة الحذف.',
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final device = await ref.read(deviceServiceProvider).ensureCurrentDevice();
    await ref
        .read(partyAdjustmentRepositoryProvider)
        .delete(transaction.id, device.id);
    _invalidateParty(ref);

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حذف المبلغ')));
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _BalanceHeader extends StatelessWidget {
  const _BalanceHeader({
    required this.party,
    required this.balance,
    required this.onAddAmount,
  });

  final PartyAccount party;
  final int balance;
  final VoidCallback onAddAmount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isNegative = balance < 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              party.displayName,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: const Color(0xFFFFFFFF),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              formatMoney(balance),
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: isNegative ? colorScheme.error : colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAddAmount,
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة مبلغ'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    this.onEdit,
    this.onDelete,
  });

  final PartyBalanceTransaction transaction;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPositive = transaction.amount >= 0;
    final amountColor = isPositive ? colorScheme.secondary : colorScheme.error;

    return Card(
      child: ListTile(
        leading: Icon(_iconFor(transaction.type), color: amountColor),
        title: Text(
          transaction.title,
          textAlign: TextAlign.right,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: const Color(0xFFFFFFFF),
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          [
            _formatDate(transaction.date),
            if (transaction.note != null && transaction.note!.trim().isNotEmpty)
              transaction.note!.trim(),
          ].join(' - '),
          textAlign: TextAlign.right,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFFFFFFFF),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatMoney(transaction.amount),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: amountColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (onEdit != null || onDelete != null) ...[
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit?.call();
                  if (value == 'delete') onDelete?.call();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('تعديل')),
                  PopupMenuItem(value: 'delete', child: Text('حذف')),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(PartyBalanceTransactionType type) {
    return switch (type) {
      PartyBalanceTransactionType.distribution => Icons.pie_chart_rounded,
      PartyBalanceTransactionType.manualAddition => Icons.add_circle_rounded,
      PartyBalanceTransactionType.withdrawal => Icons.call_made_rounded,
    };
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
