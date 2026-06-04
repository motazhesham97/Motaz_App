import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/device_service.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../application/follow_up_providers.dart';
import '../data/follow_up_task.dart';

class FollowUpTasksScreen extends ConsumerWidget {
  const FollowUpTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(followUpTasksProvider);
    return AppDrawerScaffold(
      title: 'مهام المتابعة',
      currentRoute: '/follow-up',
      child: tasks.when(
        data: (items) => items.isEmpty
            ? const _EmptyTasks()
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(followUpTasksProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) => _TaskCard(
                    task: items[index],
                  ),
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemCount: items.length,
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends ConsumerWidget {
  const _TaskCard({required this.task});

  final FollowUpTask task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _color(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.14),
                  child: Icon(_icon(), color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.clientName,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(task.message),
            if (task.amount != null || task.expiryDate != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (task.amount != null)
                    _InfoChip(
                      label: 'القيمة',
                      value: '${formatMoneyPlain(task.amount!)} ر.ي.',
                    ),
                  if (task.quantity != null)
                    _InfoChip(
                      label: 'الكمية',
                      value: task.quantity.toString(),
                    ),
                  if (task.limit != null)
                    _InfoChip(
                      label: 'الحد',
                      value: '${formatMoneyPlain(task.limit!)} ر.ي.',
                    ),
                  if (task.expiryDate != null)
                    _InfoChip(
                      label: 'انتهى في',
                      value: _formatDate(task.expiryDate!),
                    ),
                ],
              ),
            ],
            if (task.type == FollowUpTaskType.expiredProduct) ...[
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _createReturn(context, ref),
                    icon: const Icon(Icons.assignment_return_rounded),
                    label: const Text('عمل مرتجع'),
                  ),
                  FilledButton.icon(
                    onPressed: () => _renewProductionDate(context, ref),
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('تجديد تاريخ الإنتاج'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _icon() {
    return switch (task.type) {
      FollowUpTaskType.creditLimit => Icons.account_balance_wallet_rounded,
      FollowUpTaskType.invoiceGap => Icons.event_busy_rounded,
      FollowUpTaskType.expiredProduct => Icons.warning_amber_rounded,
    };
  }

  Color _color(BuildContext context) {
    return switch (task.type) {
      FollowUpTaskType.creditLimit => Colors.orange.shade700,
      FollowUpTaskType.invoiceGap => Theme.of(context).colorScheme.primary,
      FollowUpTaskType.expiredProduct => Theme.of(context).colorScheme.error,
    };
  }

  Future<void> _renewProductionDate(BuildContext context, WidgetRef ref) async {
    final lineId = task.invoiceLineId;
    if (lineId == null) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !context.mounted) return;

    try {
      final device = await ref
          .read(deviceServiceProvider)
          .ensureCurrentDevice();
      await ref
          .read(followUpRepositoryProvider)
          .renewProductionDate(
            invoiceLineId: lineId,
            productionDate: picked,
            deviceId: device.id,
          );
      ref.invalidate(followUpTasksProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث تاريخ الإنتاج')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

  Future<void> _createReturn(BuildContext context, WidgetRef ref) async {
    final lineId = task.invoiceLineId;
    if (lineId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('عمل مرتجع'),
        content: Text(
          'سيتم إنشاء مرتجع حقيقي للكمية المتبقية من ${task.productName ?? 'المنتج'}'
          ' بقيمة ${formatMoneyPlain(task.amount ?? 0)} ر.ي.، وسيتم خصمها من رصيد العميل.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('تأكيد المرتجع'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final device = await ref
          .read(deviceServiceProvider)
          .ensureCurrentDevice();
      await ref
          .read(followUpRepositoryProvider)
          .createExpiredProductReturn(
            invoiceLineId: lineId,
            deviceId: device.id,
          );
      ref.invalidate(followUpTasksProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء المرتجع وخصم قيمته من رصيد العميل'),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'لا توجد مهام متابعة الآن',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
